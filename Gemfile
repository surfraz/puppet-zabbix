source 'https://rubygems.org'

group :development, :test do
  gem 'rake'
  gem 'puppetlabs_spec_helper', :require => false
  gem 'rspec-system-puppet'
  gem 'rspec-system-serverspec'
  gem 'puppet-lint'
  gem 'yarjuf'
  gem "rspec-puppet", :git => 'https://github.com/rodjek/rspec-puppet.git'
  gem 'simplecov-rcov'
  gem 'simplecov'
  gem 'cover_me'
  gem 'xml-simple'
end

if puppetversion = ENV['PUPPET_GEM_VERSION']
  gem 'puppet', puppetversion, :require => false
else
  gem 'puppet', :require => false
end

# vim:ft=ruby
