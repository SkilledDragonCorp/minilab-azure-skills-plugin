import { describe, expect, test } from "bun:test";
import { join } from "node:path";

const ROOT = join(import.meta.dir, "..");

describe("lab .claude/skills frontmatter", () => {
  test("azure-skills-host passes check:skills", async () => {
    const proc = Bun.spawn(
      ["bun", "run", "scripts/check-skills-frontmatter.ts"],
      {
        cwd: ROOT,
        stdout: "pipe",
        stderr: "pipe",
      },
    );
    const code = await proc.exited;
    const out =
      (await new Response(proc.stdout).text()) +
      (await new Response(proc.stderr).text());
    expect(code).toBe(0);
    expect(out).toContain("azure-skills-host");
  });
});
