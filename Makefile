SHELL := /bin/env bash
PREFIX := /opt/qvm
BIN_DIR := $(PREFIX)/bin
CONFIG_DIR := /etc/opt/qvm
INSTALL_DIRS := $(BIN_DIR) $(CONFIG_DIR)

SCRIPTS := qvm-run qvm-bridge qvm-create qvm-localds libqvm.sh
CONFIG_FILES := dnsmasq.conf qvm0.nft

install: | $(INSTALL_DIRS)
install: install-bin install-config

install-bin: $(addprefix $(BIN_DIR)/,$(SCRIPTS))

install-config: $(addprefix $(CONFIG_DIR)/,$(CONFIG_FILES))

uninstall:
	rm $(BIN_DIR)/*

$(INSTALL_DIRS):%:
	mkdir -p $@

$(BIN_DIR)/%: scripts/%
	install $^ $(BIN_DIR)

$(CONFIG_DIR)/%: config/%
	cp $^ $@
