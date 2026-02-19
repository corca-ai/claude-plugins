---
name: setup
description: "Initial CWF configuration to standardize environment/tool contracts before workflow execution: hook group selection, external tool detection, setup-contract bootstrap, project config bootstrap, optional Agent Team mode setup, optional Codex integration, optional git hook gate installation, optional CWF capability index generation, and optional repository index generation. Triggers: \"cwf:setup\", \"setup hooks\", \"configure cwf\""
---

# Setup

Standardize hooks, tool contracts, and project/runtime config wiring once so later workflow runs stay reproducible. Includes interactive hook toggles, external tool detection, setup-contract bootstrap for repo-adaptive suggestions, project config bootstrap, optional Agent Team mode setup, optional Codex integration, optional git hook gate installation, optional CWF capability index generation, and optional repository index generation.

## Quick Start

```text
cwf:setup                # Full setup (hooks + tools + config + Agent Team + optional Codex/repo-index prompts)
cwf:setup --hooks        # Hook group selection only
cwf:setup --tools        # External tool detection only
cwf:setup --env          # Project config bootstrap + runtime priority guidance only
cwf:setup --agent-teams  # Agent Team mode setup only
cwf:setup --run-mode     # Configure default cwf:run ambiguity mode only
cwf:setup --codex        # Codex integration-only rerun (scope-aware skills/references sync)
cwf:setup --codex-wrapper # Codex wrapper-only rerun (scope-aware wrapper setup)
cwf:setup --git-hooks both --gate-profile balanced  # Install repo git hooks and set gate depth
cwf:setup --git-hooks pre-commit --gate-profile fast # Lightweight local-only git gate
cwf:setup --git-hooks none # Remove repo-managed git hooks
cwf:setup --cap-index    # Generate/refresh CWF capability index only
cwf:setup --repo-index   # Generate/refresh repository index (explicit)
cwf:setup --repo-index --target agents # AGENTS.md managed block target
cwf:setup --repo-index --target file   # Standalone index file target
cwf:setup --repo-index --target both   # AGENTS block + standalone index file
```

Operational note:
- Prefer `cwf:setup` first; it is the default entrypoint and asks for optional integrations when relevant.
- Use `--codex` / `--codex-wrapper` when reapplying only Codex-related integration pieces.

## Mode Routing

Parse input flags and run only the relevant phases:

| Input | Phases |
|-------|--------|
| `cwf:setup` | 1 → 2 → 2.8 → 2.9 → 2.10 → 2.4 (if codex available) → 2.7 (always ask) → 4 (opt-in) → 5 |
| `cwf:setup --hooks` | 1 → 5 |
| `cwf:setup --tools` | 2 → 2.8 → 2.9 → 2.10 → 5 |
| `cwf:setup --env` | 2.8 → 2.10 → 5 |
| `cwf:setup --agent-teams` | 2.9 → 5 |
| `cwf:setup --run-mode` | 2.10 → 5 |
| `cwf:setup --codex` | 2.5 → 5 |
| `cwf:setup --codex-wrapper` | 2.6 → 5 |
| `cwf:setup --git-hooks <none\|pre-commit\|pre-push\|both> [--gate-profile <fast\|balanced\|strict>]` | 2.7 → 5 |
| `cwf:setup --cap-index` | 3 → 5 |
| `cwf:setup --repo-index [--target <agents\|file\|both>]` | 4 → 5 |

When mode is full setup and Codex CLI is available, do not silently skip Codex integration; always run Phase 2.4 and ask the user which integration level to apply.

When mode is full setup, do not expect users to supply optional flags manually. Always ask for git hook installation mode and gate profile in Phase 2.7.

When mode is full setup or tools-only setup, always run Phase 2.8 so project config files are bootstrapped with explicit user choice.

When mode is full setup or tools-only setup, always run Phase 2.9 so Agent Team mode is explicitly aligned with CWF's multi-agent workflow assumptions.

When mode is full setup, tools-only setup, env-only setup, or run-mode-only setup, always run Phase 2.10 so `cwf:run` default ambiguity policy is explicit and reproducible.

---

## Phase 1: Hook Group Selection

Configure which hook groups are active. Default: all enabled (hooks work without running cwf:setup).

### 1.1 Read Current State

Read `cwf-state.yaml` `hooks:` section for current toggle state.

### 1.2 Present Selection

Use AskUserQuestion with `multiSelect: true`. Present 9 hook groups with descriptions:

| Group | Description |
|-------|-------------|
| `attention` | Slack notifications on idle/waiting |
| `log` | Auto-log turns + auto-commit transcripts |
| `read` | File-size aware reading guard |
| `lint_markdown` | Markdown validation after Write/Edit |
| `lint_shell` | ShellCheck validation after Write/Edit |
| `deletion_safety` | Blocks risky file deletions and requires policy-compliant justification |
| `workflow_gate` | Enforces workflow stage/branch safety rules before edits and commands |
| `websearch_redirect` | Redirect WebSearch to cwf:gather |
| `compact_recovery` | Inject live session state after auto-compact and guard session↔worktree binding on prompts |

Pre-select groups that are currently enabled in `cwf-state.yaml`.

### 1.3 Write Hook Config

Apply selected hook groups with deterministic sync script:

```bash
bash {SKILL_DIR}/scripts/sync-hook-state.sh --enable "<comma-separated selected groups>"
```

This command writes `~/.claude/cwf-hooks-enabled.sh` with:

```bash
# Generated by cwf:setup
export HOOK_ATTENTION_ENABLED="true"
export HOOK_LOG_ENABLED="true"
export HOOK_READ_ENABLED="true"
export HOOK_LINT_MARKDOWN_ENABLED="false"
export HOOK_LINT_SHELL_ENABLED="true"
export HOOK_DELETION_SAFETY_ENABLED="true"
export HOOK_WORKFLOW_GATE_ENABLED="true"
export HOOK_WEBSEARCH_REDIRECT_ENABLED="true"
export HOOK_COMPACT_RECOVERY_ENABLED="true"
```

- One `export HOOK_{GROUP}_ENABLED` line per group (uppercased)
- Values: `"true"` or `"false"` (quoted strings)
- Must match the variable names expected by `cwf-hook-gate.sh`

### 1.4 Update cwf-state.yaml

The same command updates `cwf-state.yaml` `hooks:` to mirror selections:

```yaml
hooks:
  attention: true
  log: true
  read: true
  lint_markdown: false
  lint_shell: true
  deletion_safety: true
  workflow_gate: true
  websearch_redirect: true
  compact_recovery: true
```

Before moving on, verify parity:

```bash
bash {SKILL_DIR}/scripts/sync-hook-state.sh --check
```

---

## Phase 2: External Tool Detection

Detect availability of external AI/search tools and local runtime dependencies used by CWF checks/skills.

### 2.1 Check Tools

Run external tool checks (`codex`, `gemini`, API keys) and local dependency checks (`shellcheck`, `jq`, `gh`, `node`, `python3`, `lychee`, `markdownlint-cli2`) as defined in [tool-detection-and-deps.md](references/tool-detection-and-deps.md).

### 2.2 Update cwf-state.yaml

Rewrite `cwf-state.yaml` `tools:` section with the detection results.

### 2.3 Report Results

Report both groups:
- AI/search tools + API-key presence
- local runtime dependency status

### 2.3.1 Missing Dependency Install Prompt (Required)

If missing dependencies exist, ask install strategy (`Install missing now`, `Show commands only`, `Skip for now`) and execute the matching branch from [tool-detection-and-deps.md](references/tool-detection-and-deps.md).

### 2.3.2 Retry Check (After Install Attempt)

After install attempts, re-run dependency check and explicitly report unresolved tools before continue/stop decision.

### 2.3.3 Post-Install Re-Detection + `cwf-state.yaml` Rewrite (Required)

When `Install missing now` was selected, re-run 2.1 -> 2.2 -> 2.3 in full so `cwf-state.yaml` stays SSOT. This is mandatory even when unresolved dependencies remain.

### 2.3.4 Setup Contract Bootstrap + Repo-Tool Proposal (Required for full/tools setup)

Bootstrap setup contract draft (`.cwf/setup-contract.yaml` by default), report contract status (`created|existing|updated|fallback`), and ask whether to apply repo-specific tool suggestions now. If bootstrap returns `fallback`, stop setup immediately and resolve bootstrap failure first.

Detailed checks, prompts, and commands: [tool-detection-and-deps.md](references/tool-detection-and-deps.md).

---

## Phase 2.4: Codex Integration on Full Setup (Scope-Aware)

Use this phase when:
- Mode is full setup (`cwf:setup`)
- Phase 2 detected `codex: available`

### 2.4.1 Resolve Active Plugin Scope

Resolve scope using `detect-plugin-scope.sh` and parse key-value output without `eval` (safe parser examples are in [codex-scope-integration.md](references/codex-scope-integration.md)).

Mandatory behavior:
- Always print detected values before prompting: active scope, installed scopes, active install path, active project path.
- If detection fails or returns `none`, do not silently default to `user`; ask user to choose target scope explicitly.
- When selected scope is `project` or `local` and root is empty, resolve fallback root using git top-level (or current cwd).

### 2.4.2 Ask Integration Scope + Level

Use AskUserQuestion prompts exactly as defined in [codex-scope-integration.md](references/codex-scope-integration.md):
- scope target prompt
- integration level prompt (`Skills + wrapper`, `Skills only`, `Skip`)

Safety guard:
- If active scope is non-user and target is `user`, require a second explicit confirmation before mutation.

### 2.4.3 Execute Selection

Run command matrix from [codex-scope-integration.md](references/codex-scope-integration.md):
- `Skills + wrapper`: run `sync-skills.sh`, then `install-wrapper.sh --enable` (add PATH only in user scope), then wrapper status.
- `Skills only`: run `sync-skills.sh`.
- `Skip for now`: no mutation.

### 2.4.4 Always Print Post-Setup Verification + Rollback

When wrapper installation was selected, always report:
- `install-wrapper.sh --status`
- `type -a codex`
- before-vs-after summary (scope, touched paths, rollback command)

Detailed rollback/report templates are in [codex-scope-integration.md](references/codex-scope-integration.md), including alias boundary notes for absolute-path aliases/functions.

---

## Phase 2.5: Codex Scope-Aware Skill Sync (Optional)

Use this phase when:
- User runs `cwf:setup --codex`
- Full setup and user wants Codex to load CWF from local repo via symlink

### 2.5.1 Resolve Scope

Reuse [Phase 2.4.1](#241-resolve-active-plugin-scope). Prompt/override details are in [codex-scope-integration.md](references/codex-scope-integration.md).

### 2.5.2 Run Sync Script

Run `sync-skills.sh` with selected scope and optional `--project-root` exactly as defined in [codex-scope-integration.md](references/codex-scope-integration.md).

### 2.5.3 Report Results

Report checklist and verification commands are in [codex-scope-integration.md](references/codex-scope-integration.md).

---

## Phase 2.6: Codex Scope-Aware Wrapper Opt-In (Optional)

Use this phase when:
- User runs `cwf:setup --codex-wrapper`
- Full setup and user wants Codex session logs auto-synced into repo artifacts with post-run quality checks

### 2.6.1 Resolve Scope

Reuse [Phase 2.4.1](#241-resolve-active-plugin-scope). Prompt/override details are in [codex-scope-integration.md](references/codex-scope-integration.md).

### 2.6.2 Ask for Opt-In

Use AskUserQuestion prompt text from [codex-scope-integration.md](references/codex-scope-integration.md). If user declines, skip this phase.

### 2.6.3 Install Wrapper (Approved Only)

Run wrapper install command matrix from [codex-scope-integration.md](references/codex-scope-integration.md):
- user scope uses `--add-path`
- project/local scope uses `--project-root`

### 2.6.4 Report and Reversal

Status, rollback, PATH notes, and post-run tuning options are documented in [codex-scope-integration.md](references/codex-scope-integration.md).

---

## Phase 2.7: Git Hook Gate Installation

Use this phase when:
- Mode is full setup (`cwf:setup`)
- User runs `cwf:setup --git-hooks ...`

### 2.7.1 Resolve Install Mode

Resolve install mode with this priority:
1. `--git-hooks <value>` flag
2. AskUserQuestion selection (`both`, `pre-commit`, `pre-push`, `none`)

### 2.7.2 Resolve Gate Profile

Profiles:
- `fast`
- `balanced`
- `strict`

Resolve profile from `--gate-profile` flag or AskUserQuestion. Skip profile selection when install mode is `none`.

### 2.7.3 Apply Configuration

Apply via [scripts/configure-git-hooks.sh](scripts/configure-git-hooks.sh) with resolved mode/profile.

### 2.7.4 Report Effective State

Always report effective hooks state (`core.hooksPath`, installed hooks, selected profile, enforced checks) and contract-gate resolution policy (`auto` => `authoring` only for CWF authoring repos, otherwise `portable`).

Detailed prompts, command templates, and reporting checklist: [runtime-and-index-phases.md](references/runtime-and-index-phases.md).

---

## Phase 2.8: Project Config Bootstrap

Use this phase when:
- Mode is full setup (`cwf:setup`)
- User runs `cwf:setup --tools`
- User runs `cwf:setup --env`

### 2.8.1 Bootstrap Project Config Files

Ask whether to bootstrap project config templates, then run `bootstrap-project-config.sh` (`--force` when overwrite is selected).

### 2.8.2 Explain Runtime Priority

Always report effective runtime priority:
1. `.cwf-config.local.yaml`
2. `.cwf-config.yaml`
3. process environment
4. shell profile exports

Detailed prompts, command templates, and reporting checklist: [runtime-and-index-phases.md](references/runtime-and-index-phases.md).

---

## Phase 2.9: Agent Team Mode Setup

Use this phase when:
- Mode is full setup (`cwf:setup`)
- User runs `cwf:setup --tools`
- User runs `cwf:setup --agent-teams`

### 2.9.1 Ask Team Mode Policy

Ask whether to enable, keep, or disable Agent Team mode.

### 2.9.2 Apply Selection

Apply via [scripts/configure-agent-teams.sh](scripts/configure-agent-teams.sh) with `--enable`, `--status`, or `--disable`.

### 2.9.3 Report Effective State

Always report current status and remind restart/new session for consistent activation.

Detailed prompts, command templates, and reporting checklist: [runtime-and-index-phases.md](references/runtime-and-index-phases.md).

---

## Phase 2.10: cwf:run Ambiguity Mode Setup

Use this phase when:
- Mode is full setup (`cwf:setup`)
- User runs `cwf:setup --tools`
- User runs `cwf:setup --env`
- User runs `cwf:setup --run-mode`

### 2.10.1 Detect Current Effective Mode

Detect current effective `CWF_RUN_AMBIGUITY_MODE` using env loader; fallback default is `defer-blocking`.

### 2.10.2 Ask Desired Default Mode

Ask desired default mode (`defer-blocking`, `strict`, `defer-reversible`, `explore-worktrees`).

### 2.10.3 Ask Config Scope

Ask config target scope (`shared` or `local`).

### 2.10.4 Persist Selection

Persist via [scripts/configure-run-mode.sh](scripts/configure-run-mode.sh); bootstrap templates first when missing, then retry persist command.

### 2.10.5 Report Effective State

Report selected mode/scope/path and precedence reminder:
- `--ambiguity-mode` flag
- `.cwf-config.local.yaml`
- `.cwf-config.yaml`
- env/shell
- built-in default (`defer-blocking`)

Detailed prompts, command templates, and reporting checklist: [runtime-and-index-phases.md](references/runtime-and-index-phases.md).

---

## Phase 3: Generate CWF Capability Index (Explicit)

This phase runs only when `--cap-index` is explicitly requested.

Mandatory behavior:
- build capability index from current CWF inventories
- keep deterministic ordering and link policy
- validate coverage with `check-index-coverage.sh --profile cap`
- if validation fails, regenerate and fix before finish

Detailed generation and validation checklist: [runtime-and-index-phases.md](references/runtime-and-index-phases.md).

---

## Phase 4: Generate Repository Index (Optional)

Generate repository index when explicitly requested or approved in full setup.

Mandatory behavior:
- ask include/skip decision in full setup
- resolve output target via `--target` or repository-context detection (`agents`, `file`, `both`)
- build deterministic inventories and ordering
- update selected output target(s) deterministically
- validate coverage with `check-index-coverage.sh --profile repo`

Detailed generation and validation checklist: [runtime-and-index-phases.md](references/runtime-and-index-phases.md).

---

## Phase 5: Lessons Checkpoint

### 5.1 Ask for Learnings

Ask for learnings and append `lessons.md` with the standard Expected/Actual/Takeaway format when provided.

### 5.2 Update Stage Checkpoints

Add `setup` to `cwf-state.yaml` current session's `stage_checkpoints` list.

Detailed lessons/checkpoint format: [runtime-and-index-phases.md](references/runtime-and-index-phases.md).

---

## Rules

1. **State SSOT + idempotency**: Read and edit `cwf-state.yaml` (do not overwrite wholesale), and keep reruns safe/idempotent across all phases.
2. **Single-entry setup UX**: Full setup (`cwf:setup`) must execute the integrated optional decision flow for Codex, hooks, setup-contract proposal, config bootstrap, agent-teams, and run-mode phases in one run.
3. **Index generation is explicit and deterministic**: Capability index runs only via `--cap-index`; repository index runs via `--repo-index` with target resolution (`agents`, `file`, `both`) from CLI or repository context.
4. **Index coverage/link policy is mandatory**: Generated indexes must use Markdown relative links and pass deterministic coverage checks (cap/repo profiles).
5. **File safety**: Codex sync must use symlink + backup move (no direct user file deletion).
6. **Scope-aware Codex integration**: Resolve active plugin scope first; non-user context must not mutate user-global Codex paths without explicit user confirmation.
7. **No fail-open scope fallback**: If scope detection fails or returns `none`, require explicit user scope selection before any Codex mutation.
8. **Setup-contract first-run invariant**: Full/tools setup must bootstrap setup-contract and explicitly report `created|existing|updated|fallback` status. `fallback` is fail-safe and must halt setup.
9. **Formatting invariant**: All code fences in this skill must include language specifiers.

## References

- [cwf-hook-gate.sh](../../hooks/scripts/cwf-hook-gate.sh) — hook gate mechanism
- [hooks.json](../../hooks/hooks.json) — hook definitions
- [agent-patterns.md](../../references/agent-patterns.md) — Single pattern
- [references/tool-detection-and-deps.md](references/tool-detection-and-deps.md) — detailed checks/prompts for setup Phase 2 tool detection and dependency handling
- [references/setup-contract.md](references/setup-contract.md) — setup-contract bootstrap and repo-specific tool suggestion flow
- [references/codex-scope-integration.md](references/codex-scope-integration.md) — detailed prompt/command matrix for setup Phase 2.4/2.5/2.6
- [references/runtime-and-index-phases.md](references/runtime-and-index-phases.md) — detailed prompt/command matrix for setup Phase 2.7/2.8/2.9/2.10 and Phase 3/4/5
- [detect-plugin-scope.sh](../../scripts/detect-plugin-scope.sh) — active Claude plugin scope detection for cwd
- [sync-skills.sh](../../scripts/codex/sync-skills.sh) — Codex scope-aware skill sync
- [install-wrapper.sh](../../scripts/codex/install-wrapper.sh) — Codex scope-aware wrapper management
- [verify-skill-links.sh](../../scripts/codex/verify-skill-links.sh) — Codex skill link validation
- [scripts/configure-git-hooks.sh](scripts/configure-git-hooks.sh) — installs and profiles repository git hook gates
- [scripts/check-configure-git-hooks-runtime.sh](scripts/check-configure-git-hooks-runtime.sh) — validates configure-git-hooks runtime behavior across profile/force paths
- [assets/githooks/pre-commit.template.sh](assets/githooks/pre-commit.template.sh) — pre-commit hook template rendered by `configure-git-hooks.sh`
- [assets/githooks/pre-push.template.sh](assets/githooks/pre-push.template.sh) — pre-push hook template rendered by `configure-git-hooks.sh`
- [scripts/bootstrap-project-config.sh](scripts/bootstrap-project-config.sh) — project config template/bootstrap and `.gitignore` sync
- [scripts/configure-agent-teams.sh](scripts/configure-agent-teams.sh) — toggles Claude Agent Team runtime mode in `~/.claude/settings.json`
- [scripts/configure-run-mode.sh](scripts/configure-run-mode.sh) — persists default `cwf:run` ambiguity mode into project config
- [scripts/bootstrap-setup-contract.sh](scripts/bootstrap-setup-contract.sh) — bootstraps repository-local setup contract (`.cwf/setup-contract.yaml`) from core baseline + repo scan
- [scripts/check-setup-contract-runtime.sh](scripts/check-setup-contract-runtime.sh) — validates setup-contract bootstrap status semantics (`created|existing|updated|fallback`, with fail-safe fallback)
- [scripts/install-tooling-deps.sh](scripts/install-tooling-deps.sh) — checks/installs missing local runtime dependencies for CWF workflows
- [scripts/check-index-coverage.sh](scripts/check-index-coverage.sh) — deterministic index coverage validation
- .cwf-cap-index-ignore — optional intentional exclusion list for capability index coverage
- .cwf-index-ignore — optional intentional exclusion list for repository index coverage
