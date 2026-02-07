---
name: plugin-deploy
description: |
  Automate the post-modification plugin lifecycle: version checks, marketplace sync,
  README updates, local testing, and deployment preparation.
  Triggers: "/plugin-deploy"
allowed-tools:
  - Bash
  - Read
  - Edit
  - Write
  - Glob
  - Grep
  - AskUserQuestion
---

# Plugin Deploy (/plugin-deploy)

Automate the plugin lifecycle after creation or modification. Ensures no step is skipped.

**Language**: Match the user's language.

## Commands

```text
/plugin-deploy <name>              Full lifecycle
/plugin-deploy <name> --new        Force new-plugin flow
/plugin-deploy <name> --dry-run    Check only, no modifications
/plugin-deploy <name> --skip-test  Skip local testing step
```

No args or "help" → print usage and stop.

## Execution Flow

### 1. Consistency Check

```bash
bash {SKILL_DIR}/scripts/check-consistency.sh <name> [--new]
```

Parse JSON output. If `error` field exists → report and stop.

### 2. Analyze & Route

- `detected_new: true` → new plugin: needs marketplace entry, README sections, AI_NATIVE check
- `detected_new: false` → modified plugin: needs version bump check, marketplace sync
- `--dry-run` → display report, list actions, stop

### 3. Fix Gaps

Process each `gaps[]` item:

| Gap | Action |
|-----|--------|
| Version not bumped (`version_match: true`) | AskUserQuestion: patch/minor/major → edit plugin.json |
| marketplace.json mismatch/missing | Edit marketplace.json (add entry or sync version) |
| Deprecated but still in marketplace | Remove entry from marketplace.json; clear local plugin cache |
| README.md missing mention | Add table row + detail section (EN), same for README.ko.md (KO) |
| AI_NATIVE not mentioning (new only) | Evaluate fit → suggest link if appropriate, skip if not |
| No entry point | Error — stop |

For README edits: read the file, find the plugin overview table and the Skills/Hooks section, add following existing format.

### 4. Re-verify

Re-run check-consistency.sh → confirm `gap_count: 0`. Fix iteratively if gaps remain.

### 5. Local Test (unless --skip-test)

By `plugin_type`:

- **hook**: pipe test JSON to hook scripts, run *.test.sh if present
- **skill**: verify SKILL.md frontmatter, check script executability
- **hybrid**: both

### 6. Summary

Report: plugin name, type, version change, files modified, remaining manual steps (commit).

## Usage Message

```text
Plugin Deploy — Automate the plugin lifecycle

Usage:
  /plugin-deploy <name>              Full lifecycle
  /plugin-deploy <name> --new        New plugin flow
  /plugin-deploy <name> --dry-run    Check only
  /plugin-deploy <name> --skip-test  Skip local tests

Checks: plugin.json version, marketplace.json sync, README mentions,
        AI_NATIVE links (new only), skill/hook structure
```
