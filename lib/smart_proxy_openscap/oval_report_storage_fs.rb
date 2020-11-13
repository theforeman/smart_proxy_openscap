require 'smart_proxy_openscap/storage_fs_common'
require 'smart_proxy_openscap/openscap_exception'

module Proxy::OpenSCAP
  class OvalReportStorageFs
    include StorageFsCommon

    def initialize(path_to_dir, oval_policy_id, cname, reported_at)
      @namespace = 'oval'
      @reported_at = reported_at
      @path = "#{path_to_dir}/#{@namespace}/#{oval_policy_id}/#{cname}/"
    end

    def store_report(report_data)
      store(report_data, StoreReportError)
    end

    private

    def store_file(path_to_store, report_data)
      target_path = "#{path_to_store}#{@reported_at}"
      File.open(target_path, 'w') { |f| f.write(report_data) }
      target_path
    end
  end
end
