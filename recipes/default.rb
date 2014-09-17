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

service "lvm2" do
  action [:start]
end

template '/etc/lvm/lvm.conf' do
  source 'lvm.conf.erb'
  owner 'root'
  mode 0644
  variables(:variables => node['lvm']['conf'])
  action :create
  notifies :start, "service[lvm2]", :delayed
end

unless node['lvm']['devices'].nil?
  node['lvm']['devices'].each do |dev|
    case dev['type']
    when 'pv'
      ruby_block "create pv #{dev['name']}" do
        block do
          lvm = Mixlib::ShellOut.new("pvcreate --norestorefile --metadatatype #{dev['metadatatype']} --metadatasize #{dev['metadatasize']} --dataalignmentoffset #{dev['dataalignmentoffset']} --dataalignment #{dev['dataalignment']} --setphysicalvolumesize #{dev['setphysicalvolumesize']} -Z y -y #{dev['name']}").run_command
          puts lvm.stdout
          puts lvm.stderr
          lvm.error!
        end
        not_if "pvs | grep -q #{dev['name']}"
      end
    when 'lv'
      ruby_block "create lv #{dev['name']}" do
        block do
          if dev['thin']
            lvm = Mixlib::ShellOut.new("lvcreate -L #{dev['size']} --poolmetadatasize #{dev['poolmetadatasize']} --type thin-pool --thinpool #{dev['name']} #{dev['target']}").run_command
          else
            lvm = Mixlib::ShellOut.new("lvcreate --name #{dev['name']} -L #{dev['size']} #{dev['target']}").run_command
          end
          puts lvm.stdout
          puts lvm.stderr
          lvm.error!
        end
        not_if "lvs | grep -q #{dev['name']}"
      end
    when 'vg'
      ruby_block "create vg #{dev['name']}" do
        block do
          lvm = Mixlib::ShellOut.new("vgcreate --autobackup n --maxlogicalvolumes #{dev['maxlogicalvolumes']} --metadatatype #{dev['metadatatype']} --vgmetadatacopies #{dev['vgmetadatacopies']} -y #{dev['name']} #{dev['target']}").run_command
          puts lvm.stdout
          puts lvm.stderr
          lvm.error!
        end
        not_if "vgs | grep -q #{dev['name']}"
      end
    end
  end
end
