---
name: plugin-deploy
description: Automate the post-modification plugin lifecycle (version checks, marketplace sync, README updates, local testing, deployment prep). Trigger: "/plugin-deploy".
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

For detailed edge cases and README formatting examples, see [checklist](references/checklist.md).

**Language**: Match the user's language.

## Commands

```text
/plugin-deploy <name>              Full lifecycle
/plugin-deploy <name> --new        Force new-plugin flow
/plugin-deploy <name> --dry-run    Check only, no modifications
/plugin-deploy <name> --skip-test  Skip local testing step
/plugin-deploy <name> --skip-codex-sync  Skip Codex user-scope sync (cwf only)
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
- `name == "cwf"` → include Codex user-scope sync step via [plugins/cwf/scripts/codex/sync-skills.sh](../../../plugins/cwf/scripts/codex/sync-skills.sh)
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

### 5. Codex User-Scope Sync (cwf only, unless --skip-codex-sync)

For `cwf` plugin deployments, run:

```bash
bash {SKILL_DIR}/../../../plugins/cwf/scripts/codex/sync-skills.sh --cleanup-legacy
```

This includes post-sync link validation ([plugins/cwf/scripts/codex/verify-skill-links.sh](../../../plugins/cwf/scripts/codex/verify-skill-links.sh)). If sync or validation fails, report exact stderr and stop (do not continue with stale links).

### 6. Local Test (unless --skip-test)

By `plugin_type`:

- **hook**: pipe test JSON to hook scripts, run *.test.sh if present
- **skill**: verify SKILL.md frontmatter, check script executability
- **hybrid**: both

### 7. Summary

Report: plugin name, type, version change, files modified, commit status, and created commit hash(es) when committed.

## Rules

1. **All code fences must have language specifier**: Never use bare fences.
2. **Consistency check is the source of truth**: Always run `check-consistency.sh` before and after changes.
3. **Missing dependency interaction**: When prerequisites are missing, ask to install/configure now; do not only report unavailability.
4. **Commit policy (autonomy-first)**: Commit by default after successful re-verification, using meaningful units and selective staging only. Ask the user only when commit boundaries are ambiguous or unrelated worktree changes make safe selective staging unclear.

## References

- [checklist.md](references/checklist.md) — Detailed edge cases and README formatting examples

## Usage Message

```text
Plugin Deploy — Automate the plugin lifecycle

Usage:
  /plugin-deploy <name>              Full lifecycle
  /plugin-deploy <name> --new        New plugin flow
  /plugin-deploy <name> --dry-run    Check only
  /plugin-deploy <name> --skip-test  Skip local tests
  /plugin-deploy <name> --skip-codex-sync  Skip Codex sync (cwf only)

Checks: plugin.json version, marketplace.json sync, README mentions,
        AI_NATIVE links (new only), skill/hook structure,
        Codex user-scope links for cwf
```
