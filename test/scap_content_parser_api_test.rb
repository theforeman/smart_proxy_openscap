require 'test_helper'
require 'smart_proxy_openscap'
require 'smart_proxy_openscap/openscap_api'

class ScapContentParserApiTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def setup
    @foreman_url = 'https://foreman.example.com'
    Proxy::SETTINGS.stubs(:foreman_url).returns(@foreman_url)
    @scap_content = File.new("#{Dir.getwd}/test/data/ssg-rhel7-ds.xml").read
    @tailoring_file = File.new("#{Dir.getwd}/test/data/tailoring.xml").read
  end

  def app
    ::Proxy::OpenSCAP::Api.new
  end

  def test_scap_content_policies
    post '/scap_content/policies', @scap_content, 'CONTENT_TYPE' => 'text/xml'
    expected_response = {
      "xccdf_org.ssgproject.content_profile_stig-rhel7-disa"=>"DISA STIG for Red Hat Enterprise Linux 7",
      "xccdf_org.ssgproject.content_profile_ospp"=>"United States Government Configuration Baseline",
      "xccdf_org.ssgproject.content_profile_pci-dss"=>"PCI-DSS v3.2.1 Control Baseline for Red Hat Enterprise Linux 7",
      "xccdf_org.ssgproject.content_profile_rht-ccp"=>"Red Hat Corporate Profile for Certified Cloud Providers (RH CCP)",
      "xccdf_org.ssgproject.content_profile_C2S"=>"C2S for Red Hat Enterprise Linux 7",
      "xccdf_org.ssgproject.content_profile_ospp42"=>"OSPP - Protection Profile for General Purpose Operating Systems v. 4.2",
      "xccdf_org.ssgproject.content_profile_cjis"=>"Criminal Justice Information Services (CJIS) Security Policy",
      "xccdf_org.ssgproject.content_profile_standard"=>"Standard System Security Profile for Red Hat Enterprise Linux 7",
      "xccdf_org.ssgproject.content_profile_rhelh-vpp"=>"VPP - Protection Profile for Virtualization v. 1.0 for Red Hat Enterprise Linux Hypervisor (RHELH)",
      "xccdf_org.ssgproject.content_profile_hipaa"=>"Health Insurance Portability and Accountability Act (HIPAA)",
      "xccdf_org.ssgproject.content_profile_nist-800-171-cui"=>"Unclassified Information in Non-federal Information Systems and Organizations (NIST 800-171)"
    }
    assert_equal(expected_response.to_json, last_response.body)
    assert(last_response.successful?)
  end

  def test_invalid_scap_content_policies
    post '/scap_content/policies', '<xml>blah</xml>', 'CONTENT_TYPE' => 'text/xml'
    assert(last_response.body.include?('Failed to parse profiles'))
  end

  def test_scap_content_validator
    post '/scap_file/validator/scap_content', @scap_content, 'CONTENT_TYPE' => 'text/xml'
    result = JSON.parse(last_response.body)
    assert_empty(result['errors'])
    assert(last_response.successful?)
  end

  def test_invalid_scap_content_validator
    Proxy::OpenSCAP::ContentParser.any_instance.stubs(:validate).returns({:errors => 'Invalid SCAP file type'}.to_json)
    post '/scap_file/validator/scap_content', @scap_content, 'CONTENT_TYPE' => 'text/xml'
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

  def test_validate_tailoring_file
    post '/scap_file/validator/tailoring_file', @tailoring_file, 'CONTENT_TYPE' => 'text/xml'
    result = JSON.parse(last_response.body)
    assert_empty(result['errors'])
    assert(last_response.successful?)
  end

  def test_get_profiles_from_tailoring_file
    post '/tailoring_file/profiles', @tailoring_file, 'CONTENT_TYPE' => 'text/xml'
    result = JSON.parse(last_response.body)
    assert_equal 1, result.keys.length
    assert(last_response.successful?)
  end
end
