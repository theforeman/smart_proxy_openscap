require 'smart_proxy_openscap/openscap_exception'
require 'openscap_parser/oval_report'

module Proxy::OpenSCAP
  class OvalReportParser
    include Proxy::Log

    def as_json(report_data)
      begin
        file = Tempfile.new
        file.write report_data
        file.rewind
        decompressed = `bunzip2 -dc #{file.path}`
      rescue => e
        logger.error e
        raise Proxy::OpenSCAP::ReportDecompressError, "Failed to decompress received report bzip, cause: #{e.message}"
      ensure
        file.close
        file.unlink
      end
      parse_report(decompressed).to_json
    end

    private

    def parse_report(decompressed)
      report = ::OpenscapParser::OvalReport.new(decompressed)

      results = report.definition_results.reduce({}) do |memo, result|
        memo.tap { |acc| acc[result.definition_id] = result.to_h }
      end

      report.definitions.map do |definition|
        results[definition.id].merge(definition.to_h)
      end
    end
  end
end
