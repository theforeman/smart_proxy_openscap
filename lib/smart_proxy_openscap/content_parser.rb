require 'openscap_parser/datastream_file'
require 'openscap_parser/tailoring_file'

module Proxy::OpenSCAP
  class ContentParser
    include ::Proxy::Log

    def validate(file_type, scap_file)
      msg = 'Invalid XML format'
      errors = []
      file = nil
      begin
        case file_type
        when 'scap_content'
          file = ::OpenscapParser::DatastreamFile.new(scap_file)
        when 'tailoring_file'
          file = ::OpenscapParser::TailoringFile.new(scap_file)
        end
      rescue Nokogiri::XML::SyntaxError => e
        logger.error msg
        logger.error e.backtrace.join("\n")
        errors << msg
      end
      { errors: errors }
    end
  end
end
