require File.expand_path('../lib/smart_proxy_openscap/version', __FILE__)

Gem::Specification.new do |s|
  s.name = 'smart_proxy_openscap'
  s.version = Proxy::OpenSCAP::VERSION
  s.summary = "OpenSCAP plug-in for Foreman's smart-proxy."
  s.description = "A plug-in to the Foreman's smart-proxy which receives
  bzip2ed ARF files and forwards them to the Foreman."

  s.author = ['Šimon Lukašík', 'Shlomi Zadok', 'Marek Hulan']
  s.email = 'slukasik@redhat.com'
  s.homepage = 'http://github.com/OpenSCAP/smart_proxy_openscap'
  s.license = 'GPL-3'

  s.files = `git ls-files`.split("\n") - ['.gitignore']
  s.executables = ['smart-proxy-openscap-send']

  s.add_development_dependency('rake')
  s.add_development_dependency('rack-test')
  s.add_development_dependency('mocha')
  s.add_development_dependency('webmock')
  s.add_dependency 'openscap', '~> 0.4.7'
end
