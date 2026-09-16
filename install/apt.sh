#!/usr/bin/env bash
# Apt packages that match the EC2 baseline.
set -euo pipefail
# shellcheck source=common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

log "Installing apt packages"
sudo apt-get update -y
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
  zsh tmux git curl wget ca-certificates gnupg gpg pass \
  build-essential make cmake pkg-config \
  unzip zip jq \
  python3 python3-pip python3-venv python3-dev \
  mysql-client \
  fonts-powerline \
  software-properties-common \
  apt-transport-https \
  lsb-release \
  procps

# Optional quality-of-life (ignore if unavailable on this Ubuntu)
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
  ripgrep fd-find fzf bat 2>/dev/null || true

# fd-find / bat ship as fdfind / batcat on Debian
if have fdfind && ! have fd; then
  ensure_dir "$HOME/.local/bin"
  ln -sfn "$(command -v fdfind)" "$HOME/.local/bin/fd"
fi
if have batcat && ! have bat; then
  ensure_dir "$HOME/.local/bin"
  ln -sfn "$(command -v batcat)" "$HOME/.local/bin/bat"
fi

log "Apt baseline ready"
