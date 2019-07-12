source 'https://rubygems.org'
gemspec

group :development do
  gem 'test-unit'
  gem 'pry'
  gem 'pry-byebug'
  gem 'rubocop'
  gem 'rack', '~> 1.6.8' if Gem::Version.new(RUBY_VERSION) < Gem::Version.new('2.2')
  gem 'smart_proxy', :github => "theforeman/smart-proxy", :branch => 'develop'
end

# load local gemfile
local_gemfile = File.join(File.dirname(__FILE__), 'Gemfile.local.rb')
self.instance_eval(Bundler.read_file(local_gemfile)) if File.exist?(local_gemfile)
