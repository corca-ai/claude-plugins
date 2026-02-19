# Runtime and Index Phase Details

Detailed procedure reference for setup phases 2.7, 2.8, 2.9, 2.10, 3, 4, and 5.

`SKILL.md` is the workflow router and invariant contract. Use this file for concrete prompt text, command matrices, and report/validation checklists.

## Contents

- [Phase 2.7: Git Hook Gate Installation](#phase-27-git-hook-gate-installation)
- [Phase 2.8: Project Config Bootstrap](#phase-28-project-config-bootstrap)
- [Phase 2.9: Agent Team Mode Setup](#phase-29-agent-team-mode-setup)
- [Phase 2.10: CWF Run Ambiguity Mode Setup](#phase-210-cwf-run-ambiguity-mode-setup)
- [Phase 3: Generate CWF Capability Index (Explicit)](#phase-3-generate-cwf-capability-index-explicit)
- [Phase 4: Generate Repository Index (Optional)](#phase-4-generate-repository-index-optional)
- [Phase 5: Lessons Checkpoint](#phase-5-lessons-checkpoint)

## Phase 2.7: Git Hook Gate Installation

Use this phase when:
- Mode is full setup (`cwf:setup`)
- User runs `cwf:setup --git-hooks ...`

### 2.7.1 Resolve Install Mode

Install mode values:
- `none`
- `pre-commit`
- `pre-push`
- `both`

Resolution order:
1. If command includes `--git-hooks <value>`, use it.
2. Otherwise ask AskUserQuestion (single choice):
   ```text
   Configure repository git hook gates as part of setup?
   ```
   Options:
   - `both` (recommended)
   - `pre-commit`
   - `pre-push`
   - `none`

### 2.7.2 Resolve Gate Profile

Gate profile values:
- `fast`: markdownlint only
- `balanced`: markdownlint + local link checks + staged shellcheck + push-time index coverage checks
- `strict`: balanced + provenance freshness and growth-drift reports on push

Contract gate behavior (all profiles):
- hook scripts call `check-portability-contract.sh --contract auto --context hook`
- `auto` always resolves to `portable`
- authoring checks require explicit invocation (`--contract authoring`) from repo-maintainer workflows

Resolution order:
1. If command includes `--gate-profile <value>`, use it.
2. Otherwise ask AskUserQuestion (single choice):
   ```text
   Select git gate profile (speed vs coverage).
   ```
   Options:
   - `balanced` (recommended)
   - `fast`
   - `strict`

If install mode is `none`, skip gate profile selection.

### 2.7.3 Apply Configuration

Run:

```bash
bash {SKILL_DIR}/scripts/configure-git-hooks.sh --install <mode> --profile <profile>
```

This script updates repository git hook files (`pre-commit`, `pre-push`) under the configured hooks path and sets `git config core.hooksPath .githooks` when hooks are enabled.

### 2.7.4 Report Effective State

Always report:

```bash
git config --get core.hooksPath
```

And summarize:
- installed hooks (`pre-commit`, `pre-push`)
- selected profile
- what each hook enforces at that profile
- resolved contract mode policy (`auto -> portable`) and when to run explicit `authoring`

---

## Phase 2.8: Project Config Bootstrap

Use this phase when:
- Mode is full setup (`cwf:setup`)
- User runs `cwf:setup --tools`
- User runs `cwf:setup --env`

### 2.8.1 Bootstrap Project Config Files

Ask whether to create project-level config files (.cwf-config.yaml, .cwf-config.local.yaml) now:

```text
Create project config templates now? (.cwf-config.yaml + .cwf-config.local.yaml)
```

Options:
- `Yes (recommended)`:
  - create missing config templates
  - keep existing files unchanged
  - ensure .cwf-config.local.yaml is listed in `.gitignore`
- `Overwrite templates`:
  - re-write both templates (`--force`)
  - ensure .cwf-config.local.yaml is listed in `.gitignore`
- `Skip for now`:
  - no file changes in this sub-phase

When user selects `Yes (recommended)`, run:

```bash
bash {SKILL_DIR}/scripts/bootstrap-project-config.sh
```

When user selects `Overwrite templates`, run:

```bash
bash {SKILL_DIR}/scripts/bootstrap-project-config.sh --force
```

### 2.8.2 Explain Runtime Priority

After bootstrap decisions, always report the effective CWF config source priority:

1. .cwf-config.local.yaml
2. .cwf-config.yaml
3. Process environment
4. Shell profile exports (`~/.zshenv`, `~/.zprofile`, `~/.zshrc`, `~/.bash_profile`, `~/.bashrc`, `~/.profile`)

Include this operational guidance:

```text
Use .cwf-config.yaml for team-shared, non-secret defaults.
Use .cwf-config.local.yaml for local/secret values.
Keep shell exports as global fallback.
```

---

## Phase 2.9: Agent Team Mode Setup

Use this phase when:
- Mode is full setup (`cwf:setup`)
- User runs `cwf:setup --tools`
- User runs `cwf:setup --agent-teams`

### 2.9.1 Ask Team Mode Policy

Use AskUserQuestion (single choice):

```text
Configure Claude Code Agent Team mode now?
```

Options:
- `Enable Agent Team mode (recommended)`:
  - sets `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` in `~/.claude/settings.json` `env`
- `Keep current setting`:
  - no modification, status report only
- `Disable Agent Team mode`:
  - removes `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` from `~/.claude/settings.json` `env`

### 2.9.2 Apply Selection

When user selects `Enable Agent Team mode (recommended)`, run:

```bash
bash {SKILL_DIR}/scripts/configure-agent-teams.sh --enable
```

When user selects `Keep current setting`, run:

```bash
bash {SKILL_DIR}/scripts/configure-agent-teams.sh --status
```

When user selects `Disable Agent Team mode`, run:

```bash
bash {SKILL_DIR}/scripts/configure-agent-teams.sh --disable
```

### 2.9.3 Report Effective State

Always report:

```bash
bash {SKILL_DIR}/scripts/configure-agent-teams.sh --status
```

And include this note in plain language:

```text
Restart Claude Code (or open a new session) so Agent Team mode changes are applied consistently.
```

---

## Phase 2.10: CWF Run Ambiguity Mode Setup

Use this phase when:
- Mode is full setup (`cwf:setup`)
- User runs `cwf:setup --tools`
- User runs `cwf:setup --env`
- User runs `cwf:setup --run-mode`

### 2.10.1 Detect Current Effective Mode

Run:

```bash
source {CWF_PLUGIN_DIR}/hooks/scripts/env-loader.sh
cwf_env_load_vars CWF_RUN_AMBIGUITY_MODE
printf '%s\n' "${CWF_RUN_AMBIGUITY_MODE:-defer-blocking}"
```

If the key is unset anywhere, treat `defer-blocking` as the effective default.

### 2.10.2 Ask Desired Default Mode

Use AskUserQuestion (single choice):

```text
Select default ambiguity handling mode for cwf:run (T3 decisions in clarify).
```

Options:
- `defer-blocking (recommended)`:
  - continue autonomously
  - must record autonomous T3 decisions
  - must carry unresolved decisions to ship as merge-blocking items
- `strict`:
  - stop and ask the user at T3
- `defer-reversible`:
  - continue autonomously with reversible implementation structure
  - still record decisions, but not merge-blocking by default
- `explore-worktrees`:
  - implement alternatives in separate worktrees and compare before finalization

### 2.10.3 Ask Config Scope

Use AskUserQuestion (single choice):

```text
Where should this default mode be saved?
```

Options:
- `Shared config (recommended)`:
  - write to `.cwf-config.yaml`
  - team-wide default for this repository
- `Local config`:
  - write to `.cwf-config.local.yaml`
  - local override only (highest priority)

### 2.10.4 Persist Selection

Run:

```bash
bash {SKILL_DIR}/scripts/configure-run-mode.sh --mode <selected-mode> --scope <shared|local>
```

If config templates are missing, bootstrap first:

```bash
bash {SKILL_DIR}/scripts/bootstrap-project-config.sh
```

Then retry `configure-run-mode.sh`.

### 2.10.5 Report Effective State

Report:
- selected mode
- selected scope
- written config path

Provide verification command:

```bash
rg -n "^CWF_RUN_AMBIGUITY_MODE:" .cwf-config.yaml .cwf-config.local.yaml 2>/dev/null
```

Also report precedence reminder:
- `--ambiguity-mode` flag
- `.cwf-config.local.yaml`
- `.cwf-config.yaml`
- env/shell
- built-in default (`defer-blocking`)

---

## Phase 3: Generate CWF Capability Index (Explicit)

Generate a CWF-focused capability index. This phase runs only when `--cap-index` is explicitly requested.

### 3.1 Scan CWF Structure

Build CWF capability inventories from the repository:

- [plugins/cwf/.claude-plugin/plugin.json](../../../.claude-plugin/plugin.json) (if present)
- [plugins/cwf/hooks/hooks.json](../../../hooks/hooks.json), [plugins/cwf/hooks/scripts/cwf-hook-gate.sh](../../../hooks/scripts/cwf-hook-gate.sh), and [plugins/cwf/hooks/README.md](../../../hooks/README.md) (if present)
- `plugins/cwf/skills/*/SKILL.md`
- `plugins/cwf/references/*.md`
- [plugins/cwf/scripts/README.md](../../../scripts/README.md) and key operational scripts (for example [plugins/cwf/scripts/check-session.sh](../../../scripts/check-session.sh), [plugins/cwf/scripts/codex](../../../scripts/codex))

### 3.2 Build CWF Capability Index

Generate concise capability-oriented sections:

```markdown
## {area} — {capability boundary}

- [label](path/to/file): {what this file is}
```

- Keep descriptions file-centric; avoid procedure-heavy wording.
- Use canonical CWF skill order for [plugins/cwf/skills](../..): `setup`, `update`, `gather`, `clarify`, `plan`, `review`, `impl`, `retro`, `handoff`, `ship`, `run`, `refactor`.
- Use deterministic alphabetical order for other sections.
- Ensure every internal file/directory reference uses a Markdown link with a relative target.
- Do not enumerate skill-internal files in index bullets; add one concise sentence that skill-local READMEs contain per-skill file maps.
- For hooks/scripts families, prefer linking [plugins/cwf/hooks/README.md](../../../hooks/README.md) and [plugins/cwf/scripts/README.md](../../../scripts/README.md) over enumerating every script file.

### 3.3 Write Capability Index

Create or overwrite the capability index output file under the artifact index directory:

```markdown
# CWF Capability Index

> Generated by `cwf:setup --cap-index`. Default output file: `.cwf/indexes/cwf-index.md`.

{areas}
```

### 3.4 Capability Coverage Validation (Required)

Run:

```bash
bash {SKILL_DIR}/scripts/check-index-coverage.sh .cwf/indexes/cwf-index.md --profile cap
```

This check applies optional exclusions from repository-root .cwf-cap-index-ignore.

If validation fails, regenerate and fix missing coverage before finishing.

---

## Phase 4: Generate Repository Index (Optional)

Generate a repository-wide progressive disclosure index for the current project.

### 4.0 Entry and Safety Rules

When mode is full setup (`cwf:setup`), ask first:

```text
Generate repository index for this repo as well?
```

If user answers `No`, skip Phase 4.

### 4.0.2 Output Target Selection

Target resolution:

1. If command includes `--target <agents|file|both>`, use it.
2. Otherwise auto-detect:
   - if an AGENTS guide file exists (or already contains managed block markers), default to `agents`
   - if no AGENTS guide file exists, default to `file`
3. Standalone file target: repository-index file (`repo-index.md`) under the artifact index directory.
4. `both` means writing both outputs with equivalent index content.

Managed AGENTS block markers:

```markdown
<!-- CWF:INDEX:START -->
...generated index body...
<!-- CWF:INDEX:END -->
```

If target includes `agents` and AGENTS.md does not exist, create it with a minimal scaffold and the managed block.

### 4.1 Scan Project Structure

Use Glob to find top-level directories. Exclude hidden directories (`.git`, `.claude`, `.cwf`), `node_modules`, and `projects`.

Build adaptive file inventories (sorted) from the current repository structure:

- Root entry docs if present: AGENTS.md, CLAUDE.md, README.md, README.ko.md
- `docs/*.md` (when `docs/` exists)
- `references/**/*.md` (when `references/` exists)
- Any `*/skills/*/SKILL.md` (excluding `.git/`, `.cwf/`, `node_modules/`, `projects/`)
- Any non-skill `*/references/*.md` (excluding `.git/`, `.cwf/`, `node_modules/`, `projects/`, and `*/skills/*/references/*`)
- If present: [plugins/cwf/hooks/README.md](../../../hooks/README.md), [plugins/cwf/scripts/README.md](../../../scripts/README.md)

These discovered inventories are mandatory coverage sets for repository index generation.

Apply optional exclusions from repository-root .cwf-index-ignore (glob patterns, one per line) before finalizing repository index content.

### 4.2 Build Repository Index

For each area, generate:

```markdown
## {area} — {task intent boundary; when this area becomes relevant}

- [label](path/to/file): {one-line description of what this file is}
```

- Keep intent text concise and intent-level.
- Absorb read-intent into section headings; omit separate `When to read`/`Role`/`Key files` labels.
- Prefer concise link labels when local context is clear.
- Ensure every internal file/directory reference uses a Markdown link with a relative target.
- Make descriptions file-centric ("what this file is"), not action scripts.
- Do not enumerate skill-internal files in index bullets; add one concise sentence that skill-local READMEs contain per-skill file maps.
- For hooks/scripts families, prefer linking [plugins/cwf/hooks/README.md](../../../hooks/README.md) and [plugins/cwf/scripts/README.md](../../../scripts/README.md) over enumerating every script file.
- Do not use representative sampling for coverage sets; include every file in the mandatory inventories.
- Use one stable ordering policy:
  - Root: fixed priority order (`README`, `AGENTS`, `CLAUDE`, `cwf-state`, `README.ko`).
  - When [plugins/cwf/skills](../..) exists, use canonical CWF workflow order (`setup`, `update`, `gather`, `clarify`, `plan`, `review`, `impl`, `retro`, `handoff`, `ship`, `run`, `refactor`).
  - For non-CWF skill collections, use deterministic alphabetical order.
  - Other sections: deterministic order (alphabetical unless there is a clear canonical sequence).

### 4.3 Write Selected Output Targets

When target includes `agents`, write the generated repository index body into the managed block in AGENTS.md:

- If markers exist, replace only the marker-delimited section.
- If markers are absent, append a new managed block at the end of AGENTS.md.

When target includes `file`, write the same repository index body to the standalone `repo-index.md` file under the artifact index directory (create parent directories as needed).

### 4.4 Repository Coverage Validation (Required)

Run validation for each selected target:

- `agents` target:
  ```bash
  bash {SKILL_DIR}/scripts/check-index-coverage.sh AGENTS.md --profile repo
  ```
- `file` target:
  ```bash
  bash {SKILL_DIR}/scripts/check-index-coverage.sh .cwf/indexes/repo-index.md --profile repo
  ```
- `both` target: run both commands.

Checks apply optional exclusions from repository-root `.cwf-index-ignore`.

If validation fails, regenerate and fix missing links before finishing.

---

## Phase 5: Lessons Checkpoint

### 5.1 Ask for Learnings

Ask the user: "Any learnings from the setup process?"

If yes, append to `lessons.md` in the current session artifact directory using the standard format:

```markdown
### {title}

- **Expected**: {what was anticipated}
- **Actual**: {what was discovered}
- **Takeaway**: {key insight}
```

### 5.2 Update Stage Checkpoints

Add `setup` to `cwf-state.yaml` current session's `stage_checkpoints` list.
