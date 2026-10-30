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

# Per-user data (disks, base images, seeds) and configuration (machines, user-data).
: "${QVM_DATA_DIR:=${XDG_DATA_HOME:-${HOME}/.local/share}/qvm}"
: "${QVM_CONFIG_DIR:=${XDG_CONFIG_HOME:-${HOME}/.config}/qvm}"
