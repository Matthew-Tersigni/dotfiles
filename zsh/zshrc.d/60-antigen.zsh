# Antigen plugins (autosuggestions, syntax highlight, nvm auto-use)

dotfiles_log "${Cyan}> Setting up zsh extensions"

_antigen_path=""
if [[ -f "$HOME/antigen.zsh" ]]; then
  _antigen_path="$HOME/antigen.zsh"
elif [[ -f "$DOTFILES_DIR/zsh/antigen.zsh" ]]; then
  _antigen_path="$DOTFILES_DIR/zsh/antigen.zsh"
fi

if [[ -n "$_antigen_path" ]]; then
  # shellcheck disable=SC1090
  source "$_antigen_path"

  ZSH_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
  [[ -d $ZSH_CACHE_DIR/completions ]] || mkdir -p $ZSH_CACHE_DIR/completions
  fpath=($ZSH_CACHE_DIR/completions $fpath)
  autoload -Uz compinit && compinit

  antigen bundle git
  antigen bundle zsh-users/zsh-autosuggestions
  antigen bundle zsh-users/zsh-syntax-highlighting
  antigen bundle z-shell/F-Sy-H --branch=main
  export NVM_AUTO_USE=true
  antigen bundle lukechilds/zsh-nvm
  antigen apply
fi
unset _antigen_path
