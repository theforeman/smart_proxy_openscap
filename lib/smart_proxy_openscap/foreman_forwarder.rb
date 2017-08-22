module Proxy::OpenSCAP
  class ForemanForwarder < Proxy::HttpRequest::ForemanRequest
    include ::Proxy::Log

    def post_arf_report(cname, policy_id, date, data)
      begin
        foreman_api_path = upload_path(cname, policy_id, date)
        json = Proxy::OpenSCAP::ArfParser.new(cname, policy_id, date).as_json(data)
        response = send_request(foreman_api_path, json)
        # Raise an HTTP error if the response is not 2xx (success).
        response.value
        res = JSON.parse(response.body)
        raise StandardError, "Received response: #{response.code} #{response.msg}" unless res['result'] == 'OK'
      rescue StandardError => e
        logger.debug response.body if response
        logger.debug e.backtrace.join("\n\t")
        raise e
      end
      res
    end

    private

    def upload_path(cname, policy_id, date)
      "/api/v2/compliance/arf_reports/#{cname}/#{policy_id}/#{date}"
    end

    def send_request(path, body)
      # Override the parent method to set the right headers
      path = [uri.path, path].join('/') unless uri.path.empty?
      req = Net::HTTP::Post.new(URI.join(uri.to_s, path).path)
      req.add_field('Accept', 'application/json,version=2')
      req.content_type = 'application/json'
      req.body = body
      http.request(req)
    end
  end
end
