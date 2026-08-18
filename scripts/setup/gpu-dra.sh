#!/usr/bin/env bash
# Install the NVIDIA GPU Operator + DRA driver so GPUs are claimable via DRA.
# Run once against the cluster (needs kubectl + helm and a kubeconfig).
#
#   ./gpu-dra.sh <gpu-node> [<gpu-node>...]
#
# Env: MANAGE_DRIVER=false   NVIDIA driver is already installed on the hosts
#      GPU_OPERATOR_VERSION, DRA_DRIVER_VERSION, NVIDIA_DRIVER_ROOT
#      DRA_NAMESPACE, DRA_RELEASE, NAME_OVERRIDE (match an existing install)
#      DRY_RUN=1 prints what would run instead of running it.
set -euo pipefail

GPU_OPERATOR_VERSION=${GPU_OPERATOR_VERSION:-v26.3.3}
DRA_DRIVER_VERSION=${DRA_DRIVER_VERSION:-0.4.1}
DRA_NAMESPACE=${DRA_NAMESPACE:-nvidia-dra-driver-gpu}
DRA_RELEASE=${DRA_RELEASE:-dra-driver-nvidia-gpu}
MANAGE_DRIVER=${MANAGE_DRIVER:-true}
# The DRA kubelet plugin only runs where this label is set; the GPU Operator's
# driver manager uses the same label to evict it on driver upgrades.
LABEL=nvidia.com/dra-kubelet-plugin
dry=${DRY_RUN:-}

die() { echo "$*" >&2; exit 1; }
run() { if [[ -n $dry ]]; then printf '+ %s\n' "$*"; else "$@"; fi; }

(( $# )) || die "usage: $0 <gpu-node> [<gpu-node>...]"
for bin in kubectl helm; do command -v "$bin" >/dev/null || die "$bin not found"; done

if [[ $MANAGE_DRIVER == true ]]; then
  driver_root=${NVIDIA_DRIVER_ROOT:-/run/nvidia/driver}
  operator_args=(--set driver.enabled=true
                 --set driver.manager.env[0].name=NODE_LABEL_FOR_GPU_POD_EVICTION
                 --set driver.manager.env[0].value="$LABEL")
else
  driver_root=${NVIDIA_DRIVER_ROOT:-/}
  operator_args=(--set driver.enabled=false)
fi

# Capability check beats a version string: the chart needs resource.k8s.io/v1 (K8s >= 1.34.2).
run sh -c 'kubectl get --raw /apis/resource.k8s.io/v1 >/dev/null' ||
  die "cluster does not serve resource.k8s.io/v1 — needs Kubernetes >= 1.34.2"

# A second driver install alongside an existing one gives the cluster two kubelet
# plugins for the same driver name, which breaks allocation. Upgrade in place instead.
prior=$(helm list -A -f 'dra-driver' 2>/dev/null | awk 'NR>1 {print $2"/"$1}') || true
[[ -z $prior || $prior == "$DRA_NAMESPACE/$DRA_RELEASE" ]] ||
  die "DRA driver already installed as $prior — rerun with DRA_NAMESPACE and DRA_RELEASE set to it (plus NAME_OVERRIDE=nvidia-dra-driver-gpu when upgrading a v25.x install)"

run kubectl label node --overwrite "$@" "$LABEL=true"

run helm repo add nvidia https://helm.ngc.nvidia.com/nvidia
run helm repo update nvidia

# devicePlugin.enabled=false: DRA replaces nvidia.com/gpu extended resources.
run helm upgrade --install gpu-operator nvidia/gpu-operator \
  --version "$GPU_OPERATOR_VERSION" \
  --namespace gpu-operator --create-namespace --wait \
  --set devicePlugin.enabled=false \
  "${operator_args[@]}"

run helm upgrade --install "$DRA_RELEASE" nvidia/dra-driver-nvidia-gpu \
  --version "$DRA_DRIVER_VERSION" \
  --namespace "$DRA_NAMESPACE" --create-namespace --wait \
  --set nvidiaDriverRoot="$driver_root" \
  --set gpuResourcesEnabledOverride=true \
  ${NAME_OVERRIDE:+--set nameOverride=$NAME_OVERRIDE} \
  --set-string 'kubeletPlugin.nodeSelector.nvidia\.com/dra-kubelet-plugin=true'

echo "done — check with scripts/operations/gpu-status.sh"
