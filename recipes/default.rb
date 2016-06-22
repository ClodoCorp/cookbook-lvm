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

if node['lvm']['service_name'].nil?
  case node['platform']
  when 'debian'
    case node['platform_version']
    when /^8\./
      node['lvm']['service_name'] = 'lvm2-activation'
    end
  end
end

case node['platform_family']
when 'debian','ubuntu'
  service 'lvm2' do
    case node['platform']
    when 'debian'
      case node['platform_version']
      when /^8\./
        service_name node['lvm']['service_name']
        provider Chef::Provider::Service::Systemd
      end
    end
    action [:start]
    subscribes :start, "template[#{node['lvm']['config_file']}]", :delayed
    subscribes :start, "template[#{node['mdadm']['config_file']}]", :delayed
  end
end

template node['lvm']['config_file'] do
  source 'lvm.conf.erb'
  owner 'root'
  mode 0644
  variables(:variables => node['lvm']['conf'])
  action :create
end

unless node['lvm']['devices'].nil?
  if node['lvm']['devices'].is_a?(Array)
    node['lvm']['devices'].each do |dev|
      create_lvm(dev['name'], dev)
    end
  elsif node['lvm']['devices'].is_a?(Hash)
    node['lvm']['devices'].each do |name, params|
      create_lvm(name, params)
    end
  end
end
