require 'openscap'
require 'openscap/ds/sds'
require 'openscap/source'
require 'openscap/xccdf/benchmark'
require 'openscap/xccdf/tailoring'
require 'json'

module Proxy
  module OpenSCAP
    class ScapProfiles
      def profiles(in_file, out_file, type)
        ::OpenSCAP.oscap_init
        source = ::OpenSCAP::Source.new(in_file)
        json = type == 'scap_content' ? scap_content_profiles(source) : tailoring_profiles(source)
        File.write out_file, json
        source.destroy
        ::OpenSCAP.oscap_cleanup
      end

      def scap_content_profiles(source)
        bench = benchmark_profiles source
        profiles = collect_profiles bench
        bench.destroy
        profiles.to_json
      end

      def tailoring_profiles(source)
        tailoring = ::OpenSCAP::Xccdf::Tailoring.new(source, nil)
        profiles = collect_profiles tailoring
        tailoring.destroy
        profiles.to_json
      end

      def collect_profiles(profile_source)
        profile_source.profiles.inject({}) do |memo, (key, profile)|
          memo.tap { |hash| hash[key] = profile.title.strip }
        end
      end

      def benchmark_profiles(source)
        sds          = ::OpenSCAP::DS::Sds.new(source)
        bench_source = sds.select_checklist!
        benchmark = ::OpenSCAP::Xccdf::Benchmark.new(bench_source)
        sds.destroy
        benchmark
      end
    end
  end
end
