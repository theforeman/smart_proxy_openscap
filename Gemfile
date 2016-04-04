source 'https://rubygems.org'
gemspec

group :development do
  gem 'pry'
  gem 'rubocop'
  gem 'smart_proxy', :github => "theforeman/smart-proxy", :branch => 'develop'
end

# load local gemfile
local_gemfile = File.join(File.dirname(__FILE__), 'Gemfile.local.rb')
self.instance_eval(Bundler.read_file(local_gemfile)) if File.exist?(local_gemfile)
