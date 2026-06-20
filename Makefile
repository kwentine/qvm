SHELL := /bin/env bash
PREFIX := /opt/qvm
BIN_DIR := $(PREFIX)/bin
SRC_DIR := scripts

install: | $(BIN_DIR)
install: install-bin

install-bin: $(addprefix $(BIN_DIR)/,qvm-run qvm-bridge qvm-create qvm-localds libqvm.sh) | $(BIN_DIR)

$(BIN_DIR):
	mkdir -p $@
	sudo chown -R "kwentine:kwentine" $@

$(BIN_DIR)/%: $(SRC_DIR)/%
	install $^ $(BIN_DIR)
