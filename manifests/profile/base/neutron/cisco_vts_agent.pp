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
# == Class: tripleo::profile::base::neutron::cisco_vts_agent
#
# Neutron Cisco VTS Agent profile for tripleo
#
# === Parameters
#
# [*vts_ip*]
#   (Optional) IP address for VTS Api Service
#   Defaults to hiera('vts_ip')
#
# [*vts_siteid*]
#   VTS Site ID of the controller
#
# [*vts_port*]
#   (Optional) Virtual Machine Manager ID for VTS
#   Defaults to '8888'
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
class tripleo::profile::base::neutron::cisco_vts_agent(
  $vts_url_ip   = hiera('vts::vts_ip'),
  $vts_siteid   = hiera('vts::vts_siteid'),
  $vts_port     = hiera('vts::vts_port', 8888),
  $step         = hiera('step'),
) {
  include ::tripleo::profile::base::neutron

  if $step >= 4 {

    $vts_url_ip_out = normalize_ip_for_uri($vts_url_ip)

    class { '::neutron::agents::ml2::cisco_vts_agent':
      vts_url => "https://${vts_url_ip_out}:${vts_port}/api/running/vts-service/sites/site/${vts_siteid}/openstack"
    }

    # Optional since manage_service may be false and neutron server may not be colocated.
    Service<| title == 'neutron-server' |> -> Service<| title == 'neutron-vts-agent' |>
  }

}
