# encoding=utf-8
require 'openscap'
require 'openscap/ds/arf'
require 'openscap/xccdf/testresult'
require 'openscap/xccdf/ruleresult'
require 'openscap/xccdf/rule'
require 'openscap/xccdf/fix'
require 'openscap/xccdf/benchmark'
require 'json'
require 'digest'

module Proxy
  module OpenSCAP
    class ArfJson
      def as_json(file_in, file_out)
        ::OpenSCAP.oscap_init
        arf_digest   = Digest::SHA256.hexdigest(File.read(file_in))

        arf          = ::OpenSCAP::DS::Arf.new(file_in)
        test_result  = arf.test_result

        results      = test_result.rr
        sds          = arf.report_request
        bench_source = sds.select_checklist!
        benchmark    = ::OpenSCAP::Xccdf::Benchmark.new(bench_source)
        items        = benchmark.items

        report = parse_results(items, results, arf_digest)
        File.write file_out, report.to_json
      ensure
        cleanup test_result, benchmark, sds, arf
      end

      private

      def parse_results(items, results, arf_digest)
        report       = {}
        report[:logs] = []
        passed        = 0
        failed        = 0
        othered         = 0
        results.each do |rr_id, result|
          next if result.result == 'notapplicable' || result.result == 'notselected'
          # get rules and their results
          rule_data = items[rr_id]
          report[:logs] << populate_result_data(rr_id, result.result, rule_data)
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
        report
      end

      def populate_result_data(result_id, rule_result, rule_data)
        log               = {}
        log[:source]      = ascii8bit_to_utf8(result_id)
        log[:result]      = ascii8bit_to_utf8(rule_result)
        log[:title]       = ascii8bit_to_utf8(rule_data.title)
        log[:description] = ascii8bit_to_utf8(rule_data.description)
        log[:rationale]   = ascii8bit_to_utf8(rule_data.rationale)
        log[:references]  = hash_a8b(rule_data.references.map(&:to_hash))
        log[:fixes]       = hash_a8b(rule_data.fixes.map(&:to_hash))
        log[:severity]    = ascii8bit_to_utf8(rule_data.severity)
        log
      end

      def cleanup(*args)
        args.compact.map(&:destroy)
        ::OpenSCAP.oscap_cleanup
      end

      # Unfortunately openscap in ruby 1.9.3 outputs data in Ascii-8bit.
      # We transform it to UTF-8 for easier json integration.

      # :invalid ::
      #   If the value is invalid, #encode replaces invalid byte sequences in
      #   +str+ with the replacement character.  The default is to raise the
      #   Encoding::InvalidByteSequenceError exception
      # :undef ::
      #   If the value is undefined, #encode replaces characters which are
      #   undefined in the destination encoding with the replacement character.
      #   The default is to raise the Encoding::UndefinedConversionError.
      # :replace ::
      #   Sets the replacement string to the given value. The default replacement
      #   string is "\uFFFD" for Unicode encoding forms, and "?" otherwise.
      def ascii8bit_to_utf8(string)
        return ascii8bit_to_utf8_legacy(string) if RUBY_VERSION.start_with? '1.8'
        string.to_s.encode('utf-8', :invalid => :replace, :undef => :replace, :replace => '_')
      end

      # String#encode appeared first in 1.9, so we need a workaround for 1.8
      def ascii8bit_to_utf8_legacy(string)
        Iconv.conv('UTF-8//IGNORE', 'UTF-8', string.to_s)
      end

      def hash_a8b(ary)
        ary.map do |hash|
          Hash[hash.map { |key, value| [ascii8bit_to_utf8(key), ascii8bit_to_utf8(value)] }]
        end
      end
    end
  end
end
