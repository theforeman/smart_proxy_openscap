require 'smart_proxy_openscap/foreman_forwarder'

module Proxy::OpenSCAP
  class ForemanArfForwarder < ForemanForwarder
    private

    def parse_report(cname, policy_id, date, report_data)
      Proxy::OpenSCAP::ArfParser.new(cname, policy_id, date).as_json(data)
    end

    def report_upload_path(cname, policy_id, date)
      upload_path "arf_reports", cname, policy_id, date
    end
  end
end
