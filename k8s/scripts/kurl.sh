#!/usr/bin/env bash
set -eu
REPO_ROOT="$(git rev-parse --show-toplevel)"
API_SERVER="https://cp.qvm0.lan:6443"
CACERT="${QVM_DIR}/certs/k8s/ca.crt"

cert="kwentine.crt"
key="${cert/.crt/.key}"

declare -a args
args=(
  --cert "${cert}"
  --key "${key}"
  --cacert "${CACERT}"
)

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
  curl "${args[@]}" "${API_SERVER}/${path}"
}

pods() {
  kurl api/v1/pods
}

case "${1:-}" in
  whoami | pods) "${1}" ;;
  *)
    echo "ERROR: Invalid action: ${1}"
    exit 1
    ;;
esac
