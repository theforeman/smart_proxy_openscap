module Proxy::OpenSCAP
  class ImportApi < ::Sinatra::Base
    include ::Proxy::Log
    helpers ::Proxy::Helpers
    authorize_with_trusted_hosts

    require 'smart_proxy_openscap/openscap_lib'

    post "/arf/:cname/:policy_id/:date" do
      cn = params[:cname]
      date = params[:date]
      policy = params[:policy_id]
      log_halt(500, "Insufficient data") if (cn.nil? || date.nil?)

      post_to_foreman = ForemanForwarder.new.post_arf_report(cn, policy, date, request.body.string, Proxy::OpenSCAP::Plugin.settings.timeout)
      begin
        Proxy::OpenSCAP::StorageFs.new(Proxy::OpenSCAP::Plugin.settings.reportsdir, cn, post_to_foreman['id'], date).store_archive(request.body.string)
      rescue Proxy::OpenSCAP::StoreReportError => e
        Proxy::OpenSCAP::StorageFs.new(Proxy::OpenSCAP::Plugin.settings.failed_dir, cn, post_to_foreman['id'], date).store_failed(request.body.string)
        logger.error "Failed to save Report in reports directory (#{Proxy::OpenSCAP::Plugin.settings.reportsdir}). Failed with: #{e.message}.
                        Saving file in #{Proxy::OpenSCAP::Plugin.settings.failed_dir}. Please copy manually to #{Proxy::OpenSCAP::Plugin.settings.reportsdir}"
      rescue *HTTP_ERRORS => e
        ### If the upload to foreman fails then store it in the spooldir
        logger.error "Failed to upload to Foreman, saving in spool. Failed with: #{e.message}"
        Proxy::OpenSCAP::StorageFs.new(Proxy::OpenSCAP::Plugin.settings.spooldir, cn, policy, date).store_spool(request.body.string)
      rescue Proxy::OpenSCAP::StoreSpoolError => e
        log_halt 500, e.message
      end
      {:success => true, :arf_id => post_to_foreman['id']}.to_json
    end
  end
end
