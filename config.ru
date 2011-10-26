$LOAD_PATH.unshift File.expand_path(File.join(File.dirname(__FILE__), 'lib'))
require 'fake_dropbox/server'
run FakeDropbox::Server
