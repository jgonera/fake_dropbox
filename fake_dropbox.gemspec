# -*- encoding: utf-8 -*-
$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
require "fake_dropbox/version"

Gem::Specification.new do |s|
  s.name        = "fake_dropbox"
  s.version     = FakeDropbox::VERSION
  s.authors     = ["Juliusz Gonera"]
  s.email       = ["jgonera@gmail.com"]
  s.homepage    = "https://github.com/jgonera/fake_dropbox"
  s.summary     = %q{A simple fake implementation of the Dropbox API}
  s.description = %q{Written in Ruby using the Sinatra framework. For development and testing purposes, no real authentication and users, stores files on the local machine. Can be used either as a standalone app listening on a port or intercept calls to the real Dropbox in Ruby apps.}

  s.rubyforge_project = "fake_dropbox"
  s.extra_rdoc_files  = ['README.md', 'LICENSE']

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  
  s.add_dependency 'sinatra', '~> 1.2.6'
  s.add_dependency 'json', '~> 1.6.1'
  s.add_dependency 'rack', '~> 1.3.2'
  s.add_dependency 'rack-test', '~> 0.6.1'
  s.add_dependency 'webmock', '~> 1.7.7'
  
  s.add_development_dependency 'rspec', '~> 2.7.0'
end
