# Copyright 2017 Cisco, Inc.
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
# == Class: tripleo::profile::base::neutron::plugins::ml2::vts
#
# VTS Controller ML2 Neutron profile for TripleO
#
# === Parameters
#
# [*vts_username*]
#   (Optional) Username to configure for VTS
#   Defaults to 'admin'
#
# [*vts_password*]
#   (Optional) Password to configure for VTS
#   Defaults to 'admin'
#
# [*vts_ip*]
#   (Optional) IP address for VTS Api Service
#   Defaults to hiera('vts_ip')
#
# [*vts_port*]
#   (Optional) Virtual Machine Manager ID for VTS
#   Defaults to '8888'
#
# [*vts_vmm_id*]
#   (Optional) Virtual Machine Manager ID for VTS
#   Defaults to hiera('vts_vmm_id')
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
class tripleo::profile::base::neutron::plugins::ml2::vts (
  $vts_username = hiera('vts::username'),
  $vts_password = hiera('vts::password'),
  $vts_url_ip   = hiera('vts::vts_ip'),
  $vts_vmm_id    = hiera('vts::vts_vmmid'),
  $vts_port     = hiera('vts::vts_port'),
  $step         = Integer(hiera('step')),
) {

  if is_ipv6_address($vts_url_ip) {
    $vts_url_ip = enclose_ipv6($vts_url_ip)
  }

  if $step >= 4 {
    if ! $vts_url_ip { fail('VTS IP is Empty') }

    class { '::neutron::plugins::ml2::cisco::vts':
      vts_username => $vts_username,
      vts_password => $vts_password,
      vts_url      => "https://${vts_url_ip}:${vts_port}/api/running/openstack",
      vts_vmmid    => $vts_vmm_id;
    }
  }
}
