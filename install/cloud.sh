#!/usr/bin/env bash
# awscli v2, kubectl, helm
set -euo pipefail
# shellcheck source=common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

ARCH="$(uname -m)"
case "$ARCH" in
  x86_64) KARCH=amd64; AWSARCH=x86_64 ;;
  aarch64|arm64) KARCH=arm64; AWSARCH=aarch64 ;;
  *) warn "Unsupported arch $ARCH"; exit 1 ;;
esac

if ! have aws; then
  log "Installing AWS CLI v2"
  tmp="$(mktemp -d)"
  curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-${AWSARCH}.zip" -o "$tmp/awscliv2.zip"
  unzip -q "$tmp/awscliv2.zip" -d "$tmp"
  sudo "$tmp/aws/install" --update
  rm -rf "$tmp"
else
  log "aws already installed: $(aws --version)"
fi

if ! have kubectl; then
  log "Installing kubectl"
  stable="$(curl -fsSL https://dl.k8s.io/release/stable.txt)"
  curl -fsSLo /tmp/kubectl "https://dl.k8s.io/release/${stable}/bin/linux/${KARCH}/kubectl"
  sudo install -m 0755 /tmp/kubectl /usr/local/bin/kubectl
else
  log "kubectl already installed: $(kubectl version --client --short 2>/dev/null || kubectl version --client)"
fi

if ! have helm; then
  log "Installing helm"
  curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
else
  log "helm already installed: $(helm version --short)"
fi

log "Cloud CLIs ready — import AWS SSO / kubeconfig via bin/import-secrets.sh"
