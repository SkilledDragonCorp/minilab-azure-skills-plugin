# Security Policy

**Built by [SkilledDragon LLC](https://skilleddragon.com)**

This is a **SkilledDragon educational minilab**, not a production product. We do **not** maintain these repos on a regular schedule and we do **not** operate a vulnerability response program for them.

## Contact

General questions: **hello@skilleddragon.com**  
Do not use a dedicated security mailbox for this repo — none exists.

## If you find an issue

- Prefer reporting **upstream** when the issue is in [microsoft/azure-skills](https://github.com/microsoft/azure-skills) or Azure MCP.
- For something specific to this minilab’s scripts or CI, you may email hello@skilleddragon.com. There is **no SLA**, and we may not patch or reply quickly.
- Do not expect private coordinated disclosure or paid bounty handling here.

## Scope / hygiene

This repository vendors a public GitHub pin, validates `SKILL.md` frontmatter, installs one skill via the pinned `skills` CLI, and runs Claude Code marketplace install checks.

- Never commit `.env`, API keys, tokens, or Azure client secrets.
- CI is **keyless**. Live Azure MCP is optional and out of band.
- Set `AZURE_MCP_COLLECT_TELEMETRY=false`. Upstream ships `track-telemetry.sh` hooks on SessionStart/PostToolUse — keep collection off in this lab.
- Also set `DISABLE_TELEMETRY=1` and `DO_NOT_TRACK=1` for CLI tooling.
- When adding Azure MCP, pin `@azure/mcp` to an exact version — never `@latest`.
- Prefer `az login` / OIDC with **Reader** role over `AZURE_CLIENT_SECRET`.
- Do not use Microsoft’s `packagefeedproxy.microsoft.io` npm registry override for the Claude marketplace E2E; use public `registry.npmjs.org`.

Use at your own risk. Pin versions, review the code, and treat this as sample material.
