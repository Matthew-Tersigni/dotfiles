#!/usr/bin/env bash
# zsh + Oh My Zsh + Powerlevel10k + Antigen + Oh my tmux
set -euo pipefail
# shellcheck source=common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

log "Configuring default shell → zsh"
if [[ "${SHELL:-}" != "$(command -v zsh)" ]]; then
  chsh -s "$(command -v zsh)" "$USER" || warn "chsh failed — set default shell manually"
fi

if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  log "Installing Oh My Zsh"
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
  log "Oh My Zsh already present"
fi

if [[ ! -d "$HOME/powerlevel10k" ]]; then
  log "Cloning Powerlevel10k"
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$HOME/powerlevel10k"
else
  log "Powerlevel10k already present"
fi

if [[ ! -f "$HOME/antigen.zsh" ]]; then
  log "Installing Antigen"
  if [[ -f "$DOTFILES_ROOT/zsh/antigen.zsh" ]]; then
    cp "$DOTFILES_ROOT/zsh/antigen.zsh" "$HOME/antigen.zsh"
  else
    curl -fsSL git.io/antigen > "$HOME/antigen.zsh"
  fi
fi

if [[ ! -d "$HOME/.tmux" ]]; then
  log "Installing Oh my tmux"
  git clone --depth=1 https://github.com/gpakosz/.tmux.git "$HOME/.tmux"
fi
ln -sfn "$HOME/.tmux/.tmux.conf" "$HOME/.tmux.conf"

log "Shell stack ready (configs linked by link.sh)"
warn "Install a Nerd Font (MesloLGS NF) on WINDOWS and set it in Windows Terminal / Cursor — p10k is ugly without it."
