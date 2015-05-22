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
require 'smart_proxy_openscap/openscap_exception'

module Proxy::OpenSCAP
  extend ::Proxy::Log

  def self.get_policy_content(policy_id)
    policy_store_dir = File.join(Proxy::OpenSCAP::Plugin.settings.contentdir, policy_id.to_s)
    policy_scap_file = File.join(policy_store_dir, "#{policy_id}_scap_content.xml")
    begin
      FileUtils.mkdir_p(policy_store_dir) # will fail silently if exists
    rescue Errno::EACCES => e
      logger.error "No permission to create directory #{policy_store_dir}"
      raise e
    rescue StandardError => e
      logger.error "Could not create '#{policy_store_dir}' directory: #{e.message}"
      raise e
    end

    scap_file = policy_content_file(policy_scap_file)
    scap_file ||= save_or_serve_scap_file(policy_id, policy_scap_file)
    scap_file
  end

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

  def self.spool_arf_dir(common_name, policy_id)
    validate_policy_id(policy_id)
    date = Time.now.strftime("%Y-%m-%d")
    dir = Proxy::OpenSCAP::Plugin.settings.spooldir + "/arf/#{common_name}/#{policy_id}/#{date}/"
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
    ForemanForwarder.new.do(arf_dir)
  end

  private
  def self.validate_policy_id(id)
    unless /[\d]+/ =~ id
      raise Proxy::Error::BadRequest, "Malformed policy ID"
    end
  end

  def self.fetch_scap_content_xml(policy_id, policy_scap_file)
    foreman_request = Proxy::HttpRequest::ForemanRequest.new
    policy_content_path = "api/v2/compliance/policies/#{policy_id}/content"
    req = foreman_request.request_factory.create_get(policy_content_path)
    response = foreman_request.send_request(req)
    unless response.is_a? Net::HTTPSuccess
      raise OpenSCAPException.new(response)
    end
    response.body
  end


  def self.policy_content_file(policy_scap_file)
    return nil if !File.file?(policy_scap_file) || File.zero?(policy_scap_file)
    File.open(policy_scap_file, 'rb').read
  end

  def self.save_or_serve_scap_file(policy_id, policy_scap_file)
    lock = Proxy::FileLock::try_locking(policy_scap_file)
    response = fetch_scap_content_xml(policy_id, policy_scap_file)
    if lock.nil?
      return response
    else
      begin
        File.open(policy_scap_file, 'wb') do |file|
          file << response
        end
      ensure
        Proxy::FileLock::unlock(lock)
      end
      scap_file = policy_content_file(policy_scap_file)
      raise FileNotFound if scap_file.nil?
      return scap_file
    end
  end

  class ForemanForwarder < Proxy::HttpRequest::ForemanRequest
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
      Dir.foreach(cname_dir) { |policy_id|
        policy_dir = File.join(cname_dir, policy_id)
        if File.directory? policy_dir and !(policy_id == '.' || policy_id == '..')
          forward_policy_dir(cname, policy_id, policy_dir)
        end
      }
      remove(cname_dir)
    end

    def forward_policy_dir(cname, policy_id, policy_dir)
      Dir.foreach(policy_dir) { |date|
        date_dir = File.join(policy_dir, date)
        if File.directory? date_dir and !(date == '.' || date == '..')
          forward_date_dir(cname, policy_id, date, date_dir)
        end
      }
      remove(policy_dir)
    end

    def forward_date_dir(cname, policy_id, date, date_dir)
      path = upload_path(cname, policy_id, date)
      Dir.foreach(date_dir) { |arf|
        arf_path = File.join(date_dir, arf)
        if File.file? arf_path and !(arf == '.' || arf == '..')
          logger.debug("Uploading #{arf} to #{path}")
          forward_arf_file(path, arf_path)
        end
      }
      remove(date_dir)
    end

    def upload_path(cname, policy_id, date)
      return "/api/v2/compliance/arf_reports/#{cname}/#{policy_id}/#{date}"
    end

    def forward_arf_file(foreman_api_path, arf_file_path)
      begin
        data = File.read(arf_file_path)
        response = send_request(foreman_api_path, data)
        # Raise an HTTP error if the response is not 2xx (success).
        response.value
        res = JSON.parse(response.body)
        raise StandardError, "Received result: #{res['result']}" unless res['result'] == 'OK'
        File.delete arf_file_path
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

    def send_request(path, body)
      # Override the parent method to set the right headers
      path = [uri.path, path].join('/') unless uri.path.empty?
      req = Net::HTTP::Post.new(URI.join(uri.to_s, path).path)
      # Well, this is unfortunate. We want to have content-type text/xml. We
      # also need the content-encoding to equal with x-bzip2. However, when
      # the Foreman's framework sees text/xml, it will rewrite it to application/xml.
      # What's worse, a framework will try to parse body as an utf8 string,
      # no matter what content-encoding says. Oh my.
      # Let's pass content-type arf-bzip2 and move forward.
      req.content_type = 'application/arf-bzip2'
      req['Content-Encoding'] = 'x-bzip2'
      req.body = body
      http.request(req)
    end
  end
end
