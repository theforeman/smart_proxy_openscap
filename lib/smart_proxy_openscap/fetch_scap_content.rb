require 'smart_proxy_openscap/fetch_file'

module Proxy::OpenSCAP
  class FetchScapContent < FetchFile
    def get_policy_content(policy_id, digest)
      policy_store_dir = File.join(Proxy::OpenSCAP.fullpath(Proxy::OpenSCAP::Plugin.settings.contentdir), policy_id.to_s)
      policy_scap_file = File.join(policy_store_dir, "#{policy_id}_#{digest}.xml")
      file_download_path = "api/v2/compliance/policies/#{policy_id}/content"

      create_store_dir policy_store_dir

      scap_file = policy_content_file(policy_scap_file)
      clean_store_folder(policy_store_dir) unless scap_file
      scap_file ||= save_or_serve_scap_file(policy_scap_file, file_download_path)
    end
  end
end
