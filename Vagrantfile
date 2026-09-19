Vagrant.configure("2") do |config|

  config.vm.box = "ubuntu/jammy64"

  config.vm.define "ubuntu01" do |vm|
    vm.vm.hostname = "ubuntu01"

    vm.vm.network "private_network",
      ip: "192.168.56.11"

    vm.vm.provider "virtualbox" do |vb|
      vb.name = "vagrant-ubuntu01"
      vb.memory = 2048
      vb.cpus = 2
    end
  end

  config.vm.define "ubuntu02" do |vm|
    vm.vm.hostname = "ubuntu02"

    vm.vm.network "private_network",
      ip: "192.168.56.12"

    vm.vm.provider "virtualbox" do |vb|
      vb.name = "vagrant-ubuntu02"
      vb.memory = 2048
      vb.cpus = 2
    end
  end

end
