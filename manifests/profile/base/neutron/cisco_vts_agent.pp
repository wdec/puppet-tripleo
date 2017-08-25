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
# == Class: tripleo::profile::base::neutron::ovs
#
# Neutron Cisco VTS Agent profile for tripleo
#
# === Parameters
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
class tripleo::profile::base::neutron::cisco_vts_agent(
  $step           = hiera('step'),
) {
  include ::tripleo::profile::base::neutron

  if $step >= 4 {
    #THIS LOOKS INCORRECT. BUT how does one config the fuller ovs.ini file otherwise?
    include ::neutron::agents::ml2::ovs

    # Optional since manage_service may be false and neutron server may not be colocated.
    Service<| title == 'neutron-server' |> -> Service<| title == 'neutron-vts-agent-service' |>
  }

}
