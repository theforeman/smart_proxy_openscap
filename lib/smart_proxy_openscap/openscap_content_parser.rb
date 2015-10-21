require 'openscap/ds/sds'
require 'openscap/source'
require 'openscap/xccdf/benchmark'

module Proxy::OpenSCAP
  class ContentParser
    def initialize(scap_content)
      OpenSCAP.oscap_init
      @source = OpenSCAP::Source.new(:content => scap_content)
    end

    def extract_policies
      policies = {}
      bench = benchmark_profiles
      bench.profiles.each do |key, profile|
        policies[key] = profile.title
      end
      bench.destroy
      policies.to_json
    end

    def validate
      errors = []
      allowed_type = 'SCAP Source Datastream'
      if @source.type != allowed_type
        errors << "Uploaded file is not #{allowed_type}"
      end

      begin
        @source.validate!
      rescue OpenSCAP::OpenSCAPError
        errors << "Invalid SCAP file type"
      end
      {:errors => errors}.to_json
    end

    def guide(policy)
      sds = OpenSCAP::DS::Sds.new @source
      sds.select_checklist
      profile_id = policy ? nil : policy
      html = sds.html_guide profile_id
      sds.destroy
      {:html => html.force_encoding('UTF-8')}.to_json
    end

    private

    def benchmark_profiles
      sds          = ::OpenSCAP::DS::Sds.new(@source)
      bench_source = sds.select_checklist!
      benchmark = ::OpenSCAP::Xccdf::Benchmark.new(bench_source)
      sds.destroy
      benchmark
    end
  end
end
