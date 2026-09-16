#!/usr/bin/env bash
# Clone every repo from repos/repos.tsv into $HOME (work/ + personal/).
#
# Credentials (this does NOT invent auth for you):
#   Magnet / Azure DevOps (HTTPS)
#     - import secrets (or have GCM installed)
#     - first clone will open a browser / device login via Git Credential Manager
#     - gitconfig already sets credential.https://dev.azure.com.useHttpPath=true
#   Personal GitHub (SSH via Host personal-github)
#     - ~/.ssh/config Host personal-github + IdentityFile (ters_tech) from secrets import
#     - ssh-add ~/.ssh/ters_tech
#
# Usage:
#   ./bin/clone-repos.sh                  # magnet + personal (skip vendored)
#   ./bin/clone-repos.sh --all            # include bgfx/third-party
#   ./bin/clone-repos.sh --group magnet
#   ./bin/clone-repos.sh --dry-run
#
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MANIFEST="${REPOS_MANIFEST:-$ROOT/repos/repos.tsv}"
CODE_ROOT="${CODE_ROOT:-$HOME/work}"
PERSONAL_ROOT="${PERSONAL_ROOT:-$HOME/personal}"
HOME_ROOT="$HOME"

DRY_RUN=0
INCLUDE_VENDORED=0
ONLY_GROUP=""

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    --all) INCLUDE_VENDORED=1 ;;
    --group)
      shift || true
      ;;
    --group=*)
      ONLY_GROUP="${arg#--group=}"
      ;;
    --help|-h)
      sed -n '2,20p' "$0"
      exit 0
      ;;
  esac
done

# Handle "--group NAME" as two argv tokens
args=("$@")
for ((i=0; i<${#args[@]}; i++)); do
  if [[ "${args[$i]}" == "--group" && $((i+1)) -lt ${#args[@]} ]]; then
    ONLY_GROUP="${args[$((i+1))]}"
  fi
done

[[ -f "$MANIFEST" ]] || { echo "Missing manifest: $MANIFEST" >&2; exit 1; }

normalize_remote() {
  local url="$1"
  # Prefer username-less ADO URLs; GCM + useHttpPath handles auth
  url="${url/#https:\/\/gauss-dev@dev.azure.com\//https://dev.azure.com/}"
  printf '%s' "$url"
}

need_ssh_ready() {
  if ! grep -q '^Host personal-github' "$HOME/.ssh/config" 2>/dev/null; then
    echo "!!  Missing Host personal-github in ~/.ssh/config" >&2
    echo "    Import secrets or copy ssh/config.snippet → ~/.ssh/config" >&2
    return 1
  fi
  if [[ ! -f "$HOME/.ssh/ters_tech" && ! -f "$HOME/.ssh/id_rsa" ]]; then
    echo "!!  No SSH private key found for GitHub (expected ~/.ssh/ters_tech)" >&2
    return 1
  fi
  return 0
}

need_ado_ready() {
  if ! command -v git-credential-manager >/dev/null 2>&1 \
    && [[ ! -x /usr/local/bin/git-credential-manager ]]; then
    echo "!!  Git Credential Manager not installed — run ./bootstrap.sh gcm" >&2
    return 1
  fi
  return 0
}

echo "==> Cloning from $MANIFEST"
echo "    CODE_ROOT=$CODE_ROOT  PERSONAL_ROOT=$PERSONAL_ROOT"

ok=0
skip=0
fail=0
failed_list=()

while IFS=$'\t' read -r path branch remote group; do
  [[ "$path" == "path" ]] && continue
  [[ -z "$path" || -z "$remote" ]] && continue

  if [[ -n "$ONLY_GROUP" && "$group" != "$ONLY_GROUP" ]]; then
    continue
  fi
  if [[ "$group" == "vendored" && "$INCLUDE_VENDORED" != "1" && -z "$ONLY_GROUP" ]]; then
    ((skip++)) || true
    continue
  fi

  remote="$(normalize_remote "$remote")"
  dest="$HOME_ROOT/$path"

  if [[ -d "$dest/.git" ]]; then
    echo "  = exists  $path"
    ((ok++)) || true
    continue
  fi

  case "$remote" in
    git@personal-github:*|git@github.com:*)
      need_ssh_ready || { ((fail++)); failed_list+=("$path (ssh)"); continue; }
      ;;
    https://dev.azure.com/*)
      need_ado_ready || { ((fail++)); failed_list+=("$path (ado)"); continue; }
      ;;
  esac

  mkdir -p "$(dirname "$dest")"
  echo "  + clone  $path  ($group)  →  $branch"

  if [[ "$DRY_RUN" == "1" ]]; then
    echo "      git clone --origin origin \"$remote\" \"$dest\""
    ((ok++)) || true
    continue
  fi

  if ! git clone --origin origin "$remote" "$dest"; then
    echo "  ! FAILED clone $path" >&2
    ((fail++)) || true
    failed_list+=("$path")
    continue
  fi

  if [[ -n "$branch" ]]; then
    if git -C "$dest" rev-parse --verify "origin/$branch" >/dev/null 2>&1; then
      git -C "$dest" checkout -B "$branch" --track "origin/$branch" 2>/dev/null \
        || git -C "$dest" checkout "$branch" || true
    else
      echo "  ~ branch '$branch' missing on remote — left on default"
    fi
  fi
  ((ok++)) || true
done < "$MANIFEST"

echo
echo "==> done: ok/skip/fail = $ok / $skip / $fail"
if ((fail > 0)); then
  echo "Failures:"
  printf '  - %s\n' "${failed_list[@]}"
  echo
  echo "Magnet HTTPS: run a one-shot auth if GCM prompts failed:"
  echo "  git ls-remote https://dev.azure.com/gauss-dev/Magnet/_git/magnet-review"
  echo "Personal GitHub:"
  echo "  ssh-add ~/.ssh/ters_tech && ssh -T git@personal-github"
  exit 1
fi
