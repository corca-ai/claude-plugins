# Deep Review: setup -- Quality + Concept (Criteria 5-8)

<!-- Provenance: SKILL.md 850 lines / 3685 words, 6 scripts, 0 references, concept-map row: sparse (no concepts). Reviewed at marketplace-v3 HEAD 226cdd1. -->

## Criterion 5: Writing Style

### 5.1 Imperative Form

The skill consistently uses imperative/infinitive form throughout. Examples:

- "Configure which hook groups are active" (Phase 1)
- "Run the following checks via Bash" (Phase 2.1)
- "Edit `cwf-state.yaml` `tools:` section" (Phase 2.2)
- "Ask the user" (Phase 5.1)

**Verdict**: PASS -- no "You should" or passive voice patterns detected.

### 5.2 Conciseness

The SKILL.md is 850 lines / 3685 words. Per Criterion 1 thresholds:
- Word count 3685 > 3000: **warning** triggered
- Line count 850 > 500: **warning** triggered

The high line/word count is driven by the number of distinct phases (1, 2, 2.4, 2.5, 2.6, 2.7, 2.8, 2.9, 3, 4, 5) and the verbose inline code fences for expected output formatting.

**Findings**:

| ID | Severity | Location | Finding |
|----|----------|----------|---------|
| WS-1 | warning | Phases 2.4-2.6 | Codex integration spans three phases (2.4, 2.5, 2.6) with overlapping prose. Phase 2.4 is the full-setup entrypoint; Phases 2.5 and 2.6 are flag-specific reruns. The overlap in description of what `sync-skills.sh` and `install-wrapper.sh` do could be consolidated. Consider extracting the Codex integration explanation into `references/codex-integration.md` and keeping only the procedural steps and script invocations in SKILL.md. |
| WS-2 | info | Phase 2.6.3 | The three `CWF_CODEX_POST_RUN_*` env vars are documented inline. These are runtime tuning knobs, not procedural knowledge. Could move to a reference or rely on the wrapper script's own `--help`. |
| WS-3 | info | Phase 4.2 | The repository index build rules (ordering policy, link policy, description policy) are detailed and lengthy. These are reference-grade rules that could live in `references/index-build-rules.md` with a pointer in SKILL.md. |
| WS-4 | info | Rules section | 20 rules is high for a single skill. Rules 1-20 are a mix of operational constraints and UX policies. Grouping or moving the less critical ones to a reference would reduce body weight. |

### 5.3 Information the Agent Already Knows

| ID | Severity | Location | Finding |
|----|----------|----------|---------|
| WS-5 | info | Phase 2.1 | The `command -v` check pattern is basic shell knowledge. The inline code block is appropriate here because it serves as a precise enumeration of which tools to check, not a teaching exercise. No action needed. |

### 5.4 Extraneous Documentation

No README.md, INSTALLATION_GUIDE.md, or similar extraneous docs were created. The README.md in the skill directory is a file map (consistent with the `Do not enumerate skill-internal files in index bullets; add one concise sentence that skill-local READMEs contain per-skill file maps` convention).

**Verdict**: PASS.

---

## Criterion 6: Degrees of Freedom

### 6.1 Freedom-Fragility Match Analysis

| Phase | Task Nature | Current Freedom Level | Appropriate? | Notes |
|-------|-------------|----------------------|--------------|-------|
| 1: Hook Group Selection | Config file write with exact format | Low (specific script pattern) | Yes | `cwf-hooks-enabled.sh` has a strict format contract with `cwf-hook-gate.sh`. Low freedom is correct. |
| 2: Tool Detection | Shell probes | Low (specific commands) | Yes | Exact `command -v` checks ensure deterministic results. |
| 2.3.1: Dep Install | System-level install | Low (dedicated script) | Yes | Fragile operation correctly delegated to `install-tooling-deps.sh`. |
| 2.4-2.6: Codex Integration | Symlink + wrapper install | Low (dedicated scripts) | Yes | Shell-level changes are fragile; correctly uses scripts. |
| 2.7: Git Hook Gate | Hook file generation | Low (dedicated script) | Yes | `configure-git-hooks.sh` generates exact hook file content. |
| 2.8: Env Migration | Profile editing | Low (dedicated script) | Yes | Editing `~/.zshrc` is fragile; correctly delegated to `migrate-env-vars.sh`. |
| 2.9: Agent Team Mode | JSON editing | Low (dedicated script) | Yes | Editing `~/.claude/settings.json` is fragile; correctly uses `configure-agent-teams.sh` with jq. |
| 3: CWF Cap Index | Content generation | Medium-High (text guidance) | Appropriate | Agent generates markdown index content. Multiple valid phrasings exist. The validation script (`check-index-coverage.sh`) acts as a safety net. |
| 4: Repo Index | Content generation | Medium-High (text guidance) | Appropriate | Same rationale as Phase 3. Coverage validation provides the necessary constraint. |
| 5: Lessons | Free-form capture | High (text guidance) | Yes | Lessons are inherently subjective. |

**Findings**:

| ID | Severity | Location | Finding |
|----|----------|----------|---------|
| DF-1 | pass | All phases | Freedom levels are well-matched to fragility. Fragile operations (shell profile edits, JSON edits, hook file generation, symlink management) all use dedicated scripts. Content generation phases appropriately use text guidance with validation scripts as guardrails. |

**Verdict**: PASS -- no mismatches detected.

---

## Criterion 7: Anthropic Compliance

### 7.1 Folder Naming

- Plugin folder: `cwf` -- kebab-case (single word, valid).
- Skill folder: `setup` -- kebab-case (single word, valid).

**Verdict**: PASS.

### 7.2 SKILL.md Metadata

Frontmatter:
```yaml
name: setup
description: "Initial CWF configuration to standardize environment/tool contracts..."
```

| Check | Result | Notes |
|-------|--------|-------|
| Contains only `name`, `description`, (optional `allowed-tools`) | PASS | No extra fields. |
| No XML tags in frontmatter values | PASS | |
| `name` matches skill folder name | PASS | `setup` == `setup` |

**Verdict**: PASS.

### 7.3 Description Quality

Description text (measured):
> "Initial CWF configuration to standardize environment/tool contracts before workflow execution: hook group selection, external tool detection, env migration + project config bootstrap, optional Agent Team mode setup, optional Codex integration, optional git hook gate installation, optional CWF capability index generation, and optional repository index generation. Triggers: "cwf:setup", "setup hooks", "configure cwf""

| Check | Result | Notes |
|-------|--------|-------|
| Length <= 1024 characters | PASS | ~390 characters. |
| What it does | PASS | "Initial CWF configuration to standardize environment/tool contracts" |
| When to use it | PASS | "before workflow execution" |
| Trigger phrases | PASS | `cwf:setup`, `setup hooks`, `configure cwf` |
| Key capabilities | PASS | Lists all 8 capability areas. |

**Findings**:

| ID | Severity | Location | Finding |
|----|----------|----------|---------|
| AC-1 | info | Description | The description is dense but functional. The enumeration of all 8 optional capabilities makes it read like a feature list rather than a natural trigger description. Consider a shorter summary with the capability list in the body. However, this does not violate any hard rule. |

**Verdict**: PASS.

### 7.4 Composability

| Check | Result | Notes |
|-------|--------|-------|
| Does not duplicate other skills | PASS | Setup is the only skill that handles hook config, tool detection, env migration, git hook gates, and index generation. No overlap with other skills. |
| Cross-skill references use defensive checks | PASS | Phase 3.1 uses `(if present)` guards on file references. Phase 4 scans with existence checks. |
| Output consumable by other skills | PASS | Produces `cwf-state.yaml` (SSOT consumed by all skills), `cwf-hooks-enabled.sh` (consumed by hook gate), and index files (consumed by refactor/review). |
| No hard dependencies on other plugins | PASS | Codex integration is opt-in. All external tool integrations are gated by availability checks. |

**Findings**:

| ID | Severity | Location | Finding |
|----|----------|----------|---------|
| AC-2 | info | Phase 2.7.3 | The generated pre-commit hook references `plugins/cwf/skills/refactor/scripts/check-links.sh` with a hardcoded path. If refactor skill is moved or renamed, this breaks. This is a cross-skill coupling point, though it is inside a generated script (not a runtime dependency of setup itself). |
| AC-3 | info | Phase 2.7.3 | Similarly, the generated pre-push hook references `plugins/cwf/skills/setup/scripts/check-index-coverage.sh` and `plugins/cwf/scripts/provenance-check.sh` and `plugins/cwf/scripts/check-growth-drift.sh`. These are checked with `-x` guards in the generated scripts, which is correct defensive behavior. |

**Verdict**: PASS (with informational notes on cross-skill path coupling in generated hooks).

---

## Criterion 8: Concept Integrity

### 8.1 Synchronization Map Lookup

From `concept-map.md` Section 2:

```
| setup | | | | | | |
```

The setup row is entirely empty -- no generic concepts claimed. The map explicitly notes:

> **Sparse row** (setup, ship, update) = infrastructure/operational skill, no generic concept synchronization

### 8.2 Verification: Is the Empty Row Correct?

I need to check whether setup exhibits behavior matching any of the six concepts without claiming them.

| Concept | Does setup exhibit this behavior? | Evidence | Verdict |
|---------|----------------------------------|----------|---------|
| Expert Advisor | No | Setup does not invoke domain experts or contrasting frameworks. All decisions are binary user choices (enable/disable, install/skip). | Correctly unclaimed |
| Tier Classification | No | Setup does not classify decisions by evidence strength. It presents direct user choices without evidence gathering. | Correctly unclaimed |
| Agent Orchestration | No | Setup does not spawn sub-agents or parallelize work. It runs sequentially through phases with user interaction at each step. | Correctly unclaimed |
| Decision Point | Borderline | Setup decomposes configuration into explicit choices (hook groups, tool install, env migration, git hooks, agent teams). However, these are not "ambiguity in requirements" -- they are direct configuration preferences with no evidence-gathering step. The concept requires "each point is subjected to evidence gathering before deciding" which setup does not do. | Correctly unclaimed |
| Handoff | No | Setup does not produce `next-session.md` or `phase-handoff.md`. It writes to `cwf-state.yaml` and `lessons.md`, but these are operational artifacts, not handoff documents. The lessons capture (Phase 5) is a standard session artifact pattern, not a handoff concept composition. | Correctly unclaimed |
| Provenance | No | Setup does not check staleness of reference documents or attach provenance metadata. It generates fresh content (indexes) and writes fresh config. There is no "check whether system has changed significantly" step. | Correctly unclaimed |

### 8.3 Concept Integrity Verdict

| ID | Severity | Finding |
|----|----------|---------|
| CI-1 | pass | The empty concept row for setup is correct. Setup is a pure infrastructure/operational skill. Its user interactions are direct configuration choices, not evidence-routed decision points. It does not compose any generic concept, and no unclaimed concept behavior was detected. |

**Verdict**: PASS -- the sparse row accurately reflects setup's nature as an infrastructure skill with no generic concept composition.

---

## Summary

| Criterion | Verdict | Key Findings |
|-----------|---------|--------------|
| 5. Writing Style | PASS (with warnings) | Imperative form used consistently. Size warnings triggered (3685 words, 850 lines). Codex phases and index build rules could be extracted to references to reduce body weight. |
| 6. Degrees of Freedom | PASS | All fragile operations correctly delegated to scripts. Content generation phases use text guidance with validation guardrails. No mismatches. |
| 7. Anthropic Compliance | PASS | Folder naming, metadata, description, and composability all conform. Minor informational note on cross-skill path coupling in generated git hooks. |
| 8. Concept Integrity | PASS | Empty concept row is correct. Setup is infrastructure/operational with no generic concept composition. No unclaimed concept behavior detected. |

### Actionable Items (Priority Order)

1. **WS-1** (warning): Extract Codex integration detailed explanation (Phases 2.4-2.6 overlap) into `references/codex-integration.md` to reduce SKILL.md body by ~100 lines.
2. **WS-3** (info): Consider extracting repository index build rules (Phase 4.2 ordering/link/description policies) into `references/index-build-rules.md`.
3. **WS-4** (info): Consider grouping the 20 rules into categories or moving operational-detail rules to a reference.
4. **AC-2** (info): Document or gate the hardcoded `refactor/scripts/check-links.sh` path in generated git hooks for resilience against future skill reorganization.

<!-- AGENT_COMPLETE -->
