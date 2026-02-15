# Lessons — S25: Post-S24 Follow-up

### Colon-delimited string encoding is a code smell for positional data

- **Expected**: The existing check-schemas.sh colon-delimited format (`"schema:data:converter"`) was a compact way to associate validation targets
- **Actual**: IFS parsing with colons is fragile and hides the parameter structure — a classic information hiding violation (Parnas)
- **Takeaway**: When data has positional structure (schema, data file, converter), use parallel arrays or positional function args. String encoding saves lines but costs readability and debuggability.

### Hook group reuse simplifies toggling but merges unrelated concerns

- **Expected**: Giving check-links-local.sh its own HOOK_GROUP would allow independent toggling
- **Actual**: Using `HOOK_GROUP="lint_markdown"` means link checking is controlled by the same toggle as markdown linting — appropriate since both are write-quality checks on .md files
- **Takeaway**: Hook group assignment should follow the user's mental model of "what kind of checking is this?" rather than strict functional separation. Users think "turn off markdown quality checks" not "turn off link validation separately from lint validation."

### Verified expert field eliminates a common turn-budget waste pattern

- **Expected**: Expert sub-agents would benefit from verified field to skip web identity verification
- **Actual**: Each expert agent spent 2-4 turns on web verification per invocation. With 15 verified experts and typical 2-expert usage per retro/review, this saves ~4-8 turns per deep analysis
- **Takeaway**: When a sub-agent repeatedly performs the same verification task that produces stable results, cache the verification status at the orchestrator level (cwf-state.yaml) rather than relying on agent-level deduplication.

### Mode-namespaced output files prevent silent data loss

- **Expected**: Review output files would be unique per session
- **Actual**: A session running both review-plan and review-code would overwrite review-security.md (and others) — the second review silently destroys the first review's output
- **Takeaway**: When an operation can run multiple times per session with different modes, namespace the output files by mode. This is the file-level equivalent of Parnas's namespace sharing violation.
