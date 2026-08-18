#!/usr/bin/env bash
# Runnable check for the setup scripts: syntax + dispatch + driver-root fork,
# without touching the host or a cluster.  Run: scripts/selfcheck.sh
set -euo pipefail
cd "$(dirname "$0")"

for f in setup/rke2.sh setup/gpu-dra.sh operations/gpu-status.sh selfcheck.sh; do bash -n "$f"; done

fail() { echo "FAIL: $*" >&2; exit 1; }
has() { grep -qF -- "$2" <<<"$1" || fail "expected '$2' in:\n$1"; }
rejects() { "$@" 2>/dev/null && fail "should have rejected: $*"; return 0; }

out=$(DRY_RUN=1 ./setup/rke2.sh server)
has "$out" 'INSTALL_RKE2_TYPE=server'
has "$out" 'systemctl enable --now rke2-server'
has "$out" '/var/lib/rancher/rke2/server/node-token'   # first server prints the join token

out=$(DRY_RUN=1 ./setup/rke2.sh agent 10.0.0.1 tok)
has "$out" '+ write /etc/rancher/rke2/config.yaml'     # joiners get config before first start
has "$out" 'INSTALL_RKE2_TYPE=agent'

out=$(DRY_RUN=1 RKE2_CHANNEL=v1.35 ./setup/rke2.sh server 10.0.0.1 tok)
has "$out" 'INSTALL_RKE2_CHANNEL=v1.35'
grep -qF 'node-token' <<<"$out" && fail "joining server should not print its own token"

rejects ./setup/rke2.sh bogus
rejects ./setup/rke2.sh agent 10.0.0.1
rejects ./setup/gpu-dra.sh

out=$(DRY_RUN=1 ./setup/gpu-dra.sh n1 n2)
has "$out" 'kubectl label node --overwrite n1 n2 nvidia.com/dra-kubelet-plugin=true'
has "$out" 'nvidiaDriverRoot=/run/nvidia/driver'
has "$out" 'driver.enabled=true'
has "$out" 'devicePlugin.enabled=false'

out=$(DRY_RUN=1 MANAGE_DRIVER=false ./setup/gpu-dra.sh n1)
has "$out" 'driver.enabled=false'
has "$out" 'nvidiaDriverRoot=/ '
grep -qF 'NODE_LABEL_FOR_GPU_POD_EVICTION' <<<"$out" && fail "eviction label is only for managed drivers"

echo "selfcheck OK"
