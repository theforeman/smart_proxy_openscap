require 'smart_proxy_openscap/fetch_file'

module Proxy::OpenSCAP
  class FetchScapFile < FetchFile
    def initialize(type)
      raise "Expected one of the following symbols: #{allowed_types.join(', ')}, got: #{type}" unless allowed_types.include? type
      @type = type
    end

    def fetch(policy_id, digest, content_dir)
      store_dir = File.join(Proxy::OpenSCAP.fullpath(content_dir), policy_id.to_s)
      scap_file = File.join(store_dir, file_name(policy_id, digest))

      file_download_path = download_path.sub(':policy_id', policy_id)
      create_store_dir store_dir
      file = policy_content_file scap_file
      clean_store_folder store_dir unless file
      file ||= save_or_serve_scap_file scap_file, file_download_path
    end

    def download_path
      case @type
      when :scap_content
        "api/v2/compliance/policies/:policy_id/content"
      when :tailoring_file
        "api/v2/compliance/policies/:policy_id/tailoring"
      when :oval_content
        "api/v2/compliance/oval_policies/:policy_id/oval_content"
      end
    end

    def file_name(policy_id, digest)
      case @type
      when :scap_content, :tailoring_file
        "#{policy_id}_#{digest}.xml"
      when :oval_content
        "#{digest}.oval.xml.bz2"
      end
    end

    def allowed_types
      [:scap_content, :tailoring_file, :oval_content]
    end
  end
end
