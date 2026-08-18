#!/usr/bin/env bash
# Install RKE2 and join it to the cluster.
#
#   sudo ./rke2.sh server                       # first control-plane
#   sudo ./rke2.sh server <server-ip> <token>   # extra control-plane (HA)
#   sudo ./rke2.sh agent  <server-ip> <token>   # worker / GPU node
#
# Env: RKE2_CHANNEL (default v1.34 — DRA resource.k8s.io/v1 is GA from 1.34)
#      DRY_RUN=1 prints what would run instead of running it.
set -euo pipefail

CHANNEL=${RKE2_CHANNEL:-v1.34}
dry=${DRY_RUN:-}

die() { echo "$*" >&2; exit 1; }
run() { if [[ -n $dry ]]; then printf '+ %s\n' "$*"; else "$@"; fi; }
# write stdin to $1 with mode 0600
write() { if [[ -n $dry ]]; then printf '+ write %s\n' "$1"; cat >/dev/null; else install -D -m600 /dev/stdin "$1"; fi; }

role=${1:-}
server=${2:-}
token=${3:-}

[[ $role == server || $role == agent ]] || die "usage: $0 <server|agent> [server-ip] [token]"
[[ $role == server || ( -n $server && -n $token ) ]] || die "agent needs <server-ip> and <token>"
[[ -n $server && -z $token ]] && die "joining $server needs a <token>"
[[ -n $dry || $EUID -eq 0 ]] || die "must run as root"

# Joining nodes need the server URL + token before the service first starts.
if [[ -n $server ]]; then
  write /etc/rancher/rke2/config.yaml <<EOF
server: https://${server}:9345
token: ${token}
EOF
fi

run sh -c "curl -sfL https://get.rke2.io | INSTALL_RKE2_CHANNEL=${CHANNEL} INSTALL_RKE2_TYPE=${role} sh -"
run systemctl enable --now "rke2-${role}"

if [[ $role == server ]]; then
  # First boot generates the kubeconfig; hand it to the invoking user.
  kubeconfig=/etc/rancher/rke2/rke2.yaml
  run timeout 300 sh -c "until [ -s $kubeconfig ]; do sleep 5; done"
  user=${SUDO_USER:-root}
  home=$(getent passwd "$user" | cut -d: -f6)
  run install -D -m600 -o "$user" "$kubeconfig" "$home/.kube/config"
  echo "kubeconfig -> $home/.kube/config   (add /var/lib/rancher/rke2/bin to PATH)"
  [[ -n $server ]] || run cat /var/lib/rancher/rke2/server/node-token
fi
