require 'openscap_parser/test_result_file'
require 'smart_proxy_openscap/openscap_exception'

module Proxy
  module OpenSCAP
    class ArfParser
      include Proxy::Log

      def initialize(cname, policy_id, date)
        @cname = cname
        @policy_id = policy_id
        @date = date
      end

      def as_json(arf_data)
        begin
          file = Tempfile.new
          file.write(arf_data)
          file.rewind
          decompressed = `bunzip2 -dc #{file.path}`
        rescue => e
          logger.error e
          raise Proxy::OpenSCAP::ReportDecompressError, "Failed to decompress received report bzip, cause: #{e.message}"
        ensure
          file.close
          file.unlink
        end
        arf_file = ::OpenscapParser::TestResultFile.new(decompressed)
        rules = arf_file.benchmark.rules.reduce({}) do |memo, rule|
          memo[rule.id] = rule
          memo
        end

        arf_digest = Digest::SHA256.hexdigest(arf_data)
        report = parse_results(rules, arf_file.test_result, arf_digest)
        report[:openscap_proxy_name] = Proxy::OpenSCAP::Plugin.settings.registered_proxy_name
        report[:openscap_proxy_url] = Proxy::OpenSCAP::Plugin.settings.registered_proxy_url
        report.to_json
      end

      private

      def parse_results(rules, test_result, arf_digest)
        results = test_result.rule_results
        set_values = test_result.set_values
        report = {}
        report[:logs] = []
        passed = 0
        failed = 0
        othered = 0
        results.each do |result|
          next if result.result == 'notapplicable' || result.result == 'notselected'
          # get rules and their results
          rule_data = rules[result.id]
          report[:logs] << populate_result_data(result.id, result.result, rule_data, set_values)
          # create metrics for the results
          case result.result
            when 'pass', 'fixed'
              passed += 1
            when 'fail'
              failed += 1
            else
              othered += 1
          end
        end
        report[:digest]  = arf_digest
        report[:metrics] = { :passed => passed, :failed => failed, :othered => othered }
        report[:score] = test_result.score
        report
      end

      def populate_result_data(result_id, rule_result, rule_data, set_values)
        log               = {}
        log[:source]      = result_id
        log[:result]      = rule_result
        log[:title]       = rule_data.title
        log[:description] = rule_data.description
        log[:rationale]   = rule_data.rationale
        log[:references]  = rule_data.references.map { |ref| { :href => ref.href, :title => ref.label }}
        log[:fixes]       = populate_fixes rule_data.fixes, set_values
        log[:severity]    = rule_data.severity
        log
      end

      def populate_fixes(fixes, set_values)
        fixes.map do |fix|
          {
            :id => fix.id,
            :system => fix.system,
            :full_text => fix.full_text(set_values),
            :reboot => fix.instance_variable_get('@parsed_xml')['reboot'] # TODO: add this to openscap_parser lib
          }
        end
      end
    end
  end
end
