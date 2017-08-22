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
require 'fileutils'
require 'pathname'
require 'json'
require 'proxy/error'
require 'proxy/request'
require 'smart_proxy_openscap/fetch_scap_content'
require 'smart_proxy_openscap/foreman_forwarder'
require 'smart_proxy_openscap/content_parser'
require 'smart_proxy_openscap/openscap_exception'
require 'smart_proxy_openscap/arf_parser'
require 'smart_proxy_openscap/spool_forwarder'
require 'smart_proxy_openscap/openscap_html_generator'
require 'smart_proxy_openscap/fetch_tailoring_file'
require 'smart_proxy_openscap/policy_parser'
require 'smart_proxy_openscap/profiles_parser'

module Proxy::OpenSCAP
  extend ::Proxy::Log

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
    cn
  end

  def self.send_spool_to_foreman
    arf_dir = File.join(Proxy::OpenSCAP::Plugin.settings.spooldir, "/arf")
    return unless File.exist? arf_dir
    SpoolForwarder.new.post_arf_from_spool(arf_dir)
  end

  def self.fullpath(path = Proxy::OpenSCAP::Plugin.settings.contentdir)
    pathname = Pathname.new(path)
    pathname.relative? ? pathname.expand_path(Sinatra::Base.root).to_s : path
  end
end
