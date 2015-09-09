module Proxy::OpenSCAP
  class OpenSCAPException < StandardError; end
  class StoreReportError < StandardError; end
  class StoreSpoolError <StandardError; end
  class FileNotFound < StandardError; end
end
