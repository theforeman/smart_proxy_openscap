require 'test_helper'
require 'smart_proxy_openscap'
require 'smart_proxy_openscap/openscap_api'

ENV['RACK_ENV'] = 'test'

class FetchScapApiTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def setup
    @foreman_url = 'https://foreman.example.com'
    Proxy::SETTINGS.stubs(:foreman_url).returns(@foreman_url)
    @results_path = ("#{Dir.getwd}/test/test_run_files")
    FileUtils.mkdir_p(@results_path)
    Proxy::OpenSCAP::Plugin.settings.stubs(:contentdir).returns(@results_path)
    Proxy::OpenSCAP::Plugin.settings.stubs(:spooldir).returns(@results_path)
    Proxy::OpenSCAP::Plugin.settings.stubs(:reportsdir).returns(@results_path)
    @scap_content = File.new("#{Dir.getwd}/test/data/ssg-rhel7-ds.xml").read
    @policy_id = 1
  end

  def teardown
    FileUtils.rm_rf(Dir.glob("#{@results_path}/*"))
  end

  def app
    ::Proxy::OpenSCAP::Api.new
  end

  def test_get_scap_content_from_foreman
    stub_request(:get, "#{@foreman_url}/api/v2/compliance/policies/#{@policy_id}/content").to_return(:body => @scap_content)
    get "/policies/#{@policy_id}/content"
    assert_equal("application/xml;charset=utf-8", last_response.header["Content-Type"], "Response header should be application/xml")
    assert File.file?("#{@results_path}/#{@policy_id}/#{@policy_id}_scap_content.xml")
    assert_equal(@scap_content.length, last_response.length, "Scap content should be equal")
  end

  def test_get_scap_content_from_file
    # Simulate that scap file was previously saved after fetched from Foreman.
    FileUtils.mkdir("#{@results_path}/#{@policy_id}")
    FileUtils.cp("#{Dir.getwd}/test/data/ssg-rhel7-ds.xml", "#{@results_path}/#{@policy_id}/#{@policy_id}_scap_content.xml")
    get "/policies/#{@policy_id}/content"
    assert_equal("application/xml;charset=utf-8", last_response.header["Content-Type"], "Response header should be application/xml")
    assert_equal(@scap_content.length, last_response.length, "Scap content should be equal")
    assert(last_response.successful?, "Response should be success")
  end

  def test_get_scap_content_no_policy
    stub_request(:get, "#{@foreman_url}/api/v2/compliance/policies/#{@policy_id}/content").to_return(:status => 404, :body => 'not found')
    get "/policies/#{@policy_id}/content"
    assert(last_response.not_found?, "Response should be 404")
  end

  def test_get_scap_content_permissions
    Proxy::OpenSCAP::FetchScapContent.any_instance.stubs(:get_policy_content).raises(Errno::EACCES)
    stub_request(:get, "#{@foreman_url}/api/v2/compliance/policies/#{@policy_id}/content").to_return(:body => @scap_content)
    get "/policies/#{@policy_id}/content"
    assert_equal(500, last_response.status, "No permissions should raise error 500")
    assert_equal('Error occurred: Permission denied', last_response.body)
    # binding.pry
  end

  def test_locked_file_should_serve_from_foreman
    Proxy::FileLock.stubs(:try_locking).returns(nil)
    stub_request(:get, "#{@foreman_url}/api/v2/compliance/policies/#{@policy_id}/content").to_return(:body => @scap_content)
    get "/policies/#{@policy_id}/content"
    refute(File.file?("#{@results_path}/#{@policy_id}/#{@policy_id}_scap_content.xml"), "Scap file should be saved")
    assert_equal("application/xml;charset=utf-8", last_response.header["Content-Type"], "Response header should be application/xml")
    assert_equal(@scap_content.length, last_response.length, "Scap content should be equal")
    assert(last_response.successful?, "Response should be success")
  end
end
