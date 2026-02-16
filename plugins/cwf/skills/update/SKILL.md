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

Locate the installed plugin.json using Glob:

```text
~/.claude/plugins/cache/corca-plugins/cwf/*/.claude-plugin/plugin.json
```

Read the `version` field. If not found, report that CWF is not installed and suggest installing via marketplace (`claude plugin install cwf@corca-plugins`).

### 1.2 Update Marketplace

Run marketplace update to pull latest metadata:

```bash
claude plugin marketplace update corca-plugins
```

### 1.3 Compare Versions

After marketplace update, check if the latest available version differs from the installed version. Read the source plugin.json from the marketplace cache or re-check after update.

Report the comparison:

```text
Current version: 0.6.0
Latest version:  0.7.0
```

If versions match, report "CWF is up to date" and skip Phase 2.

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

After a successful update (or when showing version diff):

1. Read CHANGELOG.md in the plugin source if it exists
2. Summarize changes between old and new version
3. If no changelog exists, list new/modified skills by comparing directory
   structure

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

- [agent-patterns.md](../../references/agent-patterns.md) — Single pattern
