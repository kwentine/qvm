# Adjust depending on your setup
repo_root=$(git rev-parse --show-toplevel)
qvm_dir=var/vms
# Toolbox container
if [[ -f /run/.containerenv ]] && [[ -d /run/host ]]; then
  root_dir=/run/host
fi
export QVM_DIR="${root_dir:-}/${qvm_dir}"
PATH="$(pwd)/scripts:${PATH}"
export PATH
export KUBECONFIG="${repo_root}/k8s/admin.kubeconfig:${repo_root}/rke2/kubeconfig.yaml"
