require 'smart_proxy_openscap/foreman_forwarder'

module Proxy::OpenSCAP
  class ForemanOvalForwarder < ForemanForwarder
    private

    def parse_report(cname, policy_id, date, report_data)
      {
        :oval_results => OvalReportParser.new.parse_cves(report_data),
        :oval_policy_id => policy_id,
        :cname => cname
      }.to_json
    end

    def report_upload_path(cname, policy_id, date)
      upload_path "oval_reports", cname, policy_id, date
    end
  end
end
