"use strict";

// Custom markdownlint rule:
// Disallow inline-code repository path literals like `docs/x.md` or
// `plugins/cwf/hooks/hooks.json`. Prefer clickable markdown links.
//
// Scope:
// - prose lines only (fenced code blocks ignored)
// - inline code spans only
// - skips already-linked labels: [`path`](path)

const RULE_NAME = "CORCA001";
const RULE_ALIASES = [
  "no-inline-file-path-literals",
  "no-inline-md-path-literals"
];

const FENCE_RE = /^\s{0,3}(```+|~~~+)/;
const INLINE_CODE_RE = /`([^`]+)`/g;
const REPO_PATH_RE =
  /^(?:\.{1,2}\/|\/)?[A-Za-z0-9_.-]+(?:\/[A-Za-z0-9_.-]+)+(?:#[A-Za-z0-9._-]+)?$/;

const ROOT_DOCS = new Set([
  "AGENTS.md",
  "CLAUDE.md",
  "README.md",
  "README.ko.md",
  "CHANGELOG.md",
  "AI_NATIVE_PRODUCT_TEAM.md",
  "AI_NATIVE_PRODUCT_TEAM.ko.md"
]);

function isLinkableRepoPath(content) {
  if (
    content.includes("*") ||
    content.includes("{") ||
    content.includes("}") ||
    content.includes("$") ||
    content.includes(" ") ||
    content.startsWith("~/")
  ) {
    return false;
  }

  if (/^(?:https?|file):\/\//i.test(content)) {
    return false;
  }

  const base = content.split("#")[0];
  if (REPO_PATH_RE.test(base) && /[A-Za-z]/.test(base)) {
    return true;
  }

  return ROOT_DOCS.has(base);
}

module.exports = [
  {
    names: [RULE_NAME, ...RULE_ALIASES],
    description:
      "Inline-code repository paths must be markdown links, not code literals",
    tags: ["links", "accessibility", "style"],
    function: function noInlineFilePathLiterals(params, onError) {
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
          if (!isLinkableRepoPath(content)) {
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
            detail: `Inline file path literal \`${content}\` should be a markdown link: [${content}](${content})`,
            context: line,
            range: [start + 1, full.length]
          });
        }
      });
    }
  }
];
