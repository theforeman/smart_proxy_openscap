# OpenSCAP plug-in for Foreman Proxy

A plug-in to the Foreman Proxy which receives bzip2ed ARF files
and forwards them to the Foreman.

Current version only receives and stores the ARF files. The
reports will be forwarded to foreman_openscap in future versions.

## Installation

- Install foreman-proxy from Foreman-proxy upstream
- Download foreman-proxy_openscap

  ```
  ~$ git clone https://github.com/OpenSCAP/foreman-proxy_openscap.git
  ```

- Build foreman-proxy_openscap RPM

  ```
  ~$ cd foreman-proxy_openscap
  ~$ gem build foreman_proxy_openscap.gemspec
  ~# yum install yum-utils
  ~# yum-builddep extra/rubygem-foreman-proxy_openscap.spec
  ~# rpmbuild  --define "_sourcedir `pwd`" -ba extra/rubygem-foreman-proxy_openscap.spec
  ```

- Install rubygem-forman-proxy_openscap

  ```
  ~$ yum local install ~/rpmbuild/RPMS/noarch/rubygem-foreman-proxy_openscap*
  ```

- Configure

  ```
  cp /etc/foreman-proxy/settings.d/openscap.yml{.example,}
  vim /etc/foreman-proxy/settings.d/openscap.yml
  ```

- Deploy

  ```
  ~# service foreman-proxy restart
  ```

- Usage:

  Deploy openscap::xccdf::foreman_audit puppet class from Foreman on your clients.
  The client will upload their audit results to your Foreman proxies.
