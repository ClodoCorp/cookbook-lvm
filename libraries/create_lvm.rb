def create_lvm(name, dev)
  case dev['type']
  when 'pv'
    ruby_block "create pv #{name}" do
      block do
        lvm = Mixlib::ShellOut.new("pvcreate --norestorefile --metadatatype #{dev['metadatatype']} --metadatasize #{dev['metadatasize']} --dataalignmentoffset #{dev['dataalignmentoffset']} --dataalignment #{dev['dataalignment']} --setphysicalvolumesize #{dev['setphysicalvolumesize']} -Z y -y #{name}").run_command
        puts lvm.stdout
        puts lvm.stderr
        lvm.error!
      end
      not_if "pvs | grep -q #{name}"
    end
  when 'lv'
    ruby_block "create lv #{name}" do
      block do
        if dev['thin']
          lvm = Mixlib::ShellOut.new("lvcreate -L #{dev['size']} --poolmetadatasize #{dev['poolmetadatasize']} --type thin-pool --thinpool #{name} #{dev['target']}").run_command
        else
          lvm = Mixlib::ShellOut.new("lvcreate --name #{name} -L #{dev['size']} #{dev['target']}").run_command
        end
        puts lvm.stdout
        puts lvm.stderr
        lvm.error!
        if dev['fs']
         fsopts = dev['fsopts'].nil? ? "" : dev['fsopts']
         filesystem = Mixlib::ShellOut.new("mkfs.#{dev['fs']} #{fsopts} /dev/#{dev['target']}/#{name}").run_command
         puts filesystem.stdout
         puts filesystem.stderr
         filesystem.error!
        end
      end
      not_if "lvs | grep -q #{name}"
    end
  when 'vg'
    ruby_block "create vg #{name}" do
      block do
        lvm = Mixlib::ShellOut.new("vgcreate --autobackup n --maxlogicalvolumes #{dev['maxlogicalvolumes']} --metadatatype #{dev['metadatatype']} --vgmetadatacopies #{dev['vgmetadatacopies']} -y #{name} #{dev['target']}").run_command
        puts lvm.stdout
        puts lvm.stderr
        lvm.error!
      end
      not_if "vgs | grep -q #{name}"
    end
  end
end