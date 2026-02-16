# Convention Compliance (Form) -- Holistic Analysis

> Date: 2026-02-16
> Skills analyzed: 13 CWF skills + 1 local skill (plugin-deploy)
> Reference: `plugins/cwf/references/skill-conventions.md`

---

## 1a. Convention Checklist Verification

### Section Order Compliance

Convention requires: frontmatter -> title -> Language -> Quick Start -> Phases -> Rules -> References

| Skill | Frontmatter | Title | Language | Quick Start | Phases | Rules | References | Compliant |
|-------|-------------|-------|----------|-------------|--------|-------|------------|-----------|
| setup | Y | Y | Y | Y (Quick Start) | Y | Y | Y | Y |
| gather | Y | Y | Y | Y (Quick Reference) | Y | Y | Y | Y |
| clarify | Y | Y | Y | Y (Quick Start) | Y | Y | Y | Y |
| plan | Y | Y | Y | Y (Quick Start) | Y | Y | Y | Y |
| impl | Y | Y | Y | Y (Quick Start) | Y | Y | Y | Y |
| review | Y | Y | Y | Y (Quick Reference) | Y | Y | Y | Y |
| hitl | Y | Y | Y | Y (Quick Reference) | Y | Y | Y | Y |
| retro | Y | Y | Y | Y (Quick Start) | Y | Y | Y | Y |
| ship | Y | Y | Y | Y (Commands) | Y | Y | Y | **DEVIATE** |
| run | Y | Y | Y | Y (Quick Start) | Y | Y | Y | Y |
| handoff | Y | Y | Y | Y (Quick Start) | Y | Y | Y | Y |
| refactor | Y | Y | Y | Y (Quick Reference) | Y | Y | Y | Y |
| update | Y | Y | Y | Y (Quick Start) | Y | Y | Y | Y |
| plugin-deploy | Y | Y | Y | Y (Commands) | Y | **N** | **N** | **DEVIATE** |

**Findings:**

1. **ship** (`plugins/cwf/skills/ship/SKILL.md:12`): Uses `## Commands` instead of `## Quick Start` or `## Quick Reference`. Functionally equivalent but deviates from the convention naming pattern.

2. **plugin-deploy** (`.claude/skills/plugin-deploy/SKILL.md`): Missing both `## Rules` and `## References` sections entirely. This is the most significant structural deviation across all skills.

---

### Frontmatter Format Compliance

Convention requires:
- `name`: lowercase, matches directory name
- `description`: multi-line with `|`, includes `Triggers:` line
- `allowed-tools`: only tools the skill actually uses

| Skill | name | description format | Triggers line | allowed-tools | Compliant |
|-------|------|--------------------|---------------|---------------|-----------|
| setup | Y | **single-line `"`** | Y | **N (missing)** | **DEVIATE** |
| gather | Y | **single-line `"`** | **`Trigger on:` not `Triggers:`** | **N (missing)** | **DEVIATE** |
| clarify | Y | **single-line `"`** | Y | **N (missing)** | **DEVIATE** |
| plan | Y | **single-line `"`** | Y | **N (missing)** | **DEVIATE** |
| impl | Y | **single-line `"`** | Y | **N (missing)** | **DEVIATE** |
| review | Y | **single-line `"`** | Y | **N (missing)** | **DEVIATE** |
| hitl | Y | **single-line `"`** | Y | **N (missing)** | **DEVIATE** |
| retro | Y | **single-line `"`** | Y | **N (missing)** | **DEVIATE** |
| ship | Y | **single-line `"`** | Y | **N (missing)** | **DEVIATE** |
| run | Y | **single-line `"`** | Y | **N (missing)** | **DEVIATE** |
| handoff | Y | **single-line `"`** | Y | **N (missing)** | **DEVIATE** |
| refactor | Y | **single-line `"`** | Y | **N (missing)** | **DEVIATE** |
| update | Y | **single-line `"`** | Y | **N (missing)** | **DEVIATE** |
| plugin-deploy | Y | single-line, no `|` | **N (missing `Triggers:`)** | Y | **PARTIAL** |

**Findings:**

1. **All 13 CWF skills** use single-line `"..."` description format instead of the multi-line `|` YAML block scalar declared in the convention (`plugins/cwf/references/skill-conventions.md:33-38`). This is a systematic, consistent deviation -- the convention says `|` but every CWF skill uses `"`. Either the convention is aspirational or the skills need bulk reformatting.

2. **All 13 CWF skills are missing `allowed-tools`** in their frontmatter. The convention recommends it (`skill-conventions.md:37-38`), and the only skill that has it is the local `plugin-deploy`. This is a universal gap.

3. **gather** (`plugins/cwf/skills/gather/SKILL.md:3`): Uses `Trigger on:` instead of the standard `Triggers:` prefix. It also uses a list-style description format (`- "cwf:gather" command - When the user...`) instead of the quoted trigger strings convention (`Triggers: "cwf:gather", "search"...`).

4. **plugin-deploy** (`.claude/skills/plugin-deploy/SKILL.md:3`): Uses `Trigger: "/plugin-deploy"` inline at end of description rather than a separate `Triggers:` line. Also has no multi-line `|` format.

---

### Language Declaration Compliance

Convention pattern: `**Language**: Write {artifact type} in English. Communicate with the user in their prompt language.`

All 13 CWF skills have a `**Language**` declaration at line 10 (immediately after description). All are positioned correctly.

**Non-standard patterns (functional but deviating from exact wording):**

| Skill | Declaration | Status |
|-------|-------------|--------|
| ship | `Issue/PR body는 한글로 작성. Code blocks, file paths, commit hashes, CLI output은 원문 유지.` | **DEVIATE**: Hardcoded Korean instead of following user language. Does not mention "Communicate with the user in their prompt language." |
| review | `Match the user's language for synthesis. Reviewer prompts in English.` | **DEVIATE**: Sentence structure differs from standard pattern. Missing "Communicate with the user in their prompt language." |
| run | `Communicate with the user in their prompt language. Artifacts in English.` | **Minor**: Reversed order from standard pattern. |
| hitl | `Write review outputs in the user's prompt language by default. If the user explicitly requests another language, follow that request.` | **Minor**: Adds override clause not in standard pattern. |
| plugin-deploy | `Match the user's language.` | **DEVIATE**: Too terse. Missing artifact language specification. |

The remaining 9 skills follow the standard pattern correctly, with appropriate artifact-type customization (e.g., "config files", "gathered artifacts", "plan.md", "code/technical implementation artifacts").

**Critical deviation**: `ship` hardcodes Korean (`한글로 작성`), making it non-portable for non-Korean users. The convention explicitly says to match the user's language.

---

### Universal Rules Compliance

Convention requires 5 universal rules in every skill's `## Rules` section:

1. All code fences must have language specifier
2. cwf-state.yaml is SSOT (for skills that read/write it)
3. cwf-state.yaml auto-init
4. Context-deficit resilience
5. Missing dependency interaction

| Skill | Rule 1 (fences) | Rule 2 (SSOT) | Rule 3 (auto-init) | Rule 4 (context-deficit) | Rule 5 (missing dep) | Uses cwf-state? |
|-------|-----------------|---------------|---------------------|--------------------------|----------------------|-----------------|
| setup | Y (rule 14) | Y (rule 2) | N | N | Y (rules 19, 20) | Y |
| gather | Y (rule 6) | N | N | N | Y (rule 7) | N |
| clarify | N | N | N | N | N | Y |
| plan | N | N | N | N | N | Y |
| impl | Y (rule 8) | N | N | N | N | Y |
| review | N | N | N | N | Y (rule 8) | Y |
| hitl | N | N | N | N | N | Y |
| retro | Y (rule 10) | N | N | N | N | Y |
| ship | Y (rule 6) | N | N | N | Y (rule 7) | N |
| run | N | N | N | Y (rule 9) | N | Y |
| handoff | Y (rule 9) | Y (rule 7) | N | N | N | Y |
| refactor | Y (rule 10) | N | N | N | N | Y |
| update | Y (rule 4) | N | N | N | N | N |
| plugin-deploy | N | N | N | N | N | N |

**Findings:**

1. **Rule 1 (code fences)**: Present in 8/13 CWF skills. Missing from: clarify, plan, review, run, hitl. Also missing from plugin-deploy.

2. **Rule 2 (cwf-state.yaml SSOT)**: Only present in 2/11 skills that use cwf-state.yaml (setup, handoff). Missing from clarify, plan, impl, review, hitl, retro, run, refactor -- all of which read/write cwf-state.yaml.

3. **Rule 3 (cwf-state.yaml auto-init)**: Present in **zero** skills. This is the most universally absent rule.

4. **Rule 4 (context-deficit resilience)**: Only present as an explicit rule in 1/13 skills (run:rule 9). Several skills implement it procedurally (via context recovery protocol references in workflow sections) but do not declare it in their Rules section.

5. **Rule 5 (missing dependency interaction)**: Present in 4/13 skills (setup, gather, review, ship). Missing from skills that interact with external tools: impl (uses git, agents), hitl (uses git), retro (uses find-skills), run (orchestrates all), refactor (uses markdownlint, shellcheck), plan (uses agents), clarify (uses agents), handoff (uses cwf-state.yaml scripts).

---

### References Section Compliance

Convention: use `../../references/` for shared references.

| Skill | Has References | Uses `../../references/` | Shared refs linked | Skill-local refs |
|-------|---------------|--------------------------|--------------------|--------------------|
| setup | Y | Y (agent-patterns) | agent-patterns | 7 script refs |
| gather | Y | N | None | 6 local refs |
| clarify | Y | Y (expert-advisor-guide) | expert-advisor-guide | 4 local refs |
| plan | Y | Y (plan-protocol) | plan-protocol | None |
| impl | Y | Y (agent-patterns) | agent-patterns | 1 local ref |
| review | Y | Y (agent-patterns, expert-advisor-guide) | agent-patterns, expert-advisor-guide | 2 local refs |
| hitl | Y | N | None | None |
| retro | Y | Y (agent-patterns) | agent-patterns | 2 local refs |
| ship | Y | Y (agent-patterns) | agent-patterns | 2 local refs |
| run | Y | Y (agent-patterns, plan-protocol) | agent-patterns, plan-protocol | None |
| handoff | Y | Y (plan-protocol, agent-patterns) | plan-protocol, agent-patterns | None |
| refactor | Y | Y (concept-map, agent-patterns, skill-conventions) | concept-map, agent-patterns, skill-conventions | 4 local refs |
| update | Y | Y (agent-patterns) | agent-patterns | None |
| plugin-deploy | **N** | N/A | N/A | 1 inline ref |

**Findings:**

1. **gather** (`plugins/cwf/skills/gather/SKILL.md:256-263`): References section exists but uses only `references/` (skill-local) paths. It does not link any shared `../../references/` files, yet it uses sub-agents (Task tool for `--local` mode) and should reference `agent-patterns.md`. The skill also references `context-recovery-protocol.md` in its workflow body but never lists it in References.

2. **hitl** (`plugins/cwf/skills/hitl/SKILL.md:191-210`): Has a Rules section but **no References section at all**. This is a structural omission since the convention requires References as the final section. HITL interacts with cwf-state.yaml and uses diff/git operations, so at minimum it should reference agent-patterns or plan-protocol.

3. **clarify** (`plugins/cwf/skills/clarify/SKILL.md:442-448`): References expert-advisor-guide but not agent-patterns.md, despite using 4+ parallel sub-agents via Task tool. Also uses context-recovery-protocol extensively but does not list it in References.

4. **plugin-deploy** (`.claude/skills/plugin-deploy/SKILL.md`): No References section at all.

5. **context-recovery-protocol.md** is referenced in workflow bodies of 6 skills (clarify, plan, review, retro, refactor, and indirectly in run) but is never listed in any skill's `## References` section. This is a systematic gap.

---

## 1b. Pattern Gaps

### Language Adaptation

**Status**: 13/13 CWF skills specify language behavior. 1/1 local skill specifies it (terse).

**Gap**: `ship` hardcodes Korean (`한글로 작성`) instead of following user language. `review` abbreviates the pattern. `plugin-deploy` is too terse to be actionable. All others are compliant.

**Recommendation**: `ship` should change to `Write Issue/PR body in the user's language. Keep code blocks, file paths, commit hashes, and CLI output verbatim.`

---

### Sub-Agent Usage Patterns

Skills using Task tool sub-agents:

| Skill | Sub-agents | Reference guide in prompt | Parallel execution | Structured output (file persistence) | Output sentinel |
|-------|------------|---------------------------|--------------------|-----------------------------------------|-----------------|
| clarify | 6 (2 research + 2 expert + 2 advisory) | Y (agent-patterns, expert-advisor-guide) | Y (in pairs) | Y (session_dir files) | Y (`<!-- AGENT_COMPLETE -->`) |
| plan | 2 (prior art + codebase) | Y (agent-patterns) | Y | Y | Y |
| impl | N agents (adaptive team) | Y (agent-prompts, agent-patterns) | Y | N (direct execution) | N |
| review | 6 (2 internal + 2 external + 2 expert) | Y (prompts, external-review, expert-advisor-guide) | Y (single message) | Y | Y |
| retro | 4 (CDM + learning + 2 expert) in 2 batches | Y (cdm-guide, expert-lens-guide, agent-patterns) | Y (batched) | Y | Y |
| refactor | 2-5 depending on mode | Y (review-criteria, holistic-criteria, tidying-guide) | Y | Y | Y |
| gather | 1 (for --local mode) | N (inline prompt) | N | Y (saves to file) | N |

**Gap - gather's sub-agent is immature**: The `--local` mode in gather (`plugins/cwf/skills/gather/SKILL.md:179-183`) uses a bare inline prompt without referencing a guide file, without output sentinel (`<!-- AGENT_COMPLETE -->`), and without context recovery protocol. All other skills that use sub-agents follow the mature pattern (reference guide + persistence + sentinel). Gather should adopt the same pattern.

**Gap - impl sub-agents lack file persistence**: Impl's agent team execution (`plugins/cwf/skills/impl/SKILL.md:256-285`) uses in-process Task returns rather than file-based persistence. This makes impl vulnerable to context loss if agents fail mid-flight. However, this may be intentional since impl agents make direct file edits rather than producing analysis artifacts.

---

### Usage Message for Subcommand Skills

Convention pattern: Skills with subcommands should show help when invoked with no args.

| Skill | Has subcommands | Shows usage on no-args | Has `## Usage Message` section |
|-------|-----------------|------------------------|-------------------------------|
| setup | Y (--hooks, --tools, etc.) | Y (runs full setup) | N |
| gather | Y (URL, --search, --local) | Y (prints usage) | Y |
| clarify | Y (default, --light) | N (runs default mode) | N |
| plan | N | N/A | N |
| impl | Y (path, --skip-branch, --skip-clarify) | N (auto-detects plan) | N |
| review | Y (--mode, --base, etc.) | N (runs default code mode) | N |
| hitl | Y (--resume, --rule, etc.) | N (runs default) | N |
| retro | Y (--deep, --from-run) | N (runs adaptive) | N |
| ship | Y (issue, pr, merge, status) | Y (prints usage) | Y |
| run | Y (--from, --skip) | N (requires task description) | N |
| handoff | Y (--register, --phase) | N (runs full) | N |
| refactor | Y (--code, --skill, --docs) | Y (runs quick scan) | N |
| update | Y (--check) | N (runs check+update) | N |
| plugin-deploy | Y (--new, --dry-run, etc.) | Y (prints usage) | Y |

**Finding**: Only 2 CWF skills (gather, ship) have explicit `## Usage Message` sections. Plugin-deploy also has one. Skills with multiple distinct subcommands (hitl with 6 subcommands, refactor with 5 modes) would benefit from explicit usage messages.

**Recommendation**: At minimum, hitl, refactor, and review should adopt explicit usage message sections given their multi-mode nature.

---

### Configuration: Env Var Naming Consistency

Convention: `CWF_{DOMAIN}_{SETTING}` pattern.

| Skill | Env vars used | Follows `CWF_*` pattern |
|-------|---------------|-------------------------|
| setup | CWF_CODEX_POST_RUN_MODE, CWF_CODEX_POST_RUN_CHECKS, etc. | Y |
| gather | CWF_GATHER_OUTPUT_DIR, CWF_GATHER_GOOGLE_OUTPUT_DIR, CWF_GATHER_NOTION_OUTPUT_DIR | Y |
| gather | TAVILY_API_KEY, EXA_API_KEY | N (third-party API keys, appropriate) |
| setup | SLACK_BOT_TOKEN, SLACK_CHANNEL_ID | N (third-party, appropriate) |
| ship | None CWF-specific | N/A |
| review | None CWF-specific | N/A |

**Status**: CWF-owned env vars follow the `CWF_{DOMAIN}_{SETTING}` pattern. Third-party API keys (TAVILY_API_KEY, EXA_API_KEY, SLACK_BOT_TOKEN) appropriately keep their upstream names. No violations found.

---

### Output Persistence

Convention: Skills that produce artifacts should offer to save them.

| Skill | Produces artifacts | Offers to save | Auto-saves |
|-------|-------------------|----------------|------------|
| clarify | clarification summary | Y ("Save this clarified requirement to a file?") | N |
| plan | plan.md, lessons.md | N (auto-writes) | Y |
| impl | modified files, lessons.md | N (auto-writes) | Y |
| review | synthesis (conversation only) | N (rule 5: "Do not write files unless the user explicitly asks") | N |
| retro | retro.md | N (auto-writes) | Y |
| ship | issue/PR (GitHub) | N (auto-creates) | Y |
| handoff | next-session.md, phase-handoff.md | N (auto-writes) | Y |
| refactor | analysis reports | Y (deep review: "Ask the user if they want to apply") | Y (holistic: auto-saves to .cwf/projects/) |
| gather | downloaded artifacts | N (auto-saves to OUTPUT_DIR) | Y |

**Gap**: `refactor --skill --holistic` mode auto-saves its report to `.cwf/projects/{YYMMDD}-refactor-holistic/analysis.md` without asking. Other refactor modes (deep review) ask first. This inconsistency is minor but worth noting.

**Gap**: `review` explicitly never writes to file (rule 5). However, review sub-agents DO write their individual verdicts to session directory files as part of the persistence protocol. The rule refers to the synthesis output only. This dual behavior is correct but could be clarified.

---

### Progressive Disclosure (Three-Level Hierarchy)

Convention: metadata (frontmatter) -> body (SKILL.md) -> references (skill-local + shared)

| Skill | Metadata (frontmatter) | Body (workflow detail) | References (extracted) | Compliant |
|-------|------------------------|------------------------|------------------------|-----------|
| setup | Y | Y (850 lines) | Y (7 scripts, 1 shared ref) | Y but body is very long |
| gather | Y | Y (263 lines) | Y (6 local refs) | Y |
| clarify | Y | Y (448 lines) | Y (4 local + 1 shared) | Y |
| plan | Y | Y (332 lines) | Y (1 shared ref) | Y |
| impl | Y | Y (445 lines) | Y (1 local + 1 shared) | Y |
| review | Y | Y (702 lines) | Y (2 local + 2 shared) | Y but body is very long |
| hitl | Y | Y (209 lines) | **N (no refs section)** | **DEVIATE** |
| retro | Y | Y (415 lines) | Y (2 local + 1 shared) | Y |
| ship | Y | Y (304 lines) | Y (2 local + 1 shared) | Y |
| run | Y | Y (210 lines) | Y (2 shared refs) | Y |
| handoff | Y | Y (415 lines) | Y (2 shared refs) | Y |
| refactor | Y | Y (433 lines) | Y (4 local + 3 shared) | Y |
| update | Y | Y (112 lines) | Y (1 shared ref) | Y |
| plugin-deploy | Y | Y (107 lines) | **N (no refs section)** | **DEVIATE** |

**Finding**: `hitl` and `plugin-deploy` break the three-level hierarchy by having no References section.

---

## 1c. Structural Extraction Opportunities

### Pattern 1: Sub-Agent Output Persistence Block

**Repeated in**: clarify (6 instances), plan (2), review (7), retro (4), refactor (6)

**Pattern**:
```text
## Output Persistence
Write your complete {findings/analysis/review} to: {session_dir}/{filename}.md
At the very end of the file, append this sentinel marker on its own line:
<!-- AGENT_COMPLETE -->
```

This exact block (with minor wording variations) appears 25+ times across 5 skills. It is always appended to sub-agent prompts.

**Proposal**: Extract to `plugins/cwf/references/agent-output-persistence.md` as a canonical template. Skills would reference it as: "Include the output persistence block from [agent-output-persistence.md](../../references/agent-output-persistence.md), targeting file `{path}`."

**Existing coverage**: The `context-recovery-protocol.md` shared reference already defines the recovery side (how to validate sentinel files), but the production side (the exact prompt block to include) is not extracted.

---

### Pattern 2: Session Directory Resolution

**Repeated in**: plan (lines 66-75), impl (lines 28-31), review (lines 173-179), retro (lines 93-99), refactor (lines 79-85, 145-151, 235-241)

**Pattern**:
```bash
live_state_file=$(bash {CWF_PLUGIN_DIR}/scripts/cwf-live-state.sh resolve)
```
```yaml
session_dir: "{live.dir value from resolved live-state file}"
```

This session directory resolution pattern appears in 7 skills with identical or near-identical boilerplate.

**Proposal**: This is already well-factored into the `cwf-live-state.sh` script. The repetition is in the SKILL.md documentation, not in executable code. Consider adding a "Session Directory Resolution" section to `agent-patterns.md` that skills can reference instead of repeating inline.

---

### Pattern 3: Live State Phase Update

**Repeated in**: clarify (lines 46-48), plan (lines 39-42), impl (lines 28-30), retro (line 31), run (lines 36-41, 78)

**Pattern**:
```bash
bash {CWF_PLUGIN_DIR}/scripts/cwf-live-state.sh set . \
  phase="{skill-name}" \
  task="{task summary}"
```

All workflow-stage skills begin by setting the phase in live state. This is a standard "Phase 0: Update Live State" block.

**Proposal**: Document the standard "Phase 0" template in `agent-patterns.md` or `skill-conventions.md` so each skill can say "Apply standard Phase 0 (live-state update)" instead of repeating the bash block.

---

### Pattern 4: Context Recovery Protocol Application

**Repeated in**: clarify (3 instances), plan (1), review (1), retro (1), refactor (3)

**Pattern**:
```text
Apply the [context recovery protocol](../../references/context-recovery-protocol.md) to these files:
| Agent | Output file |
|-------|-------------|
| {name} | `{session_dir}/{filename}.md` |
```

This pattern appears 9 times across 6 skills with the same structure: a link to the protocol, followed by a table of agent-to-file mappings.

**Status**: Already partially extracted to `context-recovery-protocol.md`. The protocol itself is shared, but each skill repeats the invocation pattern. This is acceptable since the file tables are skill-specific.

---

### Pattern 5: Lessons Checkpoint

**Repeated in**: setup (Phase 5.2), handoff (Phase 5.1), update (Phase 4)

**Pattern**:
```text
Add `{skill-name}` to `cwf-state.yaml` current session's `stage_checkpoints` list.
```

Only 3 skills have this, but every workflow-stage skill (gather, clarify, plan, impl, review, retro) should arguably have it.

**Finding**: This is an inconsistency rather than an extraction opportunity. Skills that participate in the workflow pipeline should all checkpoint their completion, but most do not.

---

### Pattern 6: Web Research Protocol in Sub-Agent Prompts

**Repeated in**: clarify (lines 112-118), plan (lines 100-107), retro (lines 120, 135-136), review (lines 393-394, 422-423)

**Pattern**:
```text
## Web Research Protocol
Read the "Web Research Protocol" section of
{CWF_PLUGIN_DIR}/references/agent-patterns.md and follow it exactly.
Key points: discover URLs via WebSearch first (never guess URLs),
use WebFetch then fall back to agent-browser for JS-rendered pages,
skip failed domains, budget turns for writing output.
You have Bash access for agent-browser CLI commands.
```

This verbatim block appears in 8+ sub-agent prompts across 4 skills.

**Proposal**: This is already extracted to `agent-patterns.md`, and the inline text serves as a summary/pointer. The repetition is in sub-agent prompt construction within SKILL.md files. An explicit "Web Research Prompt Fragment" section in `agent-patterns.md` with a copyable block would formalize this.

---

### Pattern 7: Expert Selection Protocol

**Repeated in**: clarify (Phase 2.5, lines 147-149), review (Phase 2.3, lines 375-376), retro (Section 5, lines 189-191)

**Pattern**:
```text
1. Read `expert_roster` from `cwf-state.yaml`
2. Analyze {target} for domain keywords; match against each roster entry's `domain` field
3. Select 2 experts with contrasting frameworks
4. If roster has < 2 domain matches, fill remaining slots via independent selection
```

This expert selection logic is repeated across 3 skills.

**Status**: Partially addressed by `expert-advisor-guide.md`, but the selection/matching algorithm itself is repeated in each skill's workflow section.

**Proposal**: Extract the expert selection algorithm to `expert-advisor-guide.md` as a "Selection Protocol" section. Skills would reference it rather than duplicating the 4-step algorithm.

---

## Summary of Deviations

### Critical (structural violations)

| # | Skill | File:Line | Issue |
|---|-------|-----------|-------|
| C1 | plugin-deploy | `.claude/skills/plugin-deploy/SKILL.md` (entire file) | Missing `## Rules` section |
| C2 | plugin-deploy | `.claude/skills/plugin-deploy/SKILL.md` (entire file) | Missing `## References` section |
| C3 | hitl | `plugins/cwf/skills/hitl/SKILL.md` (after line 210) | Missing `## References` section (has Rules but no References) |
| C4 | ALL CWF skills | All 13 `SKILL.md:3` | Description uses `"..."` instead of `\|` multi-line format |
| C5 | ALL CWF skills | All 13 `SKILL.md` frontmatter | Missing `allowed-tools` field |

### High (universal rule omissions)

| # | Skill(s) | Issue |
|---|----------|-------|
| H1 | ALL 13 CWF skills + plugin-deploy | No skill includes cwf-state.yaml auto-init rule (Rule 3) |
| H2 | clarify, plan, review, run, hitl, plugin-deploy | Missing "code fences must have language specifier" rule (Rule 1) |
| H3 | clarify, plan, impl, review, hitl, retro, run, refactor | Missing "cwf-state.yaml is SSOT" rule despite reading/writing cwf-state.yaml (Rule 2) |
| H4 | 12/13 CWF skills | Missing "context-deficit resilience" as an explicit rule (only `run` has it) |
| H5 | 9/13 CWF skills | Missing "missing dependency interaction" rule |

### Medium (pattern inconsistencies)

| # | Skill | File:Line | Issue |
|---|-------|-----------|-------|
| M1 | ship | `plugins/cwf/skills/ship/SKILL.md:10` | Language declaration hardcodes Korean |
| M2 | ship | `plugins/cwf/skills/ship/SKILL.md:12` | Uses `## Commands` instead of `## Quick Start` / `## Quick Reference` |
| M3 | gather | `plugins/cwf/skills/gather/SKILL.md:3` | `Trigger on:` instead of `Triggers:` in description |
| M4 | gather | `plugins/cwf/skills/gather/SKILL.md:179-183` | Sub-agent for `--local` mode uses immature pattern (no guide reference, no sentinel, no context recovery) |
| M5 | gather | `plugins/cwf/skills/gather/SKILL.md:256` | References section has no shared `../../references/` links despite using sub-agents |
| M6 | review | `plugins/cwf/skills/review/SKILL.md:10` | Language declaration omits "Communicate with the user in their prompt language" |
| M7 | context-recovery-protocol | 6 skills reference it in workflow but none list it in `## References` | Systematic omission |
| M8 | hitl, refactor, review | No explicit `## Usage Message` section despite multi-mode interfaces | Pattern gap |

### Low (stylistic drift)

| # | Skill | Issue |
|---|-------|-------|
| L1 | run | Language declaration reverses standard order ("Communicate... Artifacts in English" vs "Write artifacts in English. Communicate...") |
| L2 | hitl | Language declaration adds override clause ("If the user explicitly requests another language...") not in standard pattern |
| L3 | plugin-deploy | Language declaration too terse ("Match the user's language.") |
| L4 | 10/13 CWF skills | No lessons checkpoint in Rules (only setup, handoff, update have it) |

---

## Extraction Recommendations (Prioritized)

| Priority | What | Target file | Affected skills | Effort |
|----------|------|-------------|-----------------|--------|
| 1 | Output persistence prompt block template | `plugins/cwf/references/agent-output-persistence.md` (new) or append to `agent-patterns.md` | clarify, plan, review, retro, refactor | Small |
| 2 | Expert selection algorithm | Append to `plugins/cwf/references/expert-advisor-guide.md` | clarify, review, retro | Small |
| 3 | Standard Phase 0 live-state update template | Append to `plugins/cwf/references/skill-conventions.md` | clarify, plan, impl, retro, run | Small |
| 4 | Session directory resolution pattern | Append to `plugins/cwf/references/agent-patterns.md` | plan, impl, review, retro, refactor | Small |
| 5 | Web Research Protocol prompt fragment (copyable) | Already in `agent-patterns.md`, needs explicit "Prompt Fragment" subsection | clarify, plan, retro, review | Small |
| 6 | Lessons checkpoint protocol | Append to `plugins/cwf/references/skill-conventions.md` | All pipeline-stage skills | Medium |

---

## Convention vs Reality Assessment

The `skill-conventions.md` file defines aspirational standards that the actual skills partially follow. The most significant systemic gaps are:

1. **Frontmatter format**: Convention says `description: |` (multi-line) with `allowed-tools`. Reality: all 13 skills use `description: "..."` (single-line) and none have `allowed-tools`. This suggests the convention should either be enforced (bulk reformatting) or relaxed to match actual practice.

2. **Universal rules**: Convention lists 5 mandatory rules. Reality: no skill includes all 5. The best-covered rule (code fences) appears in only 8/13 skills. The worst-covered rule (auto-init) appears in zero skills.

3. **Progressive disclosure**: Generally well-followed. Most skills correctly use frontmatter -> body -> references. The two exceptions (hitl, plugin-deploy) lack references entirely.

4. **Shared reference usage**: Generally good -- 11/13 CWF skills link to `../../references/` paths. The notable exception is `context-recovery-protocol.md`, which is heavily used procedurally but never formally listed in any skill's References section.

<!-- AGENT_COMPLETE -->
