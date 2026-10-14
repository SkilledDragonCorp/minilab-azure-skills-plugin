# minilab-azure-skills-plugin

**Built by [SkilledDragon LLC](https://skilleddragon.com)** — architecture-led software engineering · [skilleddragon.com](https://skilleddragon.com)

Vendors [microsoft/azure-skills](https://github.com/microsoft/azure-skills) at SHA `9bb168c34349`, validates all **91** `SKILL.md` files, installs `azure-prepare` via pinned `skills@1.7.2` into `.claude/skills/` only, and runs the Claude Code plugin marketplace E2E from upstream `test-installation.yml` **without** the Microsoft npm registry override.

**Thesis label (ours):** *skills survive model swaps*. That phrase is SkilledDragon framing — not an upstream slogan. Skills are portable files you can keep when the model underneath changes.

## What we built

| Piece | Purpose |
| --- | --- |
| `scripts/vendor-upstream.sh` | Clone microsoft/azure-skills @ `9bb168c34349` into `vendor/` (gitignored) |
| `scripts/validate-all-skills.sh` | Cover all 91 `SKILL.md` at the pin: 85 with `name`+`description`; 6 nested `azure-app-onboard` phase docs lack frontmatter upstream and are allowlisted |
| `scripts/install-azure-prepare.sh` | `skills@1.7.2` copy install of `azure-prepare` with `-a claude-code` |
| `scripts/upstream-e2e-claude.sh` | Claude marketplace add/list/install/enable checks; public npm only |
| `.claude/skills/azure-skills-host/` | Meta-skill: Cursor vs Claude Code host wiring |
| CI | Bun tests, gitleaks 8.30.1, bun audit, osv-scanner 2.7.0, mirror ban |

## Setup

- **Node** `>=24` (`.nvmrc` → `24`)
- **Bun** `>=1.2.0`

```bash
cp .env.example .env
bun install
bash scripts/vendor-upstream.sh
```

## Tutorial

1. Validate all upstream skills at the pin:

```bash
bash scripts/validate-all-skills.sh
```

2. Install one skill from the local clone into `.claude/skills/` only:

```bash
DISABLE_TELEMETRY=1 bun --bun x skills@1.7.2 add \
  ./vendor/azure-skills/.github/plugins/azure-skills/skills \
  --skill azure-prepare -a claude-code -y --copy
```

3. Run Bun tests (includes install + 91-skill validation):

```bash
bun test
```

4. Claude marketplace E2E (installs `@anthropic-ai/claude-code@2.1.296`, no Microsoft registry):

```bash
bash scripts/upstream-e2e-claude.sh
```

## Test results (local, Oct 13 2026)

```text
$ bun install && bun test && bun run check:skills && bun audit
$ bash scripts/validate-all-skills.sh
$ bash scripts/install-azure-prepare.sh
$ bash scripts/upstream-e2e-claude.sh
$ gitleaks detect --source . --redact --no-banner --config .gitleaks.toml

bun test v1.4.3
 5 pass
 0 fail
Ran 5 tests across 4 files.

validate-all-skills: OK (91 SKILL.md: 85 name+description, 6 allowlisted phase docs)
install-azure-prepare: OK -> .claude/skills/azure-prepare/SKILL.md
upstream-e2e-claude: OK (6 plugins installed+enabled; public npm only)
bun audit: No vulnerabilities found
gitleaks 8.30.1: no leaks found
osv-scanner 2.7.0 on landing-page/package-lock.json: No issues found
```

## Using these skills in Claude Code and Cursor

- **Claude Code:** open this repo as the project root. Lab meta-skill: `.claude/skills/azure-skills-host/`. After `install-azure-prepare.sh`, `azure-prepare` lives under `.claude/skills/azure-prepare/`. Marketplace path: `bash scripts/upstream-e2e-claude.sh`.
- **Cursor:** same `.claude/skills/` paths. Do not create `.agents/skills` or `.cursor/skills` mirrors — CI fails if they exist.

## API keys

| Variable | Required for CI | Where | Notes |
| --- | --- | --- | --- |
| none | keyless path | — | 91-skill validation + skills CLI + Claude marketplace E2E need no Azure credentials |
| `AZURE_TENANT_ID` / `AZURE_CLIENT_ID` / `AZURE_CLIENT_SECRET` / `AZURE_SUBSCRIPTION_ID` | optional live MCP only | Azure AD app registration | Prefer `az login` / OIDC with Reader role over client secrets |
| `AZURE_MCP_COLLECT_TELEMETRY` | set `false` | env | Disables upstream telemetry hooks |
| `DISABLE_TELEMETRY` / `DO_NOT_TRACK` | set `1` | env | Lab + CLI hygiene |

See `.env.example`.

## Security

See [SECURITY.md](SECURITY.md). Contact: **hello@skilleddragon.com** only.

## License

MIT — see [LICENSE](LICENSE). Upstream [microsoft/azure-skills](https://github.com/microsoft/azure-skills) is licensed separately (MIT at this pin).
