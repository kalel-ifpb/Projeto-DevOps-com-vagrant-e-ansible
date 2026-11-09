
Vagrant.configure("2") do |config|
  config.vm.box = "debian/bookworm64"
  config.ssh.insert_key = false

  if Vagrant.has_plugin?("vagrant-vbguest")
    config.vbguest.auto_update = false
  end

  config.vm.synced_folder ".", "/vagrant", disabled: true

  config.vm.provider :virtualbox do |v|
    v.memory = 512
    v.linked_clone = true
    v.check_guest_additions = false
  end

  config.trigger.before :"Vagrant::Action::Builtin::WaitForCommunicator", type: :action do |t|
    t.warn = "Interrompe o servidor DHCP do VirtualBox"
    t.run = { inline: "vboxmanage dhcpserver stop --interface vboxnet0" }
    t.on_error = :continue
  end

  config.vm.provision "ansible" do |ansible|
    ansible.compatibility_mode = "2.0"
    ansible.playbook = "ansible/playbook.yml"
    ansible.config_file = "ansible/ansible.cfg"
  end

  config.vm.define "arq" do |arq|
    arq.vm.hostname = "arq.francisco.kalel.devops"
    arq.vm.network "private_network", ip: "192.168.56.178"
    arq.vm.disk :disk, size: "10GB", name: "disk1"
    arq.vm.disk :disk, size: "10GB", name: "disk2"
    arq.vm.disk :disk, size: "10GB", name: "disk3"
  end

  config.vm.define "db" do |db|
    db.vm.hostname = "db.francisco.kalel.devops"
    db.vm.network "private_network", type: "dhcp", mac: "080027111111"
  end

  config.vm.define "app" do |app|
    app.vm.hostname = "app.francisco.kalel.devops"
    app.vm.network "private_network", type: "dhcp", mac: "080027222222"
  end

  config.vm.define "cli" do |cli|
    cli.vm.hostname = "cli.francisco.kalel.devops"
    cli.vm.network "private_network", type: "dhcp"
    cli.vm.provider :virtualbox do |v|
      v.memory = 1024
    end
  end
end
