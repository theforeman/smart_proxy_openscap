module Proxy::OpenSCAP
  class FetchScapContent
    include ::Proxy::Log
    def get_policy_content(policy_id)
      policy_store_dir = File.join(Proxy::OpenSCAP.fullpath(Proxy::OpenSCAP::Plugin.settings.contentdir), policy_id.to_s)
      policy_scap_file = File.join(policy_store_dir, "#{policy_id}_scap_content.xml")
      begin
        logger.info "Creating directory to store SCAP file: #{policy_store_dir}"
        FileUtils.mkdir_p(policy_store_dir) # will fail silently if exists
      rescue Errno::EACCES => e
        logger.error "No permission to create directory #{policy_store_dir}"
        raise e
      rescue StandardError => e
        logger.error "Could not create '#{policy_store_dir}' directory: #{e.message}"
        raise e
      end

      scap_file = policy_content_file(policy_scap_file)
      scap_file ||= save_or_serve_scap_file(policy_id, policy_scap_file)
      scap_file
    end

    private

    def policy_content_file(policy_scap_file)
      return nil if !File.file?(policy_scap_file) || File.zero?(policy_scap_file)
      File.open(policy_scap_file, 'rb').read
    end

    def save_or_serve_scap_file(policy_id, policy_scap_file)
      lock = Proxy::FileLock::try_locking(policy_scap_file)
      response = fetch_scap_content_xml(policy_id, policy_scap_file)
      if lock.nil?
        return response
      else
        begin
          File.open(policy_scap_file, 'wb') do |file|
            file << response
          end
        ensure
          Proxy::FileLock::unlock(lock)
        end
        scap_file = policy_content_file(policy_scap_file)
        raise FileNotFound if scap_file.nil?
        return scap_file
      end
    end

    def fetch_scap_content_xml(policy_id, policy_scap_file)
      foreman_request = Proxy::HttpRequest::ForemanRequest.new
      policy_content_path = "api/v2/compliance/policies/#{policy_id}/content"
      req = foreman_request.request_factory.create_get(policy_content_path)
      response = foreman_request.send_request(req)
      response.value
      response.body
    end
  end
end
