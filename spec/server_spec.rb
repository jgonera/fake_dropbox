require 'spec_helper'

describe 'FakeDropbox::Server' do
  before :each do
    @tmpdir = Dir.mktmpdir 'fake_dropbox-test'
    ENV['DROPBOX_DIR'] = @tmpdir
    FakeDropbox::Config.reset!
  end

  after :each do
    FileUtils.remove_entry_secure @tmpdir
  end

  it "returns error 401 for any API request if not authorized" do
    post "/__config__", { authorized: false }
    get "/0/files/dropbox/file.ext"
    last_response.status.should == 401
  end

  it "outputs debug to STDIO when debug set to true" do
    post "/__config__", { debug: true }
    original_stdout = $stdout
    $stdout = StringIO.new
    put "/1/files_put/dropbox/file", "test body"
    $stdout.string.should =~ /^PUT \/1\/files_put\/dropbox\/file\nHTTP.*\ntest body\n$/m
    $stdout = original_stdout
  end

  describe "POST /<version>/oauth/request_token" do
    it "returns a fake OAuth request token" do
      post "/0/oauth/request_token"
      last_response.should be_ok
      last_response.body.should include 'oauth_token=', 'oauth_token_secret='
    end

    it "returns error 401 when not authorized" do
      post "/__config__", { authorize_request_token: false }
      post "/0/oauth/request_token"
      last_response.status.should == 401
    end
  end

  describe "POST /<version>/oauth/access_token" do
    it "returns a fake OAuth access token" do
      post "/0/oauth/access_token"
      last_response.should be_ok
      last_response.body.should include 'oauth_token=', 'oauth_token_secret='
    end

    it "returns error 401 when not authorized" do
      post "/__config__", { authorize_access_token: false }
      post "/0/oauth/access_token"
      last_response.status.should == 401
    end
  end

  describe "POST /<version>/files/dropbox/<path>" do
    let(:uploaded_file) { Rack::Test::UploadedFile.new(fixture_path('dummy.txt')) }
    let(:params) { { file: uploaded_file } }

    shared_examples_for "correct POST upload" do
      it "saves the file in the directory" do
        post "/0/files/dropbox" + path, params
        Dir.entries(dir).should include 'dummy.txt'
        original_content = File.new(fixture_path('dummy.txt')).read
        uploaded_content = File.new(File.join(dir, 'dummy.txt')).read
        uploaded_content.should == original_content
      end

      it "deletes the temporary file (RackMultipart*)" do
        post "/0/files/dropbox" + path, params
        tempfile = last_request.params['file'][:tempfile]
        File.exists?(tempfile.path).should == false
      end

      it "returns success message for version 0" do
        post "/0/files/dropbox" + path, params
        last_response.should be_ok
        response = JSON.parse(last_response.body)
        response.should == { 'result' => 'winner!' }
      end

      it "returns file metadata for version 1" do
        post "/1/files/dropbox" + path, params
        last_response.should be_ok
        metadata = JSON.parse(last_response.body)
        metadata['path'].should == path + '/dummy.txt'
        metadata['modified'].should include Time.new.strftime('%a, %d %b %Y %H:%M')
      end

    end

    context "when the path is root" do
      let(:path) { '' }
      let(:dir) { @tmpdir }

      it_behaves_like "correct POST upload"
    end

    context "when the path is not root" do
      context "when the path exists" do
        let(:path) { '/somedir' }
        let(:dir) { File.join(@tmpdir, path) }
        before { Dir.mkdir(dir) }

        it_behaves_like "correct POST upload"
      end

      context "when the path does not exist" do
        it "returns error 404" do
          post "/0/files/dropbox/incorrect", params
          last_response.status.should == 404
        end
      end
    end
  end

  describe "PUT /<version>/files_put/dropbox/<path>" do
    let(:body) { IO.read(fixture_path('dummy.txt')) }

    shared_examples_for "correct PUT upload" do
      it "saves the file in the directory" do
        put "/1/files_put/dropbox" + path, body
        Dir.entries(dir).should include 'dummy.txt'
        uploaded_content = IO.read(File.join(dir, 'dummy.txt'))
        uploaded_content.should == body
      end

      it "returns file metadata" do
        put "/1/files_put/dropbox" + path, body
        last_response.should be_ok
        metadata = JSON.parse(last_response.body)
        metadata['path'].should == path
        metadata['modified'].should include Time.new.strftime('%a, %d %b %Y %H:%M')
      end

      it "returns updated revision number in file metadata" do
        put "/1/files_put/dropbox" + path, body
        metadata = JSON.parse(last_response.body)
        rev_1 = metadata['rev']

        put "/1/files_put/dropbox" + path, body
        metadata = JSON.parse(last_response.body)
        rev_2 = metadata['rev']

        rev_2.should_not eq(rev_1)
        rev_1.should_not be_nil
        rev_2.should_not be_nil
      end

    end

    shared_examples_for "failed PUT upload" do
      it "returns error 400" do
        put "/1/files_put/dropbox" + path, body
        last_response.status.should == 400
      end
    end

    context "when the path is root" do
      let(:path) { '/dummy.txt' }
      let(:dir) { @tmpdir }

      it_behaves_like "correct PUT upload"
    end

    context "when the path is not root and already exists" do
      let(:path) { '/somedir/dummy.txt' }
      let(:dir) { File.join(@tmpdir, 'somedir') }
      before { Dir.mkdir(dir) }

      it_behaves_like "correct PUT upload"
    end

    context "when the path is not root and does not exist" do
      let(:path) { '/somedir/dummy.txt' }
      let(:dir) { File.join(@tmpdir, 'somedir') }

      it_behaves_like "correct PUT upload"
    end

    context "when the target filename already exists and is a directory" do
      let(:path) { '/dummy' }
      before { Dir.mkdir(File.join(@tmpdir, 'dummy')) }

      it_behaves_like "failed PUT upload"
    end

    context "when the target directory name already exists and is a file" do
      let(:path) { '/something/dummy.txt' }
      before { File.open(File.join(@tmpdir, 'something'), 'w') }

      it_behaves_like "failed PUT upload"
    end
  end

  describe "GET /<version>/files/dropbox/<path>" do
    context "when the file exists" do
      before do
        File.open(File.join(@tmpdir, 'file.ext'), 'w') do |f|
          f.write "This is a test."
        end
      end

      it "returns file contents" do
        get "/0/files/dropbox/file.ext"
        last_response.should be_ok
        last_response.body.should == "This is a test."
      end
    end

    context "when the file does not exist" do
      it "returns error 404" do
        get "/0/files/dropbox/none.ext"
        last_response.status.should == 404
      end
    end
  end

  describe "GET /<version>/metadata/dropbox/<path>" do
    it "returns metadata" do
      File.open(File.join(@tmpdir, 'file.ext'), 'w')
      get "/0/metadata/dropbox/file.ext", { list: 'false' }
      last_response.should be_ok
      metadata = JSON.parse(last_response.body)
      metadata['path'].should == '/file.ext'
      metadata.should_not include 'contents'
    end

    context "when the path is a directory and want a list" do
      it "returns its children metadata too" do
        FileUtils.cp(fixture_path('dummy.txt'), @tmpdir)
        get "/0/metadata/dropbox"
        last_response.should be_ok
        metadata = JSON.parse(last_response.body)
        metadata.should include 'contents'
      end
    end
  end

  describe "GET /1/media/dropbox/<path>" do
    it "returns a temporary file URL" do
      File.open(File.join(@tmpdir, 'file.ext'), 'w')
      get "/1/media/dropbox/file.ext"
      media_data = JSON.parse(last_response.body)
      media_data['url'].should ==
        'https://dl.dropbox.com/0/view/fake_media_path/file.ext'
      media_data.should include 'expires'
    end
  end

  describe "GET /0/view/fake_media_path/<path>" do
    before do
      File.open(File.join(@tmpdir, 'file.ext'), 'w') do |f|
        f.write "This is a test."
      end
    end

    it "returns file contents without authorizing" do
      post "/__config__", { authorized: false }
      get "/0/view/fake_media_path/file.ext"
      last_response.should be_ok
      last_response.body.should == "This is a test."
    end
  end

  describe "GET /u/<uid>/<path>" do
    before do
      Dir.mkdir(File.join(@tmpdir, 'Public'))
      File.open(File.join(@tmpdir, 'Public', 'file.ext'), 'w') do |f|
        f.write "This is a test."
      end
    end

    it "returns files from the Public directory without authorizing" do
      post "/__config__", { authorized: false }
      get "/u/8675309/file.ext"
      last_response.should be_ok
      last_response.body.should == "This is a test."
    end
  end

  describe "POST /<version>/fileops/create_folder" do
    shared_examples_for "creating folder" do
      let(:params) { { path: path, root: 'dropbox' } }

      it "creates a folder" do
        post "/0/fileops/create_folder", params
        File.exists?(File.join(@tmpdir, path)).should == true
        File.directory?(File.join(@tmpdir, path)).should == true
      end

      it "returns folder's metadata" do
        metadata = post "/0/fileops/create_folder", params
        last_response.should be_ok
        metadata = JSON.parse(last_response.body)
        metadata['path'].should == path
      end
    end

    context "when the path to the folder exists" do
      let(:path) { '/somedir' }

      it_behaves_like "creating folder"
    end

    context "when the path to the folder does not exist" do
      let(:path) { '/nonexistant/somedir' }

      it_behaves_like "creating folder"
    end

    context "when the root is neither 'dropbox' nor 'sandbox'" do
      let(:params) { { path: '/somedir', root: 'wrong' } }

      it "returns error 400" do
        post "/0/fileops/create_folder", params
        last_response.status.should == 400
      end
    end

    # seems that directories are created recursively (API docs wrong?)
#    context "when the path to the folder does not exist" do
#      let(:params) { { path: '/nonexistant/somedir', root: 'dropbox' } }
#
#      it "returns error 404" do
#        post "/0/fileops/create_folder", params
#        last_response.status.should == 404
#      end
#    end

    context "when the path already exists" do
      let(:params) { { path: '/somedir', root: 'dropbox' } }
      before { Dir.mkdir(File.join(@tmpdir, 'somedir')) }

      it "returns error 403" do
        post "/0/fileops/create_folder", params
        last_response.status.should == 403
      end
    end
  end

  describe "POST /<version>/fileops/delete" do
    let(:params) { { path: '/file.ext', root: 'dropbox' } }

    context "when the path exists" do

      shared_examples_for "deleting entry" do
        it "removes the entry" do
          post '/0/fileops/delete', params
          last_response.should be_ok
          File.exists?(abs_path).should == false
        end

        it "returns entry's metadata for version 0" do
          post '/0/fileops/delete', params
          last_response.body.should be_empty
        end

        it "returns entry's metadata for version 1" do
          post '/1/fileops/delete', params
          metadata = JSON.parse(last_response.body)
          metadata['path'].should == params[:path]
        end
      end

      context "when it's a non-empty directory" do
        let(:params) { { path: '/somedir', root: 'dropbox' } }
        let(:abs_path) { File.join(@tmpdir, params[:path]) }
        before do
          Dir.mkdir(abs_path)
          File.open(File.join(abs_path, 'file.ext'), 'w') { |f| f.write "Test file" }
        end

        it_behaves_like "deleting entry"
      end

      context "when it's not a non-empty directory" do
        let(:params) { { path: '/file.ext', root: 'dropbox' } }
        let(:abs_path) { File.join(@tmpdir, params[:path]) }
        before { File.open(abs_path, 'w') { |f| f.write "Test file" } }

        it_behaves_like "deleting entry"
      end

    end

    context "when the path doesn't exist" do
      let(:params) { { path: '/nonexistant.ext', root: 'dropbox' } }

      it "returns error 404" do
        post '/0/fileops/delete', params
        last_response.status.should == 404
      end
    end
  end
end
