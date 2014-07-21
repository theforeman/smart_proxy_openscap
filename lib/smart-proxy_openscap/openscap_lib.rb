#
# Copyright (c) 2014 Red Hat Inc.
#
# This software is licensed to you under the GNU General Public License,
# version 2 (GPLv2). There is NO WARRANTY for this software, express or
# implied, including the implied warranties of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. You should have received a copy of GPLv2
# along with this software; if not, see
# http://www.gnu.org/licenses/old-licenses/gpl-2.0.txt.
#

module Proxy::OpenSCAP
  def self.common_name(request)
    client_cert = request.env['SSL_CLIENT_CERT']
    raise Proxy::Error::Unauthorized, "Client certificate required!" if client_cert.to_s.empty?

    begin
      client_cert = OpenSSL::X509::Certificate.new(client_cert)
    rescue OpenSSL::OpenSSLError => e
      raise Proxy::Error::Unauthorized, e.message
    end
    cn = client_cert.subject.to_a.detect { |name, value| name == 'CN' }
    cn = cn[1] unless cn.nil?
    raise Proxy::Error::Unauthorized, "Common Name not found in the certificate" unless cn
    return cn
  end
end

