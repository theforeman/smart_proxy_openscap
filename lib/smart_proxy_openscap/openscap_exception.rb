module Proxy::OpenSCAP
  class OpenSCAPException < Exception
    attr_accessor :response
    attr_accessor :message
    def initialize(response = nil)
      @response = response
      @message = response.message if response
    end

    def http_code
      @response.code || 500
    end

    def http_body
      @response.body if @response
    end
  end

  class FileNotFound < StandardError; end
end
