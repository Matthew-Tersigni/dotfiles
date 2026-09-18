#!/usr/bin/env bash
# pyenv + virtualenvwrapper + WorkEnv + thefuck
#
# NOTE: On the EC2 you used virtualenvwrapper (WorkEnv), not pyenv binaries.
# This installs BOTH so Python version pinning (pyenv) and your WorkEnv workflow keep working.
set -euo pipefail
# shellcheck source=common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

PYENV_ROOT="${PYENV_ROOT:-$HOME/.pyenv}"
PYTHON_VERSION="${DOTFILES_PYTHON_VERSION:-3.12.8}"
REQUIREMENTS="$DOTFILES_ROOT/python/requirements-workenv.txt"

log "Installing pyenv build deps"
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
  make build-essential libssl-dev zlib1g-dev \
  libbz2-dev libreadline-dev libsqlite3-dev curl llvm \
  libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev \
  libffi-dev liblzma-dev

if [[ ! -d "$PYENV_ROOT" ]]; then
  log "Installing pyenv"
  curl -fsSL https://pyenv.run | bash
else
  log "pyenv already present"
fi

export PYENV_ROOT
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init - bash)"

if ! pyenv versions --bare | grep -qx "$PYTHON_VERSION"; then
  log "Building Python $PYTHON_VERSION via pyenv (this takes a minute)"
  pyenv install -s "$PYTHON_VERSION"
fi
pyenv global "$PYTHON_VERSION"

PYENV_PYTHON="$(pyenv which python)"
log "Using $PYENV_PYTHON"

log "Installing virtualenvwrapper + thefuck (into pyenv Python)"
"$PYENV_PYTHON" -m pip install --upgrade pip setuptools wheel
# Prefer pyenv's own bin over --user (WSL/Ubuntu PEP 668 + path weirdness)
"$PYENV_PYTHON" -m pip install virtualenv virtualenvwrapper thefuck

export PATH="$(dirname "$PYENV_PYTHON"):$HOME/.local/bin:$PATH"

export WORKON_HOME="${WORKON_HOME:-$HOME/.virtualenvs}"
export VIRTUALENVWRAPPER_PYTHON="$PYENV_PYTHON"
ensure_dir "$WORKON_HOME"

# Locate virtualenvwrapper.sh
VW=""
for candidate in \
  "$(dirname "$PYENV_PYTHON")/virtualenvwrapper.sh" \
  "$HOME/.local/bin/virtualenvwrapper.sh" \
  /usr/local/bin/virtualenvwrapper.sh; do
  if [[ -f "$candidate" ]]; then
    VW="$candidate"
    break
  fi
done
if [[ -z "$VW" ]]; then
  VW="$(find "$PYENV_ROOT" -name virtualenvwrapper.sh 2>/dev/null | head -1 || true)"
fi
[[ -n "$VW" ]] || { warn "virtualenvwrapper.sh not found"; exit 1; }

# virtualenvwrapper references ZSH_VERSION; under bash + set -u that explodes.
# Keep nounset off for the rest of this script — vw hooks are sloppy with unset vars.
set +u
# shellcheck disable=SC1090
source "$VW"

if [[ -d "$WORKON_HOME/WorkEnv" ]]; then
  log "WorkEnv already exists"
  workon WorkEnv || true
else
  log "Creating WorkEnv virtualenv"
  # mkvirtualenv often exits non-zero after success (hook noise) — judge by dest dir.
  mkvirtualenv -p "$PYENV_PYTHON" WorkEnv || true
  if [[ ! -d "$WORKON_HOME/WorkEnv" ]]; then
    warn "mkvirtualenv did not create $WORKON_HOME/WorkEnv"
    exit 1
  fi
  workon WorkEnv || true
fi

if [[ -f "$REQUIREMENTS" ]]; then
  log "Installing WorkEnv requirements"
  pip install -r "$REQUIREMENTS" || warn "requirements install had issues — continuing"
fi

# Optional: full freeze from EC2 if you exported it
if [[ -f "$DOTFILES_ROOT/python/requirements-workenv.full.txt" ]]; then
  log "Installing full WorkEnv freeze"
  pip install -r "$DOTFILES_ROOT/python/requirements-workenv.full.txt" || warn "Full freeze had conflicts — core packages still installed"
fi

log "Python stack ready (pyenv=$PYTHON_VERSION, WorkEnv at $WORKON_HOME/WorkEnv)"
set -u
