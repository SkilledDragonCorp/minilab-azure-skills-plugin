#!/usr/bin/env bash
# Claude Code plugin marketplace E2E from upstream test-installation.yml @ 9bb168c34349
# Lab omits upstream's Microsoft npm registry env override and forces public npm.
#
# Upstream steps mirrored:
#   npm install --global @anthropic-ai/claude-code
#   claude plugin marketplace add "$repo_root"
#   then .github/scripts/test-plugin-installation.js for cli=claude
# Lab pins @anthropic-ai/claude-code@2.1.296 and forces public npm registry.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VENDOR="$ROOT/vendor/azure-skills"
CLAUDE_CODE_PKG="@anthropic-ai/claude-code@2.1.296"
MARKETPLACE_NAME="azure-skills"
WORKDIR="${TMPDIR:-/tmp}/azure-skills-e2e-$$"
# Isolate Claude Code config so a prior user marketplace declaration cannot
# short-circuit "marketplace add" and leave --available empty (local pollution).
# Upstream CI is already a clean runner HOME; this keeps local keyless E2E equivalent.
ISOLATED_HOME="$WORKDIR/home"
mkdir -p "$WORKDIR" "$ISOLATED_HOME"
trap 'rm -rf "$WORKDIR"' EXIT

PLUGINS_FILE="$WORKDIR/repo-plugins.json"
AVAILABLE_FILE="$WORKDIR/available.json"
INSTALLED_FILE="$WORKDIR/installed.json"

export DISABLE_TELEMETRY=1
export DO_NOT_TRACK=1
export AZURE_MCP_COLLECT_TELEMETRY=false
# Explicit public npm only.
export NPM_CONFIG_REGISTRY="https://registry.npmjs.org"
export npm_config_registry="https://registry.npmjs.org"

if [[ ! -d "$VENDOR/.git" ]]; then
  bash "$ROOT/scripts/vendor-upstream.sh"
fi

HEAD="$(git -C "$VENDOR" rev-parse HEAD)"
if [[ "$HEAD" != "9bb168c34349d7a53d24e9033ba8de6df69d9097" ]]; then
  echo "vendor pin mismatch before E2E: $HEAD" >&2
  exit 1
fi

echo "Installing $CLAUDE_CODE_PKG from $NPM_CONFIG_REGISTRY"
# Keep real HOME for npm global prefix; isolate only Claude plugin config below.
npm install --global "$CLAUDE_CODE_PKG"

# Claude plugin commands use isolated HOME (see ISOLATED_HOME above).
export HOME="$ISOLATED_HOME"

repo_root="$(git -C "$VENDOR" rev-parse --show-toplevel)"
claude plugin marketplace add "$repo_root"

claude plugin list --available --json >"$AVAILABLE_FILE"

python3 - "$AVAILABLE_FILE" "$VENDOR" "$MARKETPLACE_NAME" "$PLUGINS_FILE" <<'PY'
import json, sys, pathlib

available_path, vendor, marketplace, out_path = sys.argv[1:5]
data = json.loads(pathlib.Path(available_path).read_text())
if not isinstance(data.get("available"), list):
    raise SystemExit("Claude Code did not return an available plugin list.")

marketplace_plugins = [
    p for p in data["available"] if p.get("marketplaceName") == marketplace
]
if not marketplace_plugins:
    raise SystemExit(
        f"Claude Code did not enumerate any {marketplace} marketplace plugins."
    )

plugins_dir = pathlib.Path(vendor) / ".github" / "plugins"
dirs = sorted(p.name for p in plugins_dir.iterdir() if p.is_dir())
if not dirs:
    raise SystemExit(f"No plugin directories under {plugins_dir}")

repo_plugins = []
for directory in dirs:
    manifest_path = plugins_dir / directory / ".plugin" / "plugin.json"
    manifest = json.loads(manifest_path.read_text())
    name = manifest.get("name")
    if not isinstance(name, str) or not name.strip():
        raise SystemExit(f"Plugin manifest {manifest_path} has no valid name.")
    repo_plugins.append({"directory": directory, "name": name})

names = [p["name"] for p in repo_plugins]
if len(names) != len(set(names)):
    raise SystemExit(f"Duplicate plugin names: {names}")

market_names = {p["name"] for p in marketplace_plugins}
for plugin in repo_plugins:
    if plugin["name"] not in market_names:
        raise SystemExit(
            f"Repository plugin {plugin['directory']} ({plugin['name']}) "
            f"is missing from the {marketplace} marketplace."
        )

pathlib.Path(out_path).write_text(json.dumps(repo_plugins))
print(f"marketplace OK: {len(repo_plugins)} plugins in {marketplace}")
PY

while IFS= read -r plugin_name; do
  [[ -z "$plugin_name" ]] && continue
  claude plugin install "${plugin_name}@${MARKETPLACE_NAME}"
done < <(python3 -c 'import json,sys; print("\n".join(p["name"] for p in json.load(open(sys.argv[1]))))' "$PLUGINS_FILE")

claude plugin list --json >"$INSTALLED_FILE"
python3 - "$INSTALLED_FILE" "$PLUGINS_FILE" "$MARKETPLACE_NAME" <<'PY'
import json, sys, pathlib

installed = json.loads(pathlib.Path(sys.argv[1]).read_text())
repo_plugins = json.loads(pathlib.Path(sys.argv[2]).read_text())
marketplace = sys.argv[3]
if not isinstance(installed, list):
    raise SystemExit("claude did not return an installed plugin list.")

for plugin in repo_plugins:
    plugin_id = f"{plugin['name']}@{marketplace}"
    ok = any(
        p.get("id") == plugin_id and p.get("enabled") is True for p in installed
    )
    if not ok:
        raise SystemExit(f"Plugin {plugin_id} is not installed and enabled.")
    print(f"enabled OK: {plugin_id}")
PY

echo "upstream-e2e-claude: OK (no Microsoft npm registry override)"
