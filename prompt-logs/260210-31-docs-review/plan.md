# Plan: Documentation & Architecture Overhaul

## Purpose

Restructure the project's documentation and CWF plugin architecture to follow
four governing principles discovered in S13.5-C2/D/E and this review session.
The goal: CLAUDE.md and docs become a thin customization layer over CWF,
CWF becomes self-contained and repo-agnostic, and agents trust intelligence
over instructions.

## Governing Principles

### P1. Maximum plugin dependency

CLAUDE.md and repo docs lean maximally on the CWF plugin. If a skill or hook
already handles a behavior, the doc does not mention it. CLAUDE.md carries
a strong dogfooding directive and a concise index — nothing more.

### P2. CWF skills are repo/user agnostic

Every CWF skill works standalone in any project without relying on this repo's
CLAUDE.md, project-context.md, or cwf-state.yaml existing beforehand.
Skills that need persistent state (retro, handoff) must create it on first use.
Exception: find-skills, skill-creator (meta-skills about this repo).

### P3. Strong coupling within CWF

CWF is one plugin. Skills assume all other CWF skills and hooks exist.
No defensive fallbacks for partial installation. Customization axes:
- Hook group toggle (`cwf:setup --hooks`)
- Env var guards (no SLACK_BOT_TOKEN → attention no-op)
- User CLAUDE.md for machine-specific overrides

### P4. Trust agent intelligence

Document WHAT and WHY only. Omit HOW unless agents frequently fail at it.
When HOW must be enforced, use deterministic scripts (hooks, linters, check scripts)
rather than behavioral instructions.

---

## Workstreams

### W1. CLAUDE.md Rewrite (~65→~40 lines)

**Goal**: Compressed index + dogfooding directive + persist routing only.

Changes:
- [ ] Replace "Before You Start" gate with a single dogfooding statement:
  `"ALWAYS use CWF skills for the task at hand. Read docs relevant to your task:"`
- [ ] Remove "Do NOT proceed" gate (P4: trust agent to judge)
- [ ] Trim Collaboration Style further: evaluate each remaining line against P1/P4
  - Keep: plan-reality mismatch reporting, file deletion safety, honest counterarguments, research-before-design
  - Move to cheatsheet: "verify against official docs via WebFetch", "test in clean environment"
- [ ] Simplify Session State: remove manual cwf-state.yaml update instruction (skills handle it per P1), keep check-session.sh instruction
- [ ] Keep Persist Routing table as-is
- [ ] Keep Language section as-is
- [ ] Update doc index to reflect merged docs (W2)

### W2. Docs Merge (9→5 documents)

**Goal**: One scope per file. Eliminate overlap.

Merge plan:
- [ ] `docs/skills-guide.md` → absorb unique content into `plugin-dev-cheatsheet.md`
- [ ] `docs/modifying-plugin.md` → absorb into `plugin-dev-cheatsheet.md`
- [ ] `docs/adding-plugin.md` → absorb 4-line checklist into `plugin-dev-cheatsheet.md`
- [ ] `docs/claude-marketplace.md` → absorb caching note + user commands into `plugin-dev-cheatsheet.md`
- [ ] Delete the 4 merged files
- [ ] `docs/plugin-dev-cheatsheet.md`: add sections "Adding New Plugins", "Marketplace", reorganize
- [ ] `docs/documentation-guide.md`: remove "Application to This Project" table (CLAUDE.md is the index)

Deduplicate:
- [ ] Remove bash debugging tip from cheatsheet OR keep only in cheatsheet (currently in both cheatsheet:147 and was in CLAUDE.md — already removed from CLAUDE.md)
- [ ] Remove "hooks are snapshots" from architecture-patterns.md (already in cheatsheet:156)
- [ ] Remove "3-tier env loading" reference from architecture-patterns.md (code is in cheatsheet:100-113)
- [ ] Remove "skill loading is cache-based" from architecture-patterns.md (covered by cheatsheet)

Result: 5 docs with clear scopes:
| File | Scope |
|------|-------|
| CLAUDE.md | Behavior rules, dogfooding, doc index, persist routing |
| docs/plugin-dev-cheatsheet.md | All development reference (structure, schemas, testing, deploy, marketplace) |
| docs/architecture-patterns.md | Reusable code/hook/plugin patterns (trimmed) |
| docs/project-context.md | Project/org facts, design principles, process heuristics |
| docs/documentation-guide.md | Documentation principles |

### W3. project-context.md Trim

**Goal**: Remove session-specific and skill-redundant heuristics.

- [ ] Remove "Count-agnostic logic design" (1-time issue from S5b)
- [ ] Remove "Separation of concerns: WHAT vs HOW" (plan.md/handoff tools enforce this)
- [ ] Remove "Retro persist criterion" (circular ref to CLAUDE.md Persist Routing)
- [ ] Remove "Lessons and retro: written in the user's language" (retro/lessons skills specify this)
- [ ] Evaluate remaining 12 heuristics against P4 (trust intelligence): remove any that are generic best practices
- [ ] Remove Documentation Intent section (1 line, self-evident from README)
- [ ] Remove orphan file: `project-context.provenance.yaml`

### W4. architecture-patterns.md Trim

**Goal**: Only reusable patterns that agents need and can't infer.

Remove:
- [ ] "YAML parser section boundary guards" (1-time bug fix)
- [ ] "Agent autonomy requires boundary awareness" (philosophical, no concrete action)
- [ ] "prompt-logger internals" (single plugin implementation detail)
- [ ] Legacy marketplace plugins listing (deprecated, confusing in architecture doc)
- [ ] Items deduplicated in W2 (3-tier env, hooks snapshot, skill loading)
- [ ] "Custom skill preference" (enforced by hook; redundant per P1)

### W5. CWF Internal Cleanup

**Goal**: Remove standalone-era defensive coding. Apply P3 (strong coupling).

- [ ] Audit all skills for `if X installed` / `fallback when not available` patterns
  - clarify: remove gather-context fallback → assume cwf:gather always available
  - gather: remove "if WebSearch redirect hook not installed" check
  - Others: scan and clean
- [ ] Audit README.md "Standalone plugins (legacy)" section — update or simplify
- [ ] Remove standalone-era `plugins/{standalone-name}/` directories if no longer needed for marketplace backward-compat (decision needed: keep for existing users or drop?)

### W6. refactor --docs Enhancement

**Goal**: Single skill invocation produces both mechanical checks AND structural proposals.

- [ ] Add Section 6 "Structural Optimization" to `docs-criteria.md`:
  - Merge candidates (group scope-overlapping docs, identify primary)
  - Deletion candidates (100% unique content fits elsewhere)
  - CLAUDE.md trimming proposals (obvious + automation-redundant + duplicated)
  - Target structure with before/after comparison
  - Principle compliance check against documentation-guide.md
- [ ] Absorb documentation-guide.md key principles INTO docs-criteria.md (P2: skill must be self-contained, not depend on this repo's docs)
- [ ] Update SKILL.md --docs mode: add Step 6 "Synthesize structural proposals"
- [ ] Run dogfood.sh after changes to sync to cache

### W7. cwf-state.yaml Mandatory Design

**Goal**: CWF creates and manages cwf-state.yaml automatically in any project.

- [ ] Design: first CWF skill invocation checks for cwf-state.yaml → creates if missing
- [ ] Location: project root (next to CLAUDE.md)
- [ ] Minimum schema: `sessions` list, `live` section, `tools` (detected CLIs)
- [ ] Skills that read/write state (handoff, retro, plan, impl) must handle missing state gracefully on first use
- [ ] compact-context.sh SessionStart hook: skip if no cwf-state.yaml (don't error)

### W8. ship & review Integration

**Goal**: Properly integrate the newly moved skills into CWF.

- [ ] Review ship/SKILL.md and review/SKILL.md for standalone-era assumptions
- [ ] Update `{PLUGIN_ROOT}` or `../../references/` paths if they reference shared resources
- [ ] Add ship and review to CWF README.md skills table
- [ ] Test both skills via dogfood.sh + session restart

### W9. README.ko.md v3 Update

**Goal**: Korean README mirrors English README structure.

- [ ] Rewrite to match CWF-focused English README structure
- [ ] 9 CWF skills table + 7 hook groups
- [ ] Remove standalone plugin individual sections
- [ ] Keep "삭제된 플러그인" section updated

### W10. dogfood.sh Integration

**Goal**: dogfood.sh becomes the standard development workflow.

- [ ] Add to plugin-deploy skill as a pre-deploy step
- [ ] Document in cheatsheet § Testing
- [ ] Consider: SessionStart hook that auto-syncs if repo is detected (too aggressive?)
- [ ] Add `--check` flag: compare source vs cache, report drift without syncing

---

## Execution Order

Phase 1 (foundation — do first, enables everything else):
- W7 (cwf-state.yaml), W10 (dogfood integration)

Phase 2 (docs overhaul — the main event):
- W1 (CLAUDE.md), W2 (merge), W3 (project-context), W4 (architecture-patterns)

Phase 3 (CWF improvements):
- W5 (internal cleanup), W6 (refactor --docs), W8 (ship/review)

Phase 4 (external-facing):
- W9 (README.ko.md)

## Dependencies

```text
W10 (dogfood) ─→ all other workstreams (need cache sync to test)
W7 (state) ─→ W5 (cleanup needs state design)
W2 (merge) ─→ W1 (CLAUDE.md index depends on final doc list)
W6 (refactor) ─→ W2 (docs-criteria references documentation-guide absorption)
```

## Delegation Strategy

- W2, W3, W4: mechanical merge/trim → good candidate for codex exec
- W5: needs codebase scan → sub-agent or codex
- W6: skill authoring → direct (small scope)
- W9: translation → codex exec with English README as source
- W1, W7, W8, W10: direct (design decisions needed)

## Out of Scope

- PLUGIN_ROOT dependency removal (Option C from earlier analysis): dogfood.sh makes this lower priority. Defer unless symlink issues arise.
- marketplace.json CWF entry: only after v3 merge to main
- Standalone plugin deprecation communication to users: separate PR after v3 merge
