source 'https://rubygems.org'
gemspec

group :development do
  gem 'test-unit'
  gem 'pry'
  gem 'pry-byebug'
  gem 'rubocop'
  gem 'smart_proxy', :github => "theforeman/smart-proxy", :branch => ENV.fetch('SMART_PROXY_BRANCH', 'develop')
end

# load local gemfile
local_gemfile = File.join(File.dirname(__FILE__), 'Gemfile.local.rb')
self.instance_eval(Bundler.read_file(local_gemfile)) if File.exist?(local_gemfile)
