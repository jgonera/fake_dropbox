ENV['RACK_ENV'] = 'test'

require 'rack/test'
require 'fake_dropbox'
require 'tmpdir'
require 'fileutils'

module TestHelpers
  def fixture_path(filename='')
    File.join(File.dirname(__FILE__), 'fixtures', filename)
  end
end

RSpec.configure do |conf|
  conf.include Rack::Test::Methods
  conf.include TestHelpers
end

# ugly hack to show app errors when running rspec ;)
module FakeDropbox
  class Server
    configure :test do
      disable :raise_errors
    end

    error do
      e = env['sinatra.error']
      puts e.to_s
      puts e.backtrace.join("\n")
    end
  end
end

def app
  FakeDropbox::Server
end

