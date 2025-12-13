#!/bin/bash
set -eu
declare -A IPS
for host in cp wk1 wk2; do
  IPS["${host}"]=$(dig +short @10.42.0.1 "${host}")
done

declare -A SUBNETS
SUBNETS=(
  wk1 10.200.0.0/24
  wk2 10.200.1.0/24
)

if [[ "${1:-}" == -n ]]; then
  echo "${IPS[@]}"
  echo "${SUBNETS[@]}"
  exit
fi

ssh -T root@cp.qvm0.lan <<EOF
  ip route add "${SUBNETS[wk1]}" via "${IPS[wk1]}"
  ip route add "${SUBNETS[wk2]}" via "${IPS[wk2]}"
EOF

ssh -T root@wk1.qvm0.lan <<EOF
  ip route add "${SUBNETS[wk2]}" via "${IPS[wk2]}"
EOF

ssh -T root@wk2.qvm0.lan <<EOF
  ip route add "${SUBNETS[wk1]}" via "${IPS[wk1]}"
EOF
