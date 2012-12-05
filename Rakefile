require "bundler/gem_tasks"

require 'rspec/core/rake_task'

task :default => [:spec]

desc "run ruby tests"
RSpec::Core::RakeTask.new do |task|
  task.pattern = "spec/**/*_spec.rb"
  task.rspec_opts = [ '-f documentation', '--color', '--backtrace']
  task.verbose = false
end
