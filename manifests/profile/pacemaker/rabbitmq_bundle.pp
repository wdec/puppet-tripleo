# Copyright 2017 Red Hat, Inc.
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
# == Class: tripleo::profile::pacemaker::rabbitmq_bundle
#
# Containerized RabbitMQ Pacemaker HA profile for tripleo
#
# === Parameters
#
# [*rabbitmq_docker_image*]
#   (Optional) The docker image to use for creating the pacemaker bundle
#   Defaults to hiera('tripleo::profile::pacemaker::rabbitmq_bundle::rabbitmq_docker_image', undef)
#
# [*rabbitmq_docker_control_port*]
#   (Optional) The bundle's pacemaker_remote control port on the host
#   Defaults to hiera('tripleo::profile::pacemaker::rabbitmq_bundle::control_port', '3121')
#
# [*bootstrap_node*]
#   (Optional) The hostname of the node responsible for bootstrapping tasks
#   Defaults to hiera('rabbitmq_short_bootstrap_node_name')
#
# [*erlang_cookie*]
#   (Optional) Content of erlang cookie.
#   Defaults to hiera('rabbitmq::erlang_cookie').
#
# [*user_ha_queues*]
#   (Optional) The number of HA queues in to be configured in rabbitmq
#   Defaults to hiera('rabbitmq::nr_ha_queues'), which is usually 0 meaning
#   that the queues number will be CEIL(N/2) where N is the number of rabbitmq
#   nodes.
#
# [*rabbit_nodes*]
#   (Optional) The list of rabbitmq nodes names
#   Defaults to hiera('rabbitmq_node_names')
#
# [*step*]
#   (Optional) The current step in deployment. See tripleo-heat-templates
#   for more details.
#   Defaults to hiera('step')
#
# [*pcs_tries*]
#   (Optional) The number of times pcs commands should be retried.
#   Defaults to hiera('pcs_tries', 20)
#
class tripleo::profile::pacemaker::rabbitmq_bundle (
  $rabbitmq_docker_image        = hiera('tripleo::profile::pacemaker::rabbitmq_bundle::rabbitmq_docker_image', undef),
  $rabbitmq_docker_control_port = hiera('tripleo::profile::pacemaker::rabbitmq_bundle::control_port', '3121'),
  $bootstrap_node               = hiera('rabbitmq_short_bootstrap_node_name'),
  $erlang_cookie                = hiera('rabbitmq::erlang_cookie'),
  $user_ha_queues               = hiera('rabbitmq::nr_ha_queues', 0),
  $rabbit_nodes                 = hiera('rabbitmq_node_names'),
  $pcs_tries                    = hiera('pcs_tries', 20),
  $step                         = Integer(hiera('step')),
) {
  if $::hostname == downcase($bootstrap_node) {
    $pacemaker_master = true
  } else {
    $pacemaker_master = false
  }

  include ::tripleo::profile::base::rabbitmq

  file { '/var/lib/rabbitmq/.erlang.cookie':
    ensure  => file,
    owner   => 'rabbitmq',
    group   => 'rabbitmq',
    mode    => '0400',
    content => $erlang_cookie,
    replace => true,
    require => Class['::rabbitmq'],
  }

  if $step >= 1 and $pacemaker_master and hiera('stack_action') == 'UPDATE' {
    tripleo::pacemaker::resource_restart_flag { 'rabbitmq-clone':
      subscribe => Class['rabbitmq::service'],
    }
  }


  if $step >= 2 {
    if $pacemaker_master {
      $rabbitmq_short_node_names = hiera('rabbitmq_short_node_names')
      $rabbitmq_nodes_count = count($rabbitmq_short_node_names)
      $rabbitmq_short_node_names.each |String $node_name| {
        pacemaker::property { "rabbitmq-role-${node_name}":
          property => 'rabbitmq-role',
          value    => true,
          tries    => $pcs_tries,
          node     => $node_name,
          before   => Pacemaker::Resource::Bundle['rabbitmq-bundle'],
        }
      }

      pacemaker::resource::bundle { 'rabbitmq-bundle':
        image             => $rabbitmq_docker_image,
        replicas          => $rabbitmq_nodes_count,
        location_rule     => {
          resource_discovery => 'exclusive',
          score              => 0,
          expression         => ['rabbitmq-role eq true'],
        },
        container_options => 'network=host',
        options           => '--user=root --log-driver=journald -e KOLLA_CONFIG_STRATEGY=COPY_ALWAYS',
        run_command       => '/bin/bash /usr/local/bin/kolla_start',
        network           => "control-port=${rabbitmq_docker_control_port}",
        storage_maps      => {
          'rabbitmq-cfg-files'               => {
            'source-dir' => '/var/lib/kolla/config_files/rabbitmq.json',
            'target-dir' => '/var/lib/kolla/config_files/config.json',
            'options'    => 'ro',
          },
          'rabbitmq-cfg-data'                => {
            'source-dir' => '/var/lib/config-data/rabbitmq/etc/rabbitmq',
            'target-dir' => '/etc/rabbitmq',
            'options'    => 'ro',
          },
          'rabbitmq-hosts'                   => {
            'source-dir' => '/etc/hosts',
            'target-dir' => '/etc/hosts',
            'options'    => 'ro',
          },
          'rabbitmq-localtime'               => {
            'source-dir' => '/etc/localtime',
            'target-dir' => '/etc/localtime',
            'options'    => 'ro',
          },
          'rabbitmq-lib'                     => {
            'source-dir' => '/var/lib/rabbitmq',
            'target-dir' => '/var/lib/rabbitmq',
            'options'    => 'rw',
          },
          'rabbitmq-pki-extracted'           => {
            'source-dir' => '/etc/pki/ca-trust/extracted',
            'target-dir' => '/etc/pki/ca-trust/extracted',
            'options'    => 'ro',
          },
          'rabbitmq-pki-ca-bundle-crt'       => {
            'source-dir' => '/etc/pki/tls/certs/ca-bundle.crt',
            'target-dir' => '/etc/pki/tls/certs/ca-bundle.crt',
            'options'    => 'ro',
          },
          'rabbitmq-pki-ca-bundle-trust-crt' => {
            'source-dir' => '/etc/pki/tls/certs/ca-bundle.trust.crt',
            'target-dir' => '/etc/pki/tls/certs/ca-bundle.trust.crt',
            'options'    => 'ro',
          },
          'rabbitmq-pki-cert'                => {
            'source-dir' => '/etc/pki/tls/cert.pem',
            'target-dir' => '/etc/pki/tls/cert.pem',
            'options'    => 'ro',
          },
          'rabbitmq-dev-log'                 => {
            'source-dir' => '/dev/log',
            'target-dir' => '/dev/log',
            'options'    => 'rw',
          },
        },
      }

      # The default nr of ha queues is ceiling(N/2)
      if $user_ha_queues == 0 {
        $nr_rabbit_nodes = size($rabbit_nodes)
        $nr_ha_queues = $nr_rabbit_nodes / 2 + ($nr_rabbit_nodes % 2)
        $params = "set_policy='ha-all ^(?!amq\\.).* {\"ha-mode\":\"exactly\",\"ha-params\":${nr_ha_queues}}'"
      } elsif $user_ha_queues == -1 {
        $params = 'set_policy=\'ha-all ^(?!amq\.).* {"ha-mode":"all"}\''
      } else {
        $nr_ha_queues = $user_ha_queues
        $params = "set_policy='ha-all ^(?!amq\\.).* {\"ha-mode\":\"exactly\",\"ha-params\":${nr_ha_queues}}'"
      }
      pacemaker::resource::ocf { 'rabbitmq':
        ocf_agent_name  => 'heartbeat:rabbitmq-cluster',
        resource_params => $params,
        meta_params     => 'notify=true',
        op_params       => 'start timeout=200s stop timeout=200s',
        tries           => $pcs_tries,
        location_rule   => {
          resource_discovery => 'exclusive',
          score              => 0,
          expression         => ['rabbitmq-role eq true'],
        },
        bundle          => 'rabbitmq-bundle',
        require         => [Class['::rabbitmq'],
                            Pacemaker::Resource::Bundle['rabbitmq-bundle']],
      }
    }
  }
}
