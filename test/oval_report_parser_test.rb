require 'test_helper'
require 'smart_proxy_openscap'
require 'smart_proxy_openscap/oval_report_parser'

class OvalReportParserTest < Test::Unit::TestCase

  def test_oval_report_parsing
    oval_report = File.open("#{Dir.getwd}/test/data/oval-results.xml.bz2").read
    res = Proxy::OpenSCAP::OvalReportParser.new.parse_cves oval_report
    refute res.empty?
    assert res.first[:result]
    refute res.first[:references].empty?
  end
end
