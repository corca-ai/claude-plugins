# Review Target and Routing Details

Detailed procedure reference for `review`:
- Phase 1 (target detection, criteria extraction, budgeting)
- Phase 2 pre-launch routing (recovery, prompt prep, provider/expert resolution)

`SKILL.md` keeps summary routing and invariants. Use this file for deterministic command and decision details.

## Contents

- [Phase 1: Gather Review Target](#phase-1-gather-review-target)
- [1. Parse mode flag](#1-parse-mode-flag)
- [2. Detect review target](#2-detect-review-target)
- [3. Extract behavioral/qualitative criteria](#3-extract-behavioralqualitative-criteria)
- [4. Optional holdout scenarios (`--scenarios <path>`)](#4-optional-holdout-scenarios---scenarios-path)
- [5. Measure review target size and set turn budget](#5-measure-review-target-size-and-set-turn-budget)
- [6. Detect Browser-Runtime Verification Scope (Code Mode)](#6-detect-browser-runtime-verification-scope-code-mode)
- [Phase 2 Pre-Launch: Recovery, Prompts, Routing](#phase-2-pre-launch-recovery-prompts-routing)
- [2.0 Resolve session directory and context recovery](#20-resolve-session-directory-and-context-recovery)
- [2.1 Prepare prompts](#21-prepare-prompts)
- [2.2 Detect provider availability and route external slots](#22-detect-provider-availability-and-route-external-slots)
- [2.2.1 Agent-slot preflight (capacity-aware)](#221-agent-slot-preflight-capacity-aware)
- [2.2.2 Resolve experts for Slot 5/6 (required)](#222-resolve-experts-for-slot-56-required)

## Phase 1: Gather Review Target

### 1. Parse mode flag

Extract flags from user input:

- `--mode` (default: `code`)
- `--base <branch>` (optional, code mode only)
- `--scenarios <path>` (optional holdout scenarios file)
- `--correctness-provider <auto|codex|gemini|claude>` (optional, default: `auto`)
- `--architecture-provider <auto|gemini|codex|claude>` (optional, default: `auto`)

### 2. Detect review target

Automatically detect what to review based on mode.

**`--mode code`** — try in order (first non-empty wins):

1. Resolve base strategy:
   - If `--base <branch>` is provided:
     - Verify branch exists locally (`refs/heads/{branch}`) or in any remote (`refs/remotes/*/{branch}`).
     - If only remote exists, resolve `{remote}/{branch}` deterministically:
       1. prefer current upstream remote (from `@{upstream}`) when it has `{branch}`
       2. then remote from first `refs/remotes/*/HEAD` symbolic ref
       3. then lexicographically first remote that has `{branch}`
     - If neither exists: stop with explicit error and ask user for a valid branch.
     - Record `base_strategy: explicit (--base)`.
   - If `--base` is not provided:
     - First try upstream-aware detection:
       `git rev-parse --abbrev-ref --symbolic-full-name @{upstream} 2>/dev/null`
     - If upstream exists, use it and record `base_strategy: upstream`.
     - Otherwise fallback to `main`, `master`, then default remote branch:
       `git for-each-ref --format='%(symref)' 'refs/remotes/*/HEAD' | sed -n '1s#^refs/remotes/##p'`
       and record `base_strategy: fallback`.
2. Branch diff vs resolved base:
   `git diff $(git merge-base HEAD {resolved_base})..HEAD`
3. Staged changes: `git diff --cached`
4. Last commit: `git show HEAD`
5. Store review-target provenance for synthesis:
   - `resolved_base`
   - `base_strategy`
   - `diff_range` (when branch diff path is used)

If all empty, ask user with AskUserQuestion.

**`--mode plan`**:
1. Search latest plan:
   ```bash
   ls -td .cwf/projects/*/plan.md 2>/dev/null | head -1
   ```
2. If not found, check `.cwf/projects/*/master-plan.md`
3. If still not found, ask user with AskUserQuestion

**`--mode clarify`**:
1. Search recent clarification artifact:
   ```bash
   ls -td .cwf/projects/*/clarify-result.md 2>/dev/null | head -1
   ```
2. If not found, ask user with AskUserQuestion

### 3. Extract behavioral/qualitative criteria

Search the associated `plan.md` for success criteria:

1. Find the most recent `.cwf/projects/*/plan.md`
2. Extract behavioral criteria (Given/When/Then or checkbox-style)
3. Extract qualitative criteria (narrative quality expectations)
4. If none found, proceed and note in synthesis:
   `"No success criteria found — review based on general best practices only."`

### 4. Optional holdout scenarios (`--scenarios <path>`)

When `--scenarios` is provided:

1. Validate path exists, is readable, and non-empty.
2. Parse checks from:
   - Given/When/Then blocks
   - checklist items (`- [ ]` / `- [x]`)
3. If file missing/invalid or parse count is zero: stop with explicit error.
4. Merge parsed holdout checks as a separate holdout set.
5. Record holdout provenance:
   - `holdout_path`
   - `holdout_count`

### 5. Measure review target size and set turn budget

For code mode:

```bash
diff_lines=$(echo "$review_target" | wc -l)
```

Turn budget scaling:

| Diff lines | `max_turns` |
|------------|-------------|
| < 500 | 12 |
| 500–2000 | 20 |
| > 2000 | 28 |

For `--mode plan` and `--mode clarify`, use document line count instead of diff lines.

CLI timeout scaling:

| Prompt lines | `cli_timeout` |
|-------------|---------------|
| < 300 | 120 |
| 300–800 | 180 |
| > 800 | 240 |

External CLI cutoff (deterministic):

- Compute `prompt_lines` from final external prompt content.
- If `prompt_lines > 1200`, set:
  - `external_cli_allowed=false`
  - `external_cli_cutoff_reason=prompt_lines_gt_1200`
  - `external_cli_cutoff_value=1200`
- Route Slot 3/4 directly to `claude` fallbacks.
- Persist cutoff evidence in synthesis Confidence Note:
  - `External CLI skipped: prompt_lines={prompt_lines} cutoff=1200 reason=prompt_lines_gt_1200`

### 6. Detect Browser-Runtime Verification Scope (Code Mode)

Set `web_debug_scope=true` when review target includes one or more signals:

- frontend/web runtime files (`*.html`, `*.css`, `*.js`, `*.ts`, `*.tsx`) with UI behavior changes
- browser runtime failures (`console error`, `DOM`, `hydration`, `navigation`, `viewport`, `mobile`)
- explicit mentions of CDP/DevTools/`agent-browser`

If `web_debug_scope=true`, reviewer prompts must include [Web Debug Loop Protocol](../../../references/agent-patterns.md#web-debug-loop-protocol).

## Phase 2 Pre-Launch: Recovery, Prompts, Routing

### 2.0 Resolve session directory and context recovery

Resolve effective live-state file, then read `live.dir`:

```bash
live_state_file=$(bash {CWF_PLUGIN_DIR}/scripts/cwf-live-state.sh resolve)
```

Mode-namespaced output files:

| Slot | Reviewer | Output file |
|------|----------|-------------|
| 1 | Security | `{session_dir}/review-security-{mode}.md` |
| 2 | UX/DX | `{session_dir}/review-ux-dx-{mode}.md` |
| 3 | Correctness | `{session_dir}/review-correctness-{mode}.md` |
| 4 | Architecture | `{session_dir}/review-architecture-{mode}.md` |
| 5 | Expert α | `{session_dir}/review-expert-alpha-{mode}.md` |
| 6 | Expert β | `{session_dir}/review-expert-beta-{mode}.md` |

If all six files are already valid, skip launch and continue from Phase 3 (cached recovery path).

### 2.1 Prepare prompts

Internal reviewers (Security, UX/DX):

1. Read `{SKILL_DIR}/references/prompts.md`
2. Extract role + mode-specific checklist
3. Build prompt with:
   - role
   - mode focus
   - review target
   - criteria checklist
   - browser verification block (when `web_debug_scope=true`)
   - output format + provenance requirement

External slots (Correctness, Architecture):

1. Read `{SKILL_DIR}/references/external-review.md`
2. Extract role + mode checklist
3. Create temp dir: `mktemp -d /tmp/claude-review-XXXXXX`
4. Write prompt files:
   - `{tmp_dir}/correctness-prompt.md`
   - `{tmp_dir}/architecture-prompt.md`

### 2.2 Detect provider availability and route external slots

Single preflight:

```bash
command -v codex >/dev/null 2>&1 && echo CODEX_FOUND
command -v npx >/dev/null 2>&1 && echo NPX_FOUND
if command -v codex >/dev/null 2>&1; then
  codex auth status >/dev/null 2>&1 && echo CODEX_AUTH_OK || true
fi
```

Routing policy:

- Slot 3 (Correctness)
  - auto: `codex` (only with `CODEX_AUTH_OK`) -> `gemini` -> `claude`
  - explicit provider overrides auto
- Slot 4 (Architecture)
  - auto: `gemini` -> `codex` (only with `CODEX_AUTH_OK`) -> `claude`
  - explicit provider overrides auto

If `external_cli_allowed=false`, set both external slots to `claude`.

### 2.2.1 Agent-slot preflight (capacity-aware)

Run:

```bash
bash {CWF_PLUGIN_DIR}/scripts/agent-slot-preflight.sh --required 6 --json
```

Use result:
- `launch_mode=single_batch`: launch all 6 in one message
- `launch_mode=multi_batch`: deterministic two-batch launch (Slots 1-4, then 5-6)
- `launch_mode=blocked`: close/wait active agents and retry preflight once

### 2.2.2 Resolve experts for Slot 5/6 (required)

Resolve project state file and roster:

```bash
source {CWF_PLUGIN_DIR}/scripts/cwf-artifact-paths.sh
cwf_state_file=$(resolve_cwf_state_file "$(pwd)")
```

Selection procedure:

1. Load `expert_roster` from `{cwf_state_file}`
2. Match review target keywords against each expert `domain`
3. Select 2 experts with contrasting frameworks
4. Tie-break: domain-match quality -> lower `usage_count` -> lexicographic `name`
5. If fewer than 2 valid matches, fill remaining slots with independent selection and record why
