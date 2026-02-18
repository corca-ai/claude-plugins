"use strict";

// Custom markdownlint rule:
// Enforce SKILL.md skeleton policy and global language-contract shape.
//
// Policy:
// - SKILL.md must include `## Quick Start` or `## Quick Reference`
// - SKILL.md must include `## Rules` and `## References`
// - `## Rules` must appear before `## References`
// - Top-level `**Language**:` declarations are disallowed
//   (language exceptions belong in `## Rules`)

const fs = require("fs");

const RULE_NAME = "CORCA005";
const RULE_ALIASES = [
  "skill-skeleton-language-contract",
  "no-skill-inline-language-section"
];

function getFileName(params) {
  return String(params.name || params.fileName || params.filename || "").replace(/\\/g, "/");
}

function isSkillFile(params) {
  const fileName = getFileName(params);
  return /(^|\/)SKILL\.md$/i.test(fileName);
}

module.exports = [
  {
    names: [RULE_NAME, ...RULE_ALIASES],
    description: "SKILL.md must follow skeleton order and global language-contract shape",
    tags: ["skills", "structure", "language-contract"],
    function: function skillSkeletonLanguageContract(params, onError) {
      const fileName = getFileName(params);
      if (!isSkillFile(params) || !fileName || !fs.existsSync(fileName)) {
        return;
      }

      const raw = fs.readFileSync(fileName, "utf8");
      const lines = raw.split(/\r?\n/);

      let firstH2Line = 0;
      let quickLine = 0;
      let rulesLine = 0;
      let refsLine = 0;

      for (let i = 0; i < lines.length; i += 1) {
        const line = lines[i];

        if (!firstH2Line && /^##\s+/.test(line)) {
          firstH2Line = i + 1;
        }
        if (!quickLine && /^##\s+Quick (Start|Reference)\b/.test(line)) {
          quickLine = i + 1;
        }
        if (!rulesLine && /^##\s+Rules\s*$/.test(line)) {
          rulesLine = i + 1;
        }
        if (!refsLine && /^##\s+References\s*$/.test(line)) {
          refsLine = i + 1;
        }
      }

      const topScanLimit = firstH2Line > 0 ? firstH2Line - 1 : lines.length;
      for (let i = 0; i < topScanLimit; i += 1) {
        if (/^\*\*Language\*\*:\s*/.test(lines[i])) {
          onError({
            lineNumber: i + 1,
            detail:
              "Top-level `**Language**:` declaration is disallowed in SKILL.md. " +
              "Use the global language contract and put skill-specific overrides under `## Rules`."
          });
          break;
        }
      }

      if (!quickLine) {
        onError({
          lineNumber: 1,
          detail: "SKILL.md must include `## Quick Start` or `## Quick Reference`."
        });
      }

      if (!rulesLine) {
        onError({
          lineNumber: 1,
          detail: "SKILL.md must include a `## Rules` section."
        });
      }

      if (!refsLine) {
        onError({
          lineNumber: 1,
          detail: "SKILL.md must include a `## References` section."
        });
      }

      if (rulesLine && refsLine && rulesLine >= refsLine) {
        onError({
          lineNumber: rulesLine,
          detail: "`## Rules` must appear before `## References` in SKILL.md."
        });
      }
    }
  }
];
