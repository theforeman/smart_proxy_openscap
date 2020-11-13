require 'smart_proxy_openscap/fetch_file'

module Proxy::OpenSCAP
  class FetchScapFile < FetchFile
    def initialize(type)
      @download_path = case type
                       when :scap_content
                          "api/v2/compliance/policies/:policy_id/content"
                       when :tailoring_file
                          "api/v2/compliance/policies/:policy_id/tailoring"
                       when :oval_content
                          "api/v2/compliance/oval_policies/:policy_id/oval_content"
                       else
                         raise "Expected one of: :scap_content, :tailoring_file, :oval_content, got: #{type}"
                       end
    end

    def fetch(policy_id, digest, content_dir)
      store_dir = File.join(Proxy::OpenSCAP.fullpath(content_dir), policy_id.to_s)
      scap_file = File.join(store_dir, "#{policy_id}_#{digest}.xml")

      file_download_path = @download_path.sub(':policy_id', policy_id)

      create_store_dir store_dir
      file = policy_content_file scap_file
      clean_store_folder store_dir unless file
      file ||= save_or_serve_scap_file scap_file, file_download_path
    end
  end
end
