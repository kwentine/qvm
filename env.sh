# Adjust depending on your setup
qvm_dir=var/vms
# Toolbox container
if [[ -f /run/.containerenv ]] && [[ -d /run/host ]]; then
  fs_root=/run/host
fi
QVM_DIR="${fs_root:-}/${qvm_dir}"
PATH="$(pwd)/scripts:${PATH}"
KUBECONFIG="${QVM_DIR}/kubeconfigs/admin.yaml:${QVM_DIR}/rke2.yaml"
export PATH QVM_DIR KUBECONFIG
