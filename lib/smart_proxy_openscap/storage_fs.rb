require 'smart_proxy_openscap/storage'

module Proxy::OpenSCAP
  class StorageFS < Storage
    def store_archive(data)
      store(data, StoreReportError)
    end

    def store_spool(data)
      store(data, StoreSpoolError)
    end

    def store_failed(data)
      store(data, StoreFailedError)
    end

    def store_corrupted(data)
      store(data, StoreCorruptedError)
    end

    def move_corrupted(digest)
      source = "#{Proxy::OpenSCAP::Plugin.settings.spooldir}/#{@namespace}/#{@cname}/#{@id}/#{@date}"
      move "#{source}/#{digest}", StoreCorruptedError
    end

    def get_arf_xml(digest)
      get_arf_file(digest)[:xml]
    end

    def get_arf_html(digest)
      OpenSCAP.oscap_init
      xml = get_arf_file(digest)[:xml]
      size = get_arf_file(digest)[:size]
      arf_object = OpenSCAP::DS::Arf.new(:content => xml, :path => 'arf.xml.bz2', :length => size)
      # @TODO: Drop this when support for 1.8.7 ends
      return arf_object.html if RUBY_VERSION.start_with? '1.8'
      arf_object.html.force_encoding('UTF-8')
    end

    def delete_arf_file
      path = "#{@path_to_dir}/#{@namespace}/#{@cname}/#{@id}"
      raise FileNotFound, "Can't find path #{path}" if !File.directory?(path) || File.zero?(path)
      FileUtils.rm_r path
      {:id => @id, :deleted => true}.to_json
    end

    private

    def store_arf(spool_arf_dir, data)
      filename = Digest::SHA256.hexdigest data
      target_path = spool_arf_dir + filename
      File.open(target_path,'w') { |f| f.write(data) }
      target_path
    end

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
        target_path = store_arf(@path, data)
      rescue StandardError => e
        raise error_type, "Could not store file: #{e.message}"
      end

      logger.debug "File #{target_path} stored in reports dir."
    end

    def get_arf_file(digest)
      full_path = @path + digest
      raise FileNotFound, "Can't find path #{full_path}" if !File.file?(full_path) || File.zero?(full_path)
      file = File.open(full_path)
      { :size => File.size(file), :xml => file.read }
    end
  end
end
