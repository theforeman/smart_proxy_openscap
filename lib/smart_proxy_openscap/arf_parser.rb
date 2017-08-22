require 'smart_proxy_openscap/shell_wrapper'

module Proxy
  module OpenSCAP
    class ArfParser < ShellWrapper

      def initialize(cname, policy_id, date)
        @cname = cname
        @policy_id = policy_id
        @date = date
        @script_name = 'smart-proxy-arf-json'
      end

      def as_json(arf_data)
        execute_shell_command arf_data
      end

      def in_filename
        "#{super}-#{@cname}-#{@policy_id}-#{@date}-"
      end

      def out_filename
        "#{in_filename}json-"
      end

      def failure_message
        "Failure when running script which parses reports"
      end

      def command(in_file, out_file)
        "#{script_location} #{in_file.path} #{out_file.path}"
      end
    end
  end
end
