# Deep Review: Remaining Skills (handoff, hitl, ship, run, update)

Combined review of five smaller CWF skills against all eight review criteria (Structural 1-4, Quality 5-8).

---

## 1. Handoff

**File**: `/home/hwidong/codes/claude-plugins/plugins/cwf/skills/handoff/SKILL.md`
**Stats**: ~2072 words, 415 lines
**Concept map row**: Handoff (x)

### Criterion 1: Size

| Metric | Value | Threshold | Status |
|--------|-------|-----------|--------|
| Words | ~2072 | 3000w warning | PASS |
| Lines | 415 | 500L warning | PASS |

Healthy. Below both warning thresholds.

### Criterion 2: Progressive Disclosure

**Frontmatter**: Contains `name` and `description` only. Description includes what ("auto-generate session or phase handoff documents"), when (triggers listed), and key modes (`--phase`). Acceptable length, well under 1024 chars.

**Body structure**: Procedural workflow across 5 phases plus rules. The "9 Required Sections" block in Phase 3 is the largest section and includes full markdown templates inline. These templates are moderately sized and serve as the canonical format specification, so inlining is defensible since they are the core procedural knowledge.

**Red flags**:
- None. No "When to Use" section in the body. No API docs or lookup tables.

**Verdict**: PASS

### Criterion 3: Duplication

The skill references `plan-protocol.md` (Handoff Document section) for the canonical template format. Phase 3 in the SKILL.md body then provides a detailed, section-by-section breakdown of the 9 required sections with full markdown templates. This overlaps with `plan-protocol.md` lines 98-129 which describe the Handoff Document and its Execution Contract.

**Finding**: Moderate duplication between Phase 3 "Execution Contract" section (lines 185-205) and `plan-protocol.md` lines 106-129. Both define the same branch gate, commit gate, and staging policy in similar wording. Rule 1 says "Read plan-protocol.md for format," but then the SKILL.md re-specifies the contract in full.

**Recommendation**: Keep the detailed breakdown in SKILL.md (it is the procedural guide the agent follows) but reduce the Execution Contract to a pointer: "Include the Execution Contract as defined in plan-protocol.md lines 106-129." This removes the maintenance burden of keeping two copies synchronized.

**Verdict**: WARNING (moderate overlap with plan-protocol.md on Execution Contract)

### Criterion 4: Resource Health

**Referenced resources**:
- `plan-protocol.md` -- referenced in Rules and Phase 3. Exists at `../../references/plan-protocol.md`.
- `agent-patterns.md` -- referenced in References section. Exists at `../../references/agent-patterns.md`.

**Skill-local resources**: No `references/`, `scripts/`, or `assets/` directories. All resources are shared plugin-level references.

**Unused resources**: N/A -- no local resource files.

**Verdict**: PASS

### Criterion 5: Writing Style

The skill uses imperative/infinitive form consistently ("Read cwf-state.yaml", "Determine the current session", "Write next-session.md"). Clear procedural language throughout. No extraneous documentation.

Minor observation: Korean keywords appear in Phase 1.3 for lesson detection ("구현은 별도 세션", "스코프 밖"). These are appropriate since lessons may be written in Korean per the lessons protocol.

**Verdict**: PASS

### Criterion 6: Degrees of Freedom

The handoff document generation involves significant user-facing output that must maintain consistency across sessions. The SKILL.md provides detailed templates for all 9 sections (low freedom) and clear rules for content sourcing (medium freedom). This is appropriate -- the format is fragile (must be consumable by future agents), while content gathering is context-dependent.

**Verdict**: PASS

### Criterion 7: Anthropic Compliance

- **Folder naming**: `handoff` -- kebab-case, matches `name` field. PASS.
- **Frontmatter**: Only `name` and `description`. No XML tags. PASS.
- **Description quality**: 282 chars. Includes what, when, triggers, and modes. PASS.
- **Composability**: References `plan-protocol.md` via relative path. Uses `AskUserQuestion` for disambiguation. References `cwf-state.yaml` as SSOT. No hard dependencies on other skills. PASS.

**Verdict**: PASS

### Criterion 8: Concept Integrity

**Map claims**: Handoff (x)

**Handoff concept verification**:

| Check | Required | Present | Status |
|-------|----------|---------|--------|
| Session handoffs (next-session.md) carry task scope, lessons, unresolved items | Yes | Phase 3: 9 sections including Task Scope, Lessons, Unresolved Items (Phase 4b) | PASS |
| Phase handoffs (phase-handoff.md) carry HOW context | Yes | Phase 3b: explicit HOW vs WHAT separation, Design Decisions, Protocols, Prohibitions | PASS |
| Plan carries WHAT, handoff carries HOW | Yes | Rule 11: "Phase handoff captures HOW, not WHAT" | PASS |

**Required state**:

| Element | Present | Status |
|---------|---------|--------|
| Session artifacts (plan.md, lessons.md, retro.md, phase-handoff.md) | Phase 1.3 reads all four | PASS |
| Unresolved items (deferred, unimplemented, retro items) | Phase 4b: three sources explicitly defined | PASS |
| Project state (cwf-state.yaml) | Phase 1.1 and Phase 4 | PASS |

**Required actions**:

| Action | Present | Status |
|--------|---------|--------|
| Scan session artifacts for context | Phase 1.3 | PASS |
| Propagate unresolved items | Phase 4b with scoping rules | PASS |
| Generate handoff document (session or phase) | Phase 3 and 3b | PASS |
| Register session in project state | Phase 4 | PASS |

**Unclaimed concepts**: The skill does not exhibit Expert Advisor, Tier Classification, Agent Orchestration, Decision Point, or Provenance behavior. No missing synchronization.

**Verdict**: PASS -- Full implementation of the Handoff concept.

### Handoff Summary

| Criterion | Verdict |
|-----------|---------|
| 1. Size | PASS |
| 2. Progressive Disclosure | PASS |
| 3. Duplication | WARNING -- Execution Contract duplicated from plan-protocol.md |
| 4. Resource Health | PASS |
| 5. Writing Style | PASS |
| 6. Degrees of Freedom | PASS |
| 7. Anthropic Compliance | PASS |
| 8. Concept Integrity | PASS |

---

## 2. HITL

**File**: `/home/hwidong/codes/claude-plugins/plugins/cwf/skills/hitl/SKILL.md`
**Stats**: ~1235 words, 209 lines
**Concept map row**: (no concepts claimed)

### Criterion 1: Size

| Metric | Value | Threshold | Status |
|--------|-------|-----------|--------|
| Words | ~1235 | 3000w warning | PASS |
| Lines | 209 | 500L warning | PASS |

Compact and well within limits.

### Criterion 2: Progressive Disclosure

**Frontmatter**: Contains `name` and `description` only. Description includes what ("human-in-the-loop diff/chunk review"), when (triggers listed), and key capabilities ("resumable state, agreement-round kickoff, rule propagation"). Under 1024 chars.

**Body structure**: Clean phase progression (0 through 4) with a state model section, chunk review loop, rule capture, and resume/close. All content is procedural workflow knowledge appropriate for the body.

**Red flags**: None. No "When to Use" section in body. No long code examples that should be in references.

**Verdict**: PASS

### Criterion 3: Duplication

No `references/` directory. The skill is self-contained. The state model (YAML structures) is defined only here. The chunk review format is unique to this skill.

No duplication detected with other skills or shared references.

**Verdict**: PASS

### Criterion 4: Resource Health

**Referenced resources**: None local. The skill references no `references/`, `scripts/`, or `assets/` files.

**Observation**: The skill defines a complex state model (`state.yaml`, `queue.json`, `rules.yaml`, `fix-queue.yaml`, `hitl-scratchpad.md`, `events.log`) entirely in the SKILL.md body. These are runtime artifacts, not reference files, so this is appropriate.

**Unused resources**: N/A.

**Verdict**: PASS

### Criterion 5: Writing Style

Uses imperative form throughout ("Resolve base branch", "Build file queue", "Normalize rule text"). Concise and direct. The Phase 2 chunk review output format uses a numbered list that reads as a specification, which is appropriate for the "low freedom" nature of the review output.

One style inconsistency: line 135 mixes Korean and English ("EOF 여부") in the chunk output format. This is a minor stylistic choice reflecting the bilingual user context.

**Verdict**: PASS

### Criterion 6: Degrees of Freedom

The skill deals with interactive human review -- a process that needs precise state management (low freedom for state model and persistence) but flexible human interaction (high freedom for review discussion). The SKILL.md appropriately provides:
- **Low freedom**: State model schema, chunk output format (7 required elements), file/chunk status transitions
- **High freedom**: Review discussion content, rule formulation, agreement round topics

**Verdict**: PASS

### Criterion 7: Anthropic Compliance

- **Folder naming**: `hitl` -- kebab-case. PASS.
- **Frontmatter**: Only `name` and `description`. No XML tags. PASS.
- **Description quality**: 229 chars. Includes what, when, triggers. PASS.
- **Composability**: Does not duplicate other skills' functionality. The `cwf:review --human` alias connects it to the review skill as a human-facing variant. Output state files could be consumed by other skills. No hard dependencies. PASS.

**Verdict**: PASS

### Criterion 8: Concept Integrity

**Map claims**: None (sparse row -- infrastructure/operational skill).

**Unclaimed concept check**:
- **Tier Classification**: The skill does route some decisions (immediate fix vs. fix-queue) but this is a local policy, not the evidence-strength-based T1/T2/T3 routing of the Tier Classification concept. No missing sync.
- **Provenance**: The skill tracks `blob_sha` and detects stale chunks, which superficially resembles Provenance's staleness detection. However, this is file-level change detection for review resumption, not reference-document staleness checking. No missing sync.
- **Handoff**: The skill has resumable state (`--resume`), but this is session-internal state persistence, not cross-session context transfer. No missing sync.

**Verdict**: PASS -- No concepts claimed, none should be.

### HITL Summary

| Criterion | Verdict |
|-----------|---------|
| 1. Size | PASS |
| 2. Progressive Disclosure | PASS |
| 3. Duplication | PASS |
| 4. Resource Health | PASS |
| 5. Writing Style | PASS |
| 6. Degrees of Freedom | PASS |
| 7. Anthropic Compliance | PASS |
| 8. Concept Integrity | PASS |

---

## 3. Ship

**File**: `/home/hwidong/codes/claude-plugins/plugins/cwf/skills/ship/SKILL.md`
**Stats**: ~1495 words, 304 lines
**Concept map row**: (no concepts claimed)

### Criterion 1: Size

| Metric | Value | Threshold | Status |
|--------|-------|-----------|--------|
| Words | ~1495 | 3000w warning | PASS |
| Lines | 304 | 500L warning | PASS |

### Criterion 2: Progressive Disclosure

**Frontmatter**: Contains `name` and `description` only. Description includes what ("automate GitHub workflow") and when (trigger: "/ship"). However, the description is relatively sparse -- it does not list key capabilities (issue creation, PR creation, merge automation, status checking).

**Body structure**: Well-organized by subcommand (`/ship issue`, `/ship pr`, `/ship merge`, `/ship status`). Each subcommand has a clear workflow. The PR body variable substitution table (lines 118-147) is moderately detailed but appropriate as core procedural knowledge.

**Red flags**: None.

**Verdict**: PASS

### Criterion 3: Duplication

The skill references two template files:
- `references/issue-template.md` -- 32 lines, defines the issue body template with `{VARIABLES}`.
- `references/pr-template.md` -- 65 lines, defines the PR body template with `{VARIABLES}`.

The SKILL.md body defines the variable substitution rules (what each `{VARIABLE}` maps to) while the templates define the structure. This is a clean separation -- no duplication.

**Verdict**: PASS

### Criterion 4: Resource Health

**Referenced resources**:
- `references/issue-template.md` -- referenced in `/ship issue` workflow step 2. EXISTS.
- `references/pr-template.md` -- referenced in `/ship pr` workflow step 3. EXISTS.
- `agent-patterns.md` -- referenced in References section. EXISTS at shared level.

Both template files are short (32 and 65 lines respectively), under the 100-line threshold for requiring a TOC. Neither exceeds 10k words.

**Unused resources**: No unreferenced files found.

**Verdict**: PASS

### Criterion 5: Writing Style

Uses imperative form ("Detect session context", "Compose issue body", "Create issue"). The prerequisite check section includes inline bash commands which is appropriate for a low-freedom operation.

**Issue**: The Language section on line 11 is in Korean: "Issue/PR body는 한글로 작성. Code blocks, file paths, commit hashes, CLI output은 원문 유지." While the skill targets Korean-language output for GitHub artifacts, this instruction mixes Korean into what is otherwise an English SKILL.md. For agent comprehension, this works fine (Claude is multilingual), but it is a style inconsistency with the other skills which use "Language: Write artifacts in English" or similar English-language directives.

**Finding**: The hardcoded Korean-language policy ("Issue/PR body는 한글로 작성") is project-specific. If the CWF plugin is used in non-Korean projects, this would produce Korean GitHub issues/PRs regardless of user language. This should be "Write issue/PR body in the user's prompt language" for generality, or be documented as a project-specific override.

**Verdict**: WARNING -- Hardcoded Korean language policy reduces portability.

### Criterion 6: Degrees of Freedom

- **Low freedom** (appropriate): `gh` CLI commands, prerequisite checks, merge readiness decision matrix. These are fragile operations where consistency is critical.
- **Medium freedom** (appropriate): PR body variable extraction from session artifacts. The agent has guidance on sources but flexibility in synthesis.
- **High freedom**: N/A -- this is a procedural automation skill.

The decision matrix for merge readiness (line 196-203) is a particularly well-calibrated low-freedom specification for a critical operation.

**Verdict**: PASS

### Criterion 7: Anthropic Compliance

- **Folder naming**: `ship` -- kebab-case. PASS.
- **Frontmatter**: Only `name` and `description`. No XML tags. PASS.
- **Description quality**: 145 chars. Short but includes what and trigger. Missing key capabilities (issue, PR, merge, status). Could be improved. MINOR.
- **Composability**: Uses `gh` CLI as the GitHub interface (Rule 1). References session artifacts from other skills (plan.md, lessons.md, retro.md) with defensive fallbacks (placeholder text for missing files). Good composability. PASS.

**Finding**: The default base branch is hardcoded to `marketplace-v3` (line 27). This is project-specific and would break for other projects. Should default to the repository's default branch or require explicit `--base`.

**Verdict**: WARNING -- Hardcoded `marketplace-v3` default and Korean-only language policy.

### Criterion 8: Concept Integrity

**Map claims**: None (sparse row).

**Unclaimed concept check**:
- The skill does not exhibit any generic concept behavior. It is a pure operational automation wrapper around `gh` CLI. No missing synchronization.

**Verdict**: PASS

### Ship Summary

| Criterion | Verdict |
|-----------|---------|
| 1. Size | PASS |
| 2. Progressive Disclosure | PASS |
| 3. Duplication | PASS |
| 4. Resource Health | PASS |
| 5. Writing Style | WARNING -- Hardcoded Korean language policy |
| 6. Degrees of Freedom | PASS |
| 7. Anthropic Compliance | WARNING -- Hardcoded base branch, sparse description |
| 8. Concept Integrity | PASS |

---

## 4. Run

**File**: `/home/hwidong/codes/claude-plugins/plugins/cwf/skills/run/SKILL.md`
**Stats**: ~1118 words, 210 lines
**Concept map row**: Agent Orchestration (x)

### Criterion 1: Size

| Metric | Value | Threshold | Status |
|--------|-------|-----------|--------|
| Words | ~1118 | 3000w warning | PASS |
| Lines | 210 | 500L warning | PASS |

Very compact for a full-pipeline orchestrator.

### Criterion 2: Progressive Disclosure

**Frontmatter**: Contains `name` and `description` only. Description is 266 chars, includes what ("full CWF pipeline auto-chaining"), when (triggers), and the pipeline stages. Lists the pipeline order and mentions Decision #19. This is a model description.

**Body structure**: Three phases (Initialize, Pipeline Execution, Completion). The Stage Definition table (lines 59-69) is an excellent compact reference. Review failure handling is well-documented.

**Red flags**: None.

**Verdict**: PASS

### Criterion 3: Duplication

The skill references `agent-patterns.md` and `plan-protocol.md`. The stage definition table in the body is unique to this skill (it defines which skill to invoke at each stage). No content from the referenced files is duplicated in the body.

**Verdict**: PASS

### Criterion 4: Resource Health

**Referenced resources**:
- `agent-patterns.md` -- referenced in References. EXISTS.
- `plan-protocol.md` -- referenced in References. EXISTS.

No local `references/`, `scripts/`, or `assets/` directories. The skill relies on CWF-level scripts (`next-prompt-dir.sh`, `cwf-live-state.sh`, `check-session.sh`) referenced via `{CWF_PLUGIN_DIR}/scripts/`.

**Verdict**: PASS

### Criterion 5: Writing Style

Uses imperative form ("Parse task description", "Bootstrap session directory", "Invoke the skill"). The pipeline report example (lines 170-191) uses markdown table format that is clear and scannable.

**Verdict**: PASS

### Criterion 6: Degrees of Freedom

- **Low freedom** (appropriate): Stage order, gate types (auto vs. user), review failure handling (max 1 retry). These are the pipeline's invariants.
- **Medium freedom** (appropriate): `--from` and `--skip` flags allow user customization of the pipeline.
- **High freedom**: The actual content of each stage is delegated to the individual skill (Rule 5: "Preserve skill autonomy").

This is a well-calibrated orchestrator: rigid on pipeline structure, flexible on entry points, and fully delegating on stage content.

**Verdict**: PASS

### Criterion 7: Anthropic Compliance

- **Folder naming**: `run` -- kebab-case. PASS.
- **Frontmatter**: Only `name` and `description`. No XML tags. PASS.
- **Description quality**: 266 chars. Excellent -- includes what, when, pipeline stages, and key design decision. PASS.
- **Composability**: Invokes other skills via the Skill tool (not by inlining their logic). This is exemplary composability. Cross-skill references are by skill name (`cwf:gather`, `cwf:plan`, etc.), not by file path. PASS.

**Verdict**: PASS

### Criterion 8: Concept Integrity

**Map claims**: Agent Orchestration (x)

**Agent Orchestration concept verification**:

| Check | Required | Present | Status |
|-------|----------|---------|--------|
| Orchestrator assesses complexity and spawns minimum agents needed | Partial | The pipeline is a fixed sequence with --skip/--from customization, not complexity-based adaptive sizing | SEE BELOW |
| Each agent has distinct, non-overlapping work | Yes | Each stage is a distinct skill with separate scope | PASS |
| Parallel execution in batches (respecting dependencies) | No | Pipeline is strictly sequential; no parallel stage execution | WARNING |
| Outputs collected, verified, synthesized | Yes | Phase 3 runs check-session.sh and produces pipeline summary | PASS |

**Required state**:

| Element | Present | Status |
|---------|---------|--------|
| Work item decomposition | Yes -- Stage Definition table with dependencies (implied by order) | PASS |
| Agent team composition | Partial -- fixed pipeline, not adaptive team | WARNING |
| Batch execution plan | No -- sequential only | WARNING |
| Provenance metadata | No -- stage outputs not tracked with source/tool/duration | WARNING |

**Required actions**:

| Action | Present | Status |
|--------|---------|--------|
| Decompose into work items | Yes -- stages are predefined | PASS |
| Size team adaptively | No -- pipeline is fixed; "Single" pattern per agent-patterns.md is not explicitly chosen | WARNING |
| Launch parallel batch | No -- stages are sequential | WARNING |
| Collect and verify results | Yes -- check-session.sh, pipeline summary table | PASS |
| Synthesize outputs | Partial -- summary table lists status but does not merge perspectives | MINOR |

**Analysis**: The `run` skill claims Agent Orchestration but implements it as a sequential pipeline orchestrator rather than a parallel agent team. This is a reasonable architectural choice (stages have sequential dependencies: gather before clarify, plan before impl, etc.), but it diverges from the concept's emphasis on parallel batches and adaptive sizing. The `run` skill is more accurately described as "pipeline sequencing" than "agent orchestration" in the concept map's sense.

However, `run` delegates to skills that themselves compose Agent Orchestration (e.g., `cwf:impl`, `cwf:review`, `cwf:refactor` all use parallel agents internally). So `run` orchestrates orchestrators -- it is a meta-orchestrator operating at the pipeline level, not the agent level.

**Recommendation**: Either (a) redefine the concept map entry to acknowledge that `run` composes Agent Orchestration at the pipeline level (sequential stage orchestration), not at the agent level (parallel sub-agents), or (b) remove the `x` from the map since `run` does not directly implement the concept's required parallel batch execution.

**Unclaimed concepts**: No other concepts appear to be implemented.

**Verdict**: WARNING -- Agent Orchestration is claimed but partially implemented. Missing parallel execution, adaptive sizing, and provenance metadata at the pipeline level.

### Run Summary

| Criterion | Verdict |
|-----------|---------|
| 1. Size | PASS |
| 2. Progressive Disclosure | PASS |
| 3. Duplication | PASS |
| 4. Resource Health | PASS |
| 5. Writing Style | PASS |
| 6. Degrees of Freedom | PASS |
| 7. Anthropic Compliance | PASS |
| 8. Concept Integrity | WARNING -- Agent Orchestration partially implemented |

---

## 5. Update

**File**: `/home/hwidong/codes/claude-plugins/plugins/cwf/skills/update/SKILL.md`
**Stats**: ~386 words, 112 lines
**Concept map row**: (no concepts claimed)

### Criterion 1: Size

| Metric | Value | Threshold | Status |
|--------|-------|-----------|--------|
| Words | ~386 | 3000w warning | PASS |
| Lines | 112 | 500L warning | PASS |

The smallest skill in the review set. Appropriately minimal for its scope.

### Criterion 2: Progressive Disclosure

**Frontmatter**: Contains `name` and `description` only. Description is 123 chars, includes what ("check and update CWF plugin") and when (triggers). Concise and adequate.

**Body structure**: Four phases (Version Check, Apply Update, Changelog Summary, Lessons Checkpoint). Simple and linear.

**Red flags**: None.

**Verdict**: PASS

### Criterion 3: Duplication

No duplication detected. The skill's content is unique -- plugin version management is not covered by any other skill.

**Verdict**: PASS

### Criterion 4: Resource Health

**Referenced resources**:
- `agent-patterns.md` -- referenced in References section. EXISTS.

No local `references/`, `scripts/`, or `assets/` directories.

**Observation**: The reference to `agent-patterns.md` with the note "Single pattern" is appropriate -- update is a simple sequential skill that does not need parallel agents.

**Unused resources**: N/A.

**Verdict**: PASS

### Criterion 5: Writing Style

Uses imperative form ("Locate the installed plugin.json", "Run marketplace update", "Read CHANGELOG.md"). Clear and concise.

**Verdict**: PASS

### Criterion 6: Degrees of Freedom

- **Low freedom** (appropriate): `claude plugin` CLI commands, version comparison logic. These are deterministic operations.
- **Medium freedom** (appropriate): Changelog summary and skill comparison when no changelog exists.

Well-calibrated for a simple operational skill.

**Verdict**: PASS

### Criterion 7: Anthropic Compliance

- **Folder naming**: `update` -- kebab-case. PASS.
- **Frontmatter**: Only `name` and `description`. No XML tags. PASS.
- **Description quality**: 123 chars. Adequate. PASS.
- **Composability**: Self-contained. No dependencies on other skills. PASS.

**Finding**: Phase 1.1 uses a hardcoded Glob path `~/.claude/plugins/cache/corca-plugins/cwf/*/.claude-plugin/plugin.json`. This assumes a specific marketplace publisher name (`corca-plugins`) and Claude plugin cache directory structure. If either changes, the skill breaks silently. Consider resolving the plugin root dynamically (e.g., from `${CLAUDE_PLUGIN_ROOT}` or by searching for `plugin.json` more broadly).

**Verdict**: WARNING -- Hardcoded cache path assumes specific publisher and directory structure.

### Criterion 8: Concept Integrity

**Map claims**: None (sparse row).

**Unclaimed concept check**:
- **Provenance**: The skill checks version currency, which is a form of staleness detection. However, this is package-version comparison, not the reference-document staleness checking that the Provenance concept describes. No missing sync.

**Verdict**: PASS

### Update Summary

| Criterion | Verdict |
|-----------|---------|
| 1. Size | PASS |
| 2. Progressive Disclosure | PASS |
| 3. Duplication | PASS |
| 4. Resource Health | PASS |
| 5. Writing Style | PASS |
| 6. Degrees of Freedom | PASS |
| 7. Anthropic Compliance | WARNING -- Hardcoded plugin cache path |
| 8. Concept Integrity | PASS |

---

## Cross-Skill Findings

### Finding CS-1: Project-Specific Hardcoding (ship, update)

Two skills contain project-specific or environment-specific hardcoding that reduces portability:

- **ship**: Default base branch `marketplace-v3` (line 27) and Korean-only language policy (line 11).
- **update**: Hardcoded plugin cache path with `corca-plugins` publisher name (line 28).

These skills would need modification to work in non-Korean or non-corca-plugins contexts. Recommendation: Use dynamic resolution (repo default branch, `${CLAUDE_PLUGIN_ROOT}`, user prompt language) with explicit overrides.

### Finding CS-2: Reference Consistency

All five skills reference `agent-patterns.md` in their References section. The handoff skill also references `plan-protocol.md`. No skill references a non-existent file. All cross-references are valid.

### Finding CS-3: Concept Map Accuracy

| Skill | Map Claim | Actual | Status |
|-------|-----------|--------|--------|
| handoff | Handoff | Fully implemented | PASS |
| hitl | (none) | Correct -- operational skill | PASS |
| ship | (none) | Correct -- operational skill | PASS |
| run | Agent Orchestration | Sequential pipeline, not parallel agents | WARNING |
| update | (none) | Correct -- operational skill | PASS |

The `run` skill's Agent Orchestration claim is the only concept integrity concern. It operates as a sequential meta-orchestrator that delegates to skills which themselves use Agent Orchestration internally. The map should clarify this distinction or remove the claim.

### Finding CS-4: Skill Interconnections

The five skills form a coherent ecosystem:
- **run** orchestrates all other skills (including ship) as pipeline stages.
- **handoff** produces `next-session.md` that enables the next `run` invocation.
- **ship** consumes artifacts produced by all prior pipeline stages.
- **hitl** serves as an alternative to automated review within or outside the pipeline.
- **update** is independent infrastructure.

No circular dependencies. No functional duplication between these five skills.

---

## Consolidated Issue Table

| # | Skill | Criterion | Severity | Description |
|---|-------|-----------|----------|-------------|
| 1 | handoff | 3. Duplication | WARNING | Execution Contract duplicated between SKILL.md and plan-protocol.md |
| 2 | ship | 5. Style | WARNING | Hardcoded Korean-only language policy for issue/PR body |
| 3 | ship | 7. Compliance | WARNING | Default base branch hardcoded to `marketplace-v3` |
| 4 | ship | 7. Compliance | MINOR | Description could list key capabilities (issue, PR, merge, status) |
| 5 | run | 8. Concept | WARNING | Agent Orchestration claimed but only sequential pipeline implemented |
| 6 | update | 7. Compliance | WARNING | Hardcoded `~/.claude/plugins/cache/corca-plugins/` path |

Total: 5 warnings, 1 minor across 5 skills. No errors. The hitl skill is the cleanest, passing all criteria without findings.

<!-- AGENT_COMPLETE -->
