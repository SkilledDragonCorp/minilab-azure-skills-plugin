import { describe, expect, test } from "bun:test";
import { join } from "node:path";
import {
  EXPECTED_SKILL_MD_COUNT,
  EXPECTED_SKILL_MD_NO_FRONTMATTER,
  EXPECTED_SKILL_MD_WITH_FRONTMATTER,
} from "../src/pins.ts";

const ROOT = join(import.meta.dir, "..");

describe("validate-all-skills", () => {
  test(
    `vendored tree covers all ${EXPECTED_SKILL_MD_COUNT} SKILL.md at pin`,
    async () => {
      const proc = Bun.spawn(["bash", "scripts/validate-all-skills.sh"], {
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
      expect(out).toContain(
        `validate-all-skills: OK (${EXPECTED_SKILL_MD_COUNT} SKILL.md: ${EXPECTED_SKILL_MD_WITH_FRONTMATTER} name+description, ${EXPECTED_SKILL_MD_NO_FRONTMATTER} allowlisted phase docs)`,
      );
    },
    120_000,
  );
});
