#!/usr/bin/env bash
# Extract work-extras-*.tgz produced by export-work-extras.sh / export-secrets.sh
set -euo pipefail

ARCHIVE="${1:-}"
if [[ -z "$ARCHIVE" || ! -f "$ARCHIVE" ]]; then
  echo "Usage: $0 <work-extras-XXXX.tgz>" >&2
  exit 1
fi

echo "==> Extracting $ARCHIVE → $HOME"
tar xzf "$ARCHIVE" -C "$HOME"
echo "==> Done. Symlinks (default_configs, docker-compose) return after clone-repos + link.sh"
