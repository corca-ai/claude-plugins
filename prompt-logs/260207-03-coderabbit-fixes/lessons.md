# Lessons: CodeRabbit PR #7 리뷰 적용 + plugin-deploy 개선

## Session Context
- Date: 2026-02-07
- Scope: PR #7 CodeRabbit 코멘트 전체 검토 및 적용, plugin-deploy deprecated 로직 수정, markdownlint 도입
- Plan: prompt-logs/260207-03-coderabbit-fixes/plan.md

## Implementation Learnings

### Markdownlint and nested code fences
- markdownlint cannot parse nested code fences (e.g., ````markdown` block containing ````bash` block inside). This causes false positive MD040 violations on the closing fence of the outer block.
- 2 such false positives remain in `protocol.md` and `04-writing-instructions.md` — structurally unfixable without rewriting the content.
- Disabled MD031, MD032, MD034, MD060 in config to reduce noise from pre-existing style issues not in PR scope.

### Deprecated plugin detection logic
- Original CodeRabbit comment suggested "sync deprecated flag between marketplace.json and plugin.json". But the correct behavior is: if `plugin.json` has `deprecated: true`, the plugin should NOT be in `marketplace.json` at all. Changed to one-directional check: `deprecated + in_marketplace → gap`.

### `set -e` and curl
- With `set -e`, a non-zero `curl` exit code terminates the script before `CURL_EXIT=$?` is reached. The `set +e` / `set -e` guard is the correct pattern for capturing the exit code.

### Bash array iteration under `set -u`
- Iterating `"${arr[@]}"` when `arr` is empty causes "unbound variable" under `set -u`. The guard `if [[ ${#arr[@]} -gt 0 ]]` prevents this.

### Scope beyond plan
- Code fence fixes expanded from 9 planned files to 30+ files across the entire codebase. The sub-agent approach worked well for this — 2 parallel agents handled the broader scope efficiently.
