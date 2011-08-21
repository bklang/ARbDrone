# -*- ruby -*-
ENV['RUBY_FLAGS'] = "-I#{%w(lib ext bin spec).join(File::PATH_SEPARATOR)}"

require 'rubygems'
require 'bundler/gem_tasks'
require 'bundler/setup'

task :default => :spec
task :gem => :build

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new


