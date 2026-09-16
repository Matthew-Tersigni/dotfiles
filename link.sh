#!/usr/bin/env bash
# Symlink / copy config into $HOME. Idempotent.
set -euo pipefail
# shellcheck source=install/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/install/common.sh"

log "Linking configs from $DOTFILES_ROOT"

backup_if_real_file() {
  local target="$1"
  if [[ -e "$target" && ! -L "$target" ]]; then
    local stamp
    stamp="$(date +%Y%m%d-%H%M%S)"
    mv "$target" "${target}.bak.${stamp}"
    warn "Backed up $target → ${target}.bak.${stamp}"
  fi
}

link_file() {
  local src="$1"
  local dest="$2"
  backup_if_real_file "$dest"
  ln -sfn "$src" "$dest"
  log "linked $dest → $src"
}

link_file "$DOTFILES_ROOT/zsh/zshrc" "$HOME/.zshrc"
link_file "$DOTFILES_ROOT/zsh/p10k.zsh" "$HOME/.p10k.zsh"
link_file "$DOTFILES_ROOT/tmux/tmux.conf.local" "$HOME/.tmux.conf.local"
link_file "$DOTFILES_ROOT/git/gitconfig" "$HOME/.gitconfig"

# Antigen copy (not symlink — antigen mutates cache nearby sometimes)
if [[ -f "$DOTFILES_ROOT/zsh/antigen.zsh" ]]; then
  cp -n "$DOTFILES_ROOT/zsh/antigen.zsh" "$HOME/antigen.zsh" 2>/dev/null \
    || cp "$DOTFILES_ROOT/zsh/antigen.zsh" "$HOME/antigen.zsh"
fi

# Review bash extensions symlink (EC2 had ~/.review_bash_extensions → magnet-review/scripts/...)
CODE_ROOT="${CODE_ROOT:-$HOME/work}"
REVIEW_EXT_SRC="${CODE_ROOT}/magnet-review/scripts/bash_extensions"
if [[ -d "$REVIEW_EXT_SRC" ]]; then
  ln -sfn "$REVIEW_EXT_SRC" "$HOME/.review_bash_extensions"
  log "linked ~/.review_bash_extensions → $REVIEW_EXT_SRC"
else
  warn "magnet-review bash_extensions not found yet — clone repos under \$CODE_ROOT then re-run link.sh"
fi

# Ensure personal-github SSH host exists (full config comes from secrets import)
ensure_dir "$HOME/.ssh"
chmod 700 "$HOME/.ssh" 2>/dev/null || true
if [[ -f "$DOTFILES_ROOT/ssh/config.snippet" ]]; then
  if [[ ! -f "$HOME/.ssh/config" ]] || ! grep -q '^Host personal-github' "$HOME/.ssh/config" 2>/dev/null; then
    {
      echo ""
      echo "# --- from dotfiles/ssh/config.snippet ---"
      cat "$DOTFILES_ROOT/ssh/config.snippet"
    } >> "$HOME/.ssh/config"
    chmod 600 "$HOME/.ssh/config"
    log "Appended personal-github SSH host to ~/.ssh/config"
  fi
fi

# Seed a local overrides file if missing
if [[ ! -f "$HOME/.zshrc.local" ]]; then
  cp "$DOTFILES_ROOT/zsh/zshrc.local.example" "$HOME/.zshrc.local"
  log "Created ~/.zshrc.local from example — edit this for machine-specific flags"
fi

# Point DOTFILES_DIR for the shell
append_once "export DOTFILES_DIR=\"$DOTFILES_ROOT\"" "$HOME/.zshrc.local"
append_once "export CODE_ROOT=\"\${CODE_ROOT:-$HOME/work}\"" "$HOME/.zshrc.local"

log "Links done"
