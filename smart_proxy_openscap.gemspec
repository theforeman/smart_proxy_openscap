require File.expand_path('../lib/smart_proxy_openscap/version', __FILE__)

Gem::Specification.new do |s|
  s.name = 'smart_proxy_openscap'
  s.version = Proxy::OpenSCAP::VERSION
  s.summary = "OpenSCAP plug-in for Foreman's smart-proxy."
  s.description = "A plug-in to the Foreman's smart-proxy which receives
  bzip2ed ARF files and forwards them to the Foreman."

  s.author = ['Šimon Lukašík', 'Shlomi Zadok', 'Marek Hulan']
  s.email = 'slukasik@redhat.com'
  s.homepage = 'https://github.com/theforeman/smart_proxy_openscap'
  s.license = 'GPL-3.0-or-later'

  s.files = `git ls-files`.split("\n") - ['.gitignore']
  s.executables = ['smart-proxy-openscap-send']
  s.requirements = 'bzip2'
  s.requirements = 'oscap'

  s.required_ruby_version = '>= 2.7', '< 4'

  s.add_development_dependency('rake', '~> 13.0')
  s.add_development_dependency('rack-test', '~> 0')
  s.add_development_dependency('mocha', '~> 1')
  s.add_development_dependency('webmock', '~> 3')
  s.add_dependency 'openscap', '~> 0.4.7'
  s.add_dependency 'openscap_parser', '~> 1.0.2'
end
