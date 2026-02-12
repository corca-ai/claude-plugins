# Prior Art Research: Static Analysis Tooling for CLI Plugin Repo

**Date:** 2026-02-12
**Session:** S24 plan phase
**Scope:** 5 static analysis tools + 1 stub (lychee, doc-graph, datasketch, ajv-cli+yq, git-log churn, vale)

---

## 1. Lychee (Link Checker)

### What it is
Lychee is a Rust-based async link checker that validates URLs in markdown, HTML,
and text files. It supports `.lychee.toml` configuration files.

### Configuration Best Practices for Monorepos with Mixed Content

**Source:** [lychee GitHub repo](https://github.com/lycheeverse/lychee),
[lychee.example.toml](https://github.com/lycheeverse/lychee/blob/master/lychee.example.toml)

Key configuration patterns from the example TOML:

```toml
# Core display
verbose = "warn"
format = "detailed"
mode = "color"

# Caching (avoids redundant network calls across runs)
cache = true
max_cache_age = "2d"
exclude_cache_status_codes = [500]

# Runtime tuning
max_redirects = 10
max_retries = 2
max_concurrency = 14
timeout = 20

# Exclusion patterns (critical for monorepos)
exclude = [
  "^https://example\\.com",       # Regex-based URL exclusion
  "^https://localhost",
]
exclude_path = [
  "node_modules",
  ".git",
  "vendor",
]

# Inclusion patterns (file extensions to check)
include_extensions = ["md", "html", "txt"]

# Per-host rate limiting (prevents 429s)
[host_config."example.com"]
max_concurrency = 2
```

**Monorepo-specific patterns:**
- Use `exclude_path` to skip code directories, build artifacts, vendored deps
- Use `include_extensions` to restrict to documentation file types (md, html, txt)
- Enable caching (`cache = true`, `max_cache_age = "2d"`) to avoid repeated
  network calls during iterative runs
- Set per-host concurrency limits to avoid rate-limiting from GitHub/npm/etc.
- Use `exclude` regexes for known-dead or intentionally-placeholder URLs
- `accept = [200, 204, 301, 302]` to whitelist acceptable HTTP status codes
- Private/loopback IP exclusion prevents false positives from internal refs

**CLI invocation (no config file needed for simple cases):**
```bash
lychee --exclude-path node_modules --include-extensions md "**/*.md"
```

**Installation:** Available via `cargo install lychee-lib`, `brew install lychee`,
or GitHub releases (single binary).

### Relevance to this repo
This repo has ~50+ markdown files across `docs/`, `plugins/`, `prompt-logs/`,
and root-level docs. Mixed content includes shell scripts with URLs in comments.
The `.lychee.toml` should exclude `prompt-logs/` session transcripts (external
URLs may be stale) and focus on `docs/`, `plugins/`, `README.md`, `AGENTS.md`.

---

## 2. datasketch / MinHash (Near-Duplicate Detection)

### What it is
Python library implementing probabilistic data structures for similarity
estimation. MinHash estimates Jaccard similarity between sets; MinHash LSH
provides threshold-based approximate nearest neighbor search.

### Best Practices for Document Deduplication

**Sources:**
- [datasketch GitHub repo](https://github.com/ekzhu/datasketch)
- [MinHash documentation](https://ekzhu.com/datasketch/minhash.html)
- [MinHash LSH documentation](https://ekzhu.com/datasketch/lsh.html)

#### Shingle Size

The documentation does not prescribe a specific shingle size. Standard practice
from the information retrieval literature:

- **Word-level shingles (k=3 to k=5):** Best for detecting near-duplicate
  documents where text is rearranged or lightly edited. k=3 is common for
  short documents; k=5 for longer ones.
- **Character-level shingles (k=5 to k=9):** Better for detecting typo-level
  similarity, but higher compute cost. Typically used for web page dedup.
- **Line-level shingles (k=1 to k=3):** Appropriate for structured documents
  like config files or markdown where line-level structure matters.

For this repo's use case (detecting near-duplicate markdown documentation),
**word-level k=3 shingles** are a reasonable starting point.

#### num_perm (Number of Permutation Functions)

From the documentation:
- Default: `num_perm=128`
- Higher values improve accuracy but increase CPU and memory linearly
- `num_perm=256` is suggested for improved accuracy over default
- The num_perm value must match between MinHash objects being compared

**Practical guidance:**
- 128 permutations: ~3.5% error rate for Jaccard estimation
- 256 permutations: ~2.5% error rate
- For a repo with <200 documents, 128 is more than sufficient

#### Threshold Tuning (MinHash LSH)

From the LSH documentation:
- Threshold is set at initialization and cannot be changed
- Higher thresholds reduce false positives but increase false negatives
- The LSH probability curve creates a "jump" at the threshold value

**Recommended thresholds for document dedup:**
- 0.5: Catches loosely similar documents (useful for finding related content)
- 0.7: Standard near-duplicate threshold (recommended starting point)
- 0.9: Very strict, only near-identical documents

**Key API patterns:**
```python
from datasketch import MinHash, MinHashLSH

# Create LSH index
lsh = MinHashLSH(threshold=0.7, num_perm=128)

# Create MinHash for each document
m = MinHash(num_perm=128)
for shingle in shingles:
    m.update(shingle.encode('utf8'))

# Insert and query
lsh.insert("doc_id", m)
result = lsh.query(m)  # Returns IDs of similar documents
```

**Additional features:**
- `LeanMinHash`: Reduced memory footprint for large collections
- `merge()`: Enables parallel/MapReduce-style processing
- `count()`: Estimates set cardinality

#### False Positive/Negative Management
- LSH guarantees higher-similarity sets have higher return probability
- For small document sets (<200), a brute-force pairwise comparison of
  MinHash Jaccard values may be simpler than LSH
- Bulk insertion sessions reduce overhead for large-scale indexing

### Relevance to this repo
The repo has accumulated documentation over 24+ sessions. Some content may be
duplicated across prompt-logs session artifacts, docs/, and plugin references.
A dedup script can flag pairs above threshold 0.7 for human review.

---

## 3. ajv-cli + yq (Schema Validation for YAML Config)

### What they are
- **ajv-cli**: Command-line interface for the Ajv JSON Schema validator
- **yq**: Go-based YAML/JSON/XML processor (like jq but for YAML)

### Best Practices for Validating YAML Config Files

**Sources:**
- [ajv-cli GitHub repo](https://github.com/ajv-validator/ajv-cli)
- [Ajv getting started](https://ajv.js.org/guide/getting-started.html)
- [yq GitHub repo](https://github.com/mikefarah/yq)
- [JSON Schema reference](https://json-schema.org/understanding-json-schema/reference)

#### Pipeline: yq converts YAML to JSON, ajv validates against schema

```bash
# Convert YAML to JSON, pipe to ajv for validation
yq -o json cwf-state.yaml | npx ajv-cli validate -s schema.json -d /dev/stdin
```

Or as a two-step process:
```bash
yq -o json cwf-state.yaml > /tmp/cwf-state.json
npx ajv-cli validate -s schemas/cwf-state.schema.json -d /tmp/cwf-state.json
```

#### ajv-cli Key Features

- **Schema spec selection:** `--spec=draft7` (default), `--spec=draft2020`
- **Glob pattern support:** `-d "test/valid*.json"` validates multiple files
- **Error output formats:** `--errors=json`, `--errors=text`, `--errors=line`
- **Referenced schemas:** `-r referenced.json` for `$ref` resolution
- **Strict mode:** `--strict=true` for stricter validation
- **All errors:** `--all-errors` reports every error (not just first)

#### yq Key Features for This Pipeline

```bash
# YAML to JSON conversion
yq -o json file.yaml

# Explicit format specification
cat file.yaml | yq -p yaml -o json '.'

# Extract specific fields
yq '.workflow.current_stage' cwf-state.yaml
```

#### JSON Schema Best Practices for cwf-state.yaml

From JSON Schema documentation:

1. **Use `required` arrays** to enforce mandatory fields (e.g., `workflow`,
   `sessions`, `hooks`)
2. **Use `enum` constraints** for fixed-value fields (e.g., stage names,
   boolean hook toggles)
3. **Use `pattern` for string validation** (e.g., session IDs matching
   `^S\d+(\.\d+)?(-[A-Z]\d*)?$`)
4. **Use `additionalProperties: false`** at the top level to prevent
   undocumented keys from silently appearing
5. **Use `$ref` for reusable definitions** (e.g., session entry schema
   referenced by the sessions array)
6. **Use `description` annotations** to make the schema self-documenting
7. **Conditional validation** (`if`/`then`/`else`) for fields that depend
   on other values (e.g., `live.phase` restricts valid `live.task` patterns)

**Example schema structure for cwf-state.yaml:**
```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "type": "object",
  "required": ["workflow", "sessions", "tools", "hooks", "live"],
  "properties": {
    "workflow": {
      "type": "object",
      "required": ["current_stage", "started_at", "stages"],
      "properties": {
        "current_stage": {
          "type": "string",
          "enum": ["clarify", "refactor", "scaffold", "review", "build", "harden", "launch"]
        }
      }
    },
    "sessions": {
      "type": "array",
      "items": { "$ref": "#/$defs/session" }
    }
  },
  "$defs": {
    "session": {
      "type": "object",
      "required": ["id", "title", "dir", "branch"],
      "properties": {
        "id": { "type": "string", "pattern": "^S\\d+" },
        "completed_at": { "type": "string", "format": "date" }
      }
    }
  }
}
```

### Relevance to this repo
`cwf-state.yaml` is the single source of truth for project state. It is read by
multiple hooks and skills. Schema validation catches structural drift early --
missing required fields, wrong types, invalid enum values, malformed session
entries.

---

## 4. remark/unified Ecosystem (Document Link Graph)

### What it is
The unified ecosystem provides a pipeline for parsing, transforming, and
serializing content. remark is the markdown processor built on unified.

### Patterns for Building Document Link Graphs

**Sources:**
- [remark GitHub repo](https://github.com/remarkjs/remark)
- [unified GitHub repo](https://github.com/unifiedjs/unified)
- [mdast spec](https://github.com/syntax-tree/mdast)
- [unist-util-visit](https://github.com/syntax-tree/unist-util-visit)
- [unified-args](https://github.com/unifiedjs/unified-args)

#### The unified Pipeline

```
parse (text -> AST) -> transform (AST -> AST) -> stringify (AST -> text)
```

For analysis-only tasks, skip stringify:
```javascript
const tree = processor.parse(input)
const transformedTree = processor.runSync(tree)
// Analyze transformedTree directly -- no need to stringify
```

#### Relevant mdast Node Types for Link Analysis

| Node Type | Key Properties | Purpose |
|-----------|---------------|---------|
| `link` | `url`, `title`, `children` | Direct hyperlinks |
| `linkReference` | `identifier`, `label`, `referenceType` | Reference-style links |
| `definition` | `identifier`, `label`, `url`, `title` | Link definitions |
| `image` | `url`, `title`, `alt` | Direct images |
| `imageReference` | `identifier`, `label`, `referenceType`, `alt` | Reference-style images |

#### Plugin Pattern for Link Extraction

```javascript
import { unified } from 'unified'
import remarkParse from 'remark-parse'
import { visit } from 'unist-util-visit'

function extractLinks() {
  return function (tree, file) {
    const links = []
    visit(tree, 'link', (node) => {
      links.push({
        url: node.url,
        position: node.position,
        source: file.path
      })
    })
    // Also capture linkReference + definition pairs
    visit(tree, 'linkReference', (node) => {
      links.push({
        identifier: node.identifier,
        referenceType: node.referenceType,
        position: node.position,
        source: file.path
      })
    })
    file.data.links = links
  }
}
```

#### unist-util-visit API

```javascript
visit(tree, test, visitor)
// visitor(node, index, parent) -> CONTINUE | EXIT | SKIP
```

- `CONTINUE` (true): Continue traversal
- `EXIT` (false): Stop all traversal
- `SKIP` ('skip'): Skip children, continue with siblings

#### Building the Graph

Pattern for constructing a document reference graph:

1. **Parse phase:** For each .md file, extract all link/linkReference nodes
2. **Resolve phase:** Normalize relative paths against source file location
3. **Graph phase:** Build adjacency list `{source -> [targets]}`
4. **Analysis phase:** Find orphan documents (no inbound links), broken
   internal references, circular dependencies

#### CLI Tooling Options

Two approaches for making this a CLI tool:

**Option A: Standalone Node.js script (recommended for this repo)**
```bash
#!/usr/bin/env node
// Uses npx-compatible shebang, reads file list from args or glob
```

**Option B: unified-args wrapper**
```javascript
import { args } from 'unified-args'
args({
  processor: remark,
  extensions: ['md', 'markdown'],
  name: 'doc-graph',
  // ...
})
```

Option A is simpler for a standalone script that outputs a graph JSON/report.
Option B is better if you want remark-cli-style file discovery and config.

### Relevance to this repo
The repo has extensive cross-references: AGENTS.md references cwf-index.md,
SKILL.md files reference protocol docs, session artifacts reference each other.
A doc-graph tool can detect broken internal links, orphan documents, and
visualize the reference structure.

---

## 5. Git Log Churn Analysis (Document Staleness)

### What it is
Using `git log` to measure how frequently files change (churn) and when they
were last modified (staleness). High-churn + stale = likely technical debt.

### Patterns for Measuring Document Churn and Staleness

**Sources:** git documentation, common DevOps/SRE patterns

#### Core Git Commands for Churn Analysis

**File modification frequency (churn):**
```bash
# Count commits touching each file, sorted by frequency
git log --pretty=format: --name-only --since="30 days ago" \
  | sort | uniq -c | sort -rn | head -20
```

**Last modification date per file (staleness):**
```bash
# For each tracked file, show last commit date
git ls-files '*.md' | while read f; do
  echo "$(git log -1 --format='%ci' -- "$f") $f"
done | sort
```

**Combined churn + staleness report:**
```bash
# Files with high churn in last 30 days
git log --since="30 days ago" --pretty=format: --name-only -- '*.md' \
  | sort | uniq -c | sort -rn

# Files NOT touched in 30+ days (stale)
git ls-files '*.md' | while read f; do
  last=$(git log -1 --format='%ct' -- "$f")
  threshold=$(date -d '30 days ago' +%s)
  if [ "$last" -lt "$threshold" ]; then
    echo "STALE: $f (last: $(git log -1 --format='%ci' -- "$f"))"
  fi
done
```

#### Advanced Patterns

**Commit-weighted churn (accounts for size of changes):**
```bash
git log --numstat --since="30 days ago" -- '*.md' \
  | awk '/^[0-9]/ { files[$3] += $1 + $2 } END { for (f in files) print files[f], f }' \
  | sort -rn
```

**Co-change analysis (files that change together):**
```bash
git log --pretty=format:'%H' -- '*.md' | while read hash; do
  git diff-tree --no-commit-id --name-only -r "$hash" -- '*.md'
  echo "---"
done
```

**Author concentration (bus factor per file):**
```bash
git ls-files '*.md' | while read f; do
  authors=$(git log --format='%aN' -- "$f" | sort -u | wc -l)
  echo "$authors $f"
done | sort -n
```

#### Staleness Thresholds (Heuristics)

For a documentation-heavy repo like this one:
- **Fresh:** Modified within 7 days
- **Current:** Modified within 30 days
- **Stale:** Not modified in 30-90 days
- **Archival:** Not modified in 90+ days

These thresholds should be configurable in the script.

#### Output Format

Recommended: JSON for machine consumption, human-readable table for CLI output.

```json
{
  "generated_at": "2026-02-12T...",
  "staleness_threshold_days": 30,
  "files": [
    {
      "path": "docs/concept-map.md",
      "last_modified": "2026-02-09",
      "commits_30d": 3,
      "lines_changed_30d": 45,
      "status": "current"
    }
  ]
}
```

### Relevance to this repo
With 24+ sessions producing documentation artifacts, some early-session docs
may be stale or superseded. Churn analysis identifies which docs are actively
maintained vs. which are archival. This feeds into the doc-graph tool to
identify stale-but-still-referenced documents (high-priority review targets).

---

## 6. Vale (Technical Documentation Linter) -- Stub

### What it is
Vale is a syntax-aware linter for prose. It checks writing style, grammar,
and terminology against configurable rule packages.

### Configuration Patterns

**Sources:**
- [Vale documentation](https://vale.sh/docs/topics/config/)

#### .vale.ini Structure

```ini
# .vale.ini
StylesPath = .vale/styles
MinAlertLevel = suggestion    # suggestion | warning | error
Packages = Google, write-good

# Vocabulary for project-specific terms
Vocab = ProjectTerms

[formats]
mdx = md

# File-type-specific rules
[*.md]
BasedOnStyles = Vale, Google, write-good
Vale.Terms = YES

[*.yaml]
# Skip YAML files
BasedOnStyles =
```

#### Key Configuration Options

| Key | Purpose | Example |
|-----|---------|---------|
| `StylesPath` | Directory containing style rules | `.vale/styles` |
| `MinAlertLevel` | Minimum severity to report | `suggestion` |
| `Packages` | Style packages to download | `Google, write-good` |
| `Vocab` | Custom vocabulary lists | `ProjectTerms` |
| `IgnoredScopes` | Inline HTML tags to skip | `code, tt` |
| `SkippedScopes` | Block HTML tags to skip | `script, style` |
| `BlockIgnores` | Regex for block content to skip | Code fences, etc. |
| `TokenIgnores` | Regex for inline content to skip | URLs, etc. |
| `BasedOnStyles` | Which style guides to apply | `Vale, Google` |

#### Setup Process

```bash
# 1. Create .vale.ini in project root
# 2. Run vale sync to download packages
vale sync
# 3. Run vale on target files
vale docs/ README.md AGENTS.md
```

#### Popular Style Packages for Technical Documentation

- **Google**: Google developer documentation style guide
- **Microsoft**: Microsoft writing style guide
- **write-good**: General-purpose writing improvement rules
- **Readability**: Flesch-Kincaid and other readability metrics
- **alex**: Catch insensitive, inconsiderate writing
- **proselint**: General prose linting

#### Configuration Discovery

Vale searches for `.vale.ini` starting from the current directory upward.
Override with `--config` flag or `VALE_CONFIG_PATH` env var.

### Relevance to this repo
Vale is a natural fit for linting the repo's extensive markdown documentation.
As a stub, the initial integration would create `.vale.ini` with minimal config
and document the intended setup, deferring full style package selection to a
future session.

---

## Integration Architecture Summary

All six tools share common patterns suitable for the `scripts/` directory:

| Tool | Language | Install Method | Script Location |
|------|----------|---------------|-----------------|
| lychee | Rust binary | `cargo install` / brew / release binary | `scripts/check-links.sh` |
| doc-graph | Node.js (remark) | `npx` (no package.json) | `scripts/doc-graph.mjs` |
| datasketch | Python | `pip install datasketch` | `scripts/check-duplicates.py` |
| ajv-cli + yq | Node.js + Go | `npx ajv-cli` + `brew install yq` | `scripts/validate-schema.sh` |
| git-log churn | Shell (git) | Built-in | `scripts/check-churn.sh` |
| vale | Go binary | `brew install vale` / release binary | `scripts/check-prose.sh` (stub) |

**Common design principles:**
- Each script is standalone, runnable without CI
- Exit code 0 = pass, non-zero = issues found
- JSON output option for machine consumption
- Human-readable table/summary for interactive use
- No shared state between tools (composable but independent)

---

## Sources

- lychee: https://github.com/lycheeverse/lychee
- lychee example config: https://github.com/lycheeverse/lychee/blob/master/lychee.example.toml
- datasketch: https://github.com/ekzhu/datasketch
- datasketch MinHash docs: https://ekzhu.com/datasketch/minhash.html
- datasketch LSH docs: https://ekzhu.com/datasketch/lsh.html
- ajv-cli: https://github.com/ajv-validator/ajv-cli
- Ajv getting started: https://ajv.js.org/guide/getting-started.html
- yq: https://github.com/mikefarah/yq
- JSON Schema reference: https://json-schema.org/understanding-json-schema/reference
- remark: https://github.com/remarkjs/remark
- unified: https://github.com/unifiedjs/unified
- mdast: https://github.com/syntax-tree/mdast
- unist-util-visit: https://github.com/syntax-tree/unist-util-visit
- unified-args: https://github.com/unifiedjs/unified-args
- Vale config: https://vale.sh/docs/topics/config/

<!-- AGENT_COMPLETE -->
