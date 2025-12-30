#!/usr/bin/env bash
set -eu
REPO_ROOT="$(git rev-parse --show-toplevel)"
SERVER_URL="https://cp.qvm0.lan:6443"
SERVER_CACERT="${QVM_DIR}/certs/k8s/ca.crt"
CLIENT_CERT="${QVM_DIR}/certs/k8s/admin.crt"
CLIENT_KEY="${QVM_DIR}/certs/k8s/admin.key"
KURL_CONTENT_TYPE="application/yaml"

declare -a args
args=(
  --cert "${CLIENT_CERT}"
  --key "${CLIENT_KEY}"
  --cacert "${SERVER_CACERT}"
  --header "Accept: ${KURL_CONTENT_TYPE}"
)

declare -A urls
urls=(
  pods api/v1/pods
  default_pods api/v1/namespaces/default/pods
  apps_deploys apis/apps/v1/deployments
  apps_coredns_deploys apis/apps/v1/namespaces/coredns/deployments
  services_argocd_argocd-server api/v1/namespaces/argocd/services/argocd-server
  apps_whoami_deploys_whoami apis/apps/v1/namespaces/whoami/deployments/whoami
  namespaces api/v1/namespaces
  # TODO: Logs
)

errexit() {
  echo "ERROR: $*" >&2
  exit 1
}

whoami() {
  if [[ -n "${KURL_TOKEN}" ]]; then
    args=(
      --cacert "${CACERT}"
      --json '{"apiVersion": "authentication.k8s.io/v1","kind": "SelfSubjectReview"}'
      -H "Authorization: Bearer ${KURL_TOKEN}"
    )
  else
    args+=(
      --json '{"apiVersion": "authentication.k8s.io/v1","kind": "SelfSubjectReview"}'
    )
  fi
  kurl apis/authentication.k8s.io/v1/selfsubjectreviews
}

kurl() {
  path="${1#/}"
  if [[ "${path:0:1}" == @ ]]; then
    path="${urls[${path:1}]:-}"
    [[ -n "${path:-}" ]] || errexit "kurl: invalid URL alias: ${1}"
  fi
  curl -s "${args[@]}" "${SERVER_URL}/${path}"
}

pods() {
  kurl api/v1/pods
}

case "${1:-}" in
  whoami | pods)
    "${1}"
    ;;
  api* | @*)
    kurl "${1}"
    ;;
  *)
    errexit "Invalid command: ${1}"
    ;;
esac
