# Copyright 2016 Red Hat, Inc.
# All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
#
# == Class: tripleo::profile::base::sshd
#
# SSH composable service for TripleO
#
# === Parameters
#
# [*bannertext*]
#   The text used within /etc/issue and /etc/issue.net
#   Defaults to hiera('BannerText')
#
# [*motd*]
#   The text used within SSH Banner
#   Defaults to hiera('MOTD')
#
# [*options*]
#   Hash of SSHD options to set. See the puppet-ssh module documentation for
#   details.
#   Defaults to {}
#
# [*port*]
#   SSH port or list of ports to bind to
#   Defaults to [22]

class tripleo::profile::base::sshd (
  $bannertext = hiera('BannerText', undef),
  $motd = hiera('MOTD', undef),
  $options = {},
  $port = [22],
) {

  if $bannertext and $bannertext != '' {
    $sshd_options_banner = {'Banner' => '/etc/issue.net'}
    $filelist = [ '/etc/issue', '/etc/issue.net', ]
    file { $filelist:
      ensure  => file,
      backup  => false,
      content => $bannertext,
      owner   => 'root',
      group   => 'root',
      mode    => '0644'
    }
  } else {
    $sshd_options_banner = {}
  }

  if $motd and $motd != '' {
    $sshd_options_motd = {'PrintMotd' => 'yes'}
    file { '/etc/motd':
      ensure  => file,
      backup  => false,
      content => $motd,
      owner   => 'root',
      group   => 'root',
      mode    => '0644'
    }
  } else {
    $sshd_options_motd = {}
  }

  if $options['Port'] {
    $sshd_options_port = {'Port' => unique(concat(any2array($options['Port']), $port))}
  }
  else {
    $sshd_options_port = {'Port' => unique(any2array($port))}
  }

  $sshd_options = merge(
    $options,
    $sshd_options_banner,
    $sshd_options_motd,
    $sshd_options_port
  )

  # NB (owalsh) in puppet-ssh hiera takes precedence over the class param
  # we need to control this, so error if it's set in hiera
  if hiera('ssh:server::options', undef) {
    err('ssh:server::options must not be set, use tripleo::profile::base::sshd::options')
  }
  class { '::ssh::server':
    storeconfigs_enabled => false,
    options              => $sshd_options
  }
}
