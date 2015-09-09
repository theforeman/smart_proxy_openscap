require 'test_helper'
require 'smart_proxy_openscap'
require 'smart_proxy_openscap/openscap_api'

class ScapContentParserApiTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def setup
    @foreman_url = 'https://foreman.example.com'
    Proxy::SETTINGS.stubs(:foreman_url).returns(@foreman_url)
    @scap_content = File.new("#{Dir.getwd}/test/data/ssg-rhel7-ds.xml").read
  end

  def app
    ::Proxy::OpenSCAP::Api.new
  end

  def test_scap_content_policies
    post '/scap_content/policies', @scap_content, 'CONTENT_TYPE' => 'text/xml'
    expected_response = {"xccdf_org.ssgproject.content_profile_test" => "test",
                         "xccdf_org.ssgproject.content_profile_rht-ccp" => "Red Hat Corporate Profile for Certified Cloud Providers (RH CCP)",
                         "xccdf_org.ssgproject.content_profile_common" => "Common Profile for General-Purpose Systems",
                         "xccdf_org.ssgproject.content_profile_stig-rhel7-server-upstream" => "Common Profile for General-Purpose SystemsPre-release Draft STIG for RHEL 7 Server"}
    assert_equal(expected_response.to_json, last_response.body)
    assert(last_response.successful?)
  end

  def test_invalid_scap_content_policies
    post '/scap_content/policies', '<xml>blah</xml>', 'CONTENT_TYPE' => 'text/xml'
    assert(last_response.body.include?('Could not create Source DataStream session'))
  end

  def test_scap_content_validator
    post '/scap_content/validator', @scap_content, 'CONTENT_TYPE' => 'text/xml'
    result = JSON.parse(last_response.body)
    assert_empty(result['errors'])
    assert(last_response.successful?)
  end

  def test_invalid_scap_content_validator
    Proxy::OpenSCAP::ContentParser.any_instance.stubs(:validate).returns({:errors => 'Invalid SCAP file type'}.to_json)
    post '/scap_content/validator', @scap_content, 'CONTENT_TYPE' => 'text/xml'
    result = JSON.parse(last_response.body)
    refute_empty(result['errors'])
    assert(last_response.successful?)
  end

  def test_scap_content_guide
    post '/scap_content/guide/xccdf_org.ssgproject.content_profile_rht-ccp', @scap_content, 'CONTENT_TYPE' => 'text/xml'
    result = JSON.parse(last_response.body)
    assert(result['html'].start_with?('<!DOCTYPE html>'))
    assert(last_response.successful?)
  end
end
