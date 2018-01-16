#
# Copyright (c) 2014--2015 Red Hat Inc.
#
# This software is licensed to you under the GNU General Public License,
# version 3 (GPLv3). There is NO WARRANTY for this software, express or
# implied, including the implied warranties of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. You should have received a copy of GPLv3
# along with this software; if not, see http://www.gnu.org/licenses/gpl.txt
#
require 'smart_proxy_openscap/openscap_lib'

module Proxy::OpenSCAP
  HTTP_ERRORS = [
    EOFError,
    Errno::ECONNRESET,
    Errno::EINVAL,
    Errno::ECONNREFUSED,
    Net::HTTPBadResponse,
    Net::HTTPHeaderSyntaxError,
    Net::ProtocolError,
    Timeout::Error
  ]

  class Api < ::Sinatra::Base
    include ::Proxy::Log
    helpers ::Proxy::Helpers
    authorize_with_ssl_client

    post "/arf/:policy" do
      # first let's verify client's certificate
      begin
        cn = Proxy::OpenSCAP::common_name request
      rescue Proxy::Error::Unauthorized => e
        log_halt 403, "Client authentication failed: #{e.message}"
      end
      date = Time.now.to_i
      policy = params[:policy]

      begin
        post_to_foreman = ForemanForwarder.new.post_arf_report(cn, policy, date, request.body.string)
        Proxy::OpenSCAP::StorageFS.new(Proxy::OpenSCAP::Plugin.settings.reportsdir, cn, post_to_foreman['id'], date).store_archive(request.body.string)
      rescue Proxy::OpenSCAP::StoreReportError => e
        Proxy::OpenSCAP::StorageFS.new(Proxy::OpenSCAP::Plugin.settings.failed_dir, cn, post_to_foreman['id'], date).store_failed(request.body.string)
        logger.error "Failed to save Report in reports directory (#{Proxy::OpenSCAP::Plugin.settings.reportsdir}). Failed with: #{e.message}.
                      Saving file in #{Proxy::OpenSCAP::Plugin.settings.failed_dir}. Please copy manually to #{Proxy::OpenSCAP::Plugin.settings.reportsdir}"
      rescue Proxy::OpenSCAP::OpenSCAPException => e
        logger.error "Failed to parse Arf Report, moving to #{Proxy::OpenSCAP::Plugin.settings.corrupted_dir}"
        Proxy::OpenSCAP::StorageFS.new(Proxy::OpenSCAP::Plugin.settings.corrupted_dir, cn, policy, date).store_corrupted(request.body.string)
      rescue *HTTP_ERRORS => e
        ### If the upload to foreman fails then store it in the spooldir
        logger.error "Failed to upload to Foreman, saving in spool. Failed with: #{e.message}"
        Proxy::OpenSCAP::StorageFS.new(Proxy::OpenSCAP::Plugin.settings.spooldir, cn, policy, date).store_spool(request.body.string)
      rescue Proxy::OpenSCAP::StoreSpoolError => e
        log_halt 500, e.message
      end
    end

    get "/arf/:id/:cname/:date/:digest/xml" do
      content_type 'application/x-bzip2'
      begin
        Proxy::OpenSCAP::StorageFS.new(Proxy::OpenSCAP::Plugin.settings.reportsdir, params[:cname], params[:id], params[:date]).get_arf_xml(params[:digest])
      rescue FileNotFound => e
        log_halt 500, "Could not find requested file, #{e.message}"
      end
    end

    delete "/arf/:id/:cname/:date/:digest" do
      begin
        Proxy::OpenSCAP::StorageFS.new(Proxy::OpenSCAP::Plugin.settings.reportsdir, params[:cname], params[:id], params[:date]).delete_arf_file
      rescue FileNotFound => e
        logger.debug "Could not find requested file, #{e.message} - Assuming deleted"
      end
    end

    get "/arf/:id/:cname/:date/:digest/html" do
      begin
        Proxy::OpenSCAP::OpenscapHtmlGenerator.new(params[:cname], params[:id], params[:date], params[:digest]).get_html
      rescue FileNotFound => e
        log_halt 500, "Could not find requested file, #{e.message}"
      rescue OpenSCAPException => e
        log_halt 500, "Could not generate report in HTML"
      end
    end

    get "/policies/:policy_id/content/:digest" do
      content_type 'application/xml'
      begin
        Proxy::OpenSCAP::FetchScapContent.new.get_policy_content(params[:policy_id], params[:digest])
      rescue *HTTP_ERRORS => e
        log_halt e.response.code.to_i, "File not found on Foreman. Wrong policy id?"
      rescue StandardError => e
        log_halt 500, "Error occurred: #{e.message}"
      end
    end

    get "/policies/:policy_id/content" do
      content_type 'application/xml'
      logger.warn 'DEPRECATION WARNING: /policies/:policy_id/content/:digest should be used, please update foreman_openscap'
      begin
        Proxy::OpenSCAP::FetchScapContent.new.get_policy_content(params[:policy_id], 'scap_content')
      rescue *HTTP_ERRORS => e
        log_halt e.response.code.to_i, "File not found on Foreman. Wrong policy id?"
      rescue StandardError => e
        log_halt 500, "Error occurred: #{e.message}"
      end
    end

    get "/policies/:policy_id/tailoring/:digest" do
      content_type 'application/xml'
      begin
        Proxy::OpenSCAP::FetchTailoringFile.new.get_tailoring_file(params[:policy_id], params[:digest])
      rescue *HTTP_ERRORS => e
        log_halt e.response.code.to_i, "File not found on Foreman. Wrong policy id?"
      rescue StandardError => e
        log_halt 500, "Error occurred: #{e.message}"
      end
    end

    post "/scap_content/policies" do
      begin
        Proxy::OpenSCAP::ProfilesParser.new('scap_content').profiles(request.body.string)
      rescue *HTTP_ERRORS => e
        log_halt 500, e.message
      rescue StandardError => e
        log_halt 500, "Error occurred: #{e.message}"
      end
    end

    post "/tailoring_file/profiles" do
      begin
        Proxy::OpenSCAP::ProfilesParser.new('tailoring_file').profiles(request.body.string)
      rescue *HTTP_ERRORS => e
        log_halt 500, e.message
      rescue StandardError => e
        log_halt 500, "Error occurred: #{e.message}"
      end
    end

    post "/scap_file/validator/:type" do
      validate_scap_file params
    end

    post "/scap_content/validator" do
      logger.warn "DEPRECATION WARNING: '/scap_content/validator' will be removed in the future. Use '/scap_file/validator/scap_content' instead"
      params[:type] = 'scap_content'
      validate_scap_file params
    end

    post "/scap_content/guide/?:policy?" do
      begin
        Proxy::OpenSCAP::PolicyParser.new(params[:policy]).guide(request.body.string)
      rescue *HTTP_ERRORS => e
        log_halt 500, e.message
      rescue StandardError => e
        log_halt 500, "Error occurred: #{e.message}"
      end
    end

    private

    def validate_scap_file(params)
      begin
        Proxy::OpenSCAP::ContentParser.new(params[:type]).validate(request.body.string)
      rescue *HTTP_ERRORS => e
        log_halt 500, e.message
      rescue StandardError => e
        log_halt 500, "Error occurred: #{e.message}"
      end
    end
  end
end
