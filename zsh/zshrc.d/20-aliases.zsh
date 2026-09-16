# ls / grep colours
if [ -x /usr/bin/dircolors ]; then
  test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
  alias ls='ls --color=auto'
  alias grep='grep --color=auto'
  alias fgrep='fgrep --color=auto'
  alias egrep='egrep --color=auto'
fi
dotfiles_log ">Setup DirColors"

alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias s="source ~/.zshrc"
alias gs="git status"
alias githome="git checkout build/saas"
alias weather="curl wttr.in/Guelph"

# Dotnet shortcuts
alias dnr="dotnet run --environment LocalDev --interactive"
alias dnw="dotnet watch --environment LocalDev --interactive"
alias dnt="dotnet test"

# Work trees — CODE_ROOT portable
alias hits="cd $CODE_ROOT/magnet-review/api/mr-hits-service/Magnet.Web.Hits"
alias cli="cd $CODE_ROOT/magnet-review/cli"
alias auth="cd $CODE_ROOT/magnet-review/api/mr-auth-service/Magnet.Web.Auth"
alias tenants="cd $CODE_ROOT/review-tenants/api/src/Magnet.Review.Tenants"
alias ingestion="cd $CODE_ROOT/magnet-review/api/review-ingestion/src/Magnet.Review.Ingestion"
alias frontend="cd $CODE_ROOT/review-frontend"
alias cases="cd $CODE_ROOT/magnet-review/api/mr-cases-service/Magnet.Web.Cases"

if [[ -f "$CODE_ROOT/magnet-review/scripts/sync-cluster/sync_cluster.py" ]]; then
  alias sync-cluster="python3 $CODE_ROOT/magnet-review/scripts/sync-cluster/sync_cluster.py"
fi

[[ -f ~/.bash_aliases ]] && source ~/.bash_aliases
dotfiles_log ">setup bash aliases"
