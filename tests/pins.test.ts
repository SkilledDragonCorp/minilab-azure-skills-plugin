import { describe, expect, test } from "bun:test";
import { readFileSync } from "node:fs";
import { join } from "node:path";
import {
  AZURE_SKILLS_PIN,
  AZURE_SKILLS_PIN_SHORT,
  CLAUDE_CODE_VERSION,
  EXPECTED_SKILL_MD_COUNT,
  EXPECTED_SKILL_MD_NO_FRONTMATTER,
  EXPECTED_SKILL_MD_WITH_FRONTMATTER,
  SKILLS_CLI_VERSION,
  THESIS_LABEL,
} from "../src/pins.ts";

const ROOT = join(import.meta.dir, "..");

describe("lab pins", () => {
  test("pin constants match scripts", () => {
    const vendor = readFileSync(join(ROOT, "scripts/vendor-upstream.sh"), "utf8");
    const validate = readFileSync(join(ROOT, "scripts/validate-all-skills.sh"), "utf8");
    const install = readFileSync(join(ROOT, "scripts/install-azure-prepare.sh"), "utf8");
    const e2e = readFileSync(join(ROOT, "scripts/upstream-e2e-claude.sh"), "utf8");

    expect(vendor).toContain(AZURE_SKILLS_PIN);
    expect(vendor).toContain(AZURE_SKILLS_PIN_SHORT);
    expect(validate).toContain(`EXPECTED=${EXPECTED_SKILL_MD_COUNT}`);
    expect(validate).toContain(`EXPECTED_WITH_FM=${EXPECTED_SKILL_MD_WITH_FRONTMATTER}`);
    expect(validate).toContain(`EXPECTED_NO_FM=${EXPECTED_SKILL_MD_NO_FRONTMATTER}`);

    expect(install).toContain(`skills@${SKILLS_CLI_VERSION}`);
    expect(install).toContain("-a claude-code");
    expect(install).toContain("--copy");
    expect(e2e).toContain(`@anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}`);
    expect(e2e).toContain('NPM_CONFIG_REGISTRY="https://registry.npmjs.org"');
    expect(e2e).toContain('npm_config_registry="https://registry.npmjs.org"');
    // Executable registry must be public npm; strip comments before ban-check.
    const e2eCode = e2e
      .split("\n")
      .filter((line) => !line.trimStart().startsWith("#"))
      .join("\n");
    expect(e2eCode).not.toMatch(/packagefeedproxy\.microsoft\.io/);
  });

  test("README states thesis is our label", () => {
    const readme = readFileSync(join(ROOT, "README.md"), "utf8");
    expect(readme).toContain(THESIS_LABEL);
    expect(readme.toLowerCase()).toMatch(/our (thesis|label)|skilleddragon framing|ours,/);
  });
});
