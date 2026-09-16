#!/usr/bin/env bash
# Scan ~/work and ~/personal for git remotes and refresh repos/repos.tsv
#
# Usage:
#   ./bin/export-repos.sh
#   CODE_ROOT=~/work ./bin/export-repos.sh
#
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="${1:-$ROOT/repos/repos.tsv}"
CODE_ROOT="${CODE_ROOT:-$HOME/work}"
PERSONAL_ROOT="${PERSONAL_ROOT:-$HOME/personal}"

normalize_remote() {
  local url="$1"
  # Drop embedded ADO username (credentials live in GCM, not the URL)
  url="${url/#https:\/\/gauss-dev@dev.azure.com\//https://dev.azure.com/}"
  url="${url/#https:\/\/*@dev.azure.com\//https://dev.azure.com/}"
  printf '%s' "$url"
}

classify() {
  local url="$1"
  case "$url" in
    *dev.azure.com*) echo magnet ;;
    *personal-github*|*Matthew-Tersigni*) echo personal ;;
    *github.com*) echo vendored ;;
    *) echo other ;;
  esac
}

# Prefer stable default branches in the committed manifest when HEAD is a feature branch.
stable_branch() {
  local repo="$1"
  local head="$2"
  local group="$3"

  if [[ "$group" != "magnet" ]]; then
    printf '%s' "$head"
    return
  fi

  # Feature / ticket branches are machine state — clone the repo default instead.
  if [[ "$head" =~ ^(RE-|HUB-|PR-) ]] || [[ "$head" == *"/"* && "$head" != "build/saas" ]]; then
    local default
    default="$(git -C "$repo" symbolic-ref --quiet refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||' || true)"
    if [[ -z "$default" ]]; then
      for candidate in build/saas fury main master; do
        if git -C "$repo" show-ref --verify --quiet "refs/remotes/origin/$candidate" 2>/dev/null \
          || git -C "$repo" show-ref --verify --quiet "refs/heads/$candidate" 2>/dev/null; then
          default="$candidate"
          break
        fi
      done
    fi
    printf '%s' "${default:-$head}"
  else
    printf '%s' "$head"
  fi
}

tmpdir="$(mktemp)"
trap 'rm -f "$tmpdir"' EXIT

{
  echo -e "path\tbranch\tremote\tgroup"
  for root in "$CODE_ROOT" "$PERSONAL_ROOT"; do
    [[ -d "$root" ]] || continue
    find "$root" -maxdepth 4 -type d -name .git 2>/dev/null | sed 's|/.git$||' | sort | while read -r repo; do
      remote="$(git -C "$repo" remote get-url origin 2>/dev/null || true)"
      [[ -n "$remote" ]] || continue
      remote="$(normalize_remote "$remote")"
      head="$(git -C "$repo" rev-parse --abbrev-ref HEAD 2>/dev/null || echo main)"
      group="$(classify "$remote")"
      branch="$(stable_branch "$repo" "$head" "$group")"

      # Path relative to $HOME when under home; else absolute-looking under work/personal labels
      rel="${repo#"$HOME"/}"
      printf '%s\t%s\t%s\t%s\n' "$rel" "$branch" "$remote" "$group"
    done
  done
} > "$tmpdir"

# Deduplicate by path (keep first)
awk -F'\t' 'NR==1 {print; next} !seen[$1]++' "$tmpdir" > "$OUT"
echo "Wrote $OUT ($(tail -n +2 "$OUT" | wc -l) repos)"
