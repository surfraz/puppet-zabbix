require 'rubygems'
require 'bundler/setup'

Bundler.require :default

require 'puppetlabs_spec_helper/rake_tasks'
require 'rspec-system/rake_task'
require 'puppet-lint/tasks/puppet-lint'


PuppetLint.configuration.send('disable_80chars')
PuppetLint.configuration.send('disable_class_inherits_from_params_class')
PuppetLint.configuration.send('disable_quoted_booleans')
PuppetLint.configuration.log_format = "%{path}:%{linenumber}:%{check}:%{KIND}:%{message}"

task :default => [:help]