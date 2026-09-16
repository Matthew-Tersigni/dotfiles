# Giant history — you actually use this.
HISTCONTROL=ignoreboth
export HISTSIZE=1000000000
export SAVEHIST=1000000000
setopt EXTENDED_HISTORY 2>/dev/null || true
setopt HIST_IGNORE_DUPS 2>/dev/null || true
setopt HIST_IGNORE_SPACE 2>/dev/null || true
setopt SHARE_HISTORY 2>/dev/null || true

dotfiles_log "${BICyan}>History Setup"

[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"
