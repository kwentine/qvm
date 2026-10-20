# Install the qvm helpers and the host networking setup.
#
#   sudo make install                 # NetworkManager creates the qvm0 bridge
#   sudo make install BRIDGE=script   # qvm-bridge.service creates it instead
#   sudo make uninstall               # VM disks in $(localstatedir) are kept
#
# Then bring the network up and down with the bridge:
#   nmcli connection up qvm0                  # BRIDGE=nm
#   sudo systemctl start qvm-bridge.service   # BRIDGE=script
# dnsmasq and NAT start and stop with the qvm0 interface.
#
# To switch BRIDGE, uninstall first: both would try to own qvm0.
#
# With DESTDIR set (staged install), files are only copied:
# no groupadd, systemctl, nmcli or edits outside the staging directory.
#
# Note: unit files hard-code the default bindir and sysconfdir.

SHELL := /usr/bin/bash

DESTDIR ?=
prefix ?= /opt/qvm
bindir ?= $(prefix)/bin
sysconfdir ?= /etc/opt/qvm
localstatedir ?= /var/opt/qvm
unitdir ?= $(sysconfdir)/systemd
nmconndir ?= /etc/NetworkManager/system-connections
qemu_bridge_conf ?= /etc/qemu/bridge.conf
sysctldir ?= /etc/sysctl.d

INSTALL ?= install
INSTALL_PROGRAM ?= $(INSTALL) -m 0755
INSTALL_DATA ?= $(INSTALL) -m 0644

# Who creates the qvm0 bridge: nm (NetworkManager) or script (qvm-bridge.service)
BRIDGE ?= nm
# Members of this group can create and run VMs in $(localstatedir)
GROUP ?= qvm

PROGRAMS := qvm-bridge qvm-create qvm-localds qvm-run
LIBS := libqvm.sh
CONFIG_FILES := dnsmasq.conf qvm0.nft
# Enabled: started whenever qvm0 appears
SERVICES := qvm-dns.service qvm-nat.service
# Linked only: started by hand
LINKED :=
ifeq ($(BRIDGE),script)
LINKED += qvm-bridge.service
else ifneq ($(BRIDGE),nm)
$(error BRIDGE must be nm or script, not '$(BRIDGE)')
endif
ALL_UNITS := qvm-bridge.service qvm-dns.service qvm-nat.service
# Installed by earlier versions, removed by uninstall
LEGACY_UNITS := qvm-network.target qvm-machine-r0.service
DATA_DIRS := templates machines localds iso run

.PHONY: install install-files install-bin install-config install-units install-bridge install-data \
	post-install uninstall

install: install-files $(if $(DESTDIR),,post-install)

install-files: install-bin install-config install-units install-bridge install-data

install-bin:
	$(INSTALL) -d $(DESTDIR)$(bindir)
	$(INSTALL_PROGRAM) $(addprefix scripts/,$(PROGRAMS)) $(DESTDIR)$(bindir)
	$(INSTALL_DATA) $(addprefix scripts/,$(LIBS)) $(DESTDIR)$(bindir)

install-config:
	$(INSTALL) -d $(DESTDIR)$(sysconfdir)
	$(INSTALL_DATA) $(addprefix config/,$(CONFIG_FILES)) $(DESTDIR)$(sysconfdir)
	$(INSTALL) -D -m 0644 config/90-qvm.conf $(DESTDIR)$(sysctldir)/90-qvm.conf

install-units:
	$(INSTALL) -d $(DESTDIR)$(unitdir)
	$(INSTALL_DATA) $(addprefix systemd/,$(SERVICES) $(LINKED)) $(DESTDIR)$(unitdir)

install-bridge:
ifeq ($(BRIDGE),nm)
# NetworkManager ignores keyfiles readable by others
	$(INSTALL) -D -m 0600 config/qvm0.nmconnection $(DESTDIR)$(nmconndir)/qvm0.nmconnection
endif

# setgid: new files inherit the group, so all members can use them
install-data:
	$(INSTALL) -d -m 2775 $(addprefix $(DESTDIR)$(localstatedir)/,$(DATA_DIRS))

post-install:
	groupadd --system --force $(GROUP)
	chgrp $(GROUP) $(addprefix $(localstatedir)/,$(DATA_DIRS))
# Let qemu-bridge-helper plug unprivileged VMs into qvm0
	grep -qsx 'allow qvm0' $(qemu_bridge_conf) || echo 'allow qvm0' >>$(qemu_bridge_conf)
# Apply now what systemd-sysctl applies at boot
	sysctl --load=$(sysctldir)/90-qvm.conf
# systemd does not search unitdir: link the units into /etc/systemd/system
	$(if $(LINKED),systemctl link $(addprefix $(unitdir)/,$(LINKED)))
	systemctl enable $(addprefix $(unitdir)/,$(SERVICES))
ifeq ($(BRIDGE),nm)
	nmcli connection reload
	@echo "To start the network: nmcli connection up qvm0"
else
	@echo "Start the network: sudo systemctl start qvm-bridge.service"
endif
	@echo "Add yourself to the $(GROUP) group: sudo usermod -aG $(GROUP) \$$USER (then log in again)"

uninstall:
	$(if $(DESTDIR),,-nmcli connection down qvm0)
	$(if $(DESTDIR),,-systemctl stop $(ALL_UNITS) $(LEGACY_UNITS))
	$(if $(DESTDIR),,for unit in $(ALL_UNITS) $(LEGACY_UNITS); do systemctl disable "$$unit" || true; done)
	$(RM) $(addprefix $(DESTDIR)$(unitdir)/,$(ALL_UNITS) $(LEGACY_UNITS))
	$(RM) $(addprefix $(DESTDIR)$(bindir)/,$(PROGRAMS) $(LIBS))
	$(RM) $(addprefix $(DESTDIR)$(sysconfdir)/,$(CONFIG_FILES))
	$(RM) $(DESTDIR)$(nmconndir)/qvm0.nmconnection
# The running ip_forward value is left alone (see config/90-qvm.conf)
	$(RM) $(DESTDIR)$(sysctldir)/90-qvm.conf
	$(if $(DESTDIR),,-nmcli connection reload)
	$(if $(DESTDIR),,sed -i '/^allow qvm0$$/d' $(qemu_bridge_conf))
	-rmdir $(DESTDIR)$(unitdir) $(DESTDIR)$(sysconfdir) $(DESTDIR)$(bindir)
