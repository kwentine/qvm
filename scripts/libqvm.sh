# shellcheck shell=bash
# Sourced by the qvm-* helpers.
declare -i dry_run=0

usage() {
  local ret=0
  [[ "${1:-}" == -h ]] || {
    ret=1
    exec >&2
  }
  sed -n "/^#+/{s/^#+ \?//; s/SCRIPT/${SCRIPT}/; p}" "$0"
  exit "${ret}"
}

info() {
  echo "INFO: $*" >&2
}

errexit() {
  echo "ERROR: $*" >&2
  exit 1
}

run() {
  ((dry_run)) && {
    echo "$@" >&2
    return
  }
  "$@"
}

: "${QVM_DATA_DIR:=/var/opt/qvm}"
# Per-user configuration (machines, user-data).
# HOME may be unset in system services (qvm-bridge.service), which do not use it.
: "${QVM_CONFIG_DIR:=${XDG_CONFIG_HOME:-${HOME:-}/.config}/qvm}"
