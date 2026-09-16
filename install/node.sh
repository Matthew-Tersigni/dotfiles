#!/usr/bin/env bash
# nvm + Node LTS versions matching EC2 habit (18/20/22)
set -euo pipefail
# shellcheck source=common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/common.sh"

export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"

if [[ ! -d "$NVM_DIR" ]]; then
  log "Installing nvm"
  curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
else
  log "nvm already present"
fi

# shellcheck disable=SC1091
. "$NVM_DIR/nvm.sh"

for version in 22 20 18; do
  log "Ensuring Node $version"
  nvm install "$version"
done
nvm alias default 22
nvm use default

log "Node $(node -v) / npm $(npm -v)"
