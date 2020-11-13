require 'test_helper'
require 'smart_proxy_openscap'
require 'smart_proxy_openscap/openscap_api'

ENV['RACK_ENV'] = 'test'

class OpenSCAPApiTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def setup
    @foreman_url = 'https://foreman.example.com'
    Proxy::SETTINGS.stubs(:foreman_url).returns(@foreman_url)
    @results_path = ("#{Dir.getwd}/test/test_run_files")
    FileUtils.mkdir_p(@results_path)
    Proxy::OpenSCAP::Plugin.settings.stubs(:contentdir).returns(@results_path)
    Proxy::OpenSCAP::Plugin.settings.stubs(:spooldir).returns(@results_path + "/spool")
    Proxy::OpenSCAP::Plugin.settings.stubs(:reportsdir).returns(@results_path + "/reports")
    Proxy::OpenSCAP::Plugin.settings.stubs(:failed_dir).returns(@results_path + "/failed")
    Proxy::OpenSCAP::Plugin.settings.stubs(:corrupted_dir).returns(@results_path + "/corrupted")
    @arf_report = File.open("#{Dir.getwd}/test/data/arf_report").read
    @corrupted_arf_report = File.open("#{Dir.getwd}/test/data/corrupted_arf_report").read
    @policy_id = 1
    @arf_id = 145
    @filename = Digest::SHA256.hexdigest(@arf_report)
    @corrupted_filename = Digest::SHA256.hexdigest(@corrupted_arf_report)
    @cname = 'node.example.org'
    @date = Time.now.to_i
    # Bypass common_name as it requires ssl certificate
    Proxy::OpenSCAP.stubs(:common_name).returns(@cname)
  end

  def teardown
    FileUtils.rm_rf(Dir.glob("#{@results_path}/*"))
  end

  def app
    ::Proxy::OpenSCAP::Api.new
  end

  def test_post_arf_report_to_foreman
    stub_request(:post, "#{@foreman_url}/api/v2/compliance/arf_reports/#{@cname}/#{@policy_id}/#{@date}")
      .to_return(:status => 200, :body => "{\"result\":\"OK\",\"id\":\"#{@arf_id}\"}")
    post "/arf/#{@policy_id}", @arf_report, 'CONTENT_TYPE' => 'text/xml', 'CONTENT_ENCODING' => 'x-bzip2'
    assert(last_response.successful?, "Should return OK")
    assert(File.file?("#{@results_path}/reports/arf/#{@cname}/#{@arf_id}/#{@date}/#{@filename}"), "File should be save on Reports directory")
  end

  def test_post_fails_save_in_spool
    @policy_id = 2
    stub_request(:post, "#{@foreman_url}/api/v2/compliance/arf_reports/#{@cname}/#{@policy_id}/#{@date}")
      .to_return(:status => 500, :body => "{\"result\":\"server error\"}")
    post "/arf/#{@policy_id}", @arf_report, 'CONTENT_TYPE' => 'text/xml', 'CONTENT_ENCODING' => 'x-bzip2'
    assert(last_response.successful?, "Should return OK")
    assert(File.file?("#{@results_path}/spool/arf/#{@cname}/#{@policy_id}/#{@date}/#{@filename}"), "File should be saved in spool directory")
    refute(File.file?("#{@results_path}/reports/arf/#{@cname}/#{@arf_id}/#{@date}/#{@filename}"), "File should not be in Reports directory")
  end

  def test_fail_save_file_should_raise_error
    @policy_id = 2
    stub_request(:post, "#{@foreman_url}/api/v2/compliance/arf_reports/#{@cname}/#{@policy_id}/#{@date}").to_return(:status => 500, :body => "{\"result\":\"server error\"}")
    Proxy::OpenSCAP::StorageFs.any_instance.stubs(:create_directory).raises(StandardError)
    post "/arf/#{@policy_id}", @arf_report, 'CONTENT_TYPE' => 'text/xml', 'CONTENT_ENCODING' => 'x-bzip2'
    assert(last_response.server_error?, "Should return 500")
    refute(File.file?("#{@results_path}/spool/arf/#{@cname}/#{@policy_id}/#{@date}/#{@filename}"), "File should be saved in spool directory")
  end

  def test_success_post_fail_save_should_save_spool
    stub_request(:post, "#{@foreman_url}/api/v2/compliance/arf_reports/#{@cname}/#{@policy_id}/#{@date}")
      .to_return(:status => 200, :body => "{\"result\":\"OK\",\"id\":\"#{@arf_id}\"}")
    Proxy::OpenSCAP::StorageFs.any_instance.stubs(:store_archive).raises(Proxy::OpenSCAP::StoreReportError)
    post "/arf/#{@policy_id}", @arf_report, 'CONTENT_TYPE' => 'text/xml', 'CONTENT_ENCODING' => 'x-bzip2'
    refute(File.file?("#{@results_path}/spool/arf/#{@cname}/#{@policy_id}/#{@date}/#{@filename}"), "File should not be  in spool directory")
    refute(File.file?("#{@results_path}/reports/arf/#{@cname}/#{@arf_id}/#{@date}/#{@filename}"), "File should not be in Reports directory")
    assert(File.file?("#{@results_path}/failed/arf/#{@cname}/#{@arf_id}/#{@date}/#{@filename}"), "File should be in Failed directory")
    log_file = File.read('logs/test.log')
    assert(log_file.include?('Failed to save Report in reports directory'), 'Logger should notify that failed to save in reports dir')
  end

  def test_post_corrupted_should_move_to_corrupted
    stub_request(:post, "#{@foreman_url}/api/v2/compliance/arf_reports/#{@cname}/#{@policy_id}/#{@date}")
      .to_return(:status => 200, :body => "{\"result\":\"OK\",\"id\":\"#{@arf_id}\"}")
    post "/arf/#{@policy_id}", @corrupted_arf_report, 'CONTENT_TYPE' => 'text/xml', 'CONTENT_ENCODING' => 'x-bzip2'
    assert(File.file?("#{@results_path}/corrupted/arf/#{@cname}/#{@policy_id}/#{@date}/#{@corrupted_filename}"), "File should be in Corrupted directory")
    refute(File.file?("#{@results_path}/spool/arf/#{@cname}/#{@policy_id}/#{@date}/#{@corrupted_filename}"), "File should not be in Spool directory")
  end
end
