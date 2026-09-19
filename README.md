# Vagrant Ubuntu Lab

A local Vagrant-based DevOps lab for running Ubuntu virtual machines on macOS.

This repository is also my personal reference for learning and revisiting Vagrant commands, VM lifecycle management, networking, provisioning, and infrastructure automation.

---

## Lab Architecture

The lab currently contains two Ubuntu virtual machines:

```text
                    macOS
                      |
                   Vagrant
                      |
          +-----------+-----------+
          |                       |
          v                       v
     +-----------+           +-----------+
     | ubuntu01  |           | ubuntu02  |
     +-----------+           +-----------+
     | 2 CPU     |           | 2 CPU     |
     | 2 GB RAM  |           | 2 GB RAM  |
     | .11       |           | .12       |
     +-----------+           +-----------+
          |                       |
          +-----------+-----------+
                      |
              Private Network
```

### VM Details

| VM       | Hostname | IP Address    | CPU | Memory |
| -------- | -------- | ------------- | --: | -----: |
| ubuntu01 | ubuntu01 | 192.168.56.11 |   2 |   2 GB |
| ubuntu02 | ubuntu02 | 192.168.56.12 |   2 |   2 GB |

---

# Prerequisites

The following software should be installed on the Mac:

* Vagrant
* A Vagrant-supported provider

Check Vagrant:

```bash
vagrant --version
```

Example:

```text
Vagrant 2.4.9
```

Check available providers:

```bash
vagrant plugin list
```

Check the provider used by this lab:

```bash
vagrant status
```

---

# Repository Structure

```text
vagrant-lab/
│
├── Vagrantfile
├── README.md
│
├── docs/
│   ├── vagrant-commands.md
│   ├── networking.md
│   ├── provisioning.md
│   └── troubleshooting.md
│
└── scripts/
    └── provision.sh
```

---

# Getting Started

## 1. Clone the repository

```bash
git clone <repository-url>
cd vagrant-lab
```

## 2. Validate the Vagrantfile

Before creating the VMs:

```bash
vagrant validate
```

Expected output:

```text
Vagrantfile validated successfully.
```

## 3. Create and start the VMs

```bash
vagrant up
```

Vagrant will create both Ubuntu VMs.

## 4. Check VM status

```bash
vagrant status
```

Expected:

```text
ubuntu01    running
ubuntu02    running
```

---

# Connecting to the VMs

Connect to the first VM:

```bash
vagrant ssh ubuntu01
```

Check the hostname:

```bash
hostname
```

Expected:

```text
ubuntu01
```

Exit:

```bash
exit
```

Connect to the second VM:

```bash
vagrant ssh ubuntu02
```

---

# VM Lifecycle

## Start

Start all VMs:

```bash
vagrant up
```

Start a specific VM:

```bash
vagrant up ubuntu01
```

---

## Stop

Gracefully shut down all VMs:

```bash
vagrant halt
```

Stop one VM:

```bash
vagrant halt ubuntu01
```

---

## Restart

Restart all VMs:

```bash
vagrant reload
```

Restart one VM:

```bash
vagrant reload ubuntu01
```

---

## Suspend

Suspend a VM:

```bash
vagrant suspend ubuntu01
```

Resume:

```bash
vagrant resume ubuntu01
```

---

## Destroy

Destroy one VM:

```bash
vagrant destroy ubuntu01
```

Destroy all VMs defined by the current Vagrantfile:

```bash
vagrant destroy
```

Force destroy:

```bash
vagrant destroy -f
```

> `vagrant destroy` permanently removes the VM. Any data stored only inside the VM may be lost.

---

# Checking Vagrant Environments

Show the VMs defined in the current project:

```bash
vagrant status
```

Show Vagrant environments across the machine:

```bash
vagrant global-status
```

Remove stale entries from the global status cache:

```bash
vagrant global-status --prune
```

---

# Vagrant Boxes

List installed boxes:

```bash
vagrant box list
```

Add a box:

```bash
vagrant box add ubuntu/jammy64
```

Remove a box:

```bash
vagrant box remove ubuntu/jammy64
```

> A Vagrant box is a reusable base image/template used to create VMs. Removing a box does not destroy VMs that were already created from it.

---

# Provisioning

Provision an existing VM:

```bash
vagrant provision ubuntu01
```

Recreate the VM and run provisioning:

```bash
vagrant reload --provision ubuntu01
```

Create the VM and run provisioning automatically:

```bash
vagrant up
```

---

# Useful Commands

Validate the Vagrantfile:

```bash
vagrant validate
```

Check Vagrant version:

```bash
vagrant --version
```

Check installed boxes:

```bash
vagrant box list
```

Check installed plugins:

```bash
vagrant plugin list
```

Get command help:

```bash
vagrant help
```

Help for a specific command:

```bash
vagrant help up
```

---

# Important Vagrant Concepts

## Vagrantfile

The `Vagrantfile` is the definition of our infrastructure.

It describes things such as:

* Base OS image
* VM names
* Hostnames
* CPU
* Memory
* Networking
* Provisioning
* Provider configuration

The VM itself is disposable.

```text
Vagrantfile
     |
     | vagrant up
     v
   VM created
     |
     | vagrant destroy
     v
   VM removed
```

The infrastructure can then be recreated from the same `Vagrantfile`.

---

## Vagrant Box

A box is a reusable base image used to create Vagrant VMs.

For example:

```text
ubuntu/jammy64
```

Think of it as a VM template.

```text
Ubuntu Box
    |
    +----> ubuntu01
    |
    +----> ubuntu02
```

---

## Provider

Vagrant itself manages the VM lifecycle, but another virtualization platform actually runs the VM.

Examples:

* VMware
* VirtualBox
* Hyper-V
* Parallels

In this lab, the provider should be checked with:

```bash
vagrant status
```

---

# Troubleshooting

## Check VM status

```bash
vagrant status
```

## Check global environments

```bash
vagrant global-status
```

## Remove stale global entries

```bash
vagrant global-status --prune
```

## Check Vagrant configuration

```bash
vagrant validate
```

## Recreate a problematic VM

```bash
vagrant destroy ubuntu01
vagrant up ubuntu01
```

---

# Learning Roadmap

This lab will gradually evolve into a complete local DevOps environment.

### Phase 1 — Vagrant

* [x] Install Vagrant
* [ ] Understand Vagrantfile
* [ ] Create Ubuntu VMs
* [ ] VM lifecycle management
* [ ] Vagrant networking
* [ ] Vagrant provisioning

### Phase 2 — Linux

* [ ] Linux administration
* [ ] SSH
* [ ] Users and permissions
* [ ] Processes
* [ ] Systemd
* [ ] Networking
* [ ] Storage

### Phase 3 — Ansible

* [ ] Install Ansible
* [ ] Configure inventory
* [ ] Create playbooks
* [ ] Create roles
* [ ] Implement idempotent configuration

### Phase 4 — Docker

* [ ] Install Docker automatically
* [ ] Build images
* [ ] Run containers
* [ ] Docker networking
* [ ] Docker volumes

### Phase 5 — Kubernetes

* [ ] Build a local Kubernetes cluster
* [ ] Deploy applications
* [ ] Services
* [ ] Ingress
* [ ] Helm

### Phase 6 — GitOps

* [ ] ArgoCD
* [ ] Application deployment
* [ ] Sync
* [ ] Rollback

### Phase 7 — Observability

* [ ] Prometheus
* [ ] Grafana
* [ ] Metrics
* [ ] Logs
* [ ] Alerts

---

# Useful References

Detailed command documentation:

```text
docs/vagrant-commands.md
```

Networking documentation:

```text
docs/networking.md
```

Provisioning documentation:

```text
docs/provisioning.md
```

Troubleshooting:

```text
docs/troubleshooting.md
```

---

# Git Workflow

After making changes:

```bash
git status
git add .
git commit -m "Add Vagrant Ubuntu lab"
git push
```

---

# Goal

The goal of this repository is not only to run two VMs.

It is to maintain a reusable local infrastructure lab where I can safely experiment with:

* Linux
* Networking
* Infrastructure as Code
* Configuration Management
* Docker
* Kubernetes
* CI/CD
* GitOps
* Monitoring
* Automation

The infrastructure should be reproducible and disposable.

**If something breaks, destroy it and rebuild it.**
