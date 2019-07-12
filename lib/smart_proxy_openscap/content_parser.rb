require 'openscap_parser/datastream_file'
require 'openscap_parser/tailoring_file'

module Proxy::OpenSCAP
  class ContentParser
    def validate(file_type, scap_file)
      msg = 'Invalid SCAP file type'
      errors = []
      file = nil
      begin
        case file_type
        when 'scap_content'
          file = ::OpenscapParser::DatastreamFile.new(scap_file)
        when 'tailoring_file'
          file = ::OpenscapParser::TailoringFile.new(scap_file)
        end
        errors << msg unless file.valid?
      rescue Nokogiri::XML::SyntaxError => e
        errors << msg
      end
      { errors: errors }
    end
  end
end
