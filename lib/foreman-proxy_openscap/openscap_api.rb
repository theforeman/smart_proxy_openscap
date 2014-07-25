#
# Copyright (c) 2014 Red Hat Inc.
#
# This software is licensed to you under the GNU General Public License,
# version 3 (GPLv3). There is NO WARRANTY for this software, express or
# implied, including the implied warranties of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. You should have received a copy of GPLv3
# along with this software; if not, see http://www.gnu.org/licenses/gpl.txt
#

require 'digest'
require 'foreman-proxy_openscap/openscap_lib'

module Proxy::OpenSCAP
  class Api < ::Sinatra::Base
    include ::Proxy::Log
    helpers ::Proxy::Helpers

    put "/arf/:policy/:date" do
      # first let's verify client's certificate
      begin
        cn = Proxy::OpenSCAP::common_name request
      rescue Proxy::Error::Unauthorized => e
        log_halt 403, "Client authentication failed: #{e.message}"
      end

      # validate the url (i.e. avoid malformed :policy)
      begin
        target_dir = Proxy::OpenSCAP::spool_arf_dir(cn, params[:policy], params[:date])
      rescue Proxy::Error::BadRequest => e
        log_halt 400, "Requested URI is malformed: #{e.message}"
      rescue StandardError => e
        log_halt 500, "Could not fulfill request: #{e.message}"
      end

      begin
        filename = Digest::SHA256.hexdigest request.body.string
        target_path = target_dir + filename
        File.open(target_path,'w') { |f| f.write(request.body.string) }
      rescue StandardError => e
        log_halt 500, "Could not store file: #{e.message}"
      end

      logger.debug "File #{target_path} stored successfully."

      {"created" => true}.to_json
    end
  end
end

