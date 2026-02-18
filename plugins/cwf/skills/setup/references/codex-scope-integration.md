# Codex Scope-Aware Integration Details

Detailed command and prompt contract for `setup` Phase 2.4, 2.5, and 2.6.

`SKILL.md` remains the routing and invariant source. Use this file for concrete prompt text, command templates, and reporting checklists.

## Contents

- [2.4 Full Setup Codex Integration](#24-full-setup-codex-integration)
- [2.5 `--codex` Skill Sync Rerun](#25---codex-skill-sync-rerun)
- [2.6 `--codex-wrapper` Wrapper Rerun](#26---codex-wrapper-wrapper-rerun)

## 2.4 Full Setup Codex Integration

### 2.4.1 Resolve Active Plugin Scope

Run detection and keep stderr for explicit failure reporting:

```bash
scope_detect_err="$(mktemp \"${TMPDIR:-/tmp}/cwf-scope-detect.XXXXXX\")"
scope_info="$(bash {CWF_PLUGIN_DIR}/scripts/detect-plugin-scope.sh --plugin cwf --cwd "$PWD" 2>"$scope_detect_err" || true)"
```

Parse key-value output without `eval`:

```bash
active_scope=""
active_plugin_id=""
active_install_path=""
active_project_path=""
installed_scopes=""

while IFS='=' read -r key value; do
  case "$key" in
    active_scope) active_scope="$value" ;;
    active_plugin_id) active_plugin_id="$value" ;;
    active_install_path) active_install_path="$value" ;;
    active_project_path) active_project_path="$value" ;;
    installed_scopes) installed_scopes="$value" ;;
  esac
done <<EOF_SCOPE
$scope_info
EOF_SCOPE
```

Normalize selection:

```bash
selected_scope="$active_scope"
selected_project_root="$active_project_path"
scope_detection_failed="false"

if [ -z "$scope_info" ] || [ -z "$active_scope" ] || [ "$active_scope" = "none" ]; then
  scope_detection_failed="true"
  selected_scope=""
fi

if [ -n "$selected_scope" ] && [ -z "$selected_project_root" ] && { [ "$selected_scope" = "project" ] || [ "$selected_scope" = "local" ]; }; then
  selected_project_root="$(git -C "$PWD" rev-parse --show-toplevel 2>/dev/null || printf '%s' "$PWD")"
fi
```

Always print before prompting:
- active scope
- installed scopes
- active install path
- active project path

When `scope_detection_failed=true`, print failure context:

```bash
echo "Scope detection failed. Choose scope explicitly for this run."
[ -s "$scope_detect_err" ] && sed 's/^/  /' "$scope_detect_err"
```

Then ask explicit target scope:

```text
Scope detection failed or returned none. Which scope should Codex integration target for this setup run?
```

Options:
- `User scope`
- `Project scope`
- `Local scope`
- `Skip Codex integration for now`

For project/local selections, ask project root if unresolved.

When detection succeeded from non-user scope and user chooses `User scope`, require second confirmation:

```text
This run is in {active_scope} scope, but selected target is user-global (~/.agents, ~/.local/bin). Continue?
```

### 2.4.2 Ask Integration Level

Prompt:

```text
Codex CLI was detected. How should CWF integrate with Codex for scope {selected_scope}?
```

Options:
- `Skills + wrapper (recommended)`
- `Skills only`
- `Skip for now`

### 2.4.3 Execute Selection

If `Skills + wrapper (recommended)`:

```bash
bash {CWF_PLUGIN_DIR}/scripts/codex/sync-skills.sh --scope "$selected_scope" ${selected_project_root:+--project-root "$selected_project_root"} --cleanup-legacy
if [ "$selected_scope" = "user" ]; then
  bash {CWF_PLUGIN_DIR}/scripts/codex/install-wrapper.sh --scope "$selected_scope" --enable --add-path
else
  bash {CWF_PLUGIN_DIR}/scripts/codex/install-wrapper.sh --scope "$selected_scope" --project-root "$selected_project_root" --enable
fi
bash {CWF_PLUGIN_DIR}/scripts/codex/install-wrapper.sh --scope "$selected_scope" ${selected_project_root:+--project-root "$selected_project_root"} --status
```

If `Skills only`:

```bash
bash {CWF_PLUGIN_DIR}/scripts/codex/sync-skills.sh --scope "$selected_scope" ${selected_project_root:+--project-root "$selected_project_root"} --cleanup-legacy
```

If `Skip for now`: do not mutate Codex integration.

### 2.4.4 Verify, Report, Rollback

When wrapper was touched, always run:

```bash
bash {CWF_PLUGIN_DIR}/scripts/codex/install-wrapper.sh --scope "$selected_scope" ${selected_project_root:+--project-root "$selected_project_root"} --status
type -a codex
```

Report:
- selected scope
- touched skills/references/wrapper paths
- rollback commands

Rollback:

```bash
bash {CWF_PLUGIN_DIR}/scripts/codex/install-wrapper.sh --scope "$selected_scope" ${selected_project_root:+--project-root "$selected_project_root"} --disable
```

Skill-link rollback roots:
- user: `~/.agents/.skill-sync-backup/*`
- project/local: `{projectRoot}/.codex/.skill-sync-backup/*`

Activation and boundary notes:
- If scope is user: open a new shell (or source shell rc) before testing `codex`.
- If scope is project/local: add `{projectRoot}/.codex/bin` to PATH in that shell before testing `codex`.
- Aliases that call `codex` by command name inherit wrapper behavior.
- Aliases/functions that call an absolute binary path bypass wrapper behavior and need manual adjustment.

## 2.5 `--codex` Skill Sync Rerun

### 2.5.1 Resolve Scope

Reuse 2.4.1. Default target is detected active scope.

From non-user context, user-global override requires explicit confirmation.

### 2.5.2 Run Sync

```bash
bash {CWF_PLUGIN_DIR}/scripts/codex/sync-skills.sh --scope "$selected_scope" ${selected_project_root:+--project-root "$selected_project_root"} --cleanup-legacy
```

Expected behavior:
- user: links into `~/.agents/skills` and `~/.agents/references`
- project/local: links into `{projectRoot}/.codex/skills` and `{projectRoot}/.codex/references`
- user scope may move legacy custom entries from `~/.codex/skills` to backup (keeping `.system`)
- relative skill references are validated by `verify-skill-links.sh`

### 2.5.3 Report Results

Report:
- linked skill count
- destination paths
- whether legacy `~/.codex/skills` entries were moved (user scope)
- before/after touched paths
- rollback guidance from `.skill-sync-backup`

Quick verification by scope:

```bash
# user
ls -la ~/.agents/skills

# project/local
ls -la "$selected_project_root/.codex/skills"
```

## 2.6 `--codex-wrapper` Wrapper Rerun

### 2.6.1 Resolve Scope

Reuse 2.4.1. Default target is detected active scope.

From non-user context, user-global override requires explicit confirmation.

### 2.6.2 Ask Opt-In

```text
Enable Codex wrapper for scope {selected_scope} with automatic session log sync and post-run quality checks (including tool-hygiene + HITL sync gates)?
```

If declined, skip.

### 2.6.3 Install Wrapper

```bash
if [ "$selected_scope" = "user" ]; then
  bash {CWF_PLUGIN_DIR}/scripts/codex/install-wrapper.sh --scope "$selected_scope" --enable --add-path
else
  bash {CWF_PLUGIN_DIR}/scripts/codex/install-wrapper.sh --scope "$selected_scope" --project-root "$selected_project_root" --enable
fi
```

Wrapper target:
- user: `~/.local/bin/codex`
- project/local: `{projectRoot}/.codex/bin/codex`

Wrapper source:

```text
{CWF_PLUGIN_DIR}/scripts/codex/codex-with-log.sh
```

Wrapper post-run behavior:

```bash
bash {CWF_PLUGIN_DIR}/scripts/codex/sync-session-logs.sh --cwd "$PWD"
bash {CWF_PLUGIN_DIR}/scripts/codex/post-run-checks.sh --cwd "$PWD" --mode warn
```

Logs persist under `.cwf/sessions/` by default (legacy fallback: `.cwf/projects/sessions/`) as `*.codex.md`.

### 2.6.4 Report and Reversal

Report status:

```bash
bash {CWF_PLUGIN_DIR}/scripts/codex/install-wrapper.sh --scope "$selected_scope" ${selected_project_root:+--project-root "$selected_project_root"} --status
```

Rollback:

```bash
bash {CWF_PLUGIN_DIR}/scripts/codex/install-wrapper.sh --scope "$selected_scope" ${selected_project_root:+--project-root "$selected_project_root"} --disable
```

Also report:
- before/after wrapper path summary
- PATH auto-update status (`user` only)
- manual PATH export command for project/local scope
- tuning knobs:
  - `CWF_CODEX_POST_RUN_CHECKS=true|false` (default `true`)
  - `CWF_CODEX_POST_RUN_MODE=warn|strict` (default `warn`)
  - `CWF_CODEX_POST_RUN_QUIET=true|false` (default `false`)
