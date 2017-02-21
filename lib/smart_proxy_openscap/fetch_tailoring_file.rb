require 'smart_proxy_openscap/fetch_file'

module Proxy::OpenSCAP
  class FetchTailoringFile < FetchFile
    def get_tailoring_file(policy_id, digest)
      store_dir = File.join(Proxy::OpenSCAP.fullpath(Proxy::OpenSCAP::Plugin.settings.tailoring_dir), policy_id.to_s)
      policy_tailoring_file = File.join(store_dir, "#{policy_id}_#{digest}.xml")
      file_download_path = "api/v2/compliance/policies/#{policy_id}/tailoring"

      create_store_dir store_dir

      scap_file = policy_content_file(policy_tailoring_file)
      clean_store_folder(store_dir) unless scap_file
      scap_file ||= save_or_serve_scap_file(policy_tailoring_file, file_download_path)
    end
  end
end
