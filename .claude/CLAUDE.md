# QVM

I started the QVM project with two objectives:
1. Educational: learn to run networked QEMU virtual machines on my Fedora linux host
2. Practical: conveniently spin up local Kubernetes clusters that I can use for experiments and debugging

Think of it as a very targeted and simple virt-manager.

## Initial design

The general design ideas are outlined below.

### Networking:
- A Linux bridge on the host is used as a shared L2 network for the VMS.
- `dnsmasq` running on the host assigns host names and IPs to VMs as they appear
- Firewall rules on the host allow traffic originating on the bridge to reach internet

### Virtual machines
- Virtual machine disks (`.qcow2`) are stored in a filesystem directory on the host
- Virtual machine disks derive from "base" `.qcow2` official images
- cloud-init local datasources customize VMs on first boot

### Helper scripts
A set of bash scripts act as helpers to setup the various components.
As the current README documents, I started by invoking them by hand separately.
Now I am moving towards integrating them with `systemd`

- `qvm-bridge` sets up the VM network bridge `qvm0` with a hard-coded IP subnet
- `qvm-create` creates VM disk images from official base images stored on disk
- `qvm-localds` build cloud-init local datasources
- `qvm-run` starts a VM by invoking qemu

### RHEL-specific considerations
To have RHEL systems close to the machines I maintain at work, without needing to bother with system registration,
RHEL packages are mounted as CDs in the VMs.

### Configuration
A VM is uniquely identified by its name, for example `workbox`.
The idea was then to store vm configurations in `~/.config/qvm`
- Cloud init configuration in `.config/user-data/workbox.yaml`
- Extra qemu parameters `.config/qvm/machines/workbox`
- SSH keys to access vms in `.config/qvm/ssh`

### System installation
This is the part I was least comfortable with: install the `qvm` tool suite on my host,
following standard filesystem conventions, and `systemd` to manage vms

Roughly, my thoughts were:
| Kind                                        | Location                                     |
| Executables                                 | /opt/qvm/bin                                 |
| Configuration files                         | /etc/opt/qvm                                 |
| Unit files                                  | /etc/systemd/system via /etc/opt/qvm/systemd |



Typical imagined workflow:
```
# Enable all the networkin prerequisites
# Create the bridge, install the firewall rules, start dnsmasq and configure DNS resolution
# Those are privileged operations, so a system service seems to make sense
sudo systemctl start qvm-network.service

# Start a particular VM
systemctl --user start qvm-machine-workbox.service

# Start a cluster, which is a group of VMs
systemctl --user start qvm-cluster-k8s.service

# ssh into a vm conveniently
ssh workbox
```

The installation should be performed from a Makefile.
`make install` installs the tools and the systemd system services

Then the user (myself essentially) edits configuration files,
including unit files, in `.config/qvm/{systemd,machines,user-data}`.

I thought VM disks could live in a system installation directory, `/var/opt/qvm`.
And host configuration (firewall, resolver configuration, dnsmasq configuration) in `/etc/opt/qvm`
I thought a good precaution would by to install `systemd` unit files there, and install them on the system using `systemctl`

I want the Makefile to be idiomatic, and respect established practices.



## Improvement ideas

- re-write the helpers in Python for easier maintenance.
  this can include simplifying removing legacy options that I no longer use
  optionally, if desirable, make it available as a python package that can be `uv` installed

- Polish the project documentation for proper open source publication, and facilitate re-use
  It should keep its educational flavor

- A drop-in ssh configuration mechanism would be nice. Currently, I have edited my `.ssh/config`
```
Host 10.42.0.* *.qvm0.lan *.qvm0 jmp cp wk1 wk2 r0 r1 r2
     StrictHostKeyChecking no
     UserKnownHostsFile /dev/null
     IdentityFile ~/.config/qvm/ssh/id_ed25519
     User root
     LogLevel QUIET
```
but I would prefer all the qvm-related SSH config and keys to live in `.config/qvm/ssh`

- Use a configuration-file approach for the `resolvectl` commands currently included in `qvm-dns.service`

When this basic setup is in place, some features could be added:
- Support multiple separate bridges
- integrate `bootc` in the picture,
  so that I can learn this technology and build my VM images from Dockerfiles
- add mechanisms to mount host directories (and later even devices) in the VMs
- have an example of how to install RKE2 on a freshly spun up cluster using pyinfra
- support alternatives to cloud-init such as
- automate the generation of the `qvm-machine-@.service` units
- add a readiness probe" on VM startup that checks that `sshd` is up
