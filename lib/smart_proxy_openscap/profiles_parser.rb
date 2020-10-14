require 'openscap_parser/datastream_file'
require 'openscap_parser/tailoring_file'

module Proxy
  module OpenSCAP
    class ProfilesParser
      def profiles(file_type, scap_file)
        profiles = []
        error_msg = 'Failed to parse profiles'
        begin
          case file_type
          when 'scap_content'
            profiles = ::OpenscapParser::DatastreamFile.new(scap_file).benchmark.profiles
          when 'tailoring_file'
            profiles = ::OpenscapParser::TailoringFile.new(scap_file).tailoring.profiles
          else
            raise OpenSCAPException, "Unknown file type, expected 'scap_content' or 'tailoring_file'"
          end
        rescue Nokogiri::XML::SyntaxError
          raise OpenSCAPException, error_msg
        end

        raise OpenSCAPException, error_msg if profiles.empty?

        result = profiles.reduce({}) do |memo, profile|
          memo.tap { |acc| acc[profile.id] = profile.title }
        end.to_json
      end
    end
  end
end
