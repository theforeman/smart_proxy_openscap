module Proxy::OpenSCAP
  class FetchFile
    include ::Proxy::Log

    private

    def create_store_dir(store_dir)
      logger.info "Creating directory to store SCAP file: #{store_dir}"
      FileUtils.mkdir_p(store_dir) # will fail silently if exists
    rescue Errno::EACCES => e
      logger.error "No permission to create directory #{store_dir}"
      raise e
    rescue StandardError => e
      logger.error "Could not create '#{store_dir}' directory: #{e.message}"
      raise e
    end

    def policy_content_file(policy_scap_file)
      return nil if !File.file?(policy_scap_file) || File.zero?(policy_scap_file)
      File.open(policy_scap_file, 'rb').read
    end

    def clean_store_folder(policy_store_dir)
      FileUtils.rm_f Dir["#{policy_store_dir}/*.xml"]
    end

    def save_or_serve_scap_file(policy_scap_file, file_download_path)
      lock = Proxy::FileLock::try_locking(policy_scap_file)
      response = fetch_scap_content_xml(file_download_path)
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

    def fetch_scap_content_xml(file_download_path)
      foreman_request = Proxy::HttpRequest::ForemanRequest.new
      req = foreman_request.request_factory.create_get(file_download_path)
      timeout = Proxy::OpenSCAP::Plugin.settings.timeout
      foreman_request.http.read_timeout = timeout if timeout
      response = foreman_request.send_request(req)
      response.value
      response.body
    end

    def clean_store_folder(policy_store_dir)
      FileUtils.rm_f Dir["#{policy_store_dir}/*.xml"]
    end
  end
end
