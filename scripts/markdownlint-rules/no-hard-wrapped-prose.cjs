"use strict";

// Custom markdownlint rule:
// Disallow hard-wrapped prose paragraphs.
// If MD013 (line-length) is disabled, this rule keeps paragraph prose on one line
// unless the break is structural (list/table/code/etc.) or explicitly intentional
// (two trailing spaces or <br>).

const RULE_NAME = "CORCA002";
const RULE_ALIAS = "no-hard-wrapped-prose";

const FENCE_RE = /^\s{0,3}(```+|~~~+)/;
const HEADING_RE = /^\s{0,3}#{1,6}\s+/;
const LIST_RE = /^\s{0,3}([-+*]|\d+\.)\s+/;
const BLOCKQUOTE_RE = /^\s{0,3}>\s?/;
const HR_RE = /^\s{0,3}((\*\s*){3,}|(-\s*){3,}|(_\s*){3,})$/;
const TABLE_ROW_RE = /^\s*\|/;
const TABLE_DELIM_RE = /^\s*:?-{3,}:?\s*(\|\s*:?-{3,}:?\s*)+$/;
const INDENTED_CODE_RE = /^( {4,}|\t)\S/;
const LINK_DEF_RE = /^\s{0,3}\[[^\]]+\]:\s+\S+/;
const HTML_RE = /^\s*</;
const SETEXT_RE = /^\s{0,3}(=+|-+)\s*$/;
const BR_RE = /<br\s*\/?>\s*$/i;

function isStructuralLine(line) {
  const trimmed = line.trim();
  if (!trimmed) {
    return true;
  }
  return (
    HEADING_RE.test(line) ||
    LIST_RE.test(line) ||
    BLOCKQUOTE_RE.test(line) ||
    HR_RE.test(trimmed) ||
    TABLE_ROW_RE.test(line) ||
    TABLE_DELIM_RE.test(trimmed) ||
    INDENTED_CODE_RE.test(line) ||
    LINK_DEF_RE.test(line) ||
    HTML_RE.test(line) ||
    SETEXT_RE.test(trimmed)
  );
}

function isIntentionalSoftBreak(line) {
  return /  $/.test(line) || BR_RE.test(line.trimEnd());
}

module.exports = [
  {
    names: [RULE_NAME, RULE_ALIAS],
    description:
      "Prose paragraphs should not be hard-wrapped across multiple lines",
    tags: ["line_length", "readability", "style"],
    function: function noHardWrappedProse(params, onError) {
      let inFence = false;
      let inFrontmatter = false;
      let prevProseLine = null;

      params.lines.forEach((line, index) => {
        const lineNo = index + 1;

        // Frontmatter (only if the document starts with ---)
        if (lineNo === 1 && line.trim() === "---") {
          inFrontmatter = true;
          prevProseLine = null;
          return;
        }
        if (inFrontmatter) {
          if (line.trim() === "---") {
            inFrontmatter = false;
          }
          prevProseLine = null;
          return;
        }

        if (FENCE_RE.test(line)) {
          inFence = !inFence;
          prevProseLine = null;
          return;
        }
        if (inFence) {
          prevProseLine = null;
          return;
        }

        if (isStructuralLine(line)) {
          prevProseLine = null;
          return;
        }

        // At this point, the line is prose.
        if (
          prevProseLine &&
          !isIntentionalSoftBreak(prevProseLine.text) &&
          !isIntentionalSoftBreak(line)
        ) {
          onError({
            lineNumber: lineNo,
            detail:
              "Hard-wrapped prose detected; keep each prose paragraph on a single line",
            context: line
          });
        }

        prevProseLine = { lineNo, text: line };
      });
    }
  }
];
