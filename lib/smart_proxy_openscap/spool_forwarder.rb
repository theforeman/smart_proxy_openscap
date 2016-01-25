module Proxy::OpenSCAP
  class SpoolForwarder
    include ::Proxy::Log

    def post_arf_from_spool(arf_dir)
      failed = nil
      Dir.foreach(arf_dir) do |cname|
        begin
          next if cname == '.' || cname == '..'
          cname_dir = File.join(arf_dir, cname)
          forward_cname_dir(cname, cname_dir) if File.directory?(cname_dir)
        rescue StandardError => e
          logger.debug e.backtrace.join("\n\t") 
          logger.error "Failed to send SCAP results for #{cname} to the Foreman server: #{e}" 
          failed = true
        end
      end
      raise "Failed to send SCAP results for one or more hosts." if failed
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
      remove(cname_dir)
    end

    def forward_policy_dir(cname, policy_id, policy_dir)
      Dir.foreach(policy_dir) do |date|
        next if date == '.' || date == '..'
        date_dir = File.join(policy_dir, date)
        if File.directory?(date_dir)
          forward_date_dir(cname, policy_id, date, date_dir)
        end
      end
      remove(policy_dir)
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
      remove(date_dir)
    end

    def forward_arf_file(cname, policy_id, date, arf_file_path)
      data = File.open(arf_file_path, 'rb') { |io| io.read }
      post_to_foreman = ForemanForwarder.new.post_arf_report(cname, policy_id, date, data)
      Proxy::OpenSCAP::StorageFS.new(Proxy::OpenSCAP::Plugin.settings.reportsdir, cname, post_to_foreman['id'], date).store_archive(data)
      File.delete arf_file_path
    end

    def remove(dir)
      begin
        Dir.delete dir
      rescue StandardError => e
        logger.error "Could not remove directory: #{e.message}"
      end
    end
  end
end
