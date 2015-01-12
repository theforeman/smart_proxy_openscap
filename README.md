# OpenSCAP plug-in for Foreman Proxy

A plug-in to the Foreman Proxy which receives bzip2ed ARF files
and forwards them to the Foreman.

Incoming ARF files are authenticated using puppet certificate of
the client machine. Proxy caches collected ARF files until they
are forwarded to Foreman.

Learn more about [Foreman-OpenSCAP](https://github.com/OpenSCAP/foreman_openscap) workflow.

## Installation from RPMs

- Install foreman-proxy from Foreman-proxy upstream

- Enable [isimluk/OpenSCAP](https://copr.fedoraproject.org/coprs/isimluk/OpenSCAP/) COPR repository

- Install Foreman-proxy_OpenSCAP

  ```
  # yum install rubygem-foreman-proxy_openscap
  ```

## Installation from upstream git

- Install foreman-proxy from Foreman-proxy upstream
- Download foreman-proxy_openscap

  ```
  ~$ git clone https://github.com/OpenSCAP/foreman-proxy_openscap.git
  ```

- Build foreman-proxy_openscap RPM

  ```
  ~$ cd foreman-proxy_openscap
  ~$ gem build foreman_proxy_openscap.gemspec
  ~# yum install yum-utils rpm-build
  ~# yum-builddep extra/rubygem-foreman-proxy_openscap.spec
  ~# rpmbuild  --define "_sourcedir `pwd`" -ba extra/rubygem-foreman-proxy_openscap.spec
  ```

- Install rubygem-forman-proxy_openscap

  ```
  ~$ yum local install ~/rpmbuild/RPMS/noarch/rubygem-foreman-proxy_openscap*
  ```

If you don't install through RPM but you are using bundler, you may need to create 
/var/spool/foreman-proxy directory manually and set it's owner to the user under which 
foreman-proxy runs.

## Configuration

  ```
  cp /etc/foreman-proxy/settings.d/openscap.yml{.example,}
  vim /etc/foreman-proxy/settings.d/openscap.yml
  echo ":foreman_url: https://my-foreman.local.lan" >> /etc/foreman-proxy/settings.yml
  ```

- Deploy

  ```
  ~# service foreman-proxy restart
  ```

- Usage:

  Learn more about [Foreman-OpenSCAP](https://github.com/OpenSCAP/foreman_openscap) workflow.

## Copyright

Copyright (c) 2014 Red Hat, Inc.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
