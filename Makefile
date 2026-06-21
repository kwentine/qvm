SHELL := /usr/bin/bash

DESTDIR ?=
PREFIX := /opt/qvm

BIN_DIR := $(PREFIX)/bin
CONFIG_DIR := /etc/opt/qvm
CONFIG_USER_DIR := $(HOME)/.config/qvm
UNIT_DIR := $(CONFIG_DIR)/systemd
UNIT_USER_DIR := $(CONFIG_USER_DIR)/systemd

INSTALL_DIRS := $(BIN_DIR) $(CONFIG_DIR) $(UNIT_DIR) $(UNIT_USER_DIR)

SCRIPTS := qvm-run qvm-bridge qvm-create qvm-localds libqvm.sh
CONFIG_FILES := dnsmasq.conf qvm0.nft
UNIT_FILES := $(notdir $(wildcard systemd/*))

.PHONY: install install-bin install-config install-units uninstall-units

install: install-bin install-config

install-bin: $(addprefix $(BIN_DIR)/,$(SCRIPTS))

install-config: $(addprefix $(CONFIG_DIR)/,$(CONFIG_FILES))

install-units: $(UNIT_FILES:%=$(DESTDIR)$(UNIT_DIR)/%)

$(DESTDIR)$(UNIT_DIR)/%: systemd/%
	install -m 0644 -D $^ $@
	$(if $(DESTDIR),,systemctl enable $@)

uninstall-units:
	$(RM) $(addprefix $(DESTDIR)$(UNIT_DIR)/,$(UNIT_FILES))
	$(if $(DESTDIR),,systemctl disable $(UNIT_FILES))

$(BIN_DIR)/%: scripts/%
	install $^ $(BIN_DIR)

$(CONFIG_DIR)/%: config/%
	cp $^ $@
