---
name: update
description: "Check and update CWF plugin to keep installed behavior aligned with latest contracts and fixes. Triggers: \"cwf:update\", \"update cwf\", \"check for updates\""
---

# Update

Keep installed CWF behavior aligned with the latest marketplace version and fixes.

**Language**: Write artifacts in English. Communicate with the user in their prompt language.

## Quick Start

```text
cwf:update               # Check + update if newer version exists
cwf:update --check       # Version check only, no install
```

---

## Phase 1: Version Check

### 1.1 Find Current Version

Locate the installed plugin.json using Glob and resolve deterministic baseline variables:

```bash
current_plugin_json="$(ls -1dt ~/.claude/plugins/cache/*/cwf/*/.claude-plugin/plugin.json 2>/dev/null | head -n1)"
[ -n "$current_plugin_json" ] || {
  echo "CWF is not installed."
  exit 1
}
current_plugin_root="$(dirname "$(dirname "$current_plugin_json")")"
current_version="$(jq -r '.version' "$current_plugin_json")"
```

If not found, report that CWF is not installed and suggest installing via marketplace.

### 1.2 Update Marketplace

Run marketplace update to pull latest metadata:

```bash
claude plugin marketplace update corca-plugins
```

### 1.3 Compare Versions

After marketplace update, resolve latest metadata and compare:

```bash
latest_plugin_json="$(ls -1dt ~/.claude/plugins/cache/*/cwf/*/.claude-plugin/plugin.json 2>/dev/null | head -n1)"
latest_plugin_root="$(dirname "$(dirname "$latest_plugin_json")")"
latest_version="$(jq -r '.version' "$latest_plugin_json")"
```

Report the comparison:

```text
Current version: 0.6.0
Latest version:  0.7.0
```

If versions match, report "CWF is up to date" and skip Phase 2.

Persist these variables for Phase 3 diffing: `current_plugin_root`, `latest_plugin_root`, `current_version`, `latest_version`.

---

## Phase 2: Apply Update

Skip this phase if `--check` flag was used or versions already match.

### 2.1 Confirm with User

Use AskUserQuestion:

```text
Update CWF from {current} to {latest}?
```

Options: "Yes, update" / "No, skip"

### 2.2 Install Update

```bash
claude plugin install cwf@corca-plugins
```

### 2.3 Report Success

```text
CWF updated to {version}. Restart Claude Code for changes to take effect.
```

---

## Phase 3: Changelog Summary

After a successful update (or when showing version diff), generate summary deterministically with explicit commands:

1. Build file-change inventory between old/new plugin trees:

```bash
git --no-pager diff --no-index --name-status "$current_plugin_root" "$latest_plugin_root" || true
```

1. Diff the changelog file first (preferred release-note source):

```bash
git --no-pager diff --no-index \
  "$current_plugin_root/CHANGELOG.md" \
  "$latest_plugin_root/CHANGELOG.md" || true
```

1. Diff README for user-facing usage/entrypoint changes, then summarize purpose explicitly:

```bash
git --no-pager diff --no-index \
  "$current_plugin_root/README.md" \
  "$latest_plugin_root/README.md" || true
```

1. Summary procedure:
   - If changelog diff exists, summarize changes between `{current_version}` and `{latest_version}` from that diff first.
   - Add notable `SKILL.md`/script/manifest changes from the name-status diff.
   - Add README delta summary as "user-facing setup/usage guidance changes".
   - If changelog is absent on both sides, state that explicitly and rely on deterministic file diff evidence.

---

## Phase 4: Lessons Checkpoint

Add `update` to `cwf-state.yaml` current session's `stage_checkpoints` list if lessons were recorded during the update process.

---

## Rules

1. **Update marketplace first, then reinstall**: Always run marketplace update
   before plugin install to get the latest version.
2. **Require user confirmation**: Never auto-update without asking.
3. **Changes take effect after restart**: Always remind the user to restart
   Claude Code.
4. **All code fences must have language specifier**: Never use bare fences.

## References

- [README.md](README.md) — File-map entry for this skill directory (not release notes)
- [agent-patterns.md](../../references/agent-patterns.md) — Single pattern
