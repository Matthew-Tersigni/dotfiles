#!/usr/bin/env bash
# zvm (Zig Version Manager) — matches EC2 / drift (Zig 0.16.0+)
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
export PATH="$PATH:$HOME/.zvm/bin:$ZVM_INSTALL"

# zvm binary lives under ~/.zvm/self after install
ZVM_BIN=""
if have zvm; then
  ZVM_BIN="$(command -v zvm)"
elif [[ -x "$HOME/.zvm/self/zvm" ]]; then
  ZVM_BIN="$HOME/.zvm/self/zvm"
elif [[ -x "$HOME/.zvm/zvm" ]]; then
  ZVM_BIN="$HOME/.zvm/zvm"
fi

# Drift requires 0.16.0+ (see build.zig.zon). Override with DOTFILES_ZIG_VERSION.
ZIG_VERSION="${DOTFILES_ZIG_VERSION:-0.16.0}"

if [[ -z "$ZVM_BIN" ]]; then
  warn "zvm binary not found — install manually, then: zvm i $ZIG_VERSION && zvm use $ZIG_VERSION"
  exit 1
fi

log "Using zvm at $ZVM_BIN"
log "Installing zig $ZIG_VERSION via zvm"
"$ZVM_BIN" install "$ZIG_VERSION" || "$ZVM_BIN" i "$ZIG_VERSION"
"$ZVM_BIN" use "$ZIG_VERSION"

# Ensure shims are on PATH for this shell
export PATH="$HOME/.zvm/bin:$PATH"
if have zig; then
  log "zig $(zig version) ready"
else
  warn "zig not on PATH yet — add to shell: export PATH=\"\$HOME/.zvm/bin:\$PATH\""
  warn "or open a new terminal after link.sh / zshrc loads zvm paths"
fi

log "Zig toolchain ready"
