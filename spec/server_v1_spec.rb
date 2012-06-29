require 'spec_helper'

describe 'FakeDropbox::Server' do
  before do
    @tmpdir = Dir.mktmpdir 'fake_dropbox-test'
    @env = { 'DROPBOX_DIR' => @tmpdir }
  end
  
  after do
    FileUtils.remove_entry_secure @tmpdir
  end
  
  describe "POST /1/oauth/request_token" do
    it "returns a fake OAuth request token" do
      post "/1/oauth/request_token", {}, @env
      #File.open('/home/julas/Desktop/aaa.html', 'w') {|f| f.write(last_response.body) }
      last_response.should be_ok
      last_response.body.should include 'oauth_token=', 'oauth_token_secret='
    end
  end
  
  describe "POST /1/oauth/access_token" do
    it "returns a fake OAuth access token" do
      post "/1/oauth/access_token", {}, @env
      last_response.should be_ok
      last_response.body.should include 'oauth_token=', 'oauth_token_secret='
    end
  end


end
