# Install the host networking setup and qvm helpers
#
# Host network (as root): NetworkManager bridge profile, dnsmasq and NAT systemd units.
#   sudo make install
#   sudo make uninstall
#
# Helper scripts into ~/.local/bin, user unit qvm-machine@.service into ~/.local/share/systemd/user.
#   make install-helpers
#   make uninstall-helpers
#
# With DESTDIR set, files are only copied, and no services enabled.

SHELL := /usr/bin/bash

DESTDIR ?=
sysconfdir ?= /etc/opt/qvm
unitdir ?= $(sysconfdir)/systemd
nmconndir ?= /etc/NetworkManager/system-connections
qemu_bridge_conf ?= /etc/qemu/bridge.conf
# qvm-machine@.service runs %h/.local/bin/qvm-run: keep in sync
userbindir ?= $(HOME)/.local/bin
userunitdir ?= $(HOME)/.local/share/systemd/user

INSTALL ?= install
INSTALL_PROGRAM ?= $(INSTALL) -m 0755
INSTALL_DATA ?= $(INSTALL) -m 0644

PROGRAMS := qvm-create qvm-localds qvm-run
LIBS := libqvm.sh
CONFIG_FILES := dnsmasq.conf qvm0.nft
UNITS := qvm-dns.service qvm-nat.service
USER_UNITS := qvm-machine@.service

.PHONY: install install-files install-config install-units install-bridge post-install uninstall \
	install-helpers uninstall-helpers

install: install-files $(if $(DESTDIR),,post-install)

install-files: install-config install-units install-bridge

install-config:
	$(INSTALL) -d $(DESTDIR)$(sysconfdir)
	$(INSTALL_DATA) $(addprefix config/,$(CONFIG_FILES)) $(DESTDIR)$(sysconfdir)

install-units:
	$(INSTALL) -d $(DESTDIR)$(unitdir)
	$(INSTALL_DATA) $(addprefix systemd/,$(UNITS)) $(DESTDIR)$(unitdir)

# NetworkManager ignores keyfiles readable by others
install-bridge:
	$(INSTALL) -D -m 0600 config/qvm0.nmconnection $(DESTDIR)$(nmconndir)/qvm0.nmconnection

post-install:
# Let qemu-bridge-helper plug unprivileged VMs into qvm0
	grep -qsx 'allow qvm0' $(qemu_bridge_conf) || echo 'allow qvm0' >>$(qemu_bridge_conf)
	systemctl --quiet enable $(addprefix $(unitdir)/,$(UNITS))
	nmcli connection reload
	@echo "Start the network: nmcli connection up qvm0"
	@echo "Install the helper scripts, without sudo: make install-helpers"

uninstall:
	$(if $(DESTDIR),,-nmcli connection down qvm0)
	$(if $(DESTDIR),,-systemctl disable --now $(UNITS))
	$(RM) $(addprefix $(DESTDIR)$(unitdir)/,$(UNITS))
	$(RM) $(addprefix $(DESTDIR)$(sysconfdir)/,$(CONFIG_FILES))
	$(RM) $(DESTDIR)$(nmconndir)/qvm0.nmconnection
	$(if $(DESTDIR),,-nmcli connection reload)
	$(if $(DESTDIR),,sed -i '/^allow qvm0$$/d' $(qemu_bridge_conf))
	-rmdir $(DESTDIR)$(unitdir) $(DESTDIR)$(sysconfdir)

install-helpers:
	$(if $(DESTDIR),,@test "$$(id -u)" != 0 || { echo "$@: run without sudo" >&2; exit 1; })
	$(INSTALL) -d $(DESTDIR)$(userbindir)
	$(INSTALL_PROGRAM) $(addprefix scripts/,$(PROGRAMS)) $(DESTDIR)$(userbindir)
	$(INSTALL_DATA) $(addprefix scripts/,$(LIBS)) $(DESTDIR)$(userbindir)
	$(INSTALL) -d $(DESTDIR)$(userunitdir)
	$(INSTALL_DATA) $(addprefix systemd/,$(USER_UNITS)) $(DESTDIR)$(userunitdir)
	$(if $(DESTDIR),,systemctl --user daemon-reload)

uninstall-helpers:
	$(RM) $(addprefix $(DESTDIR)$(userbindir)/,$(PROGRAMS) $(LIBS))
	$(RM) $(addprefix $(DESTDIR)$(userunitdir)/,$(USER_UNITS))
	$(if $(DESTDIR),,systemctl --user daemon-reload)
