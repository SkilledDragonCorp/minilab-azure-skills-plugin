#!/usr/bin/env bun
/** Print OK or fail for one SKILL.md: requires frontmatter name + description. */
import { readFileSync } from "node:fs";

const path = process.argv[2];
if (!path) {
  console.error("usage: parse-skill-frontmatter.ts <SKILL.md>");
  process.exit(2);
}

const content = readFileSync(path, "utf8");
const match = content.match(/^---\r?\n([\s\S]*?)\r?\n---/);
if (!match) {
  console.error(`${path}: missing YAML frontmatter`);
  process.exit(1);
}

const fm: Record<string, string> = {};
for (const raw of match[1].split("\n")) {
  const line = raw.trimEnd();
  if (!line || line.startsWith("#") || /^\s/.test(raw)) continue;
  const m = line.match(/^([A-Za-z0-9_-]+):\s*(.*)$/);
  if (!m) continue;
  let value = m[2].trim();
  if (
    (value.startsWith('"') && value.endsWith('"')) ||
    (value.startsWith("'") && value.endsWith("'"))
  ) {
    value = value.slice(1, -1);
  }
  fm[m[1]] = value;
}

if (!fm.name || !fm.description) {
  console.error(
    `${path}: frontmatter must include name and description (got name=${Boolean(fm.name)} description=${Boolean(fm.description)})`,
  );
  process.exit(1);
}

console.log(`OK ${path} (name=${fm.name}, desc=${fm.description.length} chars)`);
