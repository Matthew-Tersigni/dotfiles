#!/usr/bin/env bash
# zvm (Zig Version Manager) — matches EC2 .zvm setup
set -euo pipefail
# shellcheck source=common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

if [[ ! -d "$HOME/.zvm" ]]; then
  log "Installing zvm"
  curl -fsSL https://raw.githubusercontent.com/tristanisham/zvm/master/install.sh | bash
else
  log "zvm already present"
fi

export ZVM_INSTALL="$HOME/.zvm/self"
export PATH="$PATH:$HOME/.zvm/bin:$ZVM_INSTALL/"

if have zvm; then
  # Pin something modern; override with DOTFILES_ZIG_VERSION
  ZIG_VERSION="${DOTFILES_ZIG_VERSION:-0.14.0}"
  log "Installing zig $ZIG_VERSION via zvm"
  zvm install "$ZIG_VERSION" || zvm i "$ZIG_VERSION" || warn "zvm install failed — run manually"
  zvm use "$ZIG_VERSION" 2>/dev/null || true
fi

log "Zig toolchain ready"
