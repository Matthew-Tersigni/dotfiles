#!/usr/bin/env bash
# Capture a full pip freeze from the live WorkEnv into the repo (for WSL restore).
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PIP="${HOME}/.virtualenvs/WorkEnv/bin/pip"
OUT="$ROOT/python/requirements-workenv.full.txt"

if [[ ! -x "$PIP" ]]; then
  echo "WorkEnv pip not found at $PIP" >&2
  exit 1
fi

"$PIP" freeze > "$OUT"
echo "Wrote $OUT ($(wc -l < "$OUT") packages)"
echo "Commit it if you want perfect restores, or keep it local / in the secrets tarball."
