#!/usr/bin/env bash
# Pack curated non-git work extras for scp to WSL.
#
# Usage:
#   ./bin/export-work-extras.sh
#   ./bin/export-work-extras.sh --include-optional
#
# List: repos/work-extras.txt
# Always excludes: node_modules, .git, dist, build, *.mfdb
#
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LIST="${WORK_EXTRAS_LIST:-$ROOT/repos/work-extras.txt}"
OUT_DIR="${DOTFILES_SECRETS_OUT:-$ROOT/secrets}"
STAMP="$(date +%Y%m%d-%H%M%S)"
STAGE="$OUT_DIR/work-extras-stage-$STAMP"
ARCHIVE="$OUT_DIR/work-extras-$STAMP.tgz"
INCLUDE_OPTIONAL=0

RSYNC_EXCLUDES=(
  --exclude node_modules
  --exclude .git
  --exclude dist
  --exclude build
  --exclude .vite
  --exclude '*.mfdb'
  --exclude everything_unzipped
)

for arg in "$@"; do
  case "$arg" in
    --include-optional) INCLUDE_OPTIONAL=1 ;;
    --help|-h) sed -n '2,14p' "$0"; exit 0 ;;
  esac
done

[[ -f "$LIST" ]] || { echo "Missing $LIST" >&2; exit 1; }

avail_kb="$(df -Pk "$OUT_DIR" | awk 'NR==2 {print $4}')"
if (( avail_kb < 500000 )); then
  echo "!!  Only ${avail_kb}KB free under $OUT_DIR — free disk before exporting." >&2
  echo "    Tip: rm -rf $OUT_DIR/work-extras-stage-*" >&2
  exit 1
fi

mkdir -p "$STAGE"
echo "==> Staging work extras from $LIST (excluding node_modules/.git/dist)"

while IFS= read -r raw || [[ -n "$raw" ]]; do
  line="${raw%%#*}"
  line="$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
  [[ -z "$line" ]] && continue

  src="$HOME/$line"
  [[ "$line" = /* ]] && src="$line"

  if [[ ! -e "$src" ]]; then
    echo "  - missing $line"
    continue
  fi

  rel="${src#"$HOME"/}"
  dest="$STAGE/$rel"
  mkdir -p "$(dirname "$dest")"

  if [[ -d "$src" ]]; then
    mkdir -p "$dest"
    rsync -a "${RSYNC_EXCLUDES[@]}" "$src"/ "$dest"/
  else
    cp -a "$src" "$dest"
  fi
  echo "  + $rel ($(du -sh "$dest" | awk '{print $1}'))"
done < "$LIST"

if [[ "$INCLUDE_OPTIONAL" == "1" ]]; then
  echo "==> --include-optional: adding investigations (this will hurt)"
  if [[ -d "$HOME/work/investigations" ]]; then
    mkdir -p "$STAGE/work/investigations"
    rsync -a "${RSYNC_EXCLUDES[@]}" "$HOME/work/investigations"/ "$STAGE/work/investigations"/
  fi
fi

cat > "$STAGE/README-WORK-EXTRAS.txt" <<EOF
Extract over \$HOME on WSL:

  tar xzf work-extras-*.tgz -C \$HOME
  # or: ./bin/import-work-extras.sh work-extras-*.tgz

node_modules were excluded — npm/bun install where needed.
Symlinks like work/default_configs return after clone-repos + link.sh.
EOF

echo "==> Creating $ARCHIVE"
tar czf "$ARCHIVE" -C "$STAGE" .
rm -rf "$STAGE"
echo "==> Wrote $ARCHIVE ($(du -h "$ARCHIVE" | awk '{print $1}'))"
echo "    On WSL: ./bin/import-work-extras.sh $(basename "$ARCHIVE")"
