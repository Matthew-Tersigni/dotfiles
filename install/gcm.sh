#!/usr/bin/env bash
# Git Credential Manager (Azure DevOps / GitHub auth)
set -euo pipefail
# shellcheck source=common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

if have git-credential-manager || [[ -x /usr/local/bin/git-credential-manager ]]; then
  log "GCM already installed"
  exit 0
fi

ARCH="$(uname -m)"
case "$ARCH" in
  x86_64|amd64) GCM_ARCH=x64 ;;
  aarch64|arm64) GCM_ARCH=arm64 ;;
  *)
    warn "Unsupported arch for GCM: $ARCH"
    exit 1
    ;;
esac

log "Installing Git Credential Manager (linux-$GCM_ARCH)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# Repo moved to git-ecosystem; asset names are gcm-linux-x64-VERSION.deb
asset_url="$(
  curl -fsSL https://api.github.com/repos/git-ecosystem/git-credential-manager/releases/latest \
    | python3 -c "
import json, sys
assets = json.load(sys.stdin).get('assets', [])
needle = 'gcm-linux-${GCM_ARCH}-'
for asset in assets:
    name = asset.get('name', '')
    if name.startswith(needle) and name.endswith('.deb') and 'symbols' not in name:
        print(asset['browser_download_url'])
        break
"
)"

if [[ -z "$asset_url" ]]; then
  warn "Could not resolve GCM deb URL"
  warn "Install manually: https://github.com/git-ecosystem/git-credential-manager/releases"
  exit 1
fi

log "Downloading $asset_url"
curl -fsSL "$asset_url" -o "$tmp/gcm.deb"
sudo dpkg -i "$tmp/gcm.deb" || sudo apt-get install -f -y

gcm_bin="$(command -v git-credential-manager || true)"
[[ -n "$gcm_bin" ]] || gcm_bin=/usr/local/bin/git-credential-manager
"$gcm_bin" configure || true

log "GCM installed — GCM_CREDENTIAL_STORE=gpg is set in zshrc"
