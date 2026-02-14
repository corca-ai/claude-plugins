#!/usr/bin/env node

// doc-graph.mjs — Build and analyze document reference graph from Markdown files
// Usage: doc-graph.mjs [--orphans] [--impact <file>] [--json] [-h|--help]
//   --orphans  List documents with zero inbound links (excluding prompt-logs/)
//   --impact   Given a changed file, list all documents that reference it
//   --json     Output full adjacency list as JSON
//   (default)  Print human-readable summary
// Exit 0 = clean, Exit 1 = orphans or broken refs found

import { readFileSync, existsSync, readdirSync } from 'node:fs';
import { resolve, relative, dirname, extname } from 'node:path';
import { execSync } from 'node:child_process';

const DOC_GRAPH_IGNORE_FILE = '.doc-graph-ignore';

function normalizeRelPath(pathValue) {
  return pathValue.replaceAll('\\\\', '/').replace(/^\.\//, '');
}

function loadIgnoreRules(rootDir) {
  const ignoreFilePath = resolve(rootDir, DOC_GRAPH_IGNORE_FILE);
  if (!existsSync(ignoreFilePath)) {
    return [];
  }

  return readFileSync(ignoreFilePath, 'utf8')
    .split(/\r?\n/)
    .map((line) => line.trim())
    .filter((line) => line && !line.startsWith('#'))
    .map((line) => normalizeRelPath(line.replace(/^\//, '')));
}

function isIgnoredPath(relPath, rules) {
  const normalized = normalizeRelPath(relPath);
  return rules.some((rule) => {
    if (rule.endsWith('/')) {
      return normalized.startsWith(rule);
    }
    return normalized === rule;
  });
}

const args = process.argv.slice(2);
let mode = 'summary';
let impactFile = null;
let jsonOutput = false;

function usage() {
  console.log(`doc-graph.mjs — Build and analyze document reference graph from Markdown files
Usage: doc-graph.mjs [--orphans] [--impact <file>] [--json] [-h|--help]
  --orphans  List documents with zero inbound links
  --impact   Given a changed file, list all documents that reference it
  --json     Output full adjacency list as JSON
  (default)  Print human-readable summary
Exit 0 = clean, Exit 1 = orphans or broken refs found`);
  process.exit(0);
}

for (let i = 0; i < args.length; i += 1) {
  switch (args[i]) {
    case '-h':
    case '--help':
      usage();
      break;
    case '--orphans':
      mode = 'orphans';
      break;
    case '--impact':
      if (i + 1 >= args.length) {
        console.error('Error: --impact requires a file argument');
        process.exit(1);
      }
      mode = 'impact';
      impactFile = args[++i];
      break;
    case '--json':
      jsonOutput = true;
      break;
    default:
      console.error(`Error: Unknown option: ${args[i]}`);
      console.error('Run with --help for usage.');
      process.exit(1);
  }
}

const useColor = process.stdout.isTTY && !jsonOutput;
const RED = useColor ? '\x1b[0;31m' : '';
const GREEN = useColor ? '\x1b[0;32m' : '';
const YELLOW = useColor ? '\x1b[1;33m' : '';
const BOLD = useColor ? '\x1b[1m' : '';
const NC = useColor ? '\x1b[0m' : '';

let repoRoot;
try {
  repoRoot = execSync('git rev-parse --show-toplevel', { encoding: 'utf8' }).trim();
} catch {
  repoRoot = process.cwd();
}

function readdirRecursive(dir) {
  const results = [];
  const entries = readdirSync(dir, { withFileTypes: true });
  for (const entry of entries) {
    const fullPath = resolve(dir, entry.name);
    if (entry.isDirectory()) {
      if (
        entry.name === '.git' ||
        entry.name === 'node_modules' ||
        entry.name === 'prompt-logs'
      ) {
        continue;
      }
      results.push(...readdirRecursive(fullPath));
    } else {
      results.push(fullPath);
    }
  }
  return results;
}

function collectMdFiles(rootDir) {
  const ignoreRules = loadIgnoreRules(rootDir);
  const allFiles = readdirRecursive(rootDir);
  const results = [];
  for (const file of allFiles) {
    const relPath = normalizeRelPath(relative(repoRoot, file));
    if (
      relPath.startsWith('.git/') ||
      relPath.startsWith('node_modules/') ||
      relPath.includes('/node_modules/') ||
      relPath.startsWith('prompt-logs/') ||
      relPath === 'CHANGELOG.md' ||
      relPath.startsWith('references/')
    ) {
      continue;
    }
    if (isIgnoredPath(relPath, ignoreRules)) {
      continue;
    }
    if (extname(file) === '.md') {
      results.push(file);
    }
  }
  return results;
}

function stripFencedCode(content) {
  return content
    .replace(/```[\s\S]*?```/g, '\n')
    .replace(/~~~[\s\S]*?~~~/g, '\n');
}

function normalizeRefLabel(label) {
  return label.trim().toLowerCase().replace(/\s+/g, ' ');
}

function extractReferenceDefs(content) {
  const defs = new Map();
  const defRe = /^\s{0,3}\[([^\]]+)\]:\s*<?([^>\s]+)>?/gm;
  let match;
  while ((match = defRe.exec(content)) !== null) {
    const label = normalizeRefLabel(match[1]);
    const target = (match[2] || '').trim();
    if (!label || !target) {
      continue;
    }
    defs.set(label, target);
  }
  return defs;
}

function shouldSkipRawUrl(url) {
  return (
    !url ||
    url.startsWith('http://') ||
    url.startsWith('https://') ||
    url.startsWith('mailto:') ||
    url.startsWith('data:') ||
    url.startsWith('javascript:') ||
    (url.startsWith('#') && !url.includes('/'))
  );
}

function normalizeUrlForPath(url) {
  let out = url;
  const hashIdx = out.indexOf('#');
  if (hashIdx !== -1) {
    out = out.slice(0, hashIdx);
  }
  const queryIdx = out.indexOf('?');
  if (queryIdx !== -1) {
    out = out.slice(0, queryIdx);
  }
  return out;
}

function extractLinks(filePath) {
  const sourceDir = dirname(filePath);
  const content = stripFencedCode(readFileSync(filePath, 'utf8'));
  const defs = extractReferenceDefs(content);
  const links = [];

  const pushResolved = (rawUrl) => {
    if (shouldSkipRawUrl(rawUrl)) {
      return;
    }
    const pathPart = normalizeUrlForPath(rawUrl);
    if (!pathPart) {
      return;
    }
    links.push({
      raw: rawUrl,
      resolved: resolve(sourceDir, pathPart)
    });
  };

  let match;

  // Inline links/images: [label](target), ![alt](target)
  const inlineRe = /!?\[[^\]]*\]\(([^)]+)\)/g;
  while ((match = inlineRe.exec(content)) !== null) {
    pushResolved((match[1] || '').trim());
  }

  // Reference links/images: [label][ref], ![alt][ref]
  const explicitRefRe = /!?\[[^\]]*\]\[([^\]]+)\]/g;
  while ((match = explicitRefRe.exec(content)) !== null) {
    const label = normalizeRefLabel(match[1] || '');
    const target = defs.get(label);
    if (target) {
      pushResolved(target);
    }
  }

  // Collapsed references: [label][]
  const collapsedRefRe = /!?\[([^\]]+)\]\[\]/g;
  while ((match = collapsedRefRe.exec(content)) !== null) {
    const label = normalizeRefLabel(match[1] || '');
    const target = defs.get(label);
    if (target) {
      pushResolved(target);
    }
  }

  return links;
}

const mdFiles = collectMdFiles(repoRoot);
const ignoreRules = loadIgnoreRules(repoRoot);
const adjacency = {};
const inbound = {};
const brokenRefs = [];

for (const filePath of mdFiles) {
  const relSource = normalizeRelPath(relative(repoRoot, filePath));
  adjacency[relSource] = [];

  const links = extractLinks(filePath);
  for (const link of links) {
    const relTarget = normalizeRelPath(relative(repoRoot, link.resolved));
    if (isIgnoredPath(relTarget, ignoreRules)) {
      continue;
    }
    adjacency[relSource].push(relTarget);

    if (!existsSync(link.resolved)) {
      const ext = extname(link.resolved);
      if (!ext) {
        const withMd = link.resolved + '.md';
        if (existsSync(withMd)) {
          const relWithMd = normalizeRelPath(relative(repoRoot, withMd));
          if (isIgnoredPath(relWithMd, ignoreRules)) {
            continue;
          }
          if (!inbound[relWithMd]) {
            inbound[relWithMd] = [];
          }
          inbound[relWithMd].push(relSource);
          continue;
        }
      }
      brokenRefs.push({
        source: relSource,
        target: relTarget,
        raw: link.raw
      });
    } else {
      if (!inbound[relTarget]) {
        inbound[relTarget] = [];
      }
      inbound[relTarget].push(relSource);
    }
  }
}

const orphanExclude = new Set([
  'README.md',
  'README.ko.md',
  'AGENTS.md',
  'CLAUDE.md'
]);

const allMdRel = mdFiles.map((f) => relative(repoRoot, f));
const orphans = allMdRel.filter((f) => {
  if (orphanExclude.has(f)) {
    return false;
  }
  if (f.startsWith('prompt-logs/')) {
    return false;
  }
  return !inbound[f] || inbound[f].length === 0;
});

const totalDocs = allMdRel.length;
const totalLinks = Object.values(adjacency).reduce((sum, targets) => sum + targets.length, 0);

const inboundCounts = Object.entries(inbound)
  .map(([file, sources]) => ({ file, count: sources.length }))
  .sort((a, b) => b.count - a.count);

if (mode === 'orphans') {
  if (jsonOutput) {
    console.log(JSON.stringify({ orphans, count: orphans.length }, null, 2));
  } else if (orphans.length === 0) {
    console.log(`${GREEN}No orphan documents found.${NC}`);
  } else {
    console.log(`${YELLOW}Orphan documents (zero inbound links):${NC}`);
    for (const orphan of orphans) {
      console.log(`  ${RED}-${NC} ${orphan}`);
    }
    console.log(`\n${YELLOW}Total: ${orphans.length} orphan(s)${NC}`);
  }
} else if (mode === 'impact') {
  const resolvedImpact = relative(repoRoot, resolve(repoRoot, impactFile));
  const impactSources = (inbound[resolvedImpact] || []).sort();

  if (jsonOutput) {
    console.log(
      JSON.stringify(
        {
          file: resolvedImpact,
          referenced_by: impactSources,
          count: impactSources.length
        },
        null,
        2
      )
    );
  } else if (impactSources.length === 0) {
    console.log(`${YELLOW}No documents reference: ${resolvedImpact}${NC}`);
  } else {
    console.log(`${BOLD}Documents referencing ${resolvedImpact}:${NC}`);
    for (const src of impactSources) {
      console.log(`  ${GREEN}-${NC} ${src}`);
    }
    console.log(`\n${BOLD}Total: ${impactSources.length} document(s)${NC}`);
  }
} else if (jsonOutput) {
  console.log(
    JSON.stringify(
      {
        stats: {
          total_docs: totalDocs,
          total_links: totalLinks,
          orphan_count: orphans.length,
          broken_ref_count: brokenRefs.length
        },
        adjacency,
        orphans,
        broken_refs: brokenRefs,
        top_referenced: inboundCounts.slice(0, 10)
      },
      null,
      2
    )
  );
} else {
  console.log(`${BOLD}Document Graph Summary${NC}`);
  console.log(`- Total docs: ${totalDocs}`);
  console.log(`- Total links: ${totalLinks}`);
  console.log(`- Orphans: ${orphans.length}`);
  console.log(`- Broken refs: ${brokenRefs.length}`);

  if (inboundCounts.length > 0) {
    console.log(`\n${BOLD}Top referenced files:${NC}`);
    for (const item of inboundCounts.slice(0, 10)) {
      console.log(`  ${GREEN}-${NC} ${item.file} (${item.count})`);
    }
  }

  if (orphans.length > 0) {
    console.log(`\n${YELLOW}Orphans:${NC}`);
    for (const orphan of orphans) {
      console.log(`  ${YELLOW}-${NC} ${orphan}`);
    }
  }

  if (brokenRefs.length > 0) {
    console.log(`\n${RED}Broken references:${NC}`);
    for (const broken of brokenRefs.slice(0, 20)) {
      console.log(`  ${RED}-${NC} ${broken.source} -> ${broken.raw}`);
    }
    if (brokenRefs.length > 20) {
      console.log(`  ... and ${brokenRefs.length - 20} more`);
    }
  }
}

if (orphans.length > 0 || brokenRefs.length > 0) {
  process.exit(1);
}

process.exit(0);
