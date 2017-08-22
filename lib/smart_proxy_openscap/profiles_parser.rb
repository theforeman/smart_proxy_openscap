require 'smart_proxy_openscap/shell_wrapper'

module Proxy
  module OpenSCAP
    class ProfilesParser < ShellWrapper
      def initialize(type)
        @type = type
        @script_name = 'smart-proxy-scap-profiles'
      end

      def profiles(scap_file)
        execute_shell_command scap_file
      end

      def out_filename
        "#{in_filename}json-"
      end

      def in_filename
        "#{super}-#{@type}-profiles-"
      end

      def failure_message
        "Failure when running script which extracts profiles from scap file"
      end

      def command(in_file, out_file)
        "#{script_location} #{in_file.path} #{out_file.path} #{@type}"
      end
    end
  end
end
