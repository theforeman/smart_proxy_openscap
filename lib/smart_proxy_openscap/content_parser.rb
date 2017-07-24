require 'smart_proxy_openscap/shell_wrapper'

module Proxy::OpenSCAP
  class ContentParser < ShellWrapper
    def initialize(type)
      @type = type
      @script_name = 'smart-proxy-scap-validation'
    end

    def validate(scap_file)
      execute_shell_command scap_file
    end

    def out_filename
      "#{in_filename}json-"
    end

    def in_filename
      "#{super}-#{@type}-validate-"
    end

    def failure_message
      "Failure when running script which validates scap files"
    end

    def command(in_file, out_file)
      "#{script_location} #{in_file.path} #{out_file.path} #{@type}"
    end
  end
end
