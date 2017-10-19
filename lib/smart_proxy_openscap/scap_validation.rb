require 'json'
require 'openscap'
require 'openscap/source'

module Proxy
  module OpenSCAP
    class ScapValidation
      def allowed_types
        {
          'tailoring_file' => 'XCCDF Tailoring',
          'scap_content' => 'SCAP Source Datastream'
        }
      end

      def validate(in_file, out_file, type)
        errors = []
        ::OpenSCAP.oscap_init
        source = ::OpenSCAP::Source.new(in_file)
        if source.type != allowed_types[type]
          errors << "Uploaded file is #{source.type}, unexpected file type"
        end

        begin
          source.validate!
        rescue ::OpenSCAP::OpenSCAPError
          errors << "Invalid SCAP file type"
        end
        File.write out_file, { :errors => errors }.to_json
      ensure
        source.destroy if source
        ::OpenSCAP.oscap_cleanup
      end
    end
  end
end
