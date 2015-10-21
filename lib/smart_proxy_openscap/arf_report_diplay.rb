require 'openscap'
require 'openscap/ds/arf'

module Proxy::OpenSCAP
  class ArfReportDisplay
    def initialize(cname, arf_id, date, digest)
      @path = File.join(Proxy::OpenSCAP::Plugin.settings.reportsdir, 'arf', cname, arf_id, date, digest)
      raise FileNotFound, "Can't find path #{@path}" if !File.file?(@path) || File.zero?(@path)
      @arf = File.read(@path)
    end

    def to_xml
      @arf
    end

    def to_html
      OpenSCAP.oscap_init
      size = File.open(@path).size
      arf_object = OpenSCAP::DS::Arf.new(:content => @arf, :path => 'arf.xml.bz2', :length => size)
      arf_object.html.force_encoding('UTF-8')
    end
  end
end
