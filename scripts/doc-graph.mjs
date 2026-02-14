#!/usr/bin/env node

// doc-graph.mjs — Build and analyze document reference graph from Markdown files
// Usage: doc-graph.mjs [--orphans] [--impact <file>] [--json] [-h|--help]
//   --orphans  List documents with zero inbound links (excluding prompt-logs/)
//   --impact   Given a changed file, list all documents that reference it
//   --json     Output full adjacency list as JSON
//   (default)  Print human-readable summary
// Exit 0 = clean, Exit 1 = orphans or broken refs found

import { readFileSync, existsSync, statSync, readdirSync } from 'node:fs';
import { resolve, relative, dirname, extname } from 'node:path';
import { execSync } from 'node:child_process';
import { unified } from 'unified';
import remarkParse from 'remark-parse';
import { visit } from 'unist-util-visit';

// --- CLI argument parsing ---

const args = process.argv.slice(2);
let mode = 'summary'; // default mode
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

for (let i = 0; i < args.length; i++) {
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

// --- Color helpers (TTY-guarded and --json-guarded) ---

const useColor = process.stdout.isTTY && !jsonOutput;
const RED = useColor ? '\x1b[0;31m' : '';
const GREEN = useColor ? '\x1b[0;32m' : '';
const YELLOW = useColor ? '\x1b[1;33m' : '';
const BOLD = useColor ? '\x1b[1m' : '';
const NC = useColor ? '\x1b[0m' : '';

// --- Dependency check ---

const scriptDir = dirname(new URL(import.meta.url).pathname);
if (!existsSync(resolve(scriptDir, 'node_modules'))) {
  console.error('Error: scripts/node_modules/ not found.');
  console.error('Run: npm install --prefix scripts/');
  process.exit(1);
}

// --- Repo root ---

let repoRoot;
try {
  repoRoot = execSync('git rev-parse --show-toplevel', { encoding: 'utf8' }).trim();
} catch {
  repoRoot = process.cwd();
}

// --- Collect all .md files (excluding configured source scopes) ---

function collectMdFiles(dir) {
  const results = [];
  const entries = readdirRecursive(dir);
  for (const entry of entries) {
    const relPath = relative(repoRoot, entry);
    // Exclude directories
    if (
      relPath.startsWith('prompt-logs/') ||
      relPath.startsWith('node_modules/') ||
      relPath.includes('/node_modules/') ||
      relPath.startsWith('.git/') ||
      relPath === 'CHANGELOG.md' ||
      relPath.startsWith('references/')
    ) {
      continue;
    }
    if (extname(entry) === '.md') {
      results.push(entry);
    }
  }
  return results;
}

function readdirRecursive(dir) {
  const results = [];
  const entries = readdirSync(dir, { withFileTypes: true });
  for (const entry of entries) {
    const fullPath = resolve(dir, entry.name);
    if (entry.isDirectory()) {
      // Skip known excluded directories early for performance
      if (
        entry.name === 'node_modules' ||
        entry.name === '.git' ||
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

// --- Parse markdown and extract links ---

const parser = unified().use(remarkParse);

function extractLinks(filePath) {
  const content = readFileSync(filePath, 'utf8');
  const tree = parser.parse(content);
  const links = [];

  visit(tree, (node) => {
    let url = null;
    if (node.type === 'link') {
      url = node.url;
    } else if (node.type === 'image') {
      url = node.url;
    }

    if (!url) return;

    // Skip external URLs, data URIs, and fragment-only anchors
    if (
      url.startsWith('http://') ||
      url.startsWith('https://') ||
      url.startsWith('data:') ||
      url.startsWith('mailto:') ||
      url === '' ||
      (url.startsWith('#') && !url.includes('/'))
    ) {
      return;
    }

    // Strip fragment and query before resolving path
    let fragment = '';
    const hashIdx = url.indexOf('#');
    if (hashIdx !== -1) {
      fragment = url.slice(hashIdx);
      url = url.slice(0, hashIdx);
    }
    const queryIdx = url.indexOf('?');
    if (queryIdx !== -1) {
      url = url.slice(0, queryIdx);
    }

    // Skip if nothing remains after stripping (was a fragment-only link)
    if (!url) return;

    const sourceDir = dirname(filePath);
    const resolvedPath = resolve(sourceDir, url);

    links.push({
      raw: node.url,
      resolved: resolvedPath,
      fragment,
    });
  });

  return links;
}

// --- Build adjacency list ---

const mdFiles = collectMdFiles(repoRoot);
const adjacency = {}; // source -> [resolved targets]
const inbound = {};   // target -> [sources]
const brokenRefs = []; // {source, target, raw}

for (const filePath of mdFiles) {
  const relSource = relative(repoRoot, filePath);
  adjacency[relSource] = [];

  const links = extractLinks(filePath);
  for (const link of links) {
    const relTarget = relative(repoRoot, link.resolved);
    adjacency[relSource].push(relTarget);

    // Check if target exists
    if (!existsSync(link.resolved)) {
      // Also try with common extensions if no extension
      const ext = extname(link.resolved);
      if (!ext) {
        const withMd = link.resolved + '.md';
        if (existsSync(withMd)) {
          const relWithMd = relative(repoRoot, withMd);
          if (!inbound[relWithMd]) inbound[relWithMd] = [];
          inbound[relWithMd].push(relSource);
          continue;
        }
      }
      brokenRefs.push({
        source: relSource,
        target: relTarget,
        raw: link.raw,
      });
    } else {
      if (!inbound[relTarget]) inbound[relTarget] = [];
      inbound[relTarget].push(relSource);
    }
  }
}

// --- Detect orphans ---

// Root-level files excluded from orphan detection
const orphanExclude = new Set([
  'README.md',
  'README.ko.md',
  'AGENTS.md',
  'CLAUDE.md',
  'cwf-index.md',
]);

const allMdRel = mdFiles.map((f) => relative(repoRoot, f));
const orphans = allMdRel.filter((f) => {
  // Exclude root-level exempted files
  if (orphanExclude.has(f)) return false;
  // Exclude prompt-logs (already filtered, but belt-and-suspenders)
  if (f.startsWith('prompt-logs/')) return false;
  // An orphan has zero inbound links
  return !inbound[f] || inbound[f].length === 0;
});

// --- Compute stats ---

const totalDocs = allMdRel.length;
const totalLinks = Object.values(adjacency).reduce((sum, targets) => sum + targets.length, 0);

// Top-referenced files (by inbound count)
const inboundCounts = Object.entries(inbound)
  .map(([file, sources]) => ({ file, count: sources.length }))
  .sort((a, b) => b.count - a.count);

// --- Output ---

if (mode === 'orphans') {
  if (jsonOutput) {
    console.log(JSON.stringify({ orphans, count: orphans.length }, null, 2));
  } else {
    if (orphans.length === 0) {
      console.log(`${GREEN}No orphan documents found.${NC}`);
    } else {
      console.log(`${YELLOW}Orphan documents (zero inbound links):${NC}`);
      for (const o of orphans) {
        console.log(`  ${RED}-${NC} ${o}`);
      }
      console.log(`\n${YELLOW}Total: ${orphans.length} orphan(s)${NC}`);
    }
  }
} else if (mode === 'impact') {
  // Resolve the impact file path
  const resolvedImpact = relative(repoRoot, resolve(repoRoot, impactFile));

  // Find all docs that reference this file
  const impactSources = (inbound[resolvedImpact] || []).sort();

  if (jsonOutput) {
    console.log(JSON.stringify({
      file: resolvedImpact,
      referenced_by: impactSources,
      count: impactSources.length,
    }, null, 2));
  } else {
    if (impactSources.length === 0) {
      console.log(`${YELLOW}No documents reference: ${resolvedImpact}${NC}`);
    } else {
      console.log(`${BOLD}Documents referencing ${resolvedImpact}:${NC}`);
      for (const src of impactSources) {
        console.log(`  ${GREEN}-${NC} ${src}`);
      }
      console.log(`\n${BOLD}Total: ${impactSources.length} document(s)${NC}`);
    }
  }
} else {
  // Default: human-readable summary
  if (jsonOutput) {
    const output = {
      stats: {
        total_docs: totalDocs,
        total_links: totalLinks,
        orphan_count: orphans.length,
        broken_ref_count: brokenRefs.length,
      },
      adjacency,
      orphans,
      broken_refs: brokenRefs,
      top_referenced: inboundCounts.slice(0, 10),
    };
    console.log(JSON.stringify(output, null, 2));
  } else {
    console.log(`${BOLD}Document Reference Graph${NC}`);
    console.log('---');
    console.log(`Total documents: ${totalDocs}`);
    console.log(`Total internal links: ${totalLinks}`);
    console.log(`Orphan documents: ${orphans.length}`);
    console.log(`Broken references: ${brokenRefs.length}`);

    if (inboundCounts.length > 0) {
      console.log(`\n${BOLD}Top referenced files:${NC}`);
      for (const { file, count } of inboundCounts.slice(0, 10)) {
        console.log(`  ${GREEN}${count}${NC} <- ${file}`);
      }
    }

    if (orphans.length > 0) {
      console.log(`\n${YELLOW}Orphan documents (no inbound links):${NC}`);
      for (const o of orphans.slice(0, 10)) {
        console.log(`  ${RED}-${NC} ${o}`);
      }
      if (orphans.length > 10) {
        console.log(`  ... and ${orphans.length - 10} more`);
      }
    }

    if (brokenRefs.length > 0) {
      console.log(`\n${RED}Broken references:${NC}`);
      for (const { source, raw } of brokenRefs.slice(0, 10)) {
        console.log(`  ${RED}-${NC} ${source} -> ${raw}`);
      }
      if (brokenRefs.length > 10) {
        console.log(`  ... and ${brokenRefs.length - 10} more`);
      }
    }
  }
}

// --- Exit code ---

const hasIssues = orphans.length > 0 || brokenRefs.length > 0;
if (mode === 'impact') {
  // Impact mode: always exit 0 (informational query)
  process.exit(0);
} else {
  process.exit(hasIssues ? 1 : 0);
}
