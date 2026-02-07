# Lessons: Markdown Writing Quality Improvement

### markdownlint-cli2 vs markdownlint-cli ignore files

- **Expected**: `.markdownlintignore` would work with `markdownlint-cli2`
- **Actual**: `.markdownlintignore` is only for `markdownlint-cli` (v1). `markdownlint-cli2` uses `.markdownlint-cli2.jsonc` with `"ignores"` array
- **Takeaway**: Always check which tool version the config file format belongs to

When using markdownlint-cli2 → use `.markdownlint-cli2.jsonc` with `"ignores"` property, not `.markdownlintignore`

### Nested code fences in markdown examples

- **Expected**: Inner code fences inside a `` ```markdown `` block would be escaped
- **Actual**: Inner `` ```gherkin `` closes the outer block, leaving the final `` ``` `` as a bare code fence (MD040 violation)
- **Takeaway**: Use 4-backtick fences (```` ```` ````) for outer blocks containing inner code fences, or add `<!-- markdownlint-disable MD040 -->` around the affected section

### PostToolUse hook pattern

- **Expected**: PostToolUse hooks use the same `hookSpecificOutput` JSON format as PreToolUse
- **Actual**: PostToolUse hooks use `{"decision": "block", "reason": "..."}` — simpler top-level format per official docs
- **Takeaway**: PreToolUse and PostToolUse have different JSON output schemas
