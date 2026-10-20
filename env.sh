# Source from the repository root to run the helpers from this checkout
# instead of the installed copies in /opt/qvm/bin.
PATH="$(pwd)/scripts:${PATH}"
# Defaults, override as needed:
# QVM_DATA_DIR=/var/opt/qvm          # disks, base images, cloud-init seeds
# QVM_CONFIG_DIR=~/.config/qvm       # machines/VM, user-data/VM.yaml
export PATH
