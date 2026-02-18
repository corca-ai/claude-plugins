"use strict";

// Custom markdownlint rule:
// Validate SKILL.md frontmatter against Agent Skills spec-oriented keys,
// while enforcing a portability-safe subset for multi-runtime compatibility.
// Convention doc: skill-conventions.md §Frontmatter (single-line description, allowed keys)

const fs = require("fs");

const RULE_NAME = "CORCA003";
const RULE_ALIASES = ["skill-frontmatter-schema", "skill-frontmatter-portability"];

// allowed-tools is experimental in the spec, so it is accepted by the linter.
const ALLOWED_TOP_LEVEL_KEYS = new Set([
  "name",
  "description",
  "argument-hint",
  "compatibility",
  "disable-model-invocation",
  "license",
  "metadata",
  "user-invokable",
  "allowed-tools"
]);

const NAME_RE = /^[a-z0-9](?:[a-z0-9-]{0,62}[a-z0-9])?$/;

function getFileName(params) {
  return String(params.name || params.fileName || params.filename || "").replace(/\\/g, "/");
}

function isSkillFile(params) {
  const fileName = getFileName(params);
  return /(^|\/)SKILL\.md$/i.test(fileName);
}

function stripWrappingQuotes(value) {
  const trimmed = value.trim();
  if (
    (trimmed.startsWith('"') && trimmed.endsWith('"')) ||
    (trimmed.startsWith("'") && trimmed.endsWith("'"))
  ) {
    return trimmed.slice(1, -1).trim();
  }
  return trimmed;
}

module.exports = [
  {
    names: [RULE_NAME, ...RULE_ALIASES],
    description: "SKILL.md frontmatter must follow supported keys and portable field shapes",
    tags: ["frontmatter", "skills", "metadata"],
    function: function skillFrontmatterSchema(params, onError) {
      const fileName = getFileName(params);
      if (!isSkillFile(params) || !fileName || !fs.existsSync(fileName)) {
        return;
      }

      const raw = fs.readFileSync(fileName, "utf8");
      const fmMatch = raw.match(/^---\n([\s\S]*?)\n---\n/);
      if (!fmMatch) {
        onError({
          lineNumber: 1,
          detail: "SKILL.md must start with YAML frontmatter delimiter (---)"
        });
        return;
      }

      const lines = fmMatch[1].split("\n");

      let hasName = false;
      let hasDescription = false;

      for (let i = 0; i < lines.length; i += 1) {
        const line = lines[i];

        if (!line.trim() || /^\s*#/.test(line)) {
          continue;
        }

        // Nested YAML content belongs to the previous key.
        if (/^\s+/.test(line)) {
          continue;
        }

        const match = line.match(/^([A-Za-z0-9-]+):(.*)$/);
        if (!match) {
          onError({
            lineNumber: 1,
            detail: `Frontmatter line ${i + 2}: malformed entry (expected key: value)`,
            context: line
          });
          continue;
        }

        const key = match[1];
        const rawValue = match[2] || "";

        if (!ALLOWED_TOP_LEVEL_KEYS.has(key)) {
          onError({
            lineNumber: 1,
            detail:
              `Frontmatter line ${i + 2}: unsupported SKILL frontmatter key: ` +
              key +
              ". Allowed: argument-hint, compatibility, description, " +
              "disable-model-invocation, license, metadata, name, " +
              "user-invokable, allowed-tools",
            context: line
          });
          continue;
        }

        if (key === "name") {
          hasName = true;
          const name = stripWrappingQuotes(rawValue);
          if (!name) {
            onError({
              lineNumber: 1,
              detail: `Frontmatter line ${i + 2}: name must not be empty`,
              context: line
            });
          } else if (!NAME_RE.test(name)) {
            onError({
              lineNumber: 1,
              detail:
                `Frontmatter line ${i + 2}: name must be lower-kebab-case, 1-64 chars, no leading/trailing hyphen`,
              context: line
            });
          }
        }

        if (key === "description") {
          hasDescription = true;
          const value = rawValue.trim();
          if (value === "|" || value === ">") {
            onError({
              lineNumber: 1,
              detail:
                `Frontmatter line ${i + 2}: use single-line description for runtime portability (avoid block scalar | or >)`,
              context: line
            });
          }
          if (!stripWrappingQuotes(value)) {
            onError({
              lineNumber: 1,
              detail: `Frontmatter line ${i + 2}: description must not be empty`,
              context: line
            });
          }
        }
      }

      if (!hasName) {
        onError({
          lineNumber: 1,
          detail: "SKILL.md frontmatter requires name"
        });
      }

      if (!hasDescription) {
        onError({
          lineNumber: 1,
          detail: "SKILL.md frontmatter requires description"
        });
      }
    }
  }
];
