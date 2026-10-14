#!/usr/bin/env bash
# Cover every SKILL.md under vendor/azure-skills at pin 9bb168c34349 (count=91).
# 85 files ship YAML frontmatter with name + description.
# 6 nested azure-app-onboard phase docs ship as markdown without frontmatter at this pin
# (deploy/prepare/scaffold × plugin tree + root skills/ mirror). Those six are allowlisted
# and checked for a non-empty H1 — they are still counted in the 91.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VENDOR="$ROOT/vendor/azure-skills"
EXPECTED=91
EXPECTED_WITH_FM=85
EXPECTED_NO_FM=6

if [[ ! -d "$VENDOR/.git" ]]; then
  bash "$ROOT/scripts/vendor-upstream.sh"
fi

# Relative paths (from vendor root) for nested phase docs without frontmatter at this pin.
ALLOW_NO_FM=(
  ".github/plugins/azure-skills/skills/azure-app-onboard/deploy/SKILL.md"
  ".github/plugins/azure-skills/skills/azure-app-onboard/prepare/SKILL.md"
  ".github/plugins/azure-skills/skills/azure-app-onboard/scaffold/SKILL.md"
  "skills/azure-app-onboard/deploy/SKILL.md"
  "skills/azure-app-onboard/prepare/SKILL.md"
  "skills/azure-app-onboard/scaffold/SKILL.md"
)

is_allowlisted_no_fm() {
  local rel="$1"
  local a
  for a in "${ALLOW_NO_FM[@]}"; do
    if [[ "$rel" == "$a" ]]; then
      return 0
    fi
  done
  return 1
}

COUNT=0
WITH_FM=0
NO_FM=0
FAILED=0

while IFS= read -r skill; do
  COUNT=$((COUNT + 1))
  rel="${skill#"$VENDOR"/}"
  first="$(head -n 1 "$skill" || true)"
  if [[ "$first" == "---" ]]; then
    WITH_FM=$((WITH_FM + 1))
    if ! bun "$ROOT/scripts/parse-skill-frontmatter.ts" "$skill"; then
      FAILED=1
    fi
  else
    NO_FM=$((NO_FM + 1))
    if ! is_allowlisted_no_fm "$rel"; then
      echo "$skill: missing YAML frontmatter and not in pin allowlist" >&2
      FAILED=1
      continue
    fi
    if ! grep -qE '^# ' "$skill"; then
      echo "$skill: allowlisted phase doc missing H1" >&2
      FAILED=1
      continue
    fi
    echo "OK $skill (no-frontmatter phase doc allowlisted at pin)"
  fi
done < <(find "$VENDOR" -type f -name SKILL.md | sort)

if [[ "$COUNT" -ne "$EXPECTED" ]]; then
  echo "Expected $EXPECTED SKILL.md files at pin; found $COUNT" >&2
  exit 1
fi
if [[ "$WITH_FM" -ne "$EXPECTED_WITH_FM" || "$NO_FM" -ne "$EXPECTED_NO_FM" ]]; then
  echo "Expected $EXPECTED_WITH_FM with frontmatter + $EXPECTED_NO_FM without; got with=$WITH_FM without=$NO_FM" >&2
  exit 1
fi
if [[ "$FAILED" -ne 0 ]]; then
  echo "validate-all-skills: FAILED" >&2
  exit 1
fi

echo "validate-all-skills: OK ($COUNT SKILL.md: $WITH_FM name+description, $NO_FM allowlisted phase docs)"
