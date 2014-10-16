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
require 'json'
require 'proxy/error'
require 'proxy/request'

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

  def self.spool_arf_dir(common_name, policy_name, date)
    validate_policy_name policy_name
    validate_date date
    dir = Proxy::OpenSCAP::Plugin.settings.spooldir + "/arf/#{common_name}/#{policy_name}/#{date}/"
    begin
      FileUtils.mkdir_p dir
    rescue StandardError => e
      logger.error "Could not create '#{dir}' directory: #{e.message}"
      raise e
    end
    dir
  end

  def self.store_arf(spool_arf_dir, data)
    filename = Digest::SHA256.hexdigest data
    target_path = spool_arf_dir + filename
    File.open(target_path,'w') { |f| f.write(data) }
    return target_path
  end

  def self.send_spool_to_foreman
    arf_dir = File.join(Proxy::OpenSCAP::Plugin.settings.spooldir, "/arf")
    return unless File.exists? arf_dir
    ForemanForwarder.new.do arf_dir
  end

  private
  def self.validate_policy_name name
    unless /[\w-]+/ =~ name
      raise Proxy::Error::BadRequest, "Malformed policy name"
    end
  end

  def self.validate_date date
    begin
      Date.strptime(date, '%Y-%m-%d')
    rescue
      raise Proxy::Error::BadRequest, "Malformed date"
    end
  end

  class ForemanForwarder
    def do(arf_dir)
      Dir.foreach(arf_dir) { |cname|
        cname_dir = File.join(arf_dir, cname)
        if File.directory? cname_dir and !(cname == '.' || cname == '..')
          forward_cname_dir(cname, cname_dir)
        end
      }
    end

    private
    def forward_cname_dir(cname, cname_dir)
      Dir.foreach(cname_dir) { |policy_name|
        policy_dir = File.join(cname_dir, policy_name)
        if File.directory? policy_dir and !(policy_name == '.' || policy_name == '..')
          forward_policy_dir(cname, policy_name, policy_dir)
        end
      }
      remove cname_dir
    end

    def forward_policy_dir(cname, policy_name, policy_dir)
      Dir.foreach(policy_dir) { |date|
        date_dir = File.join(policy_dir, date)
        if File.directory? date_dir and !(date == '.' || date == '..')
          forward_date_dir(cname, policy_name, date, date_dir)
        end
      }
      remove policy_dir
    end

    def forward_date_dir(cname, policy_name, date, date_dir)
      path = upload_path(cname, policy_name, date)
      Dir.foreach(date_dir) { |arf|
        arf_path = File.join(date_dir, arf)
        if File.file? arf_path and !(arf == '.' || arf == '..')
          logger.debug("Uploading #{arf} to #{path}")
          forward_arf_file(path, arf_path)
        end
      }
      remove date_dir
    end

    def upload_path(cname, policy_name, date)
      return "/api/v2/openscap/arf_reports/#{cname}/#{policy_name}/#{date}"
    end

    def forward_arf_file(foreman_api_path, arf_file_path)
      begin
        data = File.read(arf_file_path)
        response = foreman.send_request(foreman_api_path, data)
        response.value
        raise StandardError, "Received #{response.code}: #{response.message}" unless response.code.to_i == 200
        res = JSON.parse(response.body)
        raise StandardError, "Received result: #{res['result']}" unless res['result'] == 'OK'
        raise StandardError, "Sent bytes: #{data.length}, but foreman received: #{res['received']}" unless data.length == res['received']
      rescue StandardError => e
        logger.debug response.body if response
        raise e
      end
    end

    def remove(dir)
      begin
        Dir.delete dir
      rescue StandardError => e
        logger.error "Could not remove directory: #{e.message}"
      end
    end

    def foreman
      @foreman ||= Proxy::HttpRequest::ForemanRequest.new
    end
  end
end

