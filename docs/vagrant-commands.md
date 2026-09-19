# Vagrant Command Reference

## Check Version

vagrant --version

## Check VMs

vagrant status

## Global VM Status

vagrant global-status

## Start VMs

vagrant up

vagrant up ubuntu01

## Stop VMs

vagrant halt

vagrant halt ubuntu01

## Restart VMs

vagrant reload

vagrant reload ubuntu01

## SSH

vagrant ssh ubuntu01

vagrant ssh ubuntu02

## Destroy

vagrant destroy ubuntu01

vagrant destroy

vagrant destroy -f

## Validate Vagrantfile

vagrant validate

## Show Vagrant Boxes

vagrant box list

## Download a Box

vagrant box add ubuntu/jammy64

## Remove a Box

vagrant box remove ubuntu/jammy64

## Suspend

vagrant suspend ubuntu01

## Resume

vagrant resume ubuntu01

## Reload Provisioning

vagrant provision ubuntu01