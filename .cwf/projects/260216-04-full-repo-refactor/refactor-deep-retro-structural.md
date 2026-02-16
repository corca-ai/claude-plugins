# Structural Review: retro Skill (Criteria 1-4)

> Reviewer: agent (structural)
> Date: 2026-02-16
> Skill: `plugins/cwf/skills/retro/SKILL.md`
> Scope: Size, Progressive Disclosure, Duplication, Resource Health

---

## 1. SKILL.md Size

| Metric | Value | Threshold | Verdict |
|--------|-------|-----------|---------|
| Word count | 3,151 | > 3,000 = warning | **WARNING** |
| Line count | 415 | > 500 = warning | PASS |

The file sits just above the 3,000-word warning threshold (151 words over). It is well below the 5,000-word error threshold and the 500-line warning threshold.

### Heaviest sections (body only)

| Section | Words | Share |
|---------|-------|-------|
| Deep Mode Path (sub-agent orchestration) | 711 | 22.6% |
| Rules | 361 | 11.5% |
| Persist Findings | 374 | 11.9% |
| Section 7: Relevant Tools | 266 | 8.4% |
| Section 3: Waste Reduction | 178 | 5.6% |
| Output Format (light + deep templates) | ~120 | 3.8% |

The Deep Mode Path block is the single largest contributor. Its bulk comes from four long sub-agent prompt templates (Agents A-D) that are inlined as prose sentences rather than being externalized.

### Recommendation

The file is at the warning boundary, not yet critical. Two targeted extractions would bring it comfortably below 3,000 words:

1. **Extract sub-agent prompt templates** (Deep Mode Path, lines 117-136). These four prompt strings total approximately 350-400 words. Move them to a new reference file (e.g., `references/retro-agent-prompts.md`) and replace with a pointer. This also makes prompt maintenance easier -- currently editing a prompt means editing a very long inline sentence inside SKILL.md.
2. **Trim Output Format templates** (lines 347-387). The light and deep mode templates are nearly identical (differ only in Sections 5-6 placeholder text). Consider a single template with conditional notes, or move to a reference file.

Severity: **WARNING** (borderline). Actionable but not blocking.

---

## 2. Progressive Disclosure Compliance

### Metadata (frontmatter) -- PASS

```yaml
name: retro
description: "Comprehensive session retrospective that turns one session's
outcomes into persistent improvements. Adaptive depth: deep by default, with
light mode via --light (and tiny-session auto-light). Triggers: \"cwf:retro\",
\"retro\", \"retrospective\", \"\ud68c\uace0\""
```

- Contains only `name` and `description`. No extra fields.
- Description covers what it does AND when to trigger (~45 words). Acceptable.
- No "When to Use This Skill" section found in the body. PASS.

### Body content -- MINOR ISSUES

**Red flag check**:

| Red flag | Present? | Details |
|----------|----------|---------|
| "When to Use" section in body | No | PASS |
| Long code examples in body | Borderline | Sub-agent prompt strings (lines 119-136) are long prose blocks embedded in the body. Not code examples per se, but they function as templates that could live in `references/`. |
| API docs / schemas / lookup tables | No | PASS |

**Sub-agent prompts as inline body content**: The four agent prompt strings (CDM Analysis, Learning Resources, Expert alpha, Expert beta) are each ~80-100 words of template text embedded as bullet-point prose. These are effectively prompt schemas. Externalizing them to `references/` would improve the body's readability and reduce load cost for light-mode invocations (which never use these prompts).

**Section 3 (Waste Reduction) 5 Whys methodology**: At 178 words this section contains a moderate amount of inline methodology (root cause drill-down framework, four-category classification). This is procedural knowledge directly needed during retro execution, so it is reasonable in the body. No action needed.

**Section 7 (Relevant Tools) at 266 words**: Contains a multi-step workflow (inventory, gap analysis, action path by category). This is orchestration-level procedural knowledge. Acceptable in the body, though borderline.

### Bundled resources -- PASS

Both reference files are under 1,000 words (well below 10k). No grep patterns needed. Resources are loaded on demand by sub-agents, not eagerly by the skill body.

### Verdict

Progressive disclosure is well-structured overall. The main improvement opportunity is externalizing the sub-agent prompt templates from the Deep Mode Path section, which would benefit both token budget (they are irrelevant in light mode) and maintainability.

---

## 3. Duplication Check

### SKILL.md vs `references/cdm-guide.md`

| Overlap area | SKILL.md location | Reference location | Severity |
|-------------|-------------------|-------------------|----------|
| "Identify 2-4 critical decisions" | Section 4, line 180 | cdm-guide.md Methodology step 1, line 36 | LOW |
| "Apply CDM probes" | Section 4, line 180 | cdm-guide.md Methodology, lines 36-48 | LOW |

SKILL.md's Section 4 description is a one-line summary ("Identify 2-4 critical decision moments... Apply CDM probes to each.") that points to the reference for methodology. The reference contains the full probe table, methodology steps, constraints, and output format. This is correct progressive disclosure: summary in SKILL.md, detail in reference.

The sub-agent prompt for Agent A (line 119) says "Read `{SKILL_DIR}/references/cdm-guide.md`. Analyze the following session summary using CDM methodology." This delegates to the reference rather than duplicating it. PASS.

### SKILL.md vs `references/expert-lens-guide.md`

| Overlap area | SKILL.md location | Reference location | Severity |
|-------------|-------------------|-------------------|----------|
| Expert selection priority (deep-clarify first, independent second) | Section 5, lines 188-190 | expert-lens-guide.md, lines 9-15 | MEDIUM |

SKILL.md Section 5 (lines 188-190) restates the expert selection priority:
> 1. Scan the conversation for `/deep-clarify` invocations. If found, extract expert names and use them as preferred starting points.
> 2. If no deep-clarify experts available, select independently per `{SKILL_DIR}/references/expert-lens-guide.md`.

The reference file `expert-lens-guide.md` (lines 9-15) contains the same two-step priority with more detail. This is a partial duplication: SKILL.md provides a condensed version and then points to the reference. The condensed version is useful for the orchestrator to know *what* to pass to sub-agents, so it serves a routing purpose. However, the two descriptions could drift independently.

**Recommendation**: Reduce SKILL.md Section 5 expert selection to a single line: "Expert selection follows `{SKILL_DIR}/references/expert-lens-guide.md` (deep-clarify experts preferred when available)." This preserves the routing hint while eliminating the duplicated two-step list.

### Cross-reference integrity

The sub-agent prompts for Agents C and D (lines 135-136) tell sub-agents to "Read `{SKILL_DIR}/references/expert-lens-guide.md`" and include "Deep-clarify experts: {names or 'not available'}" in the prompt. This correctly delegates expert selection to the reference without duplicating the logic inline. PASS.

### Verdict

One medium-severity duplication found (expert selection priority). Otherwise, the skill follows correct progressive disclosure with summaries in SKILL.md and details in references.

---

## 4. Resource Health

### 4.1 File Quality

| File | Words | Lines | ToC needed? | Grep patterns needed? |
|------|-------|-------|-------------|----------------------|
| `references/cdm-guide.md` | 481 | 74 | No (< 100 lines) | No (< 10k words) |
| `references/expert-lens-guide.md` | 479 | 77 | No (< 100 lines) | No (< 10k words) |

Both reference files are well-sized: concise, focused, and self-contained. No quality flags.

**Nested references check**: Neither reference file references another reference file. One level deep from SKILL.md. PASS.

### 4.2 Unused Resources

**Files in `references/`**:

| File | Referenced in SKILL.md? | Evidence |
|------|------------------------|---------|
| `cdm-guide.md` | Yes | Lines 177, 119, 413 |
| `expert-lens-guide.md` | Yes | Lines 190, 135, 136, 414 |

Both reference files are referenced. No unused files.

**Files in `scripts/`**: The skill has no `scripts/` directory of its own. It references scripts from the parent plugin:

| External script | Referenced in SKILL.md? | Exists? |
|----------------|------------------------|---------|
| `{CWF_PLUGIN_DIR}/scripts/cwf-live-state.sh` | Yes (lines 31, 94) | Yes |
| `{CWF_PLUGIN_DIR}/scripts/next-prompt-dir.sh` | Yes (lines 42, 44) | Yes |
| `{CWF_PLUGIN_DIR}/scripts/retro-collect-evidence.sh` | Yes (line 51) | Yes |

All referenced scripts exist. No orphaned resources.

**External references from SKILL.md**:

| External reference | Referenced? | Exists? |
|-------------------|------------|---------|
| `../../references/context-recovery-protocol.md` | Yes (line 101) | Yes |
| `../../references/agent-patterns.md` | Yes (lines 120, 135, 136, 415) | Yes |

All external references resolve. PASS.

### 4.3 Assets directory

No `assets/` directory exists for this skill. N/A.

### Verdict

Resource health is clean. All referenced files exist, no unused files, no oversized references, no nested reference chains.

---

## Summary of Findings

| Criterion | Verdict | Key Finding |
|-----------|---------|-------------|
| 1. Size | **WARNING** | 3,151 words (151 over threshold). Deep Mode Path sub-agent prompts and Output Format templates are the main bloat contributors. |
| 2. Progressive Disclosure | **PASS with notes** | Frontmatter and body/reference split are correct. Sub-agent prompt templates are candidates for extraction to `references/`. |
| 3. Duplication | **MINOR** | Expert selection priority (Section 5 vs expert-lens-guide.md) is partially duplicated. One-line condensation recommended. |
| 4. Resource Health | **PASS** | All files referenced and present. Both references well-sized. No orphans, no nesting. |

### Actionable Recommendations (priority order)

1. **Extract sub-agent prompt templates** to `references/retro-agent-prompts.md`. Reduces SKILL.md by ~350-400 words, brings it below the 3,000-word threshold, and improves maintainability. (Addresses Criteria 1 and 2.)
2. **Condense expert selection** in Section 5 to a single-line summary with pointer. (Addresses Criterion 3.)
3. **Consider merging Output Format templates** (light/deep are nearly identical). Minor savings (~50 words) but reduces visual noise. (Addresses Criterion 1, low priority.)

<!-- AGENT_COMPLETE -->
