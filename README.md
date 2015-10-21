# OpenSCAP plug-in for Foreman Proxy

A plug-in to the Foreman Proxy which receives bzip2ed ARF files
and forwards them as JSON to the Foreman.
smart_proxy_openscap plugin is required for the normal operation of OpenSCAP in the Foreman.

## How it works

Incoming ARF files are authenticated using either puppet certificate or Katello certificate of
the client machine. The ARF files are parsed on the proxy and posted to the Foreman as JSON reports 
and the ARF files are saved in a reports directory, where they can be accessed for full HTML report or 
downloaded as bzip2ed xml report.
If posting is failed, the ARF files are saved in queue for later retry.

Learn more about [Foreman-OpenSCAP](https://github.com/theforeman/foreman_openscap) workflow.

## Installation from RPMs

- Install smart_proxy_openscap

  ```
  # yum install rubygem-smart_proxy_openscap
  ```

## Installation from upstream git
- Add smart_proxy_openscap to your smart proxy `bundler.d/openscap.rb` gemfile:
 
  ```
  ~$ gem 'smart_proxy_openscap', :git => https://github.com/theforeman/smart_proxy_openscap.git
  ```

If you don't install through RPM and you are using bundler, you may need to create 
/var/spool/foreman-proxy & /usr/share/foreman-proxy/openscap directories manually and 
set it's owner to the user under which foreman-proxy runs.

## Configuration

  ```
  cp /etc/foreman-proxy/settings.d/openscap.yml{.example,}
  ```
Configure the following parameters so it would look like:
  
  ```
  ---
  :enabled: true
  
  # Log file for the forwarding script.
  :openscap_send_log_file: /var/log/foreman-proxy/openscap-send.log
  
  # Directory where OpenSCAP audits are stored
  # before they are forwarded to Foreman
  :spooldir: /var/spool/foreman-proxy/openscap
  
  # Directory where OpenSCAP content XML are stored
  # So we will not request the XML from Foreman each time
  :contentdir: /var/lib/openscap/content
  # Directory where OpenSCAP report XML are stored
  # So Foreman can request arf xml reports
  :reportsdir: /usr/share/foreman-proxy/openscap/content
  ```

- Deploy

  ```
  ~# service foreman-proxy restart
  ```

## Usage

![Openscap design](http://shlomizadok.github.io/foreman_openscap/static/images/reports_design.png)

### Exposed APIs

* POST "/compliance/arf/:policy" - API to recieve ARF files, parse them and post to the Foreman. `:policy` is the policy ID from Foreman. expects ARF bzip2 file as POST body

* GET "/compliance/arf/:id/:cname/:date/:digest/xml" - API to download bizped2 ARF file. `:id` - ArfReport id, `:cname` - Host name, `:date` - Report date, `:digest` - Digest of the Arf file

* GET "/compliance/arf/:id/:cname/:date/:digest/html" - API to fetch full HTML report. `:id` - ArfReport id, `:cname` - Host name, `:date` - Report date, `:digest` - Digest of the Arf file

* GET "/compliance/policies/:policy_id/content" - API to download and serve SCAP content file for policy. `:policy_id` - Policy id from Foreman

* POST "/compliance/scap_content/policies" - API to extract policies from SCAP content. expects SCAP content posted as the POST body

* POST "/compliance/scap_content/validator" - API to validate SCAP content. expects SCAP content posted as the POST body

* POST "/compliance/scap_content/guide/:policy" - API to return Policy's HTML guide. `:policy` - policy name. expects SCAP content posted as the POST body

### Binaries

* `smart_proxy_openscap_send` - Sends failed ARF files to Foreman (in case first try failed). When installed with RPM, a cron jobs is configured to run every 30 minutes.

## Copyright

Copyright (c) 2014--2015 Red Hat, Inc.

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
