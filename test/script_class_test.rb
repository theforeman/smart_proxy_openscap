require 'test_helper'
require 'smart_proxy_openscap/arf_html'
require 'smart_proxy_openscap/policy_guide'

class ScriptClassTest < Test::Unit::TestCase
  def test_arf_generate_html
    carry_out do |tmp|
      Proxy::OpenSCAP::ArfHtml.new.generate_html("#{Dir.getwd}/test/data/arf_report", tmp.path)
      content = File.read tmp
      assert content.start_with?('<!DOCTYPE'), "File should be html"
    end
  end

  def test_policy_guide
    carry_out do |tmp|
      profile = "xccdf_org.ssgproject.content_profile_rht-ccp"
      Proxy::OpenSCAP::PolicyGuide.new.generate_guide("#{Dir.getwd}/test/data/ssg-rhel7-ds.xml", tmp.path, profile)
      guide = read_json tmp
      assert guide['html'].start_with?('<!DOCTYPE'), "File should be html"
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
    file.flush
    JSON.parse(File.read file)
  end
end
