require 'webmock'
require 'tmpdir'
require 'fileutils'
require 'fake_dropbox/server'

module FakeDropbox
  class Glue
    attr_accessor :dropbox_dir
    
    def initialize(dropbox_dir=nil)
      # TODO: modify this if using to_rack (no actual need to pass DROPBOX_DIR, just check it)
      if dropbox_dir
        raise "Directory #{dropbox_dir} doesn't exist!" unless File.exists? dropbox_dir
        @dropbox_dir = dropbox_dir
      else
        @dropbox_dir = File.join(Dir.tmpdir, 'fake_dropbox')
        Dir.mkdir(@dropbox_dir) unless File.exists? @dropbox_dir
      end
      
      ENV['DROPBOX_DIR'] = @dropbox_dir
      WebMock.stub_request(:any, /.*dropbox.com.*/).to_rack(FakeDropbox::Server)
    end
    
    def empty!
      if File.expand_path(@dropbox_dir).start_with? Dir.tmpdir
        Dir.glob(File.join(@dropbox_dir, '*')).each do |entry|
          FileUtils.remove_entry_secure entry
        end
      else
        raise "Will not empty a directory which is outside of system's temporary path!"
      end
    end
  end
end
