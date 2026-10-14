#!/usr/bin/env bun
import { mkdirSync, writeFileSync } from "node:fs";
import { join } from "node:path";

const ROOT = join(import.meta.dir, "..");
const PIN = "9bb168c34349d7a53d24e9033ba8de6df69d9097";

type Step = { name: string; ok: boolean; detail: string; ms: number };

async function run(
  name: string,
  cmd: string[],
): Promise<Step> {
  const start = performance.now();
  const proc = Bun.spawn(cmd, {
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
  const out = (await new Response(proc.stdout).text()) + (await new Response(proc.stderr).text());
  return {
    name,
    ok: code === 0,
    detail: out.trim().split("\n").slice(-3).join(" | "),
    ms: Math.round(performance.now() - start),
  };
}

const steps: Step[] = [];
steps.push(await run("vendor", ["bash", "scripts/vendor-upstream.sh"]));
steps.push(await run("validate-all-skills", ["bash", "scripts/validate-all-skills.sh"]));
steps.push(await run("check:skills", ["bun", "run", "scripts/check-skills-frontmatter.ts"]));
steps.push(await run("bun test", ["bun", "test", "./tests"]));

const ok = steps.every((s) => s.ok);
const report = {
  pin: PIN,
  ok,
  thesisLabel: "skills survive model swaps (SkilledDragon framing — not an upstream slogan)",
  steps,
};

const reportsDir = join(ROOT, "reports");
mkdirSync(reportsDir, { recursive: true });
writeFileSync(join(reportsDir, "lab.json"), JSON.stringify(report, null, 2) + "\n");

const md = [
  "# Lab report",
  "",
  `- Pin: \`${PIN}\``,
  `- OK: ${ok}`,
  `- Thesis label (ours): skills survive model swaps`,
  "",
  "| Step | Result | ms |",
  "| --- | --- | --- |",
  ...steps.map((s) => `| ${s.name} | ${s.ok ? "pass" : "FAIL"} | ${s.ms} |`),
  "",
].join("\n");
writeFileSync(join(reportsDir, "lab.md"), md);

console.log(md);
if (!ok) process.exit(1);
