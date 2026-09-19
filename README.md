# Vagrant Ubuntu Lab

A local Vagrant-based DevOps lab for running Ubuntu virtual machines on macOS.

This repository is also my personal reference for learning and revisiting Vagrant commands, VM lifecycle management, networking, provisioning, and infrastructure automation.

---

## Table of contents

1. [What this lab is (and isn't)](#what-this-lab-is-and-isnt)
2. [Lab architecture](#lab-architecture)
3. [Prerequisites — install on macOS](#prerequisites--install-on-macos)
4. [First-time setup](#first-time-setup)
5. [Connecting to the VMs](#connecting-to-the-vms)
6. [Day-to-day VM lifecycle](#day-to-day-vm-lifecycle)
7. [Checking Vagrant environments](#checking-vagrant-environments)
8. [Vagrant boxes](#vagrant-boxes)
9. [Provisioning](#provisioning)
10. [Useful commands quick reference](#useful-commands-quick-reference)
11. [Important Vagrant concepts](#important-vagrant-concepts)
12. [Troubleshooting](#troubleshooting)
13. [Repository structure](#repository-structure)
14. [Learning roadmap](#learning-roadmap)
15. [Useful references](#useful-references)
16. [Git workflow](#git-workflow)
17. [Goal](#goal)

---

## What this lab is (and isn't)

**It is:**
- Two throw-away Ubuntu 24.04 VMs on your Mac.
- A safe sandbox to break things and rebuild from a single file.
- The first step of a multi-phase DevOps journey (Linux → Ansible → Docker → Kubernetes → GitOps → Observability).

**It is not:**
- A production setup.
- A high-performance cluster (CPU/RAM are limited by your Mac).
- A replacement for cloud labs — it is the *pre-cloud* layer where you build muscle memory.

> 🧠 **Mental model:** the `Vagrantfile` is the source of truth; the VMs are just the rendered output. If reality drifts from the file, run `vagrant up` again (or destroy + up).

---

## Lab architecture

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
              Private Network (192.168.56.0/24, VirtualBox host-only)
```

### VM details

| VM       | Hostname | IP Address    | CPU | Memory |
| -------- | -------- | ------------- | --: | -----: |
| ubuntu01 | ubuntu01 | 192.168.56.11 |   2 |   2 GB |
| ubuntu02 | ubuntu02 | 192.168.56.12 |   2 |   2 GB |

Both VMs are reachable from each other over the private network and from the host Mac. They are **not** reachable from the public internet (which is what you want for a lab).

---

## Prerequisites — install on macOS

You need three things installed on your Mac:

1. **Homebrew** (the macOS package manager) — <https://brew.sh>
2. **Vagrant** — manages VM lifecycle.
3. **VirtualBox** — the actual hypervisor that runs the VMs.

### Install Homebrew (skip if already installed)

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### Install Vagrant

```bash
brew install --cask vagrant
```

Verify:

```bash
vagrant --version
# Expected: Vagrant 2.4.x
```

### Install VirtualBox

```bash
brew install --cask virtualbox
```

> ⚠️ During install, macOS may ask you to allow a kernel extension in *System Settings → Privacy & Security*. Approve it and reboot if prompted. VirtualBox will not start VMs until that is granted.

Verify VirtualBox is usable from Vagrant:

```bash
vagrant status
```

If you see a provider error, open VirtualBox.app once to finish the macOS permission setup.

### (Optional) Recommended plugins

```bash
vagrant plugin install vagrant-vbguest   # keeps VirtualBox Guest Additions in sync with the box
vagrant plugin install vagrant-disksize  # lets you resize VM disks from the Vagrantfile
```

---

## First-time setup

Run these commands in your Mac terminal, one by one.

### 1. Clone the repository

```bash
git clone <repository-url>
cd vagrant-lab
```

### 2. Validate the Vagrantfile

Catches typos before any VM is created:

```bash
vagrant validate
```

Expected output:

```text
Vagrantfile validated successfully.
```

### 3. Create and start the VMs

```bash
vagrant up
```

The first run downloads the `bento/ubuntu-24.04` box (a few hundred MB), creates both VMs in VirtualBox, and configures networking. Subsequent `vagrant up` calls are nearly instant.

### 4. Confirm both VMs are running

```bash
vagrant status
```

Expected:

```text
ubuntu01    running
ubuntu02    running
```

---

## Connecting to the VMs

```bash
vagrant ssh ubuntu01    # open a shell inside the first VM
hostname                 # should print 'ubuntu01'
ip -4 addr show          # confirm 192.168.56.11
exit                     # leave the VM
```

Same for `ubuntu02`. You can `vagrant ssh ubuntu01` from any terminal at any time as long as the VM is `running`.

> 📁 Anything you put in this project folder on your Mac shows up at `/vagrant` inside the VM. Use it as your shared scratch space.

---

## Day-to-day VM lifecycle

The commands below are the ones you will use over and over. See [`docs/vagrant-commands.md`](docs/vagrant-commands.md) for the full reference with explanations.

### Start

```bash
vagrant up                  # start all VMs
vagrant up ubuntu01         # start a single VM
```

### Stop (graceful)

```bash
vagrant halt                # shut down all VMs
vagrant halt ubuntu01       # shut down one VM
```

### Restart (apply Vagrantfile changes)

```bash
vagrant reload              # restart all VMs and re-apply config
vagrant reload ubuntu01     # restart one VM
```

### Suspend / resume (laptop-friendly)

```bash
vagrant suspend ubuntu01
vagrant resume ubuntu01
```

### Destroy (delete the VM)

```bash
vagrant destroy ubuntu01    # ask first
vagrant destroy -f          # skip the confirmation
```

> 🧨 `vagrant destroy` permanently removes the VM. Any data stored only inside the VM is lost. Keep important work in `/vagrant` (which is synced to your Mac) or in a synced folder.

---

## Checking Vagrant environments

```bash
vagrant status                  # VMs in this project
vagrant global-status           # every Vagrant VM on this Mac
vagrant global-status --prune   # clean up stale entries
```

---

## Vagrant boxes

A *box* is a reusable base image — think "clean-install ISO". This lab uses `bento/ubuntu-24.04`.

```bash
vagrant box list                          # boxes cached on this Mac
vagrant box add bento/ubuntu-24.04        # manual download (usually automatic)
vagrant box remove bento/ubuntu-24.04     # free disk space (does NOT destroy VMs)
vagrant box outdated                      # check for newer versions
vagrant box update --box bento/ubuntu-24.04
```

> 📦 Removing a box only frees disk space; running VMs are unaffected. To pick up a new box version, `vagrant destroy && vagrant up`.

---

## Provisioning

Provisioning = installing software inside the VM automatically.

```bash
vagrant provision ubuntu01              # run the provisioner on a running VM
vagrant up --provision ubuntu01         # start + provision
vagrant reload --provision ubuntu01     # restart + provision
```

The first `vagrant up` after editing the `Vagrantfile`'s provisioning block usually means: `vagrant up --provision` (or `vagrant reload --provision` if you also changed provider/network settings).

---

## Useful commands quick reference

```bash
vagrant --version            # Vagrant client version
vagrant validate             # syntax check
vagrant status               # health check
vagrant ssh ubuntu01         # shell in
vagrant ssh-config ubuntu01  # print SSH details (useful for VS Code Remote SSH)
vagrant help <command>       # built-in help, e.g. `vagrant help up`
```

---

## Important Vagrant concepts

### Vagrantfile

The `Vagrantfile` is the **definition of your infrastructure**. It describes:
- Base OS image (the *box*)
- VM names and hostnames
- CPU and memory
- Networking
- Provisioning scripts
- Provider configuration

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

The same `Vagrantfile` can recreate the infrastructure on any machine.

### Vagrant box

A box is a reusable base image used to create Vagrant VMs. Example: `bento/ubuntu-24.04`.

```text
Ubuntu Box
    |
    +----> ubuntu01
    |
    +----> ubuntu02
```

### Provider

Vagrant manages the VM lifecycle, but a separate virtualization platform actually runs the VM. Examples: VirtualBox, VMware, Hyper-V, Parallels.

This lab uses **VirtualBox** (the default for Vagrant on macOS Intel and on Apple Silicon via the VirtualBox 7.x builds). Confirm with:

```bash
vagrant status
```

### Provisioner

A provisioner is the automation that runs *inside* the VM after it boots — typically a shell script, Ansible playbook, or similar — to install packages, create users, or write config files.

---

## Troubleshooting

When something breaks, work top-down:

1. **Status check** — `vagrant status` (per project), then `vagrant global-status --prune`.
2. **Validate** — `vagrant validate`.
3. **Logs** — re-run with `vagrant up --debug 2>&1 | tee up.log` and read the last 50 lines.
4. **Recreate** — `vagrant destroy -f ubuntu01 && vagrant up ubuntu01`.
5. **Nuke everything** — `vagrant destroy -f && vagrant up`.

Common macOS-specific issues:
- **"Provider 'virtualbox' could not be found"** → install/reinstall VirtualBox from <https://www.virtualbox.org/wiki/Downloads> and allow its kernel extension in *System Settings → Privacy & Security*.
- **"VT-x is not available"** → another hypervisor is holding the CPU (Docker Desktop, Parallels, etc.). Quit it or enable nested virtualization.
- **Stale `global-status` entries** → run `vagrant global-status --prune`.
- **Guest Additions mismatch after a VirtualBox upgrade** → `vagrant plugin install vagrant-vbguest && vagrant up ubuntu01`.

---

## Repository structure

```text
vagrant-lab/
├── Vagrantfile                          # the source of truth for the lab
├── README.md                            # this file — lab overview
│
├── docs/
│   └── vagrant-commands.md              # full command reference
│
└── scripts/
    └── (provisioning scripts go here)
```

> ℹ️ The earlier version of this README referenced `networking.md`, `provisioning.md`, and `troubleshooting.md` inside `docs/`. Those files do not exist yet — start here, then add them as you learn.

---

## Learning roadmap

This lab will gradually evolve into a complete local DevOps environment.

### Phase 1 — Vagrant
- [x] Install Vagrant
- [ ] Understand Vagrantfile
- [x] Create Ubuntu VMs
- [x] VM lifecycle management
- [ ] Vagrant networking
- [ ] Vagrant provisioning

### Phase 2 — Linux
- [ ] Linux administration
- [ ] SSH
- [ ] Users and permissions
- [ ] Processes
- [ ] Systemd
- [ ] Networking
- [ ] Storage

### Phase 3 — Ansible
- [ ] Install Ansible
- [ ] Configure inventory
- [ ] Create playbooks
- [ ] Create roles
- [ ] Implement idempotent configuration

### Phase 4 — Docker
- [ ] Install Docker automatically
- [ ] Build images
- [ ] Run containers
- [ ] Docker networking
- [ ] Docker volumes

### Phase 5 — Kubernetes
- [ ] Build a local Kubernetes cluster
- [ ] Deploy applications
- [ ] Services
- [ ] Ingress
- [ ] Helm

### Phase 6 — GitOps
- [ ] ArgoCD
- [ ] Application deployment
- [ ] Sync
- [ ] Rollback

### Phase 7 — Observability
- [ ] Prometheus
- [ ] Grafana
- [ ] Metrics
- [ ] Logs
- [ ] Alerts

---

## Useful references

- Command reference: [`docs/vagrant-commands.md`](docs/vagrant-commands.md)
- Official Vagrant docs: <https://developer.hashicorp.com/vagrant/docs>
- VirtualBox manual: <https://www.virtualbox.org/manual/>
- Homebrew: <https://brew.sh>

---

## Git workflow

A simple loop you will repeat often:

```bash
git status
git add .
git commit -m "Describe what changed and why"
git push
```

For new features, prefer a branch:

```bash
git checkout -b feat/add-ansible-provisioning
# ...edit files...
git add .
git commit -m "Add Ansible provisioning for ubuntu01"
git push -u origin feat/add-ansible-provisioning
```

Then open a Pull Request on GitHub and merge after review.

---

## Goal

The goal of this repository is not only to run two VMs.

It is to maintain a **reusable local infrastructure lab** where I can safely experiment with:
- Linux
- Networking
- Infrastructure as Code
- Configuration Management
- Docker
- Kubernetes
- CI/CD
- GitOps
- Monitoring
- Automation

The infrastructure should be reproducible and disposable.

> **If something breaks, destroy it and rebuild it.**
