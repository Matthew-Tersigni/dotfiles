# Paths + language toolchains (safe if missing)

export GPG_TTY="$(tty 2>/dev/null || echo /dev/tty)"
export GCM_CREDENTIAL_STORE=gpg

# Magnet internal workflow tools (repo-local)
if [[ -f "$CODE_ROOT/tools/tool-magnet-internal-workflow/tools.rc" ]]; then
  source "$CODE_ROOT/tools/tool-magnet-internal-workflow/tools.rc"
fi

# .NET tools
[[ -d "$HOME/.dotnet/tools" ]] && export PATH="$PATH:$HOME/.dotnet/tools"

# nvm
export NVM_DIR="$HOME/.nvm"
[[ -s "$NVM_DIR/nvm.sh" ]] && . "$NVM_DIR/nvm.sh"
[[ -s "$NVM_DIR/bash_completion" ]] && . "$NVM_DIR/bash_completion"

# bun
export BUN_INSTALL="$HOME/.bun"
[[ -s "$HOME/.bun/_bun" ]] && source "$HOME/.bun/_bun"
[[ -d "$BUN_INSTALL/bin" ]] && export PATH="$PATH:$BUN_INSTALL/bin"

# uv / ~/.local/bin (webi, etc.)
[[ -f "$HOME/.local/bin/env" ]] && . "$HOME/.local/bin/env"
[[ -d "$HOME/.local/bin" ]] && export PATH="$HOME/.local/bin:$PATH"

# zvm / zig
export ZVM_INSTALL="${ZVM_INSTALL:-$HOME/.zvm/self}"
[[ -d "$HOME/.zvm/bin" ]] && export PATH="$PATH:$HOME/.zvm/bin"
[[ -d "$ZVM_INSTALL" ]] && export PATH="$PATH:$ZVM_INSTALL/"

# pyenv
export PYENV_ROOT="${PYENV_ROOT:-$HOME/.pyenv}"
if [[ -d "$PYENV_ROOT/bin" ]]; then
  export PATH="$PYENV_ROOT/bin:$PATH"
fi
if command -v pyenv >/dev/null 2>&1; then
  eval "$(pyenv init - zsh)"
  # virtualenvs via pyenv-virtualenv if installed
  if command -v pyenv-virtualenv-init >/dev/null 2>&1 || [[ -d "$PYENV_ROOT/plugins/pyenv-virtualenv" ]]; then
    eval "$(pyenv virtualenv-init -)" 2>/dev/null || true
  fi
fi

# envman (webi)
[[ -s "$HOME/.config/envman/load.sh" ]] && source "$HOME/.config/envman/load.sh"

export KUBECONFIG="${KUBECONFIG:-$HOME/.kube/config}"
if command -v kubectl >/dev/null 2>&1; then
  alias k=kubectl
  # shellcheck disable=SC1090
  source <(kubectl completion zsh 2>/dev/null) 2>/dev/null || true
  complete -F __start_kubectl k 2>/dev/null || true
fi

dotfiles_log "${Color_Off}"
