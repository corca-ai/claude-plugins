# Lessons — Live State + Compact Recovery

### Hook output schema asymmetry

- **Expected**: PreCompact hook can inject `additionalContext` like other hooks
- **Actual**: PreCompact has NO `hookSpecificOutput` schema — only SessionStart supports `additionalContext` injection
- **Takeaway**: Always verify hook output schemas against official docs before designing hook-based features. Hook events have asymmetric capabilities not obvious from naming.

### Bootstrapping order for safety mechanisms

- **Expected**: Follow plan phase order (1→2→3→...) sequentially
- **Actual**: User recognized the bootstrapping paradox — implement and activate the compact recovery hook first, before the long implementation session that needs it
- **Takeaway**: When implementing a safety mechanism, activate it before the work it protects. Bootstrapping order > logical phase order.

### Unpublished plugin install path

- **Expected**: `scripts/install.sh` would propagate CWF hooks
- **Actual**: Failed because CWF isn't in marketplace.json (still on feature branch)
- **Takeaway**: For unpublished plugins on feature branches, use direct `.claude/settings.json` edits for bootstrapping. Skip marketplace install paths.
