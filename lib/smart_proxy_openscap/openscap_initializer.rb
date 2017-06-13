require 'openscap'

module Proxy::OpenSCAP
  class OpenscapInitializer
    include ::Proxy::Log

    def initialize
      @mutex = Mutex.new
    end

    def start
      logger.debug "Initializing openscap component"
      @mutex.synchronize { OpenSCAP.oscap_init }
    end

    def stop
      logger.debug "Stopping openscap component"
      @mutex.synchronize { OpenSCAP.oscap_cleanup }
    end
  end
end
