require 'test_helper'
require 'smart_proxy_openscap'
require 'smart_proxy_openscap/openscap_api'

ENV['RACK_ENV'] = 'test'

class PostOvalReportApiTest < Test::Unit::TestCase
  include Rack::Test::Methods

  setup do
    @foreman_url = 'https://foreman.example.com'
    Proxy::SETTINGS.stubs(:foreman_url).returns(@foreman_url)
    @oval_report = File.open("#{Dir.getwd}/test/data/oval-results.xml.bz2").read
    @cname = 'node.example.org'
    @date = Time.now.to_i
    @policy_id = 1
    Proxy::OpenSCAP.stubs(:common_name).returns(@cname)
  end

  def app
    ::Proxy::OpenSCAP::Api.new
  end

  def test_post_oval_report_to_foreman
    stub_request(:post, "#{@foreman_url}/api/v2/compliance/oval_reports/#{@cname}/#{@policy_id}/#{@date}")
      .to_return(:status => 200, :body => '{ "result": "ok" }')
    post "/oval_reports/#{@policy_id}", @oval_report, 'CONTENT_TYPE' => 'text/xml', 'CONTENT_ENCODING' => 'x-bzip2'
    assert(last_response.successful?, "Should be a success")
  end
end
