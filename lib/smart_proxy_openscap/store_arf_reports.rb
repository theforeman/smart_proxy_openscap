require 'smart_proxy_openscap/store_arf_fs'
module Proxy::OpenSCAP
  class StoreArfReports < StoreArfFS
    def store(cn, id, date, data)
      begin
        target_dir = create_directory(Proxy::OpenSCAP::Plugin.settings.reportsdir, cn, id, date)
      rescue StandardError => e
        raise Proxy::OpenSCAP::StoreReportError, "Could not fulfill request: #{e.message}"
      end

      begin
        target_path = store_arf(target_dir, data)
      rescue StandardError => e
        raise Proxy::OpenSCAP::StoreReportError, "Could not store file: #{e.message}"
      end

      logger.debug "File #{target_path} stored in reports dir."
    end
  end
end
