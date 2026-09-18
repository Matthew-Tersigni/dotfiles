#!/usr/bin/env bash
# Bootstrap a fresh Ubuntu / WSL box to match the EC2 terminal environment.
#
# Usage:
#   ./bootstrap.sh              # everything
#   ./bootstrap.sh --skip-cloud # skip aws/kubectl/helm
#   ./bootstrap.sh apt shell python  # only selected stages
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=install/common.sh
source "$ROOT/install/common.sh"

SKIP_CLOUD=0
STAGES=()

for arg in "$@"; do
  case "$arg" in
    --skip-cloud) SKIP_CLOUD=1 ;;
    --help|-h)
      sed -n '2,12p' "$0"
      exit 0
      ;;
    *) STAGES+=("$arg") ;;
  esac
done

DEFAULT_STAGES=(apt shell python node bun dotnet cloud zig gcm link)
if ((${#STAGES[@]} == 0)); then
  STAGES=("${DEFAULT_STAGES[@]}")
fi

run_stage() {
  local name="$1"
  case "$name" in
    apt)    bash "$ROOT/install/apt.sh" ;;
    shell)  bash "$ROOT/install/shell.sh" ;;
    python) bash "$ROOT/install/python.sh" ;;
    node)   bash "$ROOT/install/node.sh" ;;
    bun)    bash "$ROOT/install/bun.sh" ;;
    dotnet) bash "$ROOT/install/dotnet.sh" ;;
    cloud)
      if [[ "$SKIP_CLOUD" == "1" ]]; then
        warn "Skipping cloud stage"
      else
        bash "$ROOT/install/cloud.sh"
      fi
      ;;
    zig)    bash "$ROOT/install/zig.sh" ;;
    gcm)    bash "$ROOT/install/gcm.sh" ;;
    link)   bash "$ROOT/link.sh" ;;
    repos)  bash "$ROOT/bin/clone-repos.sh" ;;
    *)
      warn "Unknown stage: $name"
      exit 1
      ;;
  esac
}

log "Dotfiles bootstrap from $ROOT"
log "Stages: ${STAGES[*]}"

failed_stages=()
for stage in "${STAGES[@]}"; do
  log "──── stage: $stage ────"
  if ! run_stage "$stage"; then
    warn "Stage '$stage' FAILED (exit $?)"
    failed_stages+=("$stage")
    # Don't abort the whole bootstrap — finish what we can, report at the end.
    continue
  fi
  log "──── stage: $stage OK ────"
done

if ((${#failed_stages[@]} > 0)); then
  warn "Failed stages: ${failed_stages[*]}"
  warn "Re-run just the rest, e.g.:"
  warn "  ./bootstrap.sh node bun dotnet cloud zig gcm link"
  exit 1
fi

cat <<'EOF'

========================================================================
  DONE. Next steps (do not skip these, you absolute animal):

  1. Import secrets from the EC2 tarball:
       ./bin/import-secrets.sh ~/ec2-secrets.tgz

  2. Auth check (credentials are NOT magic — prove them once):
       ssh-add ~/.ssh/ters_tech
       ssh -T git@personal-github
       git ls-remote https://dev.azure.com/gauss-dev/Magnet/_git/magnet-review

  3. Clone Magnet + personal repos from repos/repos.tsv:
       ./bin/clone-repos.sh
       # optional third-party: ./bin/clone-repos.sh --all
       # or: ./bootstrap.sh repos

  4. Re-link review bash extensions after magnet-review exists:
       ./link.sh

  5. Windows: MesloLGS NF in Windows Terminal / Cursor.

  6. Docker Desktop + WSL integration. See README.md.

  7. Sanity-check: pyenv version; workon WorkEnv; node -v; zig version

  8. Noisy EC2 banners? Flip DOTFILES_* in ~/.zshrc.local
========================================================================
EOF
