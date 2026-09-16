#!/usr/bin/env bash
# Restore secrets onto a fresh WSL/home from export-secrets.sh output.
#
# Usage:
#   ./bin/import-secrets.sh ~/ec2-secrets-XXXX.tgz
#   ./bin/import-secrets.sh ~/ec2-secrets-XXXX.tgz.gpg
#
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

ARCHIVE="${1:-}"
if [[ -z "$ARCHIVE" || ! -f "$ARCHIVE" ]]; then
  echo "Usage: $0 <secrets.tgz|secrets.tgz.gpg>" >&2
  exit 1
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

if [[ "$ARCHIVE" == *.gpg ]]; then
  echo "==> Decrypting"
  gpg --decrypt "$ARCHIVE" > "$TMP/secrets.tgz"
  ARCHIVE="$TMP/secrets.tgz"
fi

echo "==> Extracting"
tar xzf "$ARCHIVE" -C "$TMP"

restore_tree() {
  local src="$1"
  local dest="$2"
  if [[ -e "$src" ]]; then
    mkdir -p "$(dirname "$dest")"
    if [[ -e "$dest" ]]; then
      local bak="${dest}.bak.$(date +%Y%m%d-%H%M%S)"
      mv "$dest" "$bak"
      echo "  backed up $dest → $bak"
    fi
    cp -a "$src" "$dest"
    echo "  restored $dest"
  fi
}

restore_tree "$TMP/ssh" "$HOME/.ssh"
restore_tree "$TMP/aws" "$HOME/.aws"
restore_tree "$TMP/gnupg" "$HOME/.gnupg"
restore_tree "$TMP/kube" "$HOME/.kube"
restore_tree "$TMP/password-store" "$HOME/.password-store"

if [[ -f "$TMP/nuget/NuGet.Config" ]]; then
  mkdir -p "$HOME/.nuget/NuGet"
  cp -a "$TMP/nuget/NuGet.Config" "$HOME/.nuget/NuGet/NuGet.Config"
  chmod 600 "$HOME/.nuget/NuGet/NuGet.Config"
  echo "  restored ~/.nuget/NuGet/NuGet.Config"
fi

if [[ -f "$TMP/npmrc" ]]; then
  cp -a "$TMP/npmrc" "$HOME/.npmrc"
  chmod 600 "$HOME/.npmrc"
  echo "  restored ~/.npmrc"
fi

# Permissions matter for ssh/gpg
[[ -d "$HOME/.ssh" ]] && chmod 700 "$HOME/.ssh" && chmod 600 "$HOME/.ssh"/* 2>/dev/null || true
[[ -d "$HOME/.gnupg" ]] && chmod 700 "$HOME/.gnupg"

# Drop full pip freeze into the repo for python installer / reinstall
if [[ -f "$TMP/requirements-workenv.full.txt" ]]; then
  cp "$TMP/requirements-workenv.full.txt" "$ROOT/python/requirements-workenv.full.txt"
  echo "  wrote $ROOT/python/requirements-workenv.full.txt"
  echo "  re-run: ./bootstrap.sh python   to install the full freeze into WorkEnv"
fi

# Sensitive scripts that lived under work/scripts
if [[ -d "$TMP/work-scripts" ]]; then
  mkdir -p "$HOME/work/scripts"
  cp -a "$TMP/work-scripts/." "$HOME/work/scripts/"
  chmod 600 "$HOME/work/scripts/myPatTokens.json" "$HOME/work/scripts/cookie.txt" 2>/dev/null || true
  echo "  restored ~/work/scripts/{myPatTokens.json,cookie.txt}"
fi

echo "==> Secrets imported. Run: chmod 600 ~/.ssh/id_* ; ssh-add ; awssso"
echo "    Then extract work extras: tar xzf work-extras-*.tgz -C \$HOME"
