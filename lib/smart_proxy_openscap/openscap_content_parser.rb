require 'openscap/ds/sds'
require 'openscap/source'
require 'openscap/xccdf/benchmark'
require 'openscap/xccdf/tailoring'

module Proxy::OpenSCAP
  class ContentParser
    def initialize(scap_file, type = 'scap_content')
      OpenSCAP.oscap_init
      @source = OpenSCAP::Source.new(:content => scap_file)
      @type = type
    end

    def allowed_types
      {
        'tailoring_file' => 'XCCDF Tailoring',
        'scap_content' => 'SCAP Source Datastream'
      }
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

    def get_profiles
      tailoring = ::OpenSCAP::Xccdf::Tailoring.new(@source, nil)
      profiles = tailoring.profiles.inject({}) do |memo, (key, profile)|
        memo.tap { |hash| hash[key] = profile.title }
      end
      tailoring.destroy
      profiles.to_json
    end

    def validate
      errors = []

      if @source.type != allowed_types[@type]
        errors << "Uploaded file is #{@source.type}, unexpected file type"
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
