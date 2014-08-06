#
# Cookbook Name:: lvm
# Recipe:: default
#
# Copyright 2009-2013, Opscode, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

node['lvm']['packages'].each do |pkg|
  package pkg
end

template '/etc/lvm/lvm.conf' do
  source 'lvm.conf.erb'
  owner 'root'
  mode 0644
  variables(:variables => node['lvm']['conf'])
  action :create
end

node['lvm']['devices'].each do |dev|
  case dev['type']
    when 'pv'
    ruby_block "create pv #{dev['name']}" do
      block do
        require 'lvm'
        lvm.raw("pvcreate --norestorefile --metadatatype #{dev['metadatatype']} --metadatasize #{dev['metadatasize']} --dataalignmentoffset #{dev['dataalignmentoffset']} --dataalignment #{dev['dataalignment']} --setphysicalvolumesize #{dev['setphysicalvolumesize']} -Z -y #{dev['name']}")
      end
    end
    when 'vg'
    ruby_block "create vg #{dev['name']}" do
      block do
        require 'lvm'
        lvm.raw("vgcreate --autobackup n --maxlogicalvolumes #{dev['maxlogicalvolumes']} --metadatatype #{dev['metadatatype']} --vgmetadatacopies #{dev['vgmetadatacopies']}-y #{dev['name']} #{dev['target']}")
      end
    end
  end
end
