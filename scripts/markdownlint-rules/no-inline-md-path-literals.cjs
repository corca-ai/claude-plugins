"use strict";

// Custom markdownlint rule:
// Disallow inline-code repository path literals like `docs/x.md` or
// `plugins/cwf/hooks/hooks.json`. Prefer clickable markdown links.
//
// Scope:
// - prose lines only (fenced code blocks ignored)
// - inline code spans only
// - skips already-linked labels: [`path`](path)

const path = require("path");
const fs = require("fs");

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

const README_INLINE_PATH_EXEMPT = new Set(["README.md", "README.ko.md"]);
const README_INLINE_PATH_EXEMPT_ABS = new Set(
  ["README.md", "README.ko.md"].map((p) => path.resolve(process.cwd(), p))
);
const RUNTIME_PATH_CACHE = new Map();

function isReadmeInlinePathExempt(fileName) {
  if (!fileName) {
    return false;
  }
  if (README_INLINE_PATH_EXEMPT.has(fileName)) {
    return true;
  }

  const withoutDotPrefix = fileName.replace(/^\.\//, "");
  if (README_INLINE_PATH_EXEMPT.has(withoutDotPrefix)) {
    return true;
  }

  return README_INLINE_PATH_EXEMPT_ABS.has(path.resolve(fileName));
}

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

function escapeRegex(value) {
  return String(value).replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

function normalizeAbsPath(value) {
  return path
    .normalize(value)
    .replace(/\\/g, "/")
    .replace(/\/+$/, "");
}

function findRepoRoot(fileName) {
  let current = path.resolve(fileName || process.cwd());

  if (path.extname(current)) {
    current = path.dirname(current);
  }

  while (true) {
    if (
      fs.existsSync(path.join(current, ".git")) ||
      fs.existsSync(path.join(current, ".cwf"))
    ) {
      return current;
    }
    const parent = path.dirname(current);
    if (parent === current) {
      break;
    }
    current = parent;
  }

  return process.cwd();
}

function readYamlScalar(filePath, key) {
  if (!fs.existsSync(filePath)) {
    return "";
  }
  const escaped = escapeRegex(key);
  const re = new RegExp(`^\\s*${escaped}\\s*:\\s*(.+)$`);
  const lines = fs.readFileSync(filePath, "utf8").split(/\r?\n/);

  for (const line of lines) {
    const match = line.match(re);
    if (!match) {
      continue;
    }
    let value = match[1].trim();
    const isQuoted =
      (value.startsWith('"') && value.endsWith('"')) ||
      (value.startsWith("'") && value.endsWith("'"));
    if (!isQuoted) {
      value = value.replace(/\s+#.*$/, "").trim();
    }
    if (
      (value.startsWith('"') && value.endsWith('"')) ||
      (value.startsWith("'") && value.endsWith("'"))
    ) {
      value = value.slice(1, -1);
    }
    return value;
  }

  return "";
}

function resolveConfigValue(repoRoot, key) {
  const localCfg = path.join(repoRoot, ".cwf", "config.local.yaml");
  const sharedCfg = path.join(repoRoot, ".cwf", "config.yaml");
  const localValue = readYamlScalar(localCfg, key);
  if (localValue) {
    return localValue;
  }
  const sharedValue = readYamlScalar(sharedCfg, key);
  if (sharedValue) {
    return sharedValue;
  }
  if (process.env[key]) {
    return process.env[key];
  }
  return "";
}

function resolveAbsPath(repoRoot, rawPath) {
  if (!rawPath) {
    return "";
  }
  if (path.isAbsolute(rawPath)) {
    return normalizeAbsPath(rawPath);
  }
  return normalizeAbsPath(path.resolve(repoRoot, rawPath));
}

function addRuntimeDir(set, absPath) {
  if (!absPath) {
    return;
  }
  set.add(normalizeAbsPath(absPath));
}

function addRuntimeFile(set, absPath) {
  if (!absPath) {
    return;
  }
  set.add(normalizeAbsPath(absPath));
}

function getRuntimePaths(repoRoot) {
  if (RUNTIME_PATH_CACHE.has(repoRoot)) {
    return RUNTIME_PATH_CACHE.get(repoRoot);
  }

  const dirs = new Set();
  const files = new Set();

  const configuredArtifactRoot = resolveConfigValue(repoRoot, "CWF_ARTIFACT_ROOT");
  const configuredProjectsDir = resolveConfigValue(repoRoot, "CWF_PROJECTS_DIR");
  const configuredStateFile = resolveConfigValue(repoRoot, "CWF_STATE_FILE");
  const configuredLogsDir = resolveConfigValue(repoRoot, "CWF_SESSION_LOG_DIR");
  const configuredPromptLogsDir = resolveConfigValue(repoRoot, "CWF_PROMPT_LOGS_DIR");
  const configuredIndexesDir = resolveConfigValue(repoRoot, "CWF_INDEXES_DIR");

  const artifactRoots = new Set([
    resolveAbsPath(repoRoot, ".cwf"),
    resolveAbsPath(repoRoot, configuredArtifactRoot)
  ]);

  for (const artifactRoot of artifactRoots) {
    if (!artifactRoot) {
      continue;
    }
    addRuntimeDir(dirs, artifactRoot);
    addRuntimeDir(dirs, path.join(artifactRoot, "projects"));
    addRuntimeDir(dirs, path.join(artifactRoot, "sessions"));
    addRuntimeDir(dirs, path.join(artifactRoot, "prompt-logs"));
    addRuntimeDir(dirs, path.join(artifactRoot, "indexes"));
    addRuntimeDir(dirs, path.join(artifactRoot, "projects", "sessions"));
    addRuntimeFile(files, path.join(artifactRoot, "cwf-state.yaml"));
  }

  addRuntimeDir(dirs, resolveAbsPath(repoRoot, configuredProjectsDir));
  addRuntimeFile(files, resolveAbsPath(repoRoot, configuredStateFile));
  addRuntimeDir(dirs, resolveAbsPath(repoRoot, configuredLogsDir));
  addRuntimeDir(dirs, resolveAbsPath(repoRoot, configuredPromptLogsDir));
  addRuntimeDir(dirs, resolveAbsPath(repoRoot, configuredIndexesDir));

  addRuntimeFile(files, path.join(repoRoot, ".cwf", "config.yaml"));
  addRuntimeFile(files, path.join(repoRoot, ".cwf", "config.local.yaml"));

  const runtimePaths = { dirs, files };
  RUNTIME_PATH_CACHE.set(repoRoot, runtimePaths);
  return runtimePaths;
}

function matchesRuntimePath(candidateAbs, runtimePaths) {
  if (runtimePaths.files.has(candidateAbs)) {
    return true;
  }
  for (const runtimeDir of runtimePaths.dirs) {
    if (candidateAbs === runtimeDir || candidateAbs.startsWith(`${runtimeDir}/`)) {
      return true;
    }
  }
  return false;
}

function isSkillRuntimePathLiteral(content, fileName) {
  if (!fileName || !/(^|\/)SKILL\.md$/i.test(fileName)) {
    return false;
  }
  const base = content.split("#")[0].trim();
  if (
    !base ||
    base.includes(" ") ||
    base.includes("{") ||
    base.includes("}") ||
    base.startsWith("~/")
  ) {
    return false;
  }

  const repoRoot = findRepoRoot(fileName);
  const runtimePaths = getRuntimePaths(repoRoot);
  const fileDir = path.dirname(path.resolve(fileName));

  const candidates = [];
  if (path.isAbsolute(base)) {
    candidates.push(normalizeAbsPath(base));
  } else {
    candidates.push(normalizeAbsPath(path.resolve(fileDir, base)));
    candidates.push(normalizeAbsPath(path.resolve(repoRoot, base.replace(/^\.\//, ""))));
  }

  for (const candidate of candidates) {
    if (matchesRuntimePath(candidate, runtimePaths)) {
      return true;
    }
  }
  return false;
}

module.exports = [
  {
    names: [RULE_NAME, ...RULE_ALIASES],
    description:
      "Inline-code repository paths must be markdown links, not code literals",
    tags: ["links", "accessibility", "style"],
    function: function noInlineFilePathLiterals(params, onError) {
      const fileName = String(params.name || params.fileName || params.filename || "")
        .replace(/\\/g, "/")
        .trim();
      if (isReadmeInlinePathExempt(fileName)) {
        return;
      }

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
          if (isSkillRuntimePathLiteral(content, fileName)) {
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
