# Holistic Analysis Framework

<!-- Provenance: written at 5 skills, 7 hooks (S11a). Restructured at 9 skills, 14 hooks (S13.5-B3): PP/BI/MC → Form/Meaning/Function. -->

Three axes for cross-plugin analysis, based on semiotic decomposition (Form / Meaning / Function). Apply each to the full plugin inventory.

## Contents

- [0. Portability Baseline (Apply Across All Axes)](#0-portability-baseline-apply-across-all-axes)
- [1. Convention Compliance (Form)](#1-convention-compliance-form)
- [2. Concept Integrity (Meaning)](#2-concept-integrity-meaning)
- [3. Workflow Coherence (Function)](#3-workflow-coherence-function)

## 0. Portability Baseline (Apply Across All Axes)

Portability is a default requirement, not an opt-in check. Evaluate each axis with this baseline:

- Skills should remain repository-agnostic and avoid hard requirements on one host repository layout.
- Cross-plugin dependencies should be defensive (existence checks + graceful fallback), not fail-open or hardcoded.
- Runtime defaults (branch/language/path) should be context-aware rather than fixed values.
- Repository-specific checks should be driven by detectable context or local contracts, not unconditional assumptions.

Report portability findings with file:line evidence and propose concrete hardening actions.

## 1. Convention Compliance (Form)

Does each skill follow shared structural templates? Focus on individual skill structural consistency.

**Input**: `{PLUGIN_ROOT}/references/skill-conventions.md`

### 1a. Convention checklist verification

Read `skill-conventions.md` and verify each skill against its checklists:

- SKILL.md skeleton order (frontmatter → title/description → Quick Start/Reference → flexible workflow/phases → Rules → References)
- Frontmatter format (name, description with Triggers, allowed-tools)
- No top-level `**Language**:` declaration in SKILL.md
- Language exceptions are declared in `## Rules` when needed
- Rules section present with universal rules
- References section with correct relative paths (`../../references/`)

Flag deviations with specific file:line references.

### 1b. Pattern gaps

Identify good patterns one skill has that others should adopt:

- Language overrides: do user-facing exception skills explicitly declare output-language overrides in Rules?
- Sub-agent usage: when skills use Task tool, do they follow the mature pattern (reference guide in `references/`, parallel execution, structured output)?
- Usage message: do skills with subcommands show help when invoked with no args?
- Configuration: are env vars named consistently (`CWF_{DOMAIN}_{SETTING}`)?
- Output persistence: do skills that produce artifacts persist them as required artifacts (not optional save prompts)?
- Progressive Disclosure: do all skills follow the three-level hierarchy (metadata → body → references)?

For each gap, name the source skill (where the pattern is done well) and the target skills (where it's missing). Be specific about what to add — not "add language adaptation" but "add a Rules-level language override for synthesis output."

### 1c. Structural extraction opportunities

When 3+ skills repeat the same structural pattern, prose block, or rule text:

- Identify the repeated content
- Propose extracting it to a shared reference file under `{PLUGIN_ROOT}/references/`
- If the shared reference already exists (e.g., `skill-conventions.md`), verify skills comply with it; if not, propose fixes

Cite the repeated text, list all skills that contain it, and propose the shared reference location.

### 1d. Portability shape checks (Form)

Check structural portability hygiene:

- Hardcoded absolute/host-specific paths in SKILL instructions
- Missing path-resolution helpers where shared resolvers already exist
- Script layouts assumed without fallback

## 2. Concept Integrity (Meaning)

Does each skill implement its claimed concepts correctly? Are skills sharing a concept consistent in implementation? Focus on semantic correctness of concept composition.

**Input**: `{PLUGIN_ROOT}/references/concept-map.md`

### 2a. Per-concept implementation consistency

For each concept column in the synchronization map (Section 2 of concept-map.md):

1. Collect all skills with `x` in that column
2. Read each skill's SKILL.md
3. Compare implementations against the concept's required behavior, state, and actions (Section 1 of concept-map.md)
4. Flag:
   - **Inconsistency**: two skills implement the same concept differently without justification
   - **Missing implementation**: concept marked in map but not reflected in SKILL.md
   - **Incorrect implementation**: skill claims to use concept but violates its required behavior

**Example**: Expert Advisor is composed by clarify, retro, review. All three should select from `expert_roster`, use contrasting frameworks, and synthesize tension. If one skips contrast, flag as inconsistent.

### 2b. Under-synchronization detection

Scan for sparse rows and missing marks in the synchronization map:

- A skill that performs expert-like analysis but doesn't compose Expert Advisor
- A skill that routes decisions but doesn't compose Tier Classification
- A skill that parallelizes work but doesn't compose Agent Orchestration

These are potential missing synchronizations — the skill uses the concept's behavior informally without its full structure.

### 2c. Over-synchronization / concept overloading detection

Scan for skills that overload a concept beyond its stated purpose:

- A skill using Agent Orchestration not just for parallelism but also for decision routing (overloading with Tier Classification's purpose)
- A skill using Expert Advisor not just for blind spot reduction but also for parallelism (overloading with Agent Orchestration's purpose)
- Any concept serving two distinct purposes within one skill

**How to report**: For each finding, cite the specific skill, the concept involved, the expected behavior (from concept-map.md), and the actual behavior (from SKILL.md). Propose whether to fix the implementation or update the concept definition.

### 2d. Portability semantics (Meaning)

Check whether skill meaning implies repository lock-in:

- Claimed generic behavior but implementation semantics require one repository's policies/files to exist
- Missing explicit distinction between CWF capability contract vs host-repo local policy

## 3. Workflow Coherence (Function)

Do skills connect properly in the workflow? Are triggers unambiguous? Are data flows complete? Focus on inter-skill operational behavior.

**Input**: Condensed inventory map (from holistic Phase 1)

### 3a. Data flow completeness

Check that skill outputs connect to downstream skill inputs:

- Skill A produces output that Skill B should consume — is the connection documented?
- Are output formats consumable by the expected downstream skills?
- Are there orphaned outputs (produced but never consumed)?

### 3b. Trigger clarity

Check that each skill can be unambiguously invoked:

- Multiple skills that could trigger on the same user intent
- Descriptions that don't clearly differentiate from similar skills
- Hook conflicts (multiple hooks on the same matcher with conflicting behavior)

For each ambiguity, list the conflicting skills, describe the ambiguous user intent, and propose a resolution (clearer descriptions, merge, or explicit routing guidance).

### 3c. Workflow automation opportunities

Identify manual steps that could be automated:

- A workflow requiring manual invocation of multiple skills in sequence
- Skills that do internal research when another skill already provides that capability
- Hook infrastructure that could bridge two skills but doesn't

**How to report**: For each finding, describe the flow (A → B), what's currently broken or manual, and propose a concrete fix. Include defensive check requirements — connections must work when either skill is not installed.

### 3d. Workflow portability (Function)

Check runtime behavior under repository variance:

- Stage flow should degrade gracefully when optional docs/inventory files are missing
- Automation should surface deterministic warnings instead of silent skips or brittle hard failures

**Important constraints on connections**:

- Cross-plugin dependencies must be defensive (gate on existence)
- Prefer lightweight suggestions ("Consider running /X") over hard dependencies
- Don't create circular dependencies
