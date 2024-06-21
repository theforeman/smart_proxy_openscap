# lib/helpers.rb

module Proxy::OpenSCAP
  module Helpers
    def forked_response
      r, w = IO.pipe
      if child_id = Process.fork
        w.close
        data = r.read
        r.close
        Process.wait(child_id)
        JSON.parse(data)
      else
        r.close
        begin
          body, code = yield
          w.write({ code: code, body: body }.to_json)
        rescue Exception => e
          w.write({ code: 500, body: e.message }.to_json)
        end
        w.close
        Process.exit!
      end
    end
  end
end
