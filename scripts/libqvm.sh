#!/bin/env bash
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

: "${QVM_DIR:=/var/vms}"

repo_root=$(git rev-parse --show-toplevel 2>/dev/null)
if [[ -n "${repo_root}" ]]; then
  QVM_CONFIG_DIR=config
else
  : "${QVM_CONFIG_DIR:=${HOME}/.config}"
fi
