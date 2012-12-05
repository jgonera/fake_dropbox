require 'sinatra/base'
require 'json'
require 'time'
require 'fileutils'
require 'fake_dropbox/utils'
require 'fake_dropbox/config'

module FakeDropbox
  class Server < Sinatra::Base
    set :show_exceptions, false

    MEDIA_EXPIRATION = 4 * 60 * 60 # in seconds
    NO_AUTH_PATHS = ['/__', '/u/', '/0/view/']

    before do
      if FakeDropbox::Config.authorized or
          NO_AUTH_PATHS.any?{ |path| request.path.start_with?(path) }
        @dropbox_dir = ENV['DROPBOX_DIR']
        raise 'no DROPBOX_DIR in ENV' if not @dropbox_dir
        if FakeDropbox::Config.debug
          puts "#{request.request_method} #{request.path}"
          request.env.select { |k, v| k.start_with? 'HTTP_' }.each do |k, v|
            puts "#{k}: #{v}"
          end
          puts request.body.read
          request.body.rewind
        end
      else
        halt 401
      end
    end

    helpers FakeDropbox::Utils

    not_found do
      # only catch 404 not returned by the API
      if request.env['sinatra.error'].class == Sinatra::NotFound
        puts "[fake_dropbox] Unknown URI: #{request.request_method} #{request.path}"
        "Unknown URI: #{request.request_method} #{request.path}"
      end
    end

    post '/__config__' do
      params.each do |key, value|
        setter = "#{key}="
        FakeDropbox::Config.send(setter, to_bool(value)) if FakeDropbox::Config.respond_to? setter
      end
    end

    post '/:version/oauth/request_token' do
      return status 401 unless FakeDropbox::Config.authorize_request_token
      'oauth_token_secret=request_secret&oauth_token=request_token'
    end

    post '/:version/oauth/access_token' do
      return status 401 unless FakeDropbox::Config.authorize_access_token
      'oauth_token_secret=access_secret&oauth_token=access_token'
    end

    post '/:version/files/:mode*' do
      dir = File.join(@dropbox_dir, params[:splat])
      return status 404 unless File.exists?(dir) and File.directory?(dir)

      tempfile = params[:file][:tempfile]
      filename = params[:file][:filename]
      file_path = File.join(params[:splat], filename)
      FileUtils.cp(tempfile.path, File.join(@dropbox_dir, file_path))
      File.delete(tempfile.path) if File.exists? tempfile.path

      result = if params[:version] == '0'
        { 'result' => 'winner!' }
      else
        metadata(file_path)
      end

      content_type :json
      result.to_json
    end

    get '/:version/files/:mode*' do
      file_path = File.join(@dropbox_dir, params[:splat])
      return status 404 unless File.exists?(file_path)

      IO.read(file_path)
    end

    put '/:version/files_put/:mode*' do
      dropbox_path = params[:splat][0]
      file_path = File.join(@dropbox_dir, dropbox_path)
      dir = File.dirname(file_path)

      return status 400 if File.directory?(file_path)
      return status 400 if File.exists?(dir) and not File.directory?(dir)

      FileUtils.makedirs(dir)
      File.open(file_path, 'w+') do |file|
        file.write(request.body.read)
      end
      update_metadata(dropbox_path)

      content_type :json
      metadata(dropbox_path).to_json
    end

    get '/:version/metadata/:mode*' do
      file_path = File.join(@dropbox_dir, params[:splat][0])
      return status 404 unless File.exists?(file_path)

      list = (params[:list] != 'false')
      content_type :json
      metadata(params[:splat][0], list).to_json
    end

    get '/u/:uid/*' do
      file_path = File.join(@dropbox_dir, 'Public', params[:splat])
      return status 404 unless File.exists?(file_path)

      IO.read(file_path)
    end

    get '/0/view/fake_media_path/*' do
      file_path = File.join(@dropbox_dir, params[:splat])
      return status 404 unless File.exists?(file_path)

      IO.read(file_path)
    end

    get '/1/media/:mode*' do
      file_path = File.join(@dropbox_dir, params[:splat])
      return status 404 unless File.exists?(file_path)

      {
        url: "https://dl.dropbox.com/0/view/fake_media_path#{params[:splat][0]}",
        expires: (Time.now + MEDIA_EXPIRATION).rfc822
      }.to_json
    end

    post '/:version/fileops/create_folder' do
      dir = params[:path]
      dir_path = File.join(@dropbox_dir, dir)

      return status 400 unless ['dropbox', 'sandbox'].include? params[:root]
      return status 403 if File.exists?(dir_path)
      # seems that directories are created recursively (API docs wrong?)
      #return status 404 unless File.exists?(File.dirname(dir_path))

      FileUtils.mkdir_p dir_path

      content_type :json
      metadata(dir).to_json
    end

    post '/:version/fileops/delete' do
      entry = safe_path(params[:path])
      entry_path = File.join(@dropbox_dir, entry)

      return status 404 unless File.exists?(entry_path)

      metadata = metadata(entry)
      FileUtils.remove_entry_secure entry_path

      # todo: update metadata store with a new "deleted" metadata entry

      if params[:version] == '1'
        content_type :json
        metadata.to_json
      end
    end
  end
end
