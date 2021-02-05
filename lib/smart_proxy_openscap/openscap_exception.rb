module Proxy::OpenSCAP
  class OpenSCAPException < StandardError; end
  class StoreReportError < StandardError; end
  class StoreSpoolError < StandardError; end
  class StoreFailedError < StandardError; end
  class FileNotFound < StandardError; end
  class StoreCorruptedError < StandardError; end
  class ReportUploadError < StandardError; end
  class ReportDecompressError < StandardError; end
end
