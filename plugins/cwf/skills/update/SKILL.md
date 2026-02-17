---
name: update
description: "Check and update CWF plugin to keep installed behavior aligned with latest contracts and fixes. Triggers: \"cwf:update\", \"update cwf\", \"check for updates\""
---

# Update

Keep installed CWF behavior aligned with the latest marketplace version and fixes, with scope-aware reconciliation for Codex integration paths.

**Language**: Write artifacts in English. Communicate with the user in their prompt language.

## Quick Start

```text
cwf:update               # Check + update selected scope if newer version exists
cwf:update --check       # Version/scope/reconcile check only (no install, no mutation)
```

---

## Phase 0: Resolve Update Scope (Required)

### 0.1 Detect Active Plugin Scope

Resolve active CWF plugin scope for current cwd:

```bash
scope_info="$(bash {CWF_PLUGIN_DIR}/scripts/detect-plugin-scope.sh --plugin cwf --cwd "$PWD" 2>/dev/null || true)"
```

Parse when available:

```bash
eval "$scope_info"
selected_scope="${active_scope:-user}"
selected_project_root="${active_project_path:-}"
if [ "$selected_scope" = "none" ]; then
  selected_scope="user"
fi
```

If `selected_scope` is `project` or `local` and project root is empty, resolve fallback root:

```bash
selected_project_root="$(git -C "$PWD" rev-parse --show-toplevel 2>/dev/null || printf '%s' "$PWD")"
```

Always print:
- active scope
- installed scopes
- active install path
- active project path (if any)

### 0.2 Confirm Target Scope (Multi-Scope Safety)

If multiple CWF scopes are installed, ask which scope to update:

```text
Multiple CWF scopes are installed. Which scope should cwf:update target?
```

Options:
- `Active scope (recommended)`
- `User scope`
- `Project scope`
- `Local scope`

If the chosen scope is not installed, stop and report valid installed scopes.

---

## Phase 1: Version Check (Selected Scope)

### 1.1 Find Current Version + Baseline Snapshot

Resolve current installed entry from `claude plugin list --json` for selected scope:

```bash
plugin_list_json="$(claude plugin list --json 2>/dev/null || printf '[]')"
current_install_path="$(
  printf '%s' "$plugin_list_json" \
    | jq -r --arg scope "$selected_scope" \
      '[.[] | select(.id | startswith("cwf@")) | select(.scope == $scope) | .installPath] | first // empty'
)"
[ -n "$current_install_path" ] || {
  echo "CWF is not installed in scope: $selected_scope"
  exit 1
}

current_plugin_json="$current_install_path/.claude-plugin/plugin.json"
[ -f "$current_plugin_json" ] || {
  echo "plugin.json not found for selected scope: $current_plugin_json"
  exit 1
}

current_plugin_root="$current_install_path"
current_version="$(jq -r '.version' "$current_plugin_json")"
baseline_root="$(mktemp -d "${TMPDIR:-/tmp}/cwf-before.XXXXXX")"
cp -a "$current_plugin_root"/. "$baseline_root"/
old_diff_root="$baseline_root"
```

### 1.2 Update Marketplace Metadata

Always refresh marketplace metadata first:

```bash
claude plugin marketplace update corca-plugins
```

### 1.3 Compare Versions

Resolve latest marketplace payload snapshot:

```bash
latest_plugin_json="$(ls -1dt ~/.claude/plugins/cache/*/cwf/*/.claude-plugin/plugin.json 2>/dev/null | head -n1)"
[ -n "$latest_plugin_json" ] || {
  echo "Latest CWF metadata not found after marketplace update."
  exit 1
}

latest_plugin_root="$(dirname "$(dirname "$latest_plugin_json")")"
latest_version="$(jq -r '.version' "$latest_plugin_json")"
marketplace_root="$(mktemp -d "${TMPDIR:-/tmp}/cwf-after-marketplace.XXXXXX")"
cp -a "$latest_plugin_root"/. "$marketplace_root"/
new_diff_root="$marketplace_root"
```

Report:

```text
Target scope:    user|project|local
Current version: 0.6.0
Latest version:  0.7.0
```

Persist for later phases: `old_diff_root`, `new_diff_root`, `current_version`, `latest_version`, `selected_scope`, `selected_project_root`.

---

## Phase 2: Apply Update (Scope-Aware)

Skip this phase if `--check` was used or versions already match.

### 2.1 Confirm with User

Use AskUserQuestion:

```text
Update CWF in scope {selected_scope} from {current_version} to {latest_version}?
```

Options: `Yes, update` / `No, skip`

### 2.2 Apply Update to Selected Scope

Run scope-aware update:

```bash
claude plugin update "cwf@corca-plugins" --scope "$selected_scope"
```

If update command is unavailable in current runtime, fallback:

```bash
claude plugin install "cwf@corca-plugins" --scope "$selected_scope"
```

### 2.3 Refresh Installed Snapshot

Re-resolve selected-scope install path after update and overwrite `new_diff_root`:

```bash
post_list_json="$(claude plugin list --json 2>/dev/null || printf '[]')"
installed_install_path="$(
  printf '%s' "$post_list_json" \
    | jq -r --arg scope "$selected_scope" \
      '[.[] | select(.id | startswith("cwf@")) | select(.scope == $scope) | .installPath] | first // empty'
)"
[ -n "$installed_install_path" ] || {
  echo "Installed CWF metadata not found after update for scope: $selected_scope"
  exit 1
}

installed_plugin_json="$installed_install_path/.claude-plugin/plugin.json"
installed_version="$(jq -r '.version' "$installed_plugin_json")"
post_install_root="$(mktemp -d "${TMPDIR:-/tmp}/cwf-after-install.XXXXXX")"
cp -a "$installed_install_path"/. "$post_install_root"/
new_diff_root="$post_install_root"
latest_version="$installed_version"
```

### 2.4 Report Success

```text
CWF updated in scope {selected_scope} to {installed_version}. Restart Claude Code for changes to take effect.
```

---

## Phase 3: Codex Integration Reconciliation (Scope-Aware)

Goal: repair stale Codex symlink/wrapper targets when plugin install paths change across versions.

### 3.1 Detect Existing Codex Integration for Selected Scope

Resolve destination paths:

- `user` scope:
  - skills: `~/.agents/skills`
  - wrapper: `~/.local/bin/codex`
- project/local scope:
  - skills: `{projectRoot}/.codex/skills`
  - wrapper: `{projectRoot}/.codex/bin/codex`

Detect prior integration signals:

```bash
skills_link_present="false"
wrapper_active="false"

if [ "$selected_scope" = "user" ]; then
  [ -L "${AGENTS_HOME:-$HOME/.agents}/skills/setup" ] && skills_link_present="true"
  wrapper_status="$(bash {CWF_PLUGIN_DIR}/scripts/codex/install-wrapper.sh --scope user --status)"
else
  [ -L "$selected_project_root/.codex/skills/setup" ] && skills_link_present="true"
  wrapper_status="$(bash {CWF_PLUGIN_DIR}/scripts/codex/install-wrapper.sh --scope "$selected_scope" --project-root "$selected_project_root" --status)"
fi
printf '%s\n' "$wrapper_status"
printf '%s' "$wrapper_status" | grep -q 'Active        : true' && wrapper_active="true"
```

### 3.2 Reconcile (Mutation Rules)

- If `--check`: never mutate; report detection only and print recommended reconcile commands.
- If update was applied in Phase 2:
  - when `skills_link_present=true`, run `sync-skills.sh` for selected scope.
  - when `wrapper_active=true`, run `install-wrapper.sh --enable` for selected scope (without `--add-path`) to repoint symlink to current version path.
  - when neither is present, report "no existing Codex integration to reconcile" and skip mutation.

Commands:

```bash
# skills reconcile
bash {CWF_PLUGIN_DIR}/scripts/codex/sync-skills.sh --scope "$selected_scope" ${selected_project_root:+--project-root "$selected_project_root"} --cleanup-legacy

# wrapper reconcile
bash {CWF_PLUGIN_DIR}/scripts/codex/install-wrapper.sh --scope "$selected_scope" ${selected_project_root:+--project-root "$selected_project_root"} --enable
bash {CWF_PLUGIN_DIR}/scripts/codex/install-wrapper.sh --scope "$selected_scope" ${selected_project_root:+--project-root "$selected_project_root"} --status
```

### 3.3 Report Reconcile Summary (Before vs After)

Always report:
- selected scope and project root (if any)
- whether skills links were detected and reconciled
- whether wrapper was active and reconciled
- rollback commands:

```bash
bash {CWF_PLUGIN_DIR}/scripts/codex/install-wrapper.sh --scope "$selected_scope" ${selected_project_root:+--project-root "$selected_project_root"} --disable
```

For skill-link rollback, direct user to scope backup roots:
- user: `~/.agents/.skill-sync-backup/*`
- project/local: `{projectRoot}/.codex/.skill-sync-backup/*`

---

## Phase 4: Changelog Summary

After update/check, summarize diff evidence with stable roots:

1. Build file-change inventory:

```bash
git --no-pager diff --no-index --name-status "$old_diff_root" "$new_diff_root" || true
```

1. Diff changelog first:

```bash
git --no-pager diff --no-index \
  "$old_diff_root/CHANGELOG.md" \
  "$new_diff_root/CHANGELOG.md" || true
```

1. Diff README for user-facing guidance changes:

```bash
git --no-pager diff --no-index \
  "$old_diff_root/README.md" \
  "$new_diff_root/README.md" || true
```

1. Summary procedure:
   - If changelog diff exists, summarize changes between `{current_version}` and `{latest_version}` first.
   - Add notable `SKILL.md`/script/manifest changes from name-status diff.
   - Add README delta as "user-facing setup/usage guidance changes".
   - If changelog is absent on both sides, state that explicitly and rely on deterministic file diff evidence.

---

## Phase 5: Lessons Checkpoint

Add `update` to `cwf-state.yaml` current session's `stage_checkpoints` list if lessons were recorded during the update process.

---

## Rules

1. **Resolve scope first**: Always resolve and report active/selected scope before version check or update.
2. **Update marketplace first**: Always run marketplace update before plugin update/install.
3. **Scope-aware apply**: Update/install must target explicit scope via `--scope`.
4. **Require user confirmation**: Never auto-update without asking.
5. **Reconcile Codex links after update**: For existing Codex integrations in selected scope, run reconcile in the same update flow.
6. **No mutation in check mode**: `cwf:update --check` must not install/update/reconcile; it reports status and suggested commands only.
7. **Changes take effect after restart**: Always remind user to restart Claude Code.
8. **All code fences must have language specifier**: Never use bare fences.

## References

- [README.md](README.md) — File-map entry for this skill directory (not release notes)
- [agent-patterns.md](../../references/agent-patterns.md) — Single pattern
- [detect-plugin-scope.sh](../../scripts/detect-plugin-scope.sh) — active Claude plugin scope detection for cwd
- [sync-skills.sh](../../scripts/codex/sync-skills.sh) — Codex scope-aware skill sync
- [install-wrapper.sh](../../scripts/codex/install-wrapper.sh) — Codex scope-aware wrapper management
