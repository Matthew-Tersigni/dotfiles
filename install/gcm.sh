#!/usr/bin/env bash
# Git Credential Manager (Azure DevOps / GitHub auth)
set -euo pipefail
# shellcheck source=common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

if have git-credential-manager || [[ -x /usr/local/bin/git-credential-manager ]]; then
  log "GCM already installed"
  exit 0
fi

log "Installing Git Credential Manager"
tmp="$(mktemp -d)"
# Latest amd64 deb from microsoft/git-credential-manager releases
asset_url="$(curl -fsSL https://api.github.com/repos/git-credential-manager/git-credential-manager/releases/latest \
  | grep -oE 'https://[^"]+gcm-linux_amd64\.[0-9.]+\.deb' | head -1 || true)"

if [[ -z "$asset_url" ]]; then
  warn "Could not resolve GCM deb URL — install manually from https://github.com/git-credential-manager/git-credential-manager/releases"
  exit 0
fi

curl -fsSL "$asset_url" -o "$tmp/gcm.deb"
sudo dpkg -i "$tmp/gcm.deb" || sudo apt-get install -f -y
rm -rf "$tmp"

git-credential-manager configure || /usr/local/bin/git-credential-manager configure || true
log "GCM installed — set GCM_CREDENTIAL_STORE=gpg (already in zshrc)"
