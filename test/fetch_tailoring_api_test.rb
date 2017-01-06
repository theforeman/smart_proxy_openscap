require 'test_helper'
require 'smart_proxy_openscap'
require 'smart_proxy_openscap/openscap_api'

ENV['RACK_ENV'] = 'test'

class FetchTailoringApiTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def setup
    @foreman_url = 'https://foreman.example.com'
    Proxy::SETTINGS.stubs(:foreman_url).returns(@foreman_url)
    @results_path = ("#{Dir.getwd}/test/test_run_files")
    FileUtils.mkdir_p(@results_path)
    Proxy::OpenSCAP::Plugin.settings.stubs(:tailoring_dir).returns(@results_path)
    @tailoring_file = File.new("#{Dir.getwd}/test/data/tailoring.xml").read
    @policy_id = 1
  end

  def teardown
    FileUtils.rm_rf(Dir.glob("#{@results_path}/*"))
  end

  def app
    ::Proxy::OpenSCAP::Api.new
  end

  def test_get_tailoring_file_from_file
    FileUtils.mkdir("#{@results_path}/#{@policy_id}")
    FileUtils.cp("#{Dir.getwd}/test/data/tailoring.xml", "#{@results_path}/#{@policy_id}/#{@policy_id}_tailoring_file.xml")
    get "/policies/#{@policy_id}/tailoring"
    assert_equal("application/xml;charset=utf-8", last_response.header["Content-Type"], "Response header should be application/xml")
    assert_equal(@tailoring_file.length, last_response.length, "Scap content should be equal")
    assert(last_response.successful?, "Response should be success")
  end
end
