#
# Copyright (c) 2014--2015 Red Hat Inc.
#
# This software is licensed to you under the GNU General Public License,
# version 3 (GPLv3). There is NO WARRANTY for this software, express or
# implied, including the implied warranties of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. You should have received a copy of GPLv3
# along with this software; if not, see http://www.gnu.org/licenses/gpl.txt
#

require 'smart_proxy_openscap/version'

module Proxy::OpenSCAP
  class Plugin < ::Proxy::Plugin
    plugin :openscap, Proxy::OpenSCAP::VERSION

    http_rackup_path File.expand_path("http_config.ru", File.expand_path("../", __FILE__))
    https_rackup_path File.expand_path("http_config.ru", File.expand_path("../", __FILE__))

    default_settings :spooldir => '/var/spool/foreman-proxy/openscap',
                     :openscap_send_log_file => File.join(APP_ROOT, 'logs/openscap-send.log'),
                     :contentdir => File.join(APP_ROOT, 'openscap/content'),
                     :reportsdir => File.join(APP_ROOT, 'openscap/reports'),
                     :failed_dir => File.join(APP_ROOT, 'openscap/failed'),
                     :tailoring_dir => File.join(APP_ROOT, 'openscap/tailoring')
  end
end
