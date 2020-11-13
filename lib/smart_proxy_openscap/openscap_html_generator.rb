require 'smart_proxy_openscap/storage_fs'
require 'smart_proxy_openscap/shell_wrapper'

module Proxy
  module OpenSCAP
    class OpenscapHtmlGenerator < ShellWrapper
      def initialize(cname, id, date, digest)
        @cname = cname
        @id = id
        @date = date
        @digest = digest
        @script_name = 'smart-proxy-arf-html'
      end

      def get_html
        execute_shell_command
      end

      def out_filename
        "#{super}-#{@cname}-#{@id}-#{@date}-#{@digest}-"
      end

      def command(in_file, out_file)
        "#{script_location} #{file_path_in_storage} #{out_file.path}"
      end

      def failure_message
        "Failure when running script which generates html reports"
      end

      def file_path_in_storage
        path_to_dir = Proxy::OpenSCAP::Plugin.settings.reportsdir
        storage = Proxy::OpenSCAP::StorageFs.new(path_to_dir, @cname, @id, @date)
        storage.get_path(@digest)
      end
    end
  end
end
