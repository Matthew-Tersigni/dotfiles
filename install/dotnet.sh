#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

if have dotnet; then
  log "dotnet already installed: $(dotnet --version 2>/dev/null || true)"
else
  log "Installing .NET SDK"
  curl -fsSL https://dot.net/v1/dotnet-install.sh -o /tmp/dotnet-install.sh
  bash /tmp/dotnet-install.sh --channel 8.0
  bash /tmp/dotnet-install.sh --channel 9.0
  ensure_dir "$HOME/.dotnet/tools"
fi

# Prefer installer's PATH layout
export DOTNET_ROOT="${DOTNET_ROOT:-$HOME/.dotnet}"
export PATH="$DOTNET_ROOT:$DOTNET_ROOT/tools:$PATH"

append_once 'export DOTNET_ROOT="$HOME/.dotnet"' "$HOME/.zshrc.local"
append_once 'export PATH="$DOTNET_ROOT:$DOTNET_ROOT/tools:$PATH"' "$HOME/.zshrc.local"

log "dotnet tools path ready"
