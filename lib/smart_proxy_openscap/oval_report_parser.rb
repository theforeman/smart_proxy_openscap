require 'smart_proxy_openscap/openscap_exception'
require 'openscap_parser/oval_report'

module Proxy::OpenSCAP
  class OvalReportParser
    include Proxy::Log

    def parse_cves(report_data)
      report = oval_report report_data
      results = report.definition_results.reduce({}) do |memo, result|
        memo.tap { |acc| acc[result.definition_id] = parse_cve_res result }
      end

      report.definitions.map do |definition|
        results[definition.id].merge(parse_cve_def definition)
      end
    end

    private

    def parse_cve_def(definition)
      refs = definition.references.reduce([]) do |memo, ref|
        memo.tap { |acc| acc << { :ref_id => ref.ref_id, :ref_url => ref.ref_url } }
      end

      { :references => refs, :definition_id => definition.id }
    end

    def parse_cve_res(result)
      { :result => result.result }
    end

    def oval_report(report_data)
      decompressed = decompress report_data
      ::OpenscapParser::OvalReport.new(decompressed)
    end

    def decompress(report_data)
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
      decompressed
    end
  end
end
