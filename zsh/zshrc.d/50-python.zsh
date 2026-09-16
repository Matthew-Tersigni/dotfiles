# Python: pyenv + virtualenvwrapper + WorkEnv + thefuck

export WORKON_HOME="${WORKON_HOME:-$HOME/.virtualenvs}"
export VIRTUALENVWRAPPER_PYTHON="${VIRTUALENVWRAPPER_PYTHON:-$(command -v python3)}"

# Prefer pyenv's python if available
if command -v pyenv >/dev/null 2>&1; then
  pyenv_python="$(pyenv which python 2>/dev/null || true)"
  if [[ -n "$pyenv_python" ]]; then
    export VIRTUALENVWRAPPER_PYTHON="$pyenv_python"
  fi
fi

# virtualenvwrapper can live in a few places depending on install method
_virtualenvwrapper_candidates=(
  "$HOME/.local/bin/virtualenvwrapper.sh"
  /usr/local/bin/virtualenvwrapper.sh
  /usr/share/virtualenvwrapper/virtualenvwrapper.sh
)
for _vw in "${_virtualenvwrapper_candidates[@]}"; do
  if [[ -f "$_vw" ]]; then
    # shellcheck disable=SC1090
    source "$_vw"
    break
  fi
done
unset _vw _virtualenvwrapper_candidates

if [[ "${DOTFILES_AUTO_WORKON:-1}" == "1" ]] && typeset -f workon >/dev/null 2>&1; then
  if [[ -d "$WORKON_HOME/WorkEnv" ]]; then
    dotfiles_log "\n\n${BIYellow}Activating Python WorkEnv VirtualEnv -- use \`deactivate\` to exit venv\n"
    workon WorkEnv 2>/dev/null || true
  else
    dotfiles_log "${Yellow}WorkEnv missing — run: mkvirtualenv WorkEnv && pip install -r \$DOTFILES_DIR/python/requirements-workenv.txt${Color_Off}"
  fi
fi

if command -v thefuck >/dev/null 2>&1; then
  dotfiles_log "${BIRed}Setting Up thefuck...\n"
  eval "$(thefuck --alias fuck)"
  alias FUCK="fuck --yeah"
fi
