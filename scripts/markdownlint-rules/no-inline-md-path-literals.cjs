"use strict";

// Custom markdownlint rule:
// Disallow inline-code document path literals like `docs/x.md`.
// Prefer clickable markdown links like [docs/x.md](docs/x.md).
//
// Scope:
// - prose lines only (fenced code blocks ignored)
// - inline code spans only
// - skips already-linked labels: [`docs/x.md`](docs/x.md)

const RULE_NAME = "CORCA001";
const RULE_ALIAS = "no-inline-md-path-literals";

const FENCE_RE = /^\s{0,3}(```+|~~~+)/;
const INLINE_CODE_RE = /`([^`]+)`/g;
const MD_PATH_RE =
  /^(?:\.{1,2}\/|\/)?[A-Za-z0-9_.-]+(?:\/[A-Za-z0-9_.-]+)*\.md(?:#[A-Za-z0-9._-]+)?$/;

const ROOT_DOCS = new Set([
  "AGENTS.md",
  "CLAUDE.md",
  "README.md",
  "README.ko.md",
  "CHANGELOG.md",
  "cwf-index.md",
  "AI_NATIVE_PRODUCT_TEAM.md",
  "AI_NATIVE_PRODUCT_TEAM.ko.md"
]);

function isLinkableDocPath(content) {
  if (content.includes("*")) {
    return false;
  }
  if (!MD_PATH_RE.test(content)) {
    return false;
  }
  if (content.includes("/")) {
    return true;
  }
  const base = content.split("#")[0];
  return ROOT_DOCS.has(base);
}

module.exports = [
  {
    names: [RULE_NAME, RULE_ALIAS],
    description:
      "Inline-code markdown document paths must be markdown links, not code literals",
    tags: ["links", "accessibility", "style"],
    function: function noInlineMdPathLiterals(params, onError) {
      let inFence = false;

      params.lines.forEach((line, index) => {
        if (FENCE_RE.test(line)) {
          inFence = !inFence;
          return;
        }
        if (inFence) {
          return;
        }

        INLINE_CODE_RE.lastIndex = 0;
        let match;
        while ((match = INLINE_CODE_RE.exec(line)) !== null) {
          const full = match[0];
          const content = match[1].trim();
          if (!isLinkableDocPath(content)) {
            continue;
          }

          const start = match.index;
          const end = start + full.length;
          const prev = start > 0 ? line[start - 1] : "";
          const after = line.slice(end);

          // Already link-wrapped form: [`path.md`](path.md)
          if (prev === "[" && after.startsWith("](")) {
            continue;
          }

          onError({
            lineNumber: index + 1,
            detail: `Inline doc path literal \`${content}\` should be a markdown link: [${content}](${content})`,
            context: line,
            range: [start + 1, full.length]
          });
        }
      });
    }
  }
];
