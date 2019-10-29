# Copyright 2018 Cisco, Inc.
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
# == Class: tripleo::profile::base::collectd
#
# Collectd profile for TripleO
#
# === Parameters
#
#
# [*plugin_configs*]
#   Keyed hash of configs, with key being the plugin name.
#   For each plugin a "content" key MUST be present, which can be empty.
#   Defaults to hiera('tripleo::collectd:plugin_config')
#
#
# [*purge*]
#   Purge default configuration and plugin configurations
#   Defaults to true
#
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
class tripleo::profile::base::collectd (
  $configs      = hiera('tripleo::collectd:plugin_configs', undef),
  $purge        = hiera('tripleo::collectd:purge', true),
  $step         = hiera('step'),
)
  {
    if $step >= 4 {
      if $purge {
        class { '::collectd':
          purge        => true,
          recurse      => true,
          purge_config => true,
        }
      }

      # Get the configs for each plugin. Work only with Puppet 4!
      if !empty($configs) {
        $configs.each | $name, $config | {
          collectd::plugin { $name:
            content => join($config["content"], "\n"),
            ensure => present,
          }
        }
      }

      include ::collectd
    }
  }



