require 'rack/test'
require 'test/unit'
require 'webmock/test_unit'
require 'mocha/test_unit'
require 'json'
require 'ostruct'
require 'tempfile'

require 'smart_proxy_for_testing'

# create log directory in our (not smart-proxy) directory
FileUtils.mkdir_p File.dirname(Proxy::SETTINGS.log_file)
APP_ROOT = "#{File.dirname(__FILE__)}/.."
