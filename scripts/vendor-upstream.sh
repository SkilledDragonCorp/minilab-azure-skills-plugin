#!/usr/bin/env bash
# Clone microsoft/azure-skills at the lab pin (script-cloned; vendor/ is gitignored).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PIN="9bb168c34349d7a53d24e9033ba8de6df69d9097"
SHORT_PIN="9bb168c34349"
DEST="$ROOT/vendor/azure-skills"

mkdir -p "$ROOT/vendor"

if [[ -d "$DEST/.git" ]]; then
  git -C "$DEST" fetch --depth 1 origin "$PIN" 2>/dev/null \
    || git -C "$DEST" fetch origin "$PIN"
  git -C "$DEST" checkout --force "$PIN"
else
  rm -rf "$DEST"
  git clone https://github.com/microsoft/azure-skills.git "$DEST"
  git -C "$DEST" checkout "$PIN"
fi

HEAD="$(git -C "$DEST" rev-parse HEAD)"
if [[ "$HEAD" != "$PIN" ]]; then
  echo "vendor pin mismatch: expected $PIN got $HEAD" >&2
  exit 1
fi

echo "vendor/azure-skills @ $HEAD (pin $SHORT_PIN)"
