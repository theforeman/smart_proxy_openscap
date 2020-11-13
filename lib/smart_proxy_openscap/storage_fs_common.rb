module Proxy::OpenSCAP
  module StorageFsCommon
    include ::Proxy::Log

    private

    def create_directory
      begin
        FileUtils.mkdir_p @path
      rescue StandardError => e
        logger.error "Could not create '#{@path}' directory: #{e.message}"
        raise e
      end
      @path
    end

    def move(source, error_type)
      begin
        create_directory
        FileUtils.mv source, @path
      rescue StandardError => e
        raise error_type, "Could not move file: #{e.message}"
      end
    end

    def store(data, error_type)
      begin
        create_directory
      rescue StandardError => e
        raise error_type, "Could not fulfill request: #{e.message}"
      end

      begin
        target_path = store_file(@path, data)
      rescue StandardError => e
        raise error_type, "Could not store file: #{e.message}"
      end

      logger.debug "File #{target_path} stored in reports dir."
    end
  end
end
