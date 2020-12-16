module Proxy::OpenSCAP
  class SpoolForwarder
    include ::Proxy::Log

    def initialize(loaded_settings)
      @loaded_settings = loaded_settings
    end

    def post_arf_from_spool(arf_dir)
      Dir.foreach(arf_dir) do |cname|
        next if cname == '.' || cname == '..'
        cname_dir = File.join(arf_dir, cname)
        forward_cname_dir(cname, cname_dir) if File.directory?(cname_dir)
      end
    end

    private

    def forward_cname_dir(cname, cname_dir)
      Dir.foreach(cname_dir) do |policy_id|
        next if policy_id == '.' || policy_id == '..'
        policy_dir = File.join(cname_dir, policy_id)
        if File.directory?(policy_dir)
          forward_policy_dir(cname, policy_id, policy_dir)
        end
      end
      remove_if_empty(cname_dir)
    end

    def forward_policy_dir(cname, policy_id, policy_dir)
      Dir.foreach(policy_dir) do |date|
        next if date == '.' || date == '..'
        date_dir = File.join(policy_dir, date)
        if File.directory?(date_dir)
          forward_date_dir(cname, policy_id, date, date_dir)
        end
      end
      remove_if_empty(policy_dir)
    end

    def forward_date_dir(cname, policy_id, date, date_dir)
      Dir.foreach(date_dir) do |arf|
        next if arf == '.' || arf == '..'
        arf_path = File.join(date_dir, arf)
        if File.file?(arf_path)
          logger.debug("Uploading #{arf} to Foreman")
          forward_arf_file(cname, policy_id, date, arf_path)
        end
      end
      remove_if_empty(date_dir)
    end

    def forward_arf_file(cname, policy_id, date, arf_file_path)
      data = File.open(arf_file_path, 'rb') { |io| io.read }
      post_to_foreman = ForemanArfForwarder.new.post_report(cname, policy_id, date, data, @loaded_settings.timeout)
      Proxy::OpenSCAP::StorageFs.new(@loaded_settings.reportsdir, cname, post_to_foreman['id'], date).store_archive(data)
      File.delete arf_file_path
    rescue Nokogiri::XML::SyntaxError, Proxy::OpenSCAP::ReportDecompressError => e
      logger.error "Failed to parse Arf Report at #{arf_file_path}, moving to #{@loaded_settings.corrupted_dir}"

      Proxy::OpenSCAP::StorageFs.new(@loaded_settings.corrupted_dir, cname, policy_id, date).
        move_corrupted(arf_file_path.split('/').last, @loaded_settings.spooldir)
    rescue Proxy::OpenSCAP::ReportUploadError => e
      logger.error "Failed to upload Arf Report at #{arf_file_path}, cause: #{e.message}, the report will be deleted."
      File.delete arf_file_path
    rescue StandardError => e
      logger.error "smart-proxy-openscap-send failed to upload Compliance report for #{cname}, generated on #{Time.at date.to_i}. Cause: #{e}"
    end

    def remove_if_empty(dir)
      begin
        Dir.delete dir if Dir["#{dir}/*"].empty?
        logger.debug "Removing directory: #{dir}"
      rescue StandardError => e
        logger.error "Could not remove directory: #{e.message}"
      end
    end
  end
end
