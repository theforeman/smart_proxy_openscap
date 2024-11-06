require 'open3'

module Proxy::OpenSCAP
  class ValidateSettings < ::Proxy::PluginValidators::Base
    def validate!(_settings)
      _, _, _ = Open3.popen3(['oscap', '--help'])
    rescue Errno::ENOENT
      raise FileNotFound.new("'oscap' utility is not available")
    end
  end
end
