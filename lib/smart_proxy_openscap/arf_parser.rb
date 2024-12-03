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
        decompressed = Tempfile.create do |file|
          file.write(arf_data)
          file.flush
          Proxy::OpenSCAP.execute!('bunzip2', '-dc', file.path).first
        rescue => e
          logger.error e
          raise Proxy::OpenSCAP::ReportDecompressError, "Failed to decompress received report bzip, cause: #{e.message}"
        end
        arf_file = ::OpenscapParser::TestResultFile.new(decompressed)
        rules = arf_file.benchmark.rules.to_h { |rule| [rule.id, rule] }

        arf_digest = Digest::SHA256.hexdigest(arf_data)
        report = parse_results(rules, arf_file.test_result, arf_digest)
        report[:openscap_proxy_name] = Proxy::OpenSCAP::Plugin.settings.registered_proxy_name
        report[:openscap_proxy_url] = Proxy::OpenSCAP::Plugin.settings.registered_proxy_url
        report.to_json
      end

      private

      def parse_results(rules, test_result, arf_digest)
        set_values = test_result.set_values
        passed = 0
        failed = 0
        othered = 0

        logs = test_result.rule_results.filter_map do |result|
          next if result.result == 'notapplicable' || result.result == 'notselected'

          # get rules and their results
          rule_data = rules[result.id]
          # create metrics for the results
          case result.result
            when 'pass', 'fixed'
              passed += 1
            when 'fail'
              failed += 1
            else
              othered += 1
          end

          populate_result_data(result.id, result.result, rule_data, set_values)
        end

        {
          logs: logs,
          digest: arf_digest,
          metrics: { :passed => passed, :failed => failed, :othered => othered },
          score: test_result.score,
        }
      end

      def populate_result_data(result_id, rule_result, rule_data, set_values)
        {
          source: result_id,
          result: rule_result,
          title: rule_data.title,
          description: rule_data.description,
          rationale: rule_data.rationale,
          references: rule_data.references.map { |ref| { :href => ref.href, :title => ref.label }},
          fixes: populate_fixes(rule_data.fixes, set_values),
          severity: rule_data.severity,
        }
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
