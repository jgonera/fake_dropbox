require 'sinatra/base'
require 'json'
require 'fileutils'
require 'fake_dropbox/utils'

module FakeDropbox
  class Server < Sinatra::Base
    before do
      if not request.path.start_with?('/__sinatra__')
        @dropbox_dir = env['DROPBOX_DIR'] || ENV['DROPBOX_DIR']
        raise 'no DROPBOX_DIR in ENV' if not @dropbox_dir
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
    
    post '/:version/oauth/request_token' do
      'oauth_token_secret=fake&oauth_token=fake'
    end
    
    post '/:version/oauth/access_token' do
      'oauth_token_secret=fake&oauth_token=fake'
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
      file_path = File.join(params[:splat])
      dir = File.join(@dropbox_dir, File.dirname(file_path))
      return status 404 unless File.exists?(dir) and File.directory?(dir)

      File.open(File.join(@dropbox_dir, file_path), 'w+') do |file|
        file.write(request.body.read)
      end

      content_type :json
      metadata(file_path).to_json
    end
    
    get '/:version/metadata/:mode*' do
      content_type :json
      metadata(params[:splat][0], params['list'] == 'true').to_json
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
      
      FileUtils.remove_entry_secure entry_path
    end
  end
end
