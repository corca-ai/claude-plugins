# Lessons — Live State + Compact Recovery

### Hook output schema asymmetry

- **Expected**: PreCompact hook can inject `additionalContext` like other hooks
- **Actual**: PreCompact has NO `hookSpecificOutput` schema — only SessionStart supports `additionalContext` injection
- **Takeaway**: Always verify hook output schemas against official docs before designing hook-based features. Hook events have asymmetric capabilities not obvious from naming.

### Bootstrapping order for safety mechanisms

- **Expected**: Follow plan phase order (1→2→3→...) sequentially
- **Actual**: User recognized the bootstrapping paradox — implement and activate the compact recovery hook first, before the long implementation session that needs it
- **Takeaway**: When implementing a safety mechanism, activate it before the work it protects. Bootstrapping order > logical phase order.

### Compact recovery needs both structural and conversational context

- **Expected**: cwf-state.yaml `live` section (session_id, phase, task, key_files) is sufficient for compact recovery
- **Actual**: Structural metadata alone lacks "what was just being discussed" — the conversational flow is critical for resuming work naturally
- **Takeaway**: Complement structural metadata with last N turns from prompt-logger session log. Cap at 3 turns / 100 lines to avoid defeating the purpose of compaction.

### Compact does NOT change session ID — verify before speculating

- **Expected**: Auto-compact might create a new session internally
- **Actual**: Session ID is preserved. SessionStart(compact) fires with the same session_id. Official docs confirm this.
- **Takeaway**: When uncertain about Claude Code internals, verify against official docs first. Do not speculate about system behavior and present it as fact.

### Plan document ≠ current state — always check SSOT

- **Expected**: master-plan Session Roadmap reflects current completion status
- **Actual**: S7+ entries lacked `(done)` markers; I treated plan document as state source instead of cwf-state.yaml
- **Takeaway**: cwf-state.yaml is SSOT for session history. When checking project status, read cwf-state.yaml sessions list first. Plan documents are plans, not execution records.

### Shell YAML parser: section boundary + regex quoting

- **Expected**: check-session.sh `while read` loop correctly extracts `dir` for the last session entry (S29)
- **Actual**: Two compounding bugs — (1) loop lacked top-level key break condition (`^[a-z#]`), so it continued past `sessions:` into `live:` section where `dir: ""` overwrote the already-extracted `SESSION_DIR`; (2) `"?${VAR}"?$` regex in bash `[[ =~ ]]` treats `?` as literal (quoted), not as regex quantifier — `\"?` is the correct escape
- **Takeaway**: Hand-rolled YAML parsers need explicit section boundary guards (break on top-level keys). In bash `[[ =~ ]]`, unescaped `"` around regex quantifiers suppresses their special meaning — always use `\"` for literal quote matching in regex patterns. The last entry in a list is the most vulnerable to boundary bugs because there's no subsequent sibling to trigger break.

### Unpublished plugin install path

- **Expected**: `scripts/install.sh` would propagate CWF hooks
- **Actual**: Failed because CWF isn't in marketplace.json (still on feature branch)
- **Takeaway**: For unpublished plugins on feature branches, use direct `.claude/settings.json` edits for bootstrapping. Skip marketplace install paths.
