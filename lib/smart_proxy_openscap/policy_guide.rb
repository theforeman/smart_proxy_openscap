require 'openscap'
require 'openscap/source'
require 'openscap/ds/sds'
require 'json'

module Proxy
  module OpenSCAP
    class PolicyGuide
      def generate_guide(in_file, out_file, policy=nil)
        ::OpenSCAP.oscap_init
        source = ::OpenSCAP::Source.new in_file
        sds = ::OpenSCAP::DS::Sds.new source
        sds.select_checklist
        html = sds.html_guide policy
        File.write(out_file, { :html => html.force_encoding('UTF-8') }.to_json)
      ensure
        sds.destroy if sds
        source.destroy if source
        ::OpenSCAP.oscap_cleanup
      end
    end
  end
end
