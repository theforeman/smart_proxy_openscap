require File.expand_path('../lib/smart-proxy_openscap/openscap_version', __FILE__)

Gem::Specification.new do |s|
  s.name = 'smart-proxy_openscap'
  s.version = Proxy::OpenSCAP::VERSION
  s.summary = "OpenSCAP plug-in for Foreman's smart-proxy."
  s.description = "A plug-in to the Foreman's smart-proxy which receives
  bzip2ed ARF files and forwards them to the Foreman."

  s.author = 'Šimon Lukašík'
  s.email = 'slukasik@redhat.com'
  s.homepage = 'http://github.com/OpenSCAP/smart-proxy_openscap'
  s.license = 'GPL-2+'

  s.files = `git ls-files`.split("\n")
end
