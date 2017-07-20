# encoding=utf-8
require 'tempfile'

module Proxy
  module OpenSCAP
    class Parse
      include ::Proxy::Log
      include ::Proxy::Util

      def initialize(cname, policy_id, date)
        @cname = cname
        @policy_id = policy_id
        @date = date
      end

      def as_json(arf_data)
        in_file = Tempfile.new("#{filename}json-", "/var/tmp")
        json_file = Tempfile.new(filename, "/var/tmp")
        begin
          in_file.write arf_data
          command = "#{script_location} #{in_file.path} #{json_file.path}"
          logger.debug "Executing: #{command}"
          `#{command}`
          json_file.read
        rescue => e
          logger.debug "Failure when running script which parses reports"
          logger.debug e.backtrace.join("\n\t")
          return nil
        ensure
          in_file.close
          in_file.unlink
          json_file.close
          json_file.unlink
        end
      end

      def filename
        "#{@cname}-#{@policy_id}-#{@date}-"
      end

      def script_location
        path = File.join(File.dirname(File.expand_path(__FILE__)), '../..','bin/smart-proxy-parse-arf')
        return path if File.exist? path
        "smart-proxy-parse-arf"
      end
    end
  end
end
