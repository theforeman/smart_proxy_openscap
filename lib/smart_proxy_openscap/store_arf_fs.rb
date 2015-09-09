module Proxy::OpenSCAP
  class StoreArfFS
    include ::Proxy::Log
    def store(cn, id, data)
      raise NotImplementedError
    end

    private

    def store_arf(spool_arf_dir, data)
      filename = Digest::SHA256.hexdigest data
      target_path = spool_arf_dir + filename
      File.open(target_path,'w') { |f| f.write(data) }
      target_path
    end

    def validate_id(id)
      raise Proxy::OpenSCAP::OpenSCAPException, 'Malformed policy ID' unless /\A\d+\Z/ =~ id
    end

    def create_directory(directory, common_name, id, date)
      validate_id(id)
      dir = "#{directory}/arf/#{common_name}/#{id}/#{date}/"
      begin
        FileUtils.mkdir_p dir
      rescue StandardError => e
        logger.error "Could not create '#{dir}' directory: #{e.message}"
        raise e
      end
      dir
    end
  end
end
