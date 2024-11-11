require 'openscap'
require 'openscap/ds/arf'

module Proxy
  module OpenSCAP
    class ArfHtml
      def generate_html(file_in, file_out)
        ::OpenSCAP.oscap_init
        File.write file_out, get_arf_html(file_in)
      ensure
        ::OpenSCAP.oscap_cleanup
      end

      def get_arf_html(file_in)
        arf_object = ::OpenSCAP::DS::Arf.new(file_in)
        arf_object.html.force_encoding('UTF-8')
      end
    end
  end
end
