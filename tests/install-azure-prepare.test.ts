import { describe, expect, test } from "bun:test";
import { existsSync, readFileSync } from "node:fs";
import { join } from "node:path";

const ROOT = join(import.meta.dir, "..");

describe("skills CLI azure-prepare install", () => {
  test(
    "installs into .claude/skills only (no .agents/.cursor mirrors)",
    async () => {
      const proc = Bun.spawn(["bash", "scripts/install-azure-prepare.sh"], {
        cwd: ROOT,
        env: {
          ...process.env,
          DISABLE_TELEMETRY: "1",
          DO_NOT_TRACK: "1",
          AZURE_MCP_COLLECT_TELEMETRY: "false",
        },
        stdout: "pipe",
        stderr: "pipe",
      });
      const code = await proc.exited;
      const out =
        (await new Response(proc.stdout).text()) +
        (await new Response(proc.stderr).text());
      expect(code).toBe(0);
      expect(out).toContain("install-azure-prepare: OK");

      const skill = join(ROOT, ".claude/skills/azure-prepare/SKILL.md");
      expect(existsSync(skill)).toBe(true);
      const body = readFileSync(skill, "utf8");
      expect(body).toContain("name: azure-prepare");
      expect(body).toContain("description:");

      expect(existsSync(join(ROOT, ".agents/skills"))).toBe(false);
      expect(existsSync(join(ROOT, ".cursor/skills"))).toBe(false);
    },
    180_000,
  );
});
