# Plan: Enhance --docs criteria + Remove deprecated plugin directories

## Task A: Enhance `--docs` mode with document design quality criteria

Reference: https://wiki.g15e.com/pages/Software%20project%20documentation%20in%20AI%20era

### Changes

#### ✅ 1. Add Section 5 to `docs-criteria.md`
**File**: `plugins/refactor/skills/refactor/references/docs-criteria.md`

Add "## 5. Document Design Quality" section with checks derived from the wiki:

| Check | Flag condition |
|-------|---------------|
| Orphaned docs | Files in `docs/` not reachable from any entry point (CLAUDE.md, README) |
| Circular references | A → B → A link cycles between docs |
| Inline overload | CLAUDE.md contains detail that should be linked, not inlined |
| Auto-generated docs in git | Generated files tracked in version control |
| Non-obvious decisions undocumented | Architecture decisions not recorded anywhere |
| Obvious/trivial instructions | Self-evident directives that add noise |

Skip checks already covered: duplication (Section 1), README brevity (Section 3).

#### ✅ 2. Add Step 5 to SKILL.md `--docs` mode
**File**: `plugins/refactor/skills/refactor/SKILL.md`

After "### 4. Cross-Document Consistency", add:

```
### 5. Document Design Quality

Read `{SKILL_DIR}/references/docs-criteria.md` Section 5 and evaluate:
- Orphaned docs: walk links from CLAUDE.md and README.md, flag unreachable docs/ files
- Circular references: detect A→B→A link cycles
- Inline overload: flag CLAUDE.md sections >20 lines that could be a link to docs/
- Auto-generated files: check for generated output tracked in git
- Missing decision records: flag significant architectural choices without documentation
- Obvious instructions: flag trivially self-evident directives
```

#### ✅ 3. Version bump
**File**: `plugins/refactor/.claude-plugin/plugin.json`

Bump version: `1.0.0` → `1.1.0` (new feature: additional criteria)

---

## Task B: Remove deprecated plugin directories

### ✅ Directories to delete

| Plugin | Directory | Reason |
|--------|-----------|--------|
| `suggest-tidyings` | `plugins/suggest-tidyings/` | Absorbed by `refactor --code` |
| `deep-clarify` | `plugins/deep-clarify/` | Absorbed by `clarify` v2 |
| `interview` | `plugins/interview/` | Absorbed by `clarify` v2 |
| `web-search` | `plugins/web-search/` | Absorbed by `gather-context` v2 |

**Safety**: `gather-context` already has its own WebSearch→`/gather-context --search` redirect hook, so removing `web-search` has zero functional impact.

### ✅ Documentation updates

#### README.md + README.ko.md (lines ~294-296)
Change: "Source code remains in `plugins/` for reference"
→ "Source code is available in git history (last version: commit `238f82d`)"

(238f82d = "feat: refactor plugin + marketplace v2.0.0" — last commit where all deprecated plugins existed)

#### docs/project-context.md
- Line 35: "Script delegation" example — change `web-search` → only `gather-context`
- Line 36: "Hook-based tool redirect" — change `WebSearch → /web-search` → `WebSearch → /gather-context --search`
- Line 39: "Sub-agent orchestration" — remove "Established by suggest-tidyings, extended by deep-clarify" → state the pattern generally
- Lines 57-63: Remove deprecated plugin detail entries, keep only a one-line note that they existed
- Line 67: Remove "Absorbs suggest-tidyings" phrasing from refactor entry

#### CLAUDE.md (line ~14 area)
- Update "web-search plugin enforces this automatically via PreToolUse hook" → "gather-context plugin enforces this automatically via PreToolUse hook"

#### docs/plugin-dev-cheatsheet.md (line 23)
- Hybrid example: change `web-search` → only `gather-context`

#### docs/skills-guide.md (line 35)
- Execution-heavy example: change `web-search` → another active example or just `gather-context`

#### AI_NATIVE_PRODUCT_TEAM.md (line 87) + .ko.md (line 87)
- Change `[tidying](./plugins/suggest-tidyings)` → `[refactor](./plugins/refactor)`

---

## Success Criteria

```gherkin
Given the --docs mode runs against the repository
When it evaluates document design quality
Then it checks for orphaned docs, circular references, inline overload, auto-generated files, missing decisions, and obvious instructions

Given the plugins/ directory
When listing plugin directories
Then suggest-tidyings, deep-clarify, interview, and web-search directories do not exist

Given a user reads README.md "Removed Plugins" section
When they want to see old source code
Then they find a git commit reference (238f82d) to access the historical code

Given the WebSearch redirect hook
When web-search plugin is removed
Then gather-context's own hook still redirects WebSearch → /gather-context --search
```

## Deferred Actions

- [ ] None

## Verification

1. `ls plugins/` — confirm only active plugins remain
2. `grep -r "suggest-tidyings\|deep-clarify\|interview" plugins/` — no references in active plugins
3. `grep -r "web-search" plugins/` — only in gather-context (its own redirect hook reference)
4. Read updated docs-criteria.md — Section 5 exists with 6 checks
5. Read updated SKILL.md — Step 5 exists in --docs mode
6. `/plugin-deploy` for refactor plugin version/marketplace sync
