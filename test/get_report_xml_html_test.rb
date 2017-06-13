require 'test_helper'
require 'smart_proxy_openscap'
require 'smart_proxy_openscap/openscap_api'

ENV['RACK_ENV'] = 'test'

class OpenSCAPGetArfTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def setup
    @foreman_url = 'https://foreman.example.com'
    Proxy::SETTINGS.stubs(:foreman_url).returns(@foreman_url)
    @results_path = ("#{Dir.getwd}/test/test_run_files")
    Proxy::OpenSCAP::Plugin.settings.stubs(:reportsdir).returns(@results_path + "/reports")
    @arf_report = File.open("#{Dir.getwd}/test/data/arf_report").read
    @policy_id = 1
    @arf_id = 145
    @filename = Digest::SHA256.hexdigest(@arf_report)
    @cname = 'node.example.org'
    @date = Time.now.strftime("%Y-%m-%d")
    # Bypass common_name as it requires ssl certificate
    Proxy::OpenSCAP.stubs(:common_name).returns(@cname)
    FileUtils.mkdir_p("#{@results_path}/reports/arf/#{@cname}/#{@arf_id}/#{@date}")
    FileUtils.cp("#{Dir.getwd}/test/data/arf_report", "#{@results_path}/reports/arf/#{@cname}/#{@arf_id}/#{@date}/#{@filename}")
  end

  def teardown
    FileUtils.rm_rf(Dir.glob("#{@results_path}/*"))
  end

  def app
    ::Proxy::OpenSCAP::Api.new
  end

  def test_get_xml_arf
    get "/arf/#{@arf_id}/#{@cname}/#{@date}/#{@filename}/xml"
    assert(last_response.successful?, "Should return OK")
    assert(last_response.header["Content-Type"].include?('application/x-bzip2'))
  end

  def test_get_html_arf
    OpenSCAP.oscap_init
    get "/arf/#{@arf_id}/#{@cname}/#{@date}/#{@filename}/html"
    OpenSCAP.oscap_cleanup
    assert(last_response.successful?, "Should return OK")
    assert(last_response.body.start_with?('<!DOCTYPE'), 'File should start with html')
  end

  def test_get_xml_file_not_found
    get "/arf/#{@arf_id}/somewhere.example.org/#{@date}/#{@filename}/xml"
    assert_equal(500, last_response.status, "Error response should be 500")
    assert(last_response.server_error?)
  end

  def test_delete_arf_file
    delete "/arf/#{@arf_id}/#{@cname}/#{@date}/#{@filename}"
    assert last_response.ok?
    refute  File.exist?("#{@results_path}/reports/arf/#{@cname}/#{@arf_id}")
  end
end
