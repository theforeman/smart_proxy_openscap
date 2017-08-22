require 'smart_proxy_openscap/shell_wrapper'

module Proxy
  module OpenSCAP
    class PolicyParser < ShellWrapper

      def initialize(policy)
        @script_name = "smart-proxy-policy-guide"
        @policy = policy
      end

      def guide(scap_file)
        execute_shell_command scap_file
      end

      def in_filename
        super
      end

      def out_filename
        "#{in_filename}json-"
      end

      def failure_message
        "Failure when running script which renders policy guide"
      end

      def command(in_file, out_file)
        "#{script_location} #{in_file.path} #{out_file.path} #{@policy}"
      end
    end
  end
end
