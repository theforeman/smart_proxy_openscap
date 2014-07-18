%global gem_name smart-proxy_openscap

%global foreman_proxy_bundlerd_dir /usr/share/foreman-proxy/bundler.d
%global foreman_proxy_pluginconf_dir /etc/foreman-proxy/settings.d

Name: rubygem-%{gem_name}
Version: 0.0.1
Release: 1%{?dist}
Summary: OpenSCAP plug-in for Foreman's smart-proxy.
Group: Applications/Internet
License: GPLv2+
URL: http://github.com/openscap/smart-proxy_openscap
Source0: https://rubygems.org/gems/%{gem_name}-%{version}.gem
Requires: ruby(release)
Requires: ruby(rubygems)
Requires: foreman-proxy
BuildRequires: ruby(release)
BuildRequires: rubygems-devel
BuildRequires: ruby
BuildArch: noarch
Provides: rubygem(%{gem_name}) = %{version}

%description
A plug-in to the Foreman's smart-proxy which receives bzip2ed ARF files
and forwards them to the Foreman.

%prep
gem unpack %{SOURCE0}
%setup -q -D -T -n  %{gem_name}-%{version}
gem spec %{SOURCE0} -l --ruby > %{gem_name}.gemspec

%build
# Create the gem as gem install only works on a gem file
gem build %{gem_name}.gemspec

# %%gem_install compiles any C extensions and installs the gem into ./%gem_dir
# by default, so that we can move it into the buildroot in %%install
%gem_install

%install
mkdir -p %{buildroot}%{gem_dir}
cp -a .%{gem_dir}/* \
       %{buildroot}%{gem_dir}/
mv %{buildroot}%{gem_instdir}/smart-proxy_openscap.gemspec %{buildroot}/%{gem_spec}

# bundler file
mkdir -p %{buildroot}%{foreman_proxy_bundlerd_dir}
mv %{buildroot}%{gem_instdir}/bundler.d/openscap.rb \
   %{buildroot}%{foreman_proxy_bundlerd_dir}

# sample config
mkdir -p %{buildroot}%{foreman_proxy_pluginconf_dir}
mv %{buildroot}%{gem_instdir}/settings.d/openscap.yml.example \
   %{buildroot}%{foreman_proxy_pluginconf_dir}/

%files
%dir %{gem_instdir}
%{gem_libdir}
%exclude %{gem_cache}
%{gem_spec}

%{foreman_proxy_bundlerd_dir}/openscap.rb
%doc %{foreman_proxy_pluginconf_dir}/openscap.yml.example

%{gem_docdir}
%{gem_instdir}/README.md
%{gem_instdir}/COPYING

%changelog
* Fri Jul 18 2014 Šimon Lukašík <slukasik@redhat.com> - 0.0.1-1
- Initial package
