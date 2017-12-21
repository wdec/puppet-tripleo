#
# Copyright (C) 2017 Red Hat, Inc.
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

require 'spec_helper'

describe 'tripleo::profile::base::logging::fluentd' do
  shared_examples_for 'tripleo::profile::base::logging::fluentd' do

    before :each do
      facts.merge!({ :step => params[:step] })
    end

    context 'with step less than 4' do
      let(:params) { { :step => 3 } }

      it 'should do nothing' do
        is_expected.to_not contain_class('fluentd')
        is_expected.to_not contain_fluentd__plugin('rubygem-fluent-plugin-add')
      end
    end

    context 'with defaults and step greater than 3' do
      let(:params) { { :step => 4 } }

      it { is_expected.to contain_class('fluentd') }
      it { is_expected.to contain_fluentd__plugin('rubygem-fluent-plugin-add').with(
        :plugin_provider => 'yum',
      ) }
    end

    context 'step greater than 3 and a fluentd source' do
      let(:params) { {
        :step => 4,
        :fluentd_sources => [ {
          'format' => '/(?<time>\\d{4}-\\d{2}-\\d{2} \\d{2} =>\\d{2}:\\d{2}.\\d+) (?<pid>\\d+) (?<priority>\\S+) (?<message>.*)$/',
          'path' => '/var/log/keystone/keystone.log',
          'pos_file' => '/var/cache/fluentd/openstack.keystone.pos',
          'tag' => 'openstack.keystone',
          'type' => 'tail'
        } ],
      } }

      it { is_expected.to contain_class('fluentd') }
      it { is_expected.to contain_fluentd__plugin('rubygem-fluent-plugin-add').with(
        :plugin_provider => 'yum',
      ) }
      it { is_expected.to contain_fluentd__config('100-openstack-sources.conf').with(
        :config => {
          'source' => params[:fluentd_sources]
        }
      ) }
    end

    context 'step greater than 3 and a fluentd source with transformation' do
      let(:params) { {
        :step => 4,
        :fluentd_sources => [ {
          'format' => '/(?<time>\\d{4}-\\d{2}-\\d{2} \\d{2} =>\\d{2}:\\d{2}.\\d+) (?<pid>\\d+) (?<priority>\\S+) (?<message>.*)$/',
          'path' => '/var/log/keystone/keystone.log',
          'pos_file' => '/var/cache/fluentd/openstack.keystone.pos',
          'tag' => 'openstack.keystone',
          'type' => 'tail'
        } ],
        :fluentd_path_transform => [
          '/var/log/',
          '/var/log/containers/',
        ]
      } }

      it { is_expected.to contain_class('fluentd') }
      it { is_expected.to contain_fluentd__plugin('rubygem-fluent-plugin-add').with(
        :plugin_provider => 'yum',
      ) }
      it { is_expected.to contain_fluentd__config('100-openstack-sources.conf').with(
        :config => {
          'source' => [ {
          'format' => '/(?<time>\\d{4}-\\d{2}-\\d{2} \\d{2} =>\\d{2}:\\d{2}.\\d+) (?<pid>\\d+) (?<priority>\\S+) (?<message>.*)$/',
          'path' => '/var/log/containers/keystone/keystone.log',
          'pos_file' => '/var/cache/fluentd/openstack.keystone.pos',
          'tag' => 'openstack.keystone',
          'type' => 'tail'
        } ]
        }
      ) }
    end

    context 'Config by service -- ceilometer_agent_central' do
      let(:params) { {
        :step => 4,
        :fluentd_default_format => '/(?<time>\\d{4}-\\d{2}-\\d{2} \\d{2} =>\\d{2}:\\d{2}.\\d+) (?<pid>\\d+) (?<priority>\\S+) (?<message>.*)$/',
        :fluentd_manage_groups => false,
        :fluentd_pos_file_path => '/var/cache/fluentd/',
        :service_names => [ 'ceilometer_agent_central' ]
      } }
      it { is_expected.to contain_class('fluentd') }
      it { is_expected.to contain_file('/var/cache/fluentd/') }
      it { is_expected.to contain_tripleo__profile__base__logging__fluentd__fluentd_service('ceilometer_agent_central').with(
       :pos_file_path => '/var/cache/fluentd/',
       :default_format => '/(?<time>\\d{4}-\\d{2}-\\d{2} \\d{2} =>\\d{2}:\\d{2}.\\d+) (?<pid>\\d+) (?<priority>\\S+) (?<message>.*)$/'
      ) }
      it { is_expected.to contain_fluentd__config('100-openstack-ceilometer_agent_central.conf') }
      it { is_expected.to contain_file('/etc/fluentd/config.d/100-openstack-ceilometer_agent_central.conf') }
    end

    context 'Groups by service -- ceilometer_agent_central added ceilometer' do
      let(:params) { {
        :step => 4,
        :fluentd_manage_groups => true,
        :fluentd_groups => [ 'fluentd' ]
      } }
      it { is_expected.to contain_class('fluentd') }
      it { is_expected.to contain_user('fluentd').with(
        :ensure =>'present',
        :groups => [ 'fluentd', 'ceilometer' ],
        :membership => 'minimum'
      ) }
    end

  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let (:facts) {
        facts
      }
      it_behaves_like 'tripleo::profile::base::logging::fluentd'
    end
  end
end