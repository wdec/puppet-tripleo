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
# Cisco VPFA profile for TripleO
#
# === Parameters
#
#
# [*vts_ip*]
#   IP address for VTS Api Service
#   Defaults to hiera('vts_ip')
#
# [*vts_port*]
#   Virtual Machine Manager ID for VTS
#   Defaults to '8888'
#
# [*vpfa_hostname*]
#   (Optional) Hostname to represent the VPFA.
#   Defaults to the host's hostname if not overriden by user config.
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
class tripleo::profile::base::cisco_vpfa (
  $vts_url_ip   = hiera('vts::vts_ip'),
  $vts_port     = hiera('vts::vts_port'),
  $vpfa_hostname = hiera('cisco_vpfa::vpfa_hostname', $::hostname),
  $vpfa_ip1 = hiera('vts::vtf_underlay_ip_v4', undef),
  $vpfa_ip1_mask = hiera('vts::vtf_underlay_mask_v4', undef),

  $step         = hiera('step'),

) {

  if $step >= 4 {
    if ! $vts_url_ip { fail('VTS IP is Empty') }

  if is_ipv6_address($vts_url_ip) {
    $vts_url_ip_out = enclose_ipv6($vts_url_ip)
  }
  else {
    $vts_url_ip_out = $vts_url_ip
  }


  if $vpfa_ip1 == undef {
    fail('Cisco VPFA IP address is undefined')
  }

  if $vpfa_ip1_mask == undef {
    fail('Cisco VPFA IP Mask is undefined')
  }

  #Figure out the underlay interface config source and bonding
  if !hiera('vts::vpfa_init') {
    # OSPD native module is used to config VPP. Need to extract the underlay interfaces from
    # os-net-config
    $underlay_interface = hiera('cisco_vpfa::underlay_interface')
    $bond_if_list = hiera('cisco_vpfa::bond_if_list')

  }
  else {
    $underlay_interface = hiera('vts::underlay_interface', undef)
    $bond_if_list = hiera('vts::bond_if_list', undef)
  }

    class { '::cisco_vpfa':
      vts_registration_api      => "https://${vts_url_ip_out}:${vts_port}/api/running/cisco-vts/vtfs/vtf",
      vts_address => $vts_url_ip_out,
      vpfa_hostname => $vpfa_hostname,
      network_ipv4_address => $vpfa_ip1,
      network_ipv4_mask => $vpfa_ip1_mask,
      underlay_interface => $underlay_interface,
      bond_if_list => $bond_if_list
    }
  }
}
