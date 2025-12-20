#!/usr/bin/env bash
username="${1}"
ca_key="${QVM_DIR}/certs/k8s/ca.key"
ca_crt="${QVM_DIR}/certs/k8s/ca.crt"
# Create a x509 certificate
args=(
  -x509
  -CAkey "${ca_key}"
  -CA "${ca_crt}"
  -days 365
  -out "${username}.crt"
  -newkey rsa:2048
  -keyout "${username}.key"
  -noenc
  -subj "/CN=kwentine/O=kwentine"
)
openssl req "${args[@]}"
