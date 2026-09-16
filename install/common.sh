#!/usr/bin/env bash
# Shared helpers for install/*.sh
set -euo pipefail

DOTFILES_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export DOTFILES_ROOT

log()  { printf '==> %s\n' "$*"; }
warn() { printf '!!  %s\n' "$*" >&2; }
have() { command -v "$1" >/dev/null 2>&1; }

is_wsl() {
  grep -qiE 'microsoft|wsl' /proc/version 2>/dev/null
}

ensure_dir() {
  mkdir -p "$1"
}

append_once() {
  local line="$1"
  local file="$2"
  grep -Fqx "$line" "$file" 2>/dev/null || echo "$line" >> "$file"
}
