require 'test_helper'
require 'smart_proxy_openscap'
require 'smart_proxy_openscap/openscap_api'

ENV['RACK_ENV'] = 'test'

class FetchOvalContentApiTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def setup
    @foreman_url = 'https://foreman.example.com'
    @fixture_path = "/test/data/rhel-7-including-unpatched.oval.xml.bz2"
    @fixture_full_path = File.join(Dir.getwd, @fixture_path)
    Proxy::SETTINGS.stubs(:foreman_url).returns(@foreman_url)
    @results_path = ("#{Dir.getwd}/test/test_run_files")
    FileUtils.mkdir_p(@results_path)
    Proxy::OpenSCAP::Plugin.settings.stubs(:oval_content_dir).returns(@results_path)
    @oval_content = File.new(@fixture_full_path).read
    @digest = Digest::SHA256.hexdigest @oval_content
    @policy_id = 1
  end

  def teardown
    FileUtils.rm_rf(Dir.glob("#{@results_path}/*"))
  end

  def app
    ::Proxy::OpenSCAP::Api.new
  end

  def test_get_oval_content_from_file
    FileUtils.mkdir("#{@results_path}/#{@policy_id}")
    FileUtils.cp(@fixture_full_path, "#{@results_path}/#{@policy_id}/#{@digest}.oval.xml.bz2")
    get "/oval_policies/#{@policy_id}/oval_content/#{@digest}"
    assert_equal("application/x-bzip2", last_response.header["Content-Type"], "Response header should be application/x-bzip2")
    assert(last_response.successful?, "Response should be success")
  end
end
