"use strict";

const path = require("path");

const RULE_NAME = "CORCA004";
const RULE_ALIASES = ["no-plugin-external-links", "plugin-root-link-boundary"];

const FENCE_RE = /^\s{0,3}(```+|~~~+)/;
const INLINE_LINK_RE = /!?\[[^\]]*\]\(([^)]+)\)/g;
const REF_DEF_RE = /^\s{0,3}\[[^\]]+\]:\s*<?([^>\s]+)>?/;

function getFileName(params) {
  return String(params.name || params.fileName || params.filename || "").replace(/\\/g, "/");
}

function parsePluginRoot(fileName) {
  const marker = "/plugins/cwf/";
  const idx = fileName.indexOf(marker);
  if (idx === -1) {
    return "";
  }
  return fileName.slice(0, idx + marker.length - 1);
}

function cleanTarget(raw) {
  let target = raw.trim();
  const hash = target.indexOf("#");
  if (hash !== -1) {
    target = target.slice(0, hash);
  }
  const query = target.indexOf("?");
  if (query !== -1) {
    target = target.slice(0, query);
  }
  return target;
}

function shouldSkip(raw) {
  if (!raw) return true;
  if (/^(https?:|mailto:|data:|javascript:)/i.test(raw)) return true;
  if (raw.startsWith("#")) return true;
  return false;
}

function isTemplateLike(target) {
  return (
    !target ||
    target.includes("{") ||
    target.includes("}") ||
    target.includes("path/to/") ||
    target.includes("label")
  );
}

module.exports = [
  {
    names: [RULE_NAME, ...RULE_ALIASES],
    description: "Links in plugins/cwf docs must not resolve outside plugins/cwf",
    tags: ["links", "boundaries", "plugins"],
    function: function noPluginExternalLinks(params, onError) {
      const fileName = getFileName(params);
      if (!fileName.endsWith(".md")) {
        return;
      }

      const pluginRoot = parsePluginRoot(fileName);
      if (!pluginRoot) {
        return;
      }

      const sourceDir = path.dirname(fileName);
      let inFence = false;

      params.lines.forEach((line, index) => {
        if (FENCE_RE.test(line)) {
          inFence = !inFence;
          return;
        }
        if (inFence) {
          return;
        }

        const targets = [];

        INLINE_LINK_RE.lastIndex = 0;
        let m;
        while ((m = INLINE_LINK_RE.exec(line)) !== null) {
          targets.push((m[1] || "").trim());
        }

        const defMatch = line.match(REF_DEF_RE);
        if (defMatch) {
          targets.push((defMatch[1] || "").trim());
        }

        for (const raw of targets) {
          if (shouldSkip(raw)) {
            continue;
          }

          const target = cleanTarget(raw);
          if (isTemplateLike(target)) {
            continue;
          }

          const resolved = path.resolve(sourceDir, target).replace(/\\/g, "/");
          const root = pluginRoot.replace(/\\/g, "/");
          if (!(resolved === root || resolved.startsWith(root + "/"))) {
            onError({
              lineNumber: index + 1,
              detail: `Link resolves outside plugin root: ${raw}`,
              context: line
            });
          }
        }
      });
    }
  }
];
