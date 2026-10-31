# QVM

I started the QVM project with two objectives:
1. Educational: learn to run networked QEMU virtual machines on my Fedora linux host
2. Practical: conveniently spin up local Kubernetes clusters that I can use for experiments and debugging

Think of it as a very targeted and simple virt-manager.
The documentation should keep its educational flavor: explain each layer, show the plain commands.

## Design

### Network (host side, root)
- The `qvm0` bridge (`10.42.0.1/24`) is a shared L2 network for the VMs.
  It is defined in a NetworkManager keyfile, `config/qvm0.nmconnection`, not brought up at boot:
  `nmcli connection up qvm0` / `down`.
  The manual way (`ip`, `resolvectl`), for hosts without NetworkManager, is documented in `docs/net.org`.
- `dnsmasq` (`config/dnsmasq.conf`) assigns IPs to VMs and registers their host names in `qvm0.lan`.
- NAT lives in its own nftables table, `inet qvm0` (`config/qvm0.nft`).
  `qvm-nat.service` loads it and turns on IPv4 forwarding (never off, like Docker or libvirt).
- `qvm-dns.service` and `qvm-nat.service` follow the bridge: wanted by and bound to
  `sys-subsystem-net-devices-qvm0.device`.

### Virtual machines (user side, unprivileged)
- Helper scripts: `qvm-create` (qcow2 overlay of a base image), `qvm-localds` (cloud-init NoCloud seed),
  `qvm-run` (starts qemu; MAC derived from the VM name).
  `qvm-run` is a single-file Python script (stdlib only, Python >= 3.11 for `tomllib`, lint: `ruff`);
  the others are still bash, sharing `libqvm.sh`.
- Data in `QVM_DATA_DIR` (default `~/.local/share/qvm`): `templates/`, `machines/`, `localds/VM/`, `iso/`.
  Pid files (`qvm-run -d`) in `QVM_RUNTIME_DIR` (default `$XDG_RUNTIME_DIR/qvm`).
  The seed directory is attached as a VFAT disk by QEMU's `vvfat` driver: no image, no root.
- Configuration in `QVM_CONFIG_DIR` (default `~/.config/qvm`):
  `user-data/VM.yaml`, `machines/VM.toml` (see `config/machine.example.toml`), `ssh/`.
  `[qvm]` (schema: the `Machine` dataclass in `qvm-run`, which also generates the command line options)
  and `[qemu]` (QEMU options passed as they are; a list repeats an option, `true` is a flag;
  it wins over `[qvm]` and the command line).
- VMs join the bridge through the setuid `qemu-bridge-helper` (`allow qvm0` in `/etc/qemu/bridge.conf`).

### RHEL-specific considerations
To have RHEL systems close to the machines I maintain at work, without needing to bother with system registration,
RHEL packages are mounted as CDs in the VMs (see `config/user-data/rhel.example.yaml`).

### Installation
The Makefile should be idiomatic and respect established practices (no `sudo` inside recipes, `DESTDIR` support).
- `sudo make install`: host network. Configuration in `/etc/opt/qvm`, unit files in `/etc/opt/qvm/systemd`,
  enabled with `systemctl` (which links them into `/etc/systemd/system`).
- `make install-helpers`: helper scripts in `~/.local/bin`.

### My host
Fedora Atomic (Sericea): `/opt` is a symlink to `/var/opt`, extra packages (qemu) are layered with `rpm-ostree`.

## Roadmap
See `.claude/PLAN.org` for details.

- Re-write the helpers in Python for easier maintenance, installable with `uv`;
  TOML machine configuration (including `mac`), dropping legacy options I no longer use.
- Manage VMs with `systemd --user`:
  a `qvm-machine@.service` template unit, cluster targets, graceful shutdown (QMP),
  and a readiness probe on VM startup that checks that `sshd` is up.
  Typical workflow:
  ```
  nmcli connection up qvm0
  systemctl --user start qvm-machine@workbox.service
  systemctl --user start k8s.target      # a group of VMs
  ssh workbox
  ```
- A drop-in SSH configuration: all qvm-related SSH config and keys in `~/.config/qvm/ssh`,
  included from `~/.ssh/config`, instead of my hand-edited block:
  ```
  Host 10.42.0.* *.qvm0.lan *.qvm0 jmp cp wk1 wk2 r0 r1 r2
       StrictHostKeyChecking no
       UserKnownHostsFile /dev/null
       IdentityFile ~/.config/qvm/ssh/id_ed25519
       User root
       LogLevel QUIET
  ```
- Polish the documentation for open source publication, and facilitate re-use.

Later features:
- Support multiple separate bridges
- Integrate `bootc`, to learn this technology and build my VM images from Containerfiles
- Mount host directories (and later even devices) in the VMs
- An example of how to install RKE2 on a freshly spun up cluster using pyinfra
- Support alternatives to cloud-init (e.g. Ignition)
