#!/usr/bin/env bash
# Pack secrets + AWS/kube/nuget/ssh/gpg from THIS machine for transfer to WSL.
# Output is encrypted if gpg recipient is set, otherwise a private tarball.
#
# Usage:
#   ./bin/export-secrets.sh
#   GPG_RECIPIENT=you@example.com ./bin/export-secrets.sh
#
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="${DOTFILES_SECRETS_OUT:-$ROOT/secrets}"
STAMP="$(date +%Y%m%d-%H%M%S)"
STAGE="$OUT_DIR/stage-$STAMP"
ARCHIVE="$OUT_DIR/ec2-secrets-$STAMP.tgz"

mkdir -p "$STAGE"

copy_tree() {
  local src="$1"
  local dest="$2"
  if [[ -e "$src" ]]; then
    mkdir -p "$(dirname "$dest")"
    cp -a "$src" "$dest"
    echo "  + $src"
  else
    echo "  - skip missing $src"
  fi
}

echo "==> Staging secrets into $STAGE"
copy_tree "$HOME/.ssh" "$STAGE/ssh"
copy_tree "$HOME/.aws" "$STAGE/aws"
copy_tree "$HOME/.gnupg" "$STAGE/gnupg"
copy_tree "$HOME/.kube" "$STAGE/kube"
copy_tree "$HOME/.nuget/NuGet/NuGet.Config" "$STAGE/nuget/NuGet.Config"
copy_tree "$HOME/.npmrc" "$STAGE/npmrc"
copy_tree "$HOME/.password-store" "$STAGE/password-store"

# Sensitive work scripts that must NOT go in the plain work-extras archive
copy_tree "$HOME/work/scripts/myPatTokens.json" "$STAGE/work-scripts/myPatTokens.json"
copy_tree "$HOME/work/scripts/cookie.txt" "$STAGE/work-scripts/cookie.txt"

# Optional: full WorkEnv freeze for perfect pip restore
if [[ -x "$HOME/.virtualenvs/WorkEnv/bin/pip" ]]; then
  echo "==> Freezing WorkEnv pip packages"
  "$HOME/.virtualenvs/WorkEnv/bin/pip" freeze > "$STAGE/requirements-workenv.full.txt"
fi

echo "==> Creating archive $ARCHIVE"
tar czf "$ARCHIVE" -C "$STAGE" .
rm -rf "$STAGE"

# Also pack curated non-git work extras (docs, helpers, small projects)
if [[ "${SKIP_WORK_EXTRAS:-0}" != "1" ]]; then
  echo "==> Packing work extras alongside secrets"
  bash "$ROOT/bin/export-work-extras.sh"
fi

if [[ -n "${GPG_RECIPIENT:-}" ]]; then
  echo "==> Encrypting for $GPG_RECIPIENT"
  gpg --yes --encrypt --recipient "$GPG_RECIPIENT" --output "${ARCHIVE}.gpg" "$ARCHIVE"
  shred -u "$ARCHIVE" 2>/dev/null || rm -f "$ARCHIVE"
  echo "==> Wrote ${ARCHIVE}.gpg"
  echo "    Transfer that file ONLY. Import with: ./bin/import-secrets.sh ${ARCHIVE}.gpg"
else
  echo "==> Wrote $ARCHIVE"
  echo "    WARNING: unencrypted. Prefer GPG_RECIPIENT=... or move via a private channel."
  echo "    Import with: ./bin/import-secrets.sh $ARCHIVE"
fi

echo "==> scp both archives from $OUT_DIR :"
echo "      ec2-secrets-*.tgz   (keys/creds + PAT/cookie)"
echo "      work-extras-*.tgz   (non-git keepers under ~/work)"
