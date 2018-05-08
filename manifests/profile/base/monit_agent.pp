# Copyright 2018 Cisco Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
#
# == Class: tripleo::profile::base::monit_agent
#
# Monit agent profile for tripleo
#
# Relies on the echoes-monit module
#
# === Parameters
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
# [*user*]
#   (Optional) The monit username
#
# [*password*]
#   (Optional) The monit password
#
# [*raw_config*]
#   (Optional) String containing raw monit configuration.

class tripleo::profile::base::monit_agent (
  $step         = hiera('step'),
  $user         = hiera('monit::httpd_user', ''),
  $password     = hiera('monit::httpd_password', ''),
  $raw_config   = hiera('tripleo::monit::raw_config', ''),
) {

  # Include monit after other services
  if $step > 4 {

    if !empty($raw_config) {
      monit::check {'vtf':
        content => sprintf("# TRIPLEO PUPPET MANAGED!!\n %s", $raw_config),
      }
    }

    if !empty($user) {
      # Create PAM authentication with SSL
      if hiera('monit::httpd_ssl', false) {
        group { 'monit-ro':
          ensure => 'present',
        }
        if !empty($password) {
          user { "$user":
            ensure   => 'present',
            gid      => 'monit-ro',
            shell    => '/usr/sbin/nologin',
            password => pw_hash("$password", 'SHA-512', fqdn_rand_string(10)),
          }
        }
      }
    }
    include ::monit
  }
}

