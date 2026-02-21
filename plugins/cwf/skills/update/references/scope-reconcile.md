# Scope Resolution and Codex Reconcile Details

Detailed prompts, parsing patterns, and command matrix for `update` Phase 0 and Phase 3.

## Contents

- [Phase 0 Details](#phase-0-details)
- [Phase 1 Latest Resolution Details](#phase-1-latest-resolution-details)
- [Phase 3 Details](#phase-3-details)

## Phase 0 Details

### Safe Scope Detection (No `eval`)

Run detection while preserving stderr for explicit failure reporting:

```bash
scope_detect_err="$(mktemp "${TMPDIR:-/tmp}/cwf-update-scope.XXXXXX")"
scope_info="$(bash {CWF_PLUGIN_DIR}/scripts/detect-plugin-scope.sh --plugin cwf --cwd "$PWD" 2>"$scope_detect_err" || true)"
```

Parse key-value output without shell evaluation:

```bash
active_scope=""
active_install_path=""
active_project_path=""
installed_scopes=""

while IFS='=' read -r key value; do
  case "$key" in
    active_scope) active_scope="$value" ;;
    active_install_path) active_install_path="$value" ;;
    active_project_path) active_project_path="$value" ;;
    installed_scopes) installed_scopes="$value" ;;
  esac
done <<EOF_SCOPE
$scope_info
EOF_SCOPE
```

Normalization:

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

If `scope_detection_failed=true`, print diagnostics and ask for explicit scope:

```text
Scope detection failed or returned none. Which scope should cwf:update target?
```

Options:
- `User scope`
- `Project scope`
- `Local scope`
- `Stop update`

If project/local is selected and root is unresolved, ask for project root path.

### Multi-Scope Confirmation

When multiple scopes are installed, ask target scope:

```text
Multiple CWF scopes are installed. Which scope should cwf:update target?
```

Options:
- `Active scope (recommended)`
- `User scope`
- `Project scope`
- `Local scope`

If chosen scope is not installed, stop and report valid installed scopes.

### Non-User -> User Escalation Guard

If detected active scope is `project`/`local` and selected target is `user`, require second confirmation:

```text
Active scope is {active_scope}, but update target is user-global. Continue with user scope update and user-global Codex reconciliation?
```

If declined, return to scope selection.

## Phase 1 Latest Resolution Details

After marketplace metadata refresh, resolve latest verdict through authoritative checker first:

```bash
consistency_json="$(
  bash {CWF_PLUGIN_DIR}/scripts/check-update-latest-consistency.sh \
    --mode top-level \
    --scope "$selected_scope" \
    --json
)"
verdict="$(printf '%s' "$consistency_json" | jq -r '.verdict // "UNVERIFIED"')"
```

Fail-closed behavior:
- `verdict=UNVERIFIED`: stop update flow immediately (no success-style no-update output)
- `verdict=UP_TO_DATE|OUTDATED`: continue normal flow using checker-provided `current_version` and `authoritative_latest`

Cache snapshot remains supporting evidence only. Checker internally resolves latest cached `plugin.json` using context-aware cache roots and validates it against authoritative marketplace metadata:

```bash
extra_cache_roots_raw="${CWF_UPDATE_CACHE_ROOTS:-}"
IFS=':' read -r -a extra_cache_roots <<< "$extra_cache_roots_raw"
cache_roots=(
  "${CLAUDE_HOME:-$HOME/.claude}/plugins/cache"
  "$HOME/.claude/plugins/cache"
  "${XDG_CACHE_HOME:-$HOME/.cache}/claude/plugins/cache"
  "/usr/local/share/claude/plugins/cache"
)
for extra_root in "${extra_cache_roots[@]}"; do
  [ -n "$extra_root" ] || continue
  cache_roots+=("$extra_root")
done
latest_plugin_json=""
for cache_root in "${cache_roots[@]}"; do
  [ -d "$cache_root" ] || continue
  candidate="$(ls -1dt "$cache_root"/*/cwf/*/.claude-plugin/plugin.json 2>/dev/null | head -n1)"
  if [ -n "$candidate" ]; then
    latest_plugin_json="$candidate"
    break
  fi
done
```

If authoritative fetch or top-level marketplace update is unavailable, checker returns `UNVERIFIED` and the update flow must stop.

## Phase 3 Details

### Detect Existing Integration Signals

```bash
skills_link_present="false"
wrapper_active="false"
wrapper_link_present="false"

if [ "$selected_scope" = "user" ]; then
  [ -L "${AGENTS_HOME:-$HOME/.agents}/skills/setup" ] && skills_link_present="true"
  wrapper_status="$(bash {CWF_PLUGIN_DIR}/scripts/codex/install-wrapper.sh --scope user --status)"
else
  [ -L "$selected_project_root/.codex/skills/setup" ] && skills_link_present="true"
  wrapper_status="$(bash {CWF_PLUGIN_DIR}/scripts/codex/install-wrapper.sh --scope "$selected_scope" --project-root "$selected_project_root" --status)"
fi

printf '%s\n' "$wrapper_status"
printf '%s' "$wrapper_status" | grep -q 'Active        : true' && wrapper_active="true"

wrapper_link_path="$(printf '%s\n' "$wrapper_status" | awk -F': ' '/^Wrapper link/ {print $2}')"
if [ -n "$wrapper_link_path" ] && [ -L "$wrapper_link_path" ]; then
  wrapper_link_present="true"
fi
```

### Reconcile Mutation Rules

- In `--check`: never mutate; only report detection and recommended commands.
- After update apply:
  - if `skills_link_present=true`, run `sync-skills.sh`
  - if `wrapper_link_present=true` or `wrapper_active=true`, run `install-wrapper.sh --enable` (without `--add-path`) and re-check status
  - if both false, report no prior Codex integration and skip mutation

Commands:

```bash
# skills reconcile
bash {CWF_PLUGIN_DIR}/scripts/codex/sync-skills.sh --scope "$selected_scope" ${selected_project_root:+--project-root "$selected_project_root"}

# wrapper reconcile
bash {CWF_PLUGIN_DIR}/scripts/codex/install-wrapper.sh --scope "$selected_scope" ${selected_project_root:+--project-root "$selected_project_root"} --enable
bash {CWF_PLUGIN_DIR}/scripts/codex/install-wrapper.sh --scope "$selected_scope" ${selected_project_root:+--project-root "$selected_project_root"} --status
type -a codex
```

### Reporting and Boundary Notes

Always report:
- selected scope + project root
- skills link detected/reconciled
- wrapper link detected/active/reconciled
- rollback command (`install-wrapper.sh --disable`)
- skill rollback backup roots by scope

Boundary note:
- Aliases that invoke `codex` by command name inherit wrapper behavior.
- Aliases/functions that invoke absolute binary paths bypass wrapper behavior and must be adjusted manually.
