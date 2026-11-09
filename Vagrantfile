
Vagrant.configure("2") do |config|
  # --- Configuração geral (todas as VMs) ---
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

  # Gatilho: para o DHCP do VirtualBox ANTES de o guest configurar a rede privada.
  # (precisa ser em WaitForCommunicator; em ":up" o VirtualBox recria o servidor)
  config.trigger.before :"Vagrant::Action::Builtin::WaitForCommunicator", type: :action do |t|
    t.warn = "Interrompe o servidor DHCP do VirtualBox"
    t.run = { inline: "vboxmanage dhcpserver stop --interface vboxnet0" }
    t.on_error = :continue
  end

  # --- Provisionamento Ansible ---
  # Declarado no nível global: roda em CADA VM, limitado a ela mesma.
  # O Vagrant gera o inventário sozinho (hosts: arq, db, app, cli) usando o
  # SSH via NAT, sem depender de DNS no hospedeiro.
  config.vm.provision "ansible" do |ansible|
    ansible.compatibility_mode = "2.0"
    ansible.playbook = "ansible/playbook.yml"
    ansible.config_file = "ansible/ansible.cfg"
  end

  # --- SERVIDOR DE ARQUIVOS (arq) --- precisa ser o primeiro (DHCP/DNS/NFS)
  config.vm.define "arq" do |arq|
    arq.vm.hostname = "arq.francisco.kalel.devops"
    arq.vm.network "private_network", ip: "192.168.56.178"
    arq.vm.disk :disk, size: "10GB", name: "disk1"
    arq.vm.disk :disk, size: "10GB", name: "disk2"
    arq.vm.disk :disk, size: "10GB", name: "disk3"
  end

  # --- SERVIDOR DE BANCO DE DADOS (db) ---
  config.vm.define "db" do |db|
    db.vm.hostname = "db.francisco.kalel.devops"
    db.vm.network "private_network", type: "dhcp", mac: "080027111111"
  end

  # --- SERVIDOR DE APLICAÇÃO (app) ---
  config.vm.define "app" do |app|
    app.vm.hostname = "app.francisco.kalel.devops"
    app.vm.network "private_network", type: "dhcp", mac: "080027222222"
  end

  # --- HOST CLIENTE (cli) ---
  config.vm.define "cli" do |cli|
    cli.vm.hostname = "cli.francisco.kalel.devops"
    cli.vm.network "private_network", type: "dhcp"
    cli.vm.provider :virtualbox do |v|
      v.memory = 1024
    end
  end
end
