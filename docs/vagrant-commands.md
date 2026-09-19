# Vagrant Command Reference

> A friendly, macOS-focused command sheet for this lab. Read it top-to-bottom on day one; afterwards use it as a quick lookup.

> **Convention used below**
> - `ubuntu01` / `ubuntu02` are the names defined in the `Vagrantfile`. Replace them if you rename a VM.
> - Commands assume your current directory is the project root (the folder that contains `Vagrantfile`). Run `pwd` first if you are unsure — you should see `.../vagrant-lab`.
> - Anything in `inline code` is something you actually type (or paste) into your terminal.

---

## 0. The 30-second mental model

```text
Vagrantfile  ──►  vagrant up  ──►  VirtualBox VM(s)
                       │
                       └──►  vagrant ssh ubuntu01  (you land inside the VM)
```

- `Vagrantfile` = your infrastructure as code (declarative).
- `vagrant up` = make reality match the file.
- `vagrant ssh` = open a shell inside the VM.
- `vagrant destroy` = remove the VM(s); the file remains, so you can rebuild anytime.

If a command ever looks scary, remember: **the VM is disposable**. Worst case you destroy and re-`up`.

---

## 1. Sanity checks (run these first)

| Goal | Command | What you should see |
| --- | --- | --- |
| Confirm Vagrant is installed | `vagrant --version` | `Vagrant 2.4.x` (any 2.x is fine) |
| Confirm VirtualBox is installed | `vagrant status` | A list of VMs and their state — proves Vagrant can talk to the provider |
| List installed boxes | `vagrant box list` | `bento/ubuntu-24.04` should appear after your first `vagrant up` |
| List installed plugins | `vagrant plugin list` | Useful when troubleshooting provider issues |
| Validate your `Vagrantfile` syntax | `vagrant validate` | `Vagrantfile validated successfully.` |

> 💡 If `vagrant status` complains about a missing provider, install VirtualBox from <https://www.virtualbox.org/wiki/Downloads> (macOS hosts: download the `.dmg`, double-click, follow the installer). Restart the terminal afterwards.

---

## 2. VM lifecycle

These are the commands you will use 95% of the time. Memorize the names; the flags will come with practice.

### 2.1 Start

```bash
# Start every VM defined in the Vagrantfile
vagrant up

# Start a single VM (faster when iterating on one box)
vagrant up ubuntu01

# Start a single VM and immediately re-run the provisioner
vagrant up ubuntu01 --provision
```

What happens under the hood on a cold start:
1. Vagrant reads the `Vagrantfile`.
2. Downloads the box (only the first time).
3. Asks VirtualBox to create the VM.
4. Boots it, configures networking, mounts the project folder at `/vagrant` inside the VM.
5. Runs any provisioning steps defined in the `Vagrantfile`.

### 2.2 Check status

```bash
vagrant status                  # this project only
vagrant global-status           # every Vagrant VM on this Mac
vagrant global-status --prune   # same, but cleans stale entries (VMs you deleted manually)
```

### 2.3 SSH into a VM

```bash
vagrant ssh ubuntu01
vagrant ssh ubuntu02
```

You will land in the VM's home directory as the `vagrant` user (sudo-capable, password `vagrant`).

Useful things to try once inside:

```bash
hostname                 # should print 'ubuntu01' or 'ubuntu02'
ip -4 addr show          # confirm 192.168.56.11 or .12
ls /vagrant              # this folder is shared with your Mac project
exit                     # leave the VM and return to your Mac terminal
```

> 🔐 `vagrant ssh` works out of the box because Vagrant injects an insecure keypair on first boot. If you ever replace the SSH keys, regenerate them with `vagrant ssh-config` (view only) or recreate the VM.

### 2.4 Graceful stop

```bash
vagrant halt                 # shut down all VMs
vagrant halt ubuntu01        # shut down one VM
```

`halt` is the equivalent of `sudo shutdown -h now` — the VM state is preserved on disk, so a later `vagrant up` is quick.

### 2.5 Restart (apply Vagrantfile changes)

```bash
vagrant reload                # restart all VMs and re-apply network/provider config
vagrant reload ubuntu01       # restart one VM
vagrant reload --provision    # also re-run the provisioner after restart
```

Use `reload` whenever you change `cpus`, `memory`, `private_network`, or any provider setting — those need a restart to take effect.

### 2.6 Suspend / resume (laptop-friendly)

```bash
vagrant suspend ubuntu01      # save RAM, freeze the VM
vagrant resume ubuntu01       # wake it back up
```

Suspend is great when you close your MacBook lid for a while; resume is faster than a full boot.

### 2.7 Destroy (the "delete and rebuild" button)

```bash
vagrant destroy ubuntu01      # ask before deleting one VM
vagrant destroy               # ask before deleting all VMs
vagrant destroy -f            # skip the confirmation prompt
```

`destroy` deletes the VM but **keeps the box** cached on your Mac, so the next `vagrant up` is fast. Any data stored only inside the VM is lost — keep important work in `/vagrant` (synced to your Mac) or in a synced folder you configured.

> 🧨 "If something breaks, destroy it and rebuild it." — that is the Vagrant way.

---

## 3. Boxes (VM templates)

A *box* is the base image (think: clean-install ISO) that Vagrant uses to create VMs. In this lab the box is `bento/ubuntu-24.04` (declared in the `Vagrantfile`).

```bash
vagrant box list                              # show boxes cached on this Mac
vagrant box add bento/ubuntu-24.04            # manually download a box (usually automatic via 'up')
vagrant box remove bento/ubuntu-24.04         # delete a box from cache (does NOT destroy existing VMs)
vagrant box outdated                          # see which boxes have newer versions
vagrant box update --box bento/ubuntu-24.04   # update a specific box (VMs must be recreated to use it)
```

> 📦 Removing a box only frees disk space; running VMs are unaffected. To pick up a new box version, `vagrant destroy && vagrant up`.

---

## 4. Provisioning

Provisioning = installing software inside the VM automatically (packages, users, files, etc.).

```bash
vagrant provision ubuntu01              # run provisioner on an already-running VM
vagrant up --provision ubuntu01         # start the VM (if needed) and provision
vagrant reload --provision ubuntu01     # restart the VM and provision in one step
```

Typical first-time flow after editing a provisioner:

```bash
vagrant provision ubuntu01
# or, if you changed provider/network settings:
vagrant reload --provision ubuntu01
```

---

## 5. Validation and debugging

```bash
vagrant validate                     # check Vagrantfile syntax
vagrant status                       # quick health check
vagrant global-status --prune        # clean stale entries from VMs you deleted manually
vagrant ssh-config ubuntu01          # print SSH connection info (handy for VS Code "Remote SSH")
vagrant version                      # Vagrant client version
vagrant help <command>               # built-in help, e.g. `vagrant help up`
```

Verbose output (for when things go wrong):

```bash
vagrant up --debug                   # wall of logs — pipe to a file: vagrant up --debug 2>&1 | tee up.log
VAGRANT_LOG=debug vagrant up ubuntu01   # alternative: env variable
```

---

## 6. Common day-to-day recipes

### 6.1 First-time setup of this lab

```bash
cd /Users/onikazad/repo/vagrant-lab   # or wherever you cloned it
vagrant validate                       # optional but recommended
vagrant up                             # creates both VMs
vagrant ssh ubuntu01                   # jump into the first box
exit
```

### 6.2 Wipe and rebuild a single VM

```bash
vagrant destroy -f ubuntu01
vagrant up ubuntu01
```

### 6.3 Apply memory/CPU changes from the Vagrantfile

```bash
vagrant reload ubuntu01
```

### 6.4 Hand off SSH access to VS Code or another editor

```bash
vagrant ssh-config ubuntu01 > ~/.ssh/vagrant-ubuntu01.config
# Then in VS Code: "Remote-SSH: Connect to Host" → paste:
# ssh vagrant@127.0.0.1 -p 2222 -i <printed key path>
# (Use the host/port/identityfile lines printed by ssh-config.)
```

### 6.5 Update VirtualBox Guest Additions after a VirtualBox upgrade

```bash
vagrant plugin install vagrant-vbguest
vagrant up ubuntu01                    # vbguest will (re)install matching additions
```

---

## 7. Cheat sheet (one screen)

```bash
vagrant up                              # start
vagrant status                          # health check
vagrant ssh ubuntu01                    # shell in
vagrant halt                            # stop
vagrant reload                          # restart + apply Vagrantfile changes
vagrant suspend / vagrant resume        # freeze / wake
vagrant destroy -f                      # delete VMs (keep box)
vagrant box list                        # cached images
vagrant provision ubuntu01              # re-run provisioner
vagrant validate                        # syntax check
vagrant global-status --prune           # cleanup stale entries
vagrant help <command>                  # built-in docs
```

---

## 8. Where to go next

- `README.md` — the lab overview and learning roadmap.
- Official docs: <https://developer.hashicorp.com/vagrant/docs>
