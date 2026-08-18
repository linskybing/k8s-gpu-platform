#!/usr/bin/env bash
# One-shot view of DRA GPU state across the cluster.
set -euo pipefail

section() { printf '\n== %s ==\n' "$1"; }

section nodes
kubectl get nodes -L nvidia.com/dra-kubelet-plugin

section "dra driver"
kubectl get pods -A -o wide \
  -l 'app.kubernetes.io/name in (dra-driver-nvidia-gpu,nvidia-dra-driver-gpu)'

section deviceclasses
kubectl get deviceclass

section "gpus advertised (resourceslices)"
kubectl get resourceslices -o custom-columns=\
'NAME:.metadata.name,NODE:.spec.nodeName,DRIVER:.spec.driver,DEVICES:.spec.devices[*].name'

section "gpu models"
kubectl get resourceslices -o yaml | grep -i 'productName' -A2 | grep string || echo "none reported"

section "claims in use"
kubectl get resourceclaims -A -o custom-columns=\
'NS:.metadata.namespace,NAME:.metadata.name,POD:.status.reservedFor[*].name,DEVICE:.status.allocation.devices.results[*].device'
