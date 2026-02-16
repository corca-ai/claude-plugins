# Documentation Consistency Review

> Date: 2026-02-16
> Deterministic tool results: markdownlint 0/73 errors, check-links 0/360 errors, doc-graph 0 orphans / 0 broken refs

## 0. Deterministic Gate Results

All three deterministic tools pass cleanly:

| Tool | Result |
|------|--------|
| markdownlint-cli2 | 73 files, 0 errors |
| check-links (local) | 360 links, 0 errors, 17 excluded |
| doc-graph | 70 docs, 364 links, 0 orphans, 0 broken refs |

No lint-level or structural issues detected by automation.

## 1. Agent Entry Docs Review

### AGENTS.md (96 lines)

**Strengths:**
- Well within the <100 line ideal for always-loaded files
- Index-shaped: routing map with clear scope descriptions per linked doc
- Clean separation between Operating Invariants (behavioral) and Document Map (navigation)
- CWF:INDEX managed block enables automated refresh

**Findings:**

| Severity | Finding | Classification |
|----------|---------|---------------|
| LOW | "Before Editing Docs" section duplicates routing already in Document Map | NON_AUTOMATABLE — routing consolidation is judgment-level |
| LOW | AGENTS.md self-references itself in the Document Map (line 33: `[AGENTS](AGENTS.md)`) | AUTO_CANDIDATE — could add a lint rule to flag self-referencing entries |

### CLAUDE.md (14 lines)

**Strengths:**
- Extremely thin adapter — only Claude-specific runtime deltas
- Correctly delegates to AGENTS.md as primary reference
- No duplication of AGENTS.md content

**Findings:** None. This is a model adapter file.

## 2. Project Context Review (docs/project-context.md)

| Check | Status | Detail |
|-------|--------|--------|
| Plugin listing matches plugins/ | WARN | No explicit plugin list — refers to CWF implicitly. Since there's only one plugin (cwf), this is acceptable but could become stale if plugins are added. |
| Architecture patterns current | PASS | All referenced plugins/scripts exist |
| Convention entries match practice | PASS | Conventions align with observed behavior |
| Process heuristics current | PASS | 20+ heuristics all reference valid concepts and files |

## 3. README Review

### README.md (477 lines)

| Check | Status | Detail |
|-------|--------|--------|
| Overview table matches marketplace.json | **FAIL** | README lists 13 skills in table (includes hitl), but marketplace.json says "12 skills" and omits hitl from list and keywords |
| Active plugins have install/update | PASS | Clear install, setup, and update instructions |
| Deprecated plugins marked | PASS | "Standalone plugins (legacy)" section clearly explains v3.0 removal |
| Dead links | PASS | doc-graph confirms 0 broken refs |

### README.ko.md (541 lines) — SSOT

| Check | Status | Detail |
|-------|--------|--------|
| Structure mirrors English | PASS | Same major sections in same order |
| Content mirrors English | WARN | Korean version has "설계 의도" (Design Intent) + "무엇을 하는가" (What It Does) structure per skill that English version lacks. English has single unified paragraphs. |
| 13 skills listed | PASS | Both versions list 13 skills |

### README Structural Mismatch (English vs Korean SSOT)

The Korean SSOT has a richer per-skill structure:
- **설계 의도** (Design Intent / Why) — explains the design rationale
- **무엇을 하는가** (What It Does) — explains the functional behavior

The English README omits this split and uses unified paragraphs. This is a significant structural divergence from the SSOT. Since README.ko.md is declared as SSOT, README.md should mirror this structure.

## 4. Cross-Document Consistency

| Source A | Source B | Status | Issue |
|----------|----------|--------|-------|
| marketplace.json (12 skills) | README table (13 skills) | **FAIL** | marketplace.json omits `hitl` from skill count, description list, and keywords |
| marketplace.json descriptions | plugin.json descriptions | PASS | Both reference CWF correctly |
| project-context.md plugins | plugins/ directory | PASS | Only cwf exists, correctly reflected |
| AGENTS.md references | Filesystem | PASS | All referenced paths exist (doc-graph confirmed) |
| README deprecated section | marketplace.json | PASS | Consistent — no deprecated flags needed |

### Critical Fix Required

**marketplace.json** must be updated:
- Change "12 skills" to "13 skills"
- Add "hitl" to the skill list in description
- Add "hitl" to keywords array

## 5. Document Design Quality

| Check | Status | Detail |
|-------|--------|--------|
| Orphaned documents | PASS | 0 orphans per doc-graph |
| Circular references | LOW | AGENTS.md ↔ CLAUDE.md mutual reference is expected for adapter pattern |
| Inline overload | PASS | No substantive content embedded in entry docs |
| Unnecessary hard wraps | PASS | No hard-wrapped prose detected in entry docs |
| Auto-generated files in git | LOW | `.cwf/projects/` session artifacts are tracked by design (not auto-generated build output) |
| Undocumented decisions | PASS | Key decisions documented in project-context.md and README.ko.md |
| Obvious instructions | PASS | No self-evident guidance detected |
| Automation-redundant instructions | PASS | Entry docs do not duplicate hook/skill enforcement |
| Root-relative links | PASS | All links use file-relative paths |
| Scope-overlapping docs | LOW | `docs/interactive-doc-review-protocol.md` and `plugins/cwf/skills/hitl/SKILL.md` both cover review flows, but scope is distinct (docs review protocol vs code review with HITL) |

## 6. Structural Optimization

### Merge Candidates
None identified — docs have clear scope boundaries.

### Deletion Candidates
None identified.

### AGENTS/Adapter Trimming
- AGENTS.md "Before Editing Docs" section (lines 17-21): Consider merging into Document Map section as a note, since it's routing guidance.
- Net recommendation: keep as-is. The section is short (5 lines) and serves a distinct purpose (write-path routing vs read-path routing).

### Automation Promotion Candidates

| Finding | Current State | Proposed Automation |
|---------|--------------|-------------------|
| marketplace.json skill count | Manual | Script to validate marketplace.json skill count against actual `plugins/*/skills/*/SKILL.md` |
| README ↔ marketplace.json alignment | Manual | Script to compare README skill table against marketplace.json |
| AGENTS.md self-reference | Manual | Custom markdownlint rule to flag self-referencing entries in index blocks |

### Target Structure (Before/After)

No structural changes recommended. The current doc set is well-organized with clear scope per file. The only action items are:

1. **Fix marketplace.json** — add hitl (Critical)
2. **Align README.md structure** with README.ko.md SSOT (Medium)
3. **Consider automation** for marketplace.json ↔ README alignment (Low)

## Summary

| Priority | Action | Effort | Impact |
|----------|--------|--------|--------|
| P0 | Fix marketplace.json: 12→13 skills, add hitl | Small | Marketplace listing accuracy |
| P1 | Align README.md per-skill structure with README.ko.md SSOT | Medium | Documentation consistency |
| P2 | Add marketplace.json ↔ README validation script | Small | Prevent future drift |

<!-- AGENT_COMPLETE -->
