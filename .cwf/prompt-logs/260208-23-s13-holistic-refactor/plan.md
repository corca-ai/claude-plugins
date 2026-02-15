# S13 Holistic Refactor — CWF Plugin

## Context

Quality gate review before S14 integration testing and merge to main.
All 9 CWF skills and 14 hook scripts analyzed.

## Goal

Identify and fix cross-cutting issues across all skills and hooks.

## Scope

- Cross-skill consistency (frontmatter, rules, language, references)
- Hook-skill alignment (gate variables, toggle names)
- Reference integrity (all links resolve)
- Code fence specifiers (MD040 compliance)
- cwf-state.yaml schema consistency
- Agent pattern alignment
- Script quality (Bash 3.2 compatibility)
- Linter strictness review

## Analysis Results

### Plugin Map

| Skill | Words | Pattern | References | Has Rules |
|-------|-------|---------|------------|-----------|
| setup | ~220 | Single | 3 links | 7 rules |
| update | ~125 | Single | 1 link | 4 rules |
| gather | ~260 | Adaptive | 6 links | **MISSING** → FIXED |
| clarify | ~310 | 4 agents | 4 links | 8 rules |
| plan | ~245 | Team | 1 link | 6 rules |
| impl | ~330 | Team | 2 links | 8 rules |
| retro | ~280 | Parallel | 3 links | 13 rules |
| refactor | ~335 | Parallel | 5 links | 8 rules |
| handoff | ~270 | Single | 2 links | 9 rules |

### Hooks (14 scripts)

| Script | Group | Event | Gate |
|--------|-------|-------|------|
| cwf-hook-gate.sh | (shared) | N/A | N/A |
| attention.sh | attention | Notification:idle | ✓ |
| track-user-input.sh | attention | UserPromptSubmit | ✓ |
| start-timer.sh | attention | PreToolUse:AskUser/Plan | ✓ |
| cancel-timer.sh | attention | PostToolUse:AskUser/Plan | ✓ |
| heartbeat.sh | attention | PreToolUse:* | ✓ |
| log-turn.sh | log | Stop/SessionEnd | ✓ |
| smart-read.sh | read | PreToolUse:Read | ✓ |
| check-markdown.sh | lint_markdown | PostToolUse:Write/Edit | ✓ |
| check-shell.sh | lint_shell | PostToolUse:Write/Edit | ✓ |
| redirect-websearch.sh | websearch_redirect | PreToolUse:WebSearch | ✓ |
| enter-plan-mode.sh | plan_protocol | PreToolUse:EnterPlanMode | ✓ |
| slack-send.sh | (utility) | N/A | N/A |
| parse-transcript.sh | (utility) | N/A | N/A |

## Findings

### F1. [CRITICAL] Broken reference links — 4 skills

**What**: Relative paths to shared `references/` directory used wrong depth.
**Where**:
- `plan/SKILL.md:104,244`: `../../../references/plan-protocol.md` (3 levels up = `plugins/`)
- `impl/SKILL.md:126,328`: `../references/agent-patterns.md` (1 level up = `skills/`)
- `retro/SKILL.md:262`: `../references/agent-patterns.md`
- `refactor/SKILL.md:324`: `../references/agent-patterns.md`

**Fix**: All should use `../../references/` (2 levels up from `skills/{name}/` to `plugins/cwf/`).
**Status**: FIXED

### F2. [IMPORTANT] gather missing Rules section

**What**: All 8 other skills have a `## Rules` section; gather did not.
**Fix**: Added 6 rules covering URL priority, graceful degradation, output dir, privacy, sub-agents, code fences.
**Status**: FIXED

### F3. [IMPORTANT] Language declaration inconsistency

**What**: 5+ different wordings across 9 skills. retro had Language section at bottom.
**Pattern**: `**Language**: Write {artifact type} in English. Communicate with the user in their prompt language.`
**Exception**: retro writes in the user's language (deliberate — retro artifacts are user-facing).
**Fix**: Standardized all 9 skills to the pattern. Moved retro's Language to after title.
**Status**: FIXED

### F4. [PASS] Hook-skill alignment

**What**: cwf-hook-gate.sh variable names match cwf:setup output format exactly.
7 groups: attention, log, read, lint_markdown, lint_shell, websearch_redirect, plan_protocol.
**Status**: No issues

### F5. [PASS] Code fence specifiers

**What**: markdownlint (MD040 enabled) passes on all 28 markdown files with 0 errors.
**Status**: No issues

### F6. [PASS] cwf-state.yaml schema

**What**: All skills that read/write cwf-state.yaml use compatible field names.
Fields: workflow.{current_stage, stages}, sessions[].{id, title, dir, branch, completed_at, summary, artifacts, stage_checkpoints}, session_defaults.artifacts.{impl_complete, always, milestone}, tools.{codex, gemini, tavily, exa}, hooks.{7 groups}.
**Status**: No issues

### F7. [PASS] Agent pattern consistency

**What**: Each skill follows its declared pattern from agent-patterns.md.
Single: setup, update, handoff. Adaptive: gather. Team: plan, impl. Parallel: retro, refactor.
**Status**: No issues

### F8. [PASS] Script quality — Bash 3.2 compatibility

**What**: No Bash 4+ features (declare -A, nameref, |&, coproc, mapfile) found in any script.
cwf-hook-gate.sh uses `printenv` instead of `${!var}` for Bash 3.2 compatibility.
`((var++))` avoided in favor of `$((var + 1))`.
install.sh and update-all.sh use proper portable patterns.
**Status**: No issues

### F9. [INFO] Linter strictness review

**What**: S12 raised concern about lint_markdown and lint_shell hooks being too aggressive.
**Data collected**:
- `.markdownlint.json` disables: MD013 (line length), MD031/32 (blank lines around fences), MD033 (inline HTML), MD034 (bare URLs), MD036 (emphasis as heading), MD041 (first line heading), MD060.
- MD040 (code fence language) is enabled — enforces language specifiers.
- shellcheck runs with default severity (all rules).
- Both linters skip `prompt-logs/` paths.
- Both hooks are toggleable via cwf:setup (HOOK_LINT_MARKDOWN_ENABLED, HOOK_LINT_SHELL_ENABLED).

**Assessment**: Current markdownlint config is reasonable — disables the most friction-prone rules. shellcheck with no exclusions may be noisy (SC2086 double-quoting is common), but no concrete false positive data collected yet. The toggle mechanism via cwf:setup is the first-line solution. No config changes recommended without concrete friction examples.

### F10. [NOTE] WebSearch in allowed-tools vs redirect hook

**What**: clarify, plan, and retro list `WebSearch` in allowed-tools, but the `websearch_redirect` hook blocks it and redirects to `cwf:gather --search`.
**Assessment**: This is correct behavior — the allowed-tools list declares what the skill CAN use, while the hook determines runtime behavior. If the redirect hook is disabled via cwf:setup, these skills should be able to use WebSearch directly. No change needed.

## Success Criteria

```gherkin
Given cwf:refactor --holistic was run on plugins/cwf/
When all 9 skills and hook scripts were analyzed
Then a review report was generated with specific file:line references

Given broken reference links were found in 4 skills
When fixes were applied
Then all SKILL.md reference links resolve correctly to ../../references/

Given cross-skill inconsistencies were found
When fixes were applied
Then all SKILL.md files have a Rules section
And all SKILL.md files have a standardized Language declaration after the title

Given all markdown files in plugins/cwf/ are checked
When markdownlint is run
Then 0 errors are reported

Given all bash scripts are checked for Bash 3.2 compatibility
When no Bash 4+ features are used
Then scripts work on macOS default bash
```

## Files Modified

| File | Action | Fix |
|------|--------|-----|
| `skills/plan/SKILL.md` | Edit | F1: Fix reference path ../../ |
| `skills/impl/SKILL.md` | Edit | F1: Fix reference path ../../ |
| `skills/retro/SKILL.md` | Edit | F1: Fix reference path, F3: Move Language |
| `skills/refactor/SKILL.md` | Edit | F1: Fix reference path, F3: Language |
| `skills/gather/SKILL.md` | Edit | F2: Add Rules section, F3: Language |
| `skills/setup/SKILL.md` | Edit | F3: Language standardization |
| `skills/update/SKILL.md` | Edit | F3: Language standardization |
| `skills/clarify/SKILL.md` | Edit | F3: Language standardization |

## Don't Touch

- `plugins/plan-and-lessons/` — kept until S14
- `prompt-logs/` — session history is read-only
- Architecture decisions in master-plan.md
