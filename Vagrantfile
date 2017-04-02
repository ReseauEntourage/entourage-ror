Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/xenial64"

  config.vm.provision :shell, privileged: false, path: "scripts/vagrant_setup.sh"

  # Make this VM reachable on the host network as well, so that other
  # VM's running other browsers can access our dev server.
  config.vm.network :private_network, ip: "192.168.10.200"

  # Make it so that network access from the vagrant guest is able to
  # use SSH private keys that are present on the host without copying
  # them into the VM.
  config.ssh.forward_agent = true

  config.vm.provider :virtualbox do |v|
    # This setting gives the VM 1024MB of RAM instead of the default 384.
    v.memory = [ENV["ENTOURAGE_VM_MEM"].to_i, 1024].max

    # Determine the available cores in host system or default to 2.
    v.cpus =
      case RUBY_PLATFORM
      when /linux/
        `nproc`.to_i
      when /darwin/
        `sysctl -n hw.ncpu`.to_i
      else
        2
      end

    # Enable I/O APIC to allow for multiple virtual CPUs
    v.customize ["modifyvm", :id, "--ioapic", "on"]

    # This setting makes it so that network access from inside the vagrant guest
    # is able to resolve DNS using the hosts VPN connection.
    v.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
  end

  config.vm.network :forwarded_port, guest: 3000, host: 4000

  config.vm.synced_folder ".", "/home/vagrant/entourage-ror", id: "vagrant-root"
end
