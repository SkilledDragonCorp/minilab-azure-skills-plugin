#!/usr/bin/env bash
# Install azure-prepare from the pinned local clone into .claude/skills/ only.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if [[ ! -d "$ROOT/vendor/azure-skills/.git" ]]; then
  bash "$ROOT/scripts/vendor-upstream.sh"
fi

SKILLS_SRC="$ROOT/vendor/azure-skills/.github/plugins/azure-skills/skills"
if [[ ! -f "$SKILLS_SRC/azure-prepare/SKILL.md" ]]; then
  echo "Missing $SKILLS_SRC/azure-prepare/SKILL.md" >&2
  exit 1
fi

export DISABLE_TELEMETRY=1
export DO_NOT_TRACK=1

# Exact skills CLI install (pinned). -a claude-code writes .claude/skills only.
DISABLE_TELEMETRY=1 bun --bun x skills@1.7.2 add \
  ./vendor/azure-skills/.github/plugins/azure-skills/skills \
  --skill azure-prepare \
  -a claude-code \
  -y \
  --copy

if [[ -e "$ROOT/.agents/skills" ]]; then
  echo "Forbidden mirror created: .agents/skills" >&2
  exit 1
fi
if [[ -e "$ROOT/.cursor/skills" ]]; then
  echo "Forbidden mirror created: .cursor/skills" >&2
  exit 1
fi

TARGET="$ROOT/.claude/skills/azure-prepare/SKILL.md"
if [[ ! -f "$TARGET" ]]; then
  echo "Expected $TARGET after skills CLI install" >&2
  exit 1
fi

echo "install-azure-prepare: OK -> $TARGET"
