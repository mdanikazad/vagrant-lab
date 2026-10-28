# -*- mode: ruby -*-
# vi: set ft=ruby :

# Shared provisioning steps for every VM in this lab.
#
# The scripts are deliberately self-contained: Vagrant's shell provisioner
# uploads a script to /tmp and executes it there, so a script cannot rely on
# sibling files being present next to it.
DOCKER_PROVISION = [
  {
    "type" => "shell",
    "path" => "scripts/install-docker.sh",
    "privileged" => true
  },
  {
    "type" => "shell",
    "path" => "scripts/install-docker-compose.sh",
    "privileged" => true
  }
].freeze

Vagrant.configure("2") do |config|

  config.vm.box = "bento/ubuntu-24.04"

  config.vm.define "ubuntu01" do |vm|
    vm.vm.hostname = "ubuntu01"

    vm.vm.network "private_network",
      ip: "192.168.56.11"

    vm.vm.provider "virtualbox" do |vb|
      vb.name = "vagrant-ubuntu01"
      vb.memory = 2048
      vb.cpus = 2
    end

    DOCKER_PROVISION.each do |provisioner|
      vm.vm.provision provisioner["type"],
        path: provisioner["path"],
        privileged: provisioner["privileged"]
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

    DOCKER_PROVISION.each do |provisioner|
      vm.vm.provision provisioner["type"],
        path: provisioner["path"],
        privileged: provisioner["privileged"]
    end
  end

end
