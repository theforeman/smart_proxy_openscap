require 'tempfile'

module Proxy
  module OpenSCAP
    class ShellWrapper
      include ::Proxy::Log

      attr_reader :script_name

      def script_location
        raise NotImplementedError, 'Must have @script_name' unless script_name
        path = File.join(File.dirname(File.expand_path(__FILE__)), '../../bin', script_name)
        return path if File.exist? path
        script_name
      end

      def execute_shell_command(in_file_content = nil)
        out_file = Tempfile.new(out_filename, "/var/tmp")
        in_file = prepare_in_file in_file_content
        comm = command(in_file, out_file)
        logger.debug "Executing: #{comm}"
        output = nil
        begin
          `#{comm}`
          output = out_file.read
        rescue => e
          logger.debug failure_message
          logger.debug e.message
          logger.debug e.backtrace.join("\n\t")
        ensure
          close_unlink out_file, in_file
        end
        raise OpenSCAPException, exception_message if output.nil? || output.empty?
        output
      end

      def close_unlink(*files)
        files.compact.each do |file|
          file.close
          file.unlink
        end
      end

      def prepare_in_file(in_file_content)
        return unless in_file_content
        file = Tempfile.new(in_filename, "/var/tmp")
        file.write in_file_content
        file.rewind
        file
      end

      def in_filename
        @in_filename ||= unique_filename
      end

      def out_filename
        @out_filename ||= unique_filename
      end

      def unique_filename
        SecureRandom.uuid
      end

      def command(in_file, out_file)
        raise NotImplementedError, "Must be implemented"
      end

      def failure_message
        raise NotImplementedError, "Must be implemented"
      end

      def exception_message
        failure_message
      end
    end
  end
end
