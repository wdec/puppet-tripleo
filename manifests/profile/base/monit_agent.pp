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
# Fundamentally needed to delay strating up of monit until some of the core services have been configured
#
# === Parameters
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
# [*password*]
#   (Optional) The monit password
#
# [*user*]
#   (Optional) The monit username
#
# [*allow*]
#   (Optional) Monit allow statement array.
#
# [*raw_config*]
#   (Optional) String containing raw monit configuration.

class tripleo::profile::base::monit_agent (
  $step         = hiera('step'),
  $user         = hiera('tripleo::monit_agent::user', ''),
  $password     = hiera('tripleo::monit_agent::password'),
  $allow        = hiera('tripleo::monit::allow', []),
  $raw_config   = hiera('tripleo::monit::raw_config', ''),
) {

  # Fix for issue with puppet module. Purge the Fedora default config
  $conf_file    = hiera('monit::conf_file', '/etc/monitrc')

  if hiera('monit::conf_purge', true) {
    exec {"/bin/rm -rf ${conf_file}":
    }
  }

  # Include monit after other services
  if $step > 4 {
    exec { 'fixup config':
      command => "/bin/touch ${conf_file}; chmod 0700 ${conf_file}",
      before  => Class['monit'],
    }

    if !empty($raw_config) {
      file {'/etc/monit.d/20-raw_config':
        ensure  => present,
        content => sprintf("# TRIPLEO PUPPET MANAGED!!\n %s", $raw_config),
        notify  => Class['monit'],
      }
    }

    if !empty($user) {
      # Create PAM authentication with SSL
      if hiera('monit::httpserver_ssl') {
        group { 'monit-ro':
          ensure => 'present',
        }
        user { "$user":
          ensure   => 'present',
          gid      => 'monit-ro',
          shell    => '/usr/sbin/nologin',
          password => pw_hash("$password", 'SHA-512', fqdn_rand_string(10)),
        }
        class { '::monit':
          httpserver_allow => concat(any2array("@${user} read-only"), $allow),
          # Fix issue with puppet module not correctly defining the config files for Rhel
          conf_file => '/etc/monitrc',
        }
      }
      else {
        $user_pass = any2array("${user}:${password}")
        class { '::monit':
          httpserver_allow => concat($user_pass, $allow),
          conf_file => '/etc/monitrc',
        }
      }
    }
    else {
      include ::monit
    }
  }
}

