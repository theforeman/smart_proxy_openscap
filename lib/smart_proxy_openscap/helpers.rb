# lib/helpers.rb

module Proxy::OpenSCAP
  module Helpers
    if Process.respond_to?(:fork)
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
    else
      def forked_response
        body, code = yield
        { code: code, body: body }
      end
    end
  end
end
