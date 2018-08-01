require 'test_helper'
require 'smart_proxy_openscap/arf_html'
require 'smart_proxy_openscap/arf_json'
require 'smart_proxy_openscap/policy_guide'
require 'smart_proxy_openscap/scap_profiles'
require 'smart_proxy_openscap/arf_json'
require 'smart_proxy_openscap/scap_validation'

class ScriptClassTest < Test::Unit::TestCase
  def test_arf_generate_html
    carry_out do |tmp|
      Proxy::OpenSCAP::ArfHtml.new.generate_html("#{Dir.getwd}/test/data/arf_report", tmp.path)
      content = File.read tmp
      assert content.start_with?('<!DOCTYPE'), "File should be html"
    end
  end

  def test_arf_as_json
    carry_out do |tmp|
      Proxy::OpenSCAP::ArfJson.new.as_json("#{Dir.getwd}/test/data/arf_report", tmp.path, 'my-proxy', 'http://test-proxy.org')
      json = read_json tmp
      refute json['logs'].empty?
      refute json['metrics'].empty?
      refute json['openscap_proxy_name'].empty?
      refute json['openscap_proxy_url'].empty?
    end
  end

  def test_policy_guide
    carry_out do |tmp|
      profile = "xccdf_org.ssgproject.content_profile_stig-rhel7-workstation-upstream"
      Proxy::OpenSCAP::PolicyGuide.new.generate_guide("#{Dir.getwd}/test/data/ssg-rhel7-ds.xml", tmp.path, profile)
      guide = read_json tmp
      assert guide['html'].start_with?('<!DOCTYPE'), "File should be html"
    end
  end

  def test_scap_file_profiles
    carry_out do |tmp|
      Proxy::OpenSCAP::ScapProfiles.new.profiles("#{Dir.getwd}/test/data/ssg-rhel7-ds.xml", tmp.path, 'scap_content')
      profiles = read_json tmp
      refute profiles.empty?
      assert profiles["xccdf_org.ssgproject.content_profile_common"]
    end
  end

  def test_tailoring_file_profiles
    carry_out do |tmp|
      Proxy::OpenSCAP::ScapProfiles.new.profiles("#{Dir.getwd}/test/data/tailoring.xml", tmp.path, 'tailoring_file')
      profiles = read_json tmp
      refute profiles.empty?
      assert profiles["xccdf_org.ssgproject.content_profile_stig-firefox-upstream_customized"]
    end
  end

  def test_arf_json
    carry_out do |tmp|
      Proxy::OpenSCAP::ArfJson.new.as_json("#{Dir.getwd}/test/data/arf_report", tmp.path, 'my-proxy', 'http://test-proxy.org')
      json = read_json tmp
      refute json['logs'].empty?
      refute json['metrics'].empty?
    end
  end

  def test_scap_content_validation
    carry_out do |tmp|
      Proxy::OpenSCAP::ScapValidation.new.validate("#{Dir.getwd}/test/data/ssg-rhel7-ds.xml", tmp.path, 'scap_content')
      res = read_json tmp
      assert res['errors'].empty?
    end
  end

  def test_tailoring_file_validation
    carry_out do |tmp|
      Proxy::OpenSCAP::ScapValidation.new.validate("#{Dir.getwd}/test/data/tailoring.xml", tmp.path, 'tailoring_file')
      res = read_json tmp
      assert res['errors'].empty?
    end
  end

  private

  def carry_out
    tmp = Tempfile.new('test')
    begin
      yield tmp if block_given?
    ensure
      tmp.close
      tmp.unlink
    end
  end

  def read_json(file)
    JSON.parse(File.read file)
  end
end
