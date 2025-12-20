export KUBECONFIG=/etc/rancher/rke2/rke2.yaml
export PATH=/var/lib/rancher/rke2/bin:/var/lib/rancher/rke2/bin:/root/.local/bin:/root/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin
export CRI_CONFIG_FILE=/var/lib/rancher/rke2/agent/etc/crictl.yaml
# shellcheck disable=SC1090
source <(kubectl completion bash)

etcdctl() {
  local etcd_id
  etcd_id=$(crictl ps --label io.kubernetes.container.name=etcd -q)
  local tls_dir=/var/lib/rancher/rke2/server/tls/etcd
  flags=(
    --endpoints=https://127.0.0.1:2379
    --cacert="${tls_dir}"/server-ca.crt
    --cert="${tls_dir}"/server-client.crt
    --key="${tls_dir}"/server-client.key
  )
  crictl exec "${etcd_id}" etcdctl "${flags[@]}" "$@"
}

# Wipe etcd database
clear_db() {
  rm -rf /var/lib/rancher/rke2/server/db
  rm -rf /var/lib/rancher/rke2/server/tls
  rm -rf /var/lib/rancher/rke2/server/cred
}
