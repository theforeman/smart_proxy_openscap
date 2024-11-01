require 'smart_proxy_openscap/openscap_exception'

module Proxy
  module OpenSCAP
    class PolicyGuide
      include ::Proxy::Log

      def generate_guide(file_content, policy_id)
        Tempfile.create do |file|
          file.write file_content
          file.flush
          command = ['oscap', 'xccdf', 'generate'] + profile_opt(policy_id) + ['guide', file.path]
          Proxy::OpenSCAP.execute(*command).first
        end
      rescue => e
        logger.debug e.message
        logger.debug e.backtrace.join("\n\t")
        raise OpenSCAPException, "Failed to generate policy guide, cause: #{e.message}"
      end

      def profile_opt(policy_id)
        policy_id ? ['--profile', policy_id] : []
      end
    end
  end
end
