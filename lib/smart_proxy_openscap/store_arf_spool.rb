require 'smart_proxy_openscap/store_arf_fs'
module Proxy::OpenSCAP
  class StoreArfSpool < StoreArfFS
    def store(cn, id, date, data)
      begin
        target_dir = create_directory(Proxy::OpenSCAP::Plugin.settings.spooldir, cn, id, date)
      rescue StandardError => e
        raise Proxy::OpenSCAP::StoreSpoolError, "Could not fulfill request: #{e.message}"
      end

      begin
        target_path = store_arf(target_dir, data)
      rescue StandardError => e
        raise Proxy::OpenSCAP::StoreSpoolError, "Could not store file: #{e.message}"
      end

      logger.debug "File #{target_path} stored in spool for later processing."
    end
  end
end
