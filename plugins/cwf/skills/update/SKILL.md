---
name: update
description: "Check and update CWF plugin to keep installed behavior aligned with latest contracts and fixes. Triggers: \"cwf:update\", \"update cwf\", \"check for updates\""
---

# Update

Keep installed CWF behavior aligned with the latest marketplace version and fixes, with scope-aware reconciliation for Codex integration paths.

## Quick Start

```text
cwf:update               # Check + auto-update selected scope if newer version exists
cwf:update --check       # Version/scope/reconcile check only (no install, no mutation)
```

---

## Phase 0: Resolve Update Scope (Required)

### 0.1 Detect Active Plugin Scope

Resolve active scope using the safe parsing flow in [scope-reconcile.md](references/scope-reconcile.md) (no `eval`).

Mandatory behavior:
- Always print active scope, installed scopes, active install path, and active project path before prompting.
- If detection fails or returns `none`, do not default to `user`; ask for explicit target scope.
- If selected scope is `project`/`local` and project root is missing, resolve fallback root via git top-level (or current cwd).

### 0.2 Confirm Target Scope (Multi-Scope Safety)

Use scope selection prompt/options from [scope-reconcile.md](references/scope-reconcile.md).

Safety guard:
- If active scope is non-user and selected target is `user`, require a second explicit confirmation before update/reconcile mutation.
- If the chosen scope is not installed, stop and report valid installed scopes.

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

### 1.3 Compare Versions (Authoritative + Fail-Closed)

Run authoritative consistency checker after marketplace refresh:

```bash
consistency_json="$(
  bash {CWF_PLUGIN_DIR}/scripts/check-update-latest-consistency.sh \
    --mode top-level \
    --scope "$selected_scope" \
    --json
)"
```

Parse result:

```bash
verdict="$(printf '%s' "$consistency_json" | jq -r '.verdict // "UNVERIFIED"')"
consistency_reason="$(printf '%s' "$consistency_json" | jq -r '.reason // "UNKNOWN"')"
checked_current_version="$(printf '%s' "$consistency_json" | jq -r '.current_version // empty')"
authoritative_latest_version="$(printf '%s' "$consistency_json" | jq -r '.authoritative_latest // empty')"
```

Fail-closed rule:

```bash
if [ "$verdict" = "UNVERIFIED" ]; then
  echo "Latest-version verification is UNVERIFIED (reason: $consistency_reason)."
  echo "Do not emit success-style no-update verdicts in this state."
  echo "Re-run from a top-level environment where marketplace update + authoritative fetch are available."
  exit 2
fi
```

Then set compare values and post-marketplace snapshot:

```bash
[ -n "$checked_current_version" ] || {
  echo "Current version missing from consistency check output."
  exit 1
}
[ -n "$authoritative_latest_version" ] || {
  echo "Authoritative latest version missing from consistency check output."
  exit 1
}

current_version="$checked_current_version"
latest_version="$authoritative_latest_version"
authoritative_snapshot_root="$(mktemp -d "${TMPDIR:-/tmp}/cwf-after-marketplace.XXXXXX")"
cp -a "$current_install_path"/. "$authoritative_snapshot_root"/
new_diff_root="$authoritative_snapshot_root"
```

Report:

```text
Target scope:    user|project|local
Current version: 0.6.0
Latest version:  0.7.0
Verdict:         UP_TO_DATE|OUTDATED
```

Persist for later phases: `old_diff_root`, `new_diff_root`, `current_version`, `latest_version`, `verdict`, `selected_scope`, `selected_project_root`.

---

## Phase 2: Apply Update (Scope-Aware)

Skip this phase if `--check` was used or `verdict=UP_TO_DATE`, and report that no update mutation was applied when the skip reason is parity. `verdict=UNVERIFIED` never enters this phase (fail-closed in Phase 1.3).

### 2.1 Apply Update to Selected Scope (No Confirmation Prompt)

Run scope-aware update:

```bash
echo "Updating CWF in scope $selected_scope from $current_version to $latest_version..."
claude plugin update "cwf@corca-plugins" --scope "$selected_scope"
```

If update command is unavailable in current runtime, fallback:

```bash
claude plugin install "cwf@corca-plugins" --scope "$selected_scope"
```

### 2.2 Refresh Installed Snapshot

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

### 2.3 Report Success

```text
CWF updated in scope {selected_scope} to {installed_version}. Restart Claude Code for changes to take effect.
```

---

## Phase 3: Codex Integration Reconciliation (Scope-Aware)

Goal: repair stale Codex symlink/wrapper targets when plugin install paths change across versions.

### 3.1 Detect Existing Codex Integration for Selected Scope

Detect integration signals using the detailed flow in [scope-reconcile.md](references/scope-reconcile.md).

Detection output must track:
- `skills_link_present`
- `wrapper_active`
- `wrapper_link_present` (wrapper link exists even when `Active` is false)

### 3.2 Reconcile (Mutation Rules)

- If `--check`: never mutate; report detection only and print recommended reconcile commands.
- If update was applied in Phase 2:
  - when `skills_link_present=true`, run `sync-skills.sh` for selected scope.
  - when `wrapper_link_present=true` or `wrapper_active=true`, run `install-wrapper.sh --enable` for selected scope (without `--add-path`) to repoint stale wrapper links.
  - when neither is present, report "no existing Codex integration to reconcile" and skip mutation.

Command templates are maintained in [scope-reconcile.md](references/scope-reconcile.md).

### 3.3 Report Reconcile Summary (Before vs After)

Always report:
- selected scope and project root (if any)
- whether skills links were detected and reconciled
- whether wrapper link/active state was detected and reconciled
- `type -a codex` for command-resolution visibility
- rollback commands:

```bash
bash {CWF_PLUGIN_DIR}/scripts/codex/install-wrapper.sh --scope "$selected_scope" ${selected_project_root:+--project-root "$selected_project_root"} --disable
```

For skill-link rollback, direct user to scope backup roots:
- user: `~/.agents/.skill-sync-backup/*`
- project/local: `{projectRoot}/.codex/.skill-sync-backup/*`

Include alias boundary note:
- aliases that call `codex` by command name inherit wrapper behavior
- aliases/functions that call absolute paths bypass wrapper behavior and need manual adjustment

---

## Phase 4: Change Summary (Opt-In)

After update/check, ask whether to summarize diff evidence.

Use AskUserQuestion:

```text
Show change summary for differences between {current_version} and {latest_version}?
```

Options: `Yes, summarize` / `No, skip`

- If user selects `No, skip`, do not run diff commands and continue.
- If user selects `Yes, summarize`, collect and summarize diff evidence with stable roots:

1. Build file-change inventory:

```bash
git --no-pager diff --no-index --name-status "$old_diff_root" "$new_diff_root" || true
```

1. Diff README for user-facing guidance changes:

```bash
git --no-pager diff --no-index \
  "$old_diff_root/README.md" \
  "$new_diff_root/README.md" || true
```

1. Summary procedure:
   - Summarize notable `SKILL.md`/script/manifest changes from name-status diff.
   - Add README delta as "user-facing setup/usage guidance changes".
   - If diff evidence is sparse, state that explicitly and keep the summary minimal.

---

## Phase 5: Lessons Checkpoint

Add `update` to `cwf-state.yaml` current session's `stage_checkpoints` list if lessons were recorded during the update process.

---

## Rules

1. **Resolve scope first**: Always resolve and report active/selected scope before version check or update.
2. **Update marketplace first**: Always run marketplace update before plugin update/install.
3. **Scope-aware apply**: Update/install must target explicit scope via `--scope`.
4. **Auto-apply when newer version exists**: In normal mode (not `--check`), apply update immediately without a separate update-confirmation prompt.
5. **Reconcile Codex links after update**: For existing Codex integrations in selected scope, run reconcile in the same update flow.
6. **No fail-open scope fallback**: If scope detection fails or returns `none`, require explicit scope selection before mutation.
7. **No mutation in check mode**: `cwf:update --check` must not install/update/reconcile; it reports status and suggested commands only.
8. **Change summary is opt-in**: Run change summary only when the user explicitly requests it in Phase 4.
9. **Authoritative latest only**: cache is supporting evidence, not oracle; latest-version verdict must come from authoritative metadata path.
10. **UNVERIFIED is fail-closed**: never present `No update needed` when verdict is `UNVERIFIED`.
11. **Top-level verification required**: release confidence claims require top-level marketplace update + authoritative fetch success.
12. **Changes take effect after restart**: Always remind user to restart Claude Code.
13. **All code fences must have language specifier**: Never use bare fences.

## References

- [README.md](README.md) — File-map entry for this skill directory (not release notes)
- [agent-patterns.md](../../references/agent-patterns.md) — Single pattern
- [references/scope-reconcile.md](references/scope-reconcile.md) — detailed scope resolution and Codex reconcile matrix
- [check-update-latest-consistency.sh](../../scripts/check-update-latest-consistency.sh) — authoritative latest-version consistency checker (`contract`, `top-level`)
- [detect-plugin-scope.sh](../../scripts/detect-plugin-scope.sh) — active Claude plugin scope detection for cwd
- [sync-skills.sh](../../scripts/codex/sync-skills.sh) — Codex scope-aware skill sync
- [install-wrapper.sh](../../scripts/codex/install-wrapper.sh) — Codex scope-aware wrapper management
