import { readdirSync, readFileSync } from "node:fs";
import { resolve } from "node:path";
import process from "node:process";

const root = process.cwd();
const skillsRoot = resolve(root, "skills");

function read(path) {
  return readFileSync(resolve(root, path), "utf8");
}

function assert(condition, message) {
  if (!condition) {
    throw new Error(message);
  }
}

function frontmatter(markdown, file) {
  const match = /^---\n([\s\S]*?)\n---/.exec(markdown);
  assert(match, `${file} must start with YAML frontmatter.`);
  return match[1];
}

function field(frontmatterText, key) {
  const match = new RegExp(`^${key}:\\s*(.+)$`, "m").exec(frontmatterText);
  return match?.[1]?.trim();
}

function parseRequires(raw) {
  if (!raw || raw === "[]") {
    return [];
  }
  const match = /^\[(.*)\]$/.exec(raw);
  assert(match, `requires must use inline array syntax, received: ${raw}`);
  return match[1]
    .split(",")
    .map((token) => token.trim())
    .filter(Boolean);
}

const readme = read("README.md");
const requiresDoc = read("docs/REQUIRES.md");
const documentedTokens = new Set(
  [...requiresDoc.matchAll(/\| `([^`]+)` \|/g)].map((match) => match[1]),
);

const skillDirs = readdirSync(skillsRoot, { withFileTypes: true })
  .filter((entry) => entry.isDirectory())
  .map((entry) => entry.name)
  .sort();

for (const dir of skillDirs) {
  const file = `skills/${dir}/SKILL.md`;
  const fm = frontmatter(read(file), file);
  const name = field(fm, "name");
  const runtime = field(fm, "runtime");
  const requires = parseRequires(field(fm, "requires"));

  assert(name === dir, `${file} name must match its directory.`);
  assert(["neutral", "hermes", "openclaw"].includes(runtime), `${file} runtime is invalid.`);
  assert(readme.includes(`](${`skills/${dir}/`})`), `${dir} is missing from README.md skill index.`);

  for (const token of requires) {
    assert(documentedTokens.has(token), `${file} uses undocumented requires token: ${token}`);
  }
}

console.log(`Validated ${skillDirs.length} skills.`);
