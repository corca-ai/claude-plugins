# S5b Lessons

## Implementation Notes

- **SKILL.md stays under 500 lines** (351 lines after adding all 4 phases) by delegating external reviewer details to `references/external-review.md` (221 lines). This follows the cheatsheet's "move details to references/" pattern.
- **Phase structure simplification**: The plan's 7 steps collapsed into a cleaner 4-phase flow in SKILL.md (Gather → Launch All → Collect → Synthesize) rather than having separate steps for each concern. This is more natural for the executing agent.
- **Provenance format unified**: Adding `duration_ms` and `command` to internal reviewer provenance (even as `—`) creates a consistent format across all 4 reviewers, simplifying synthesis template logic.
- **Bash command wrapping for external CLIs**: Using `START_MS/END_MS` pattern with meta files (`codex-meta.txt`) lets us capture both exit codes and timing without complex parsing. The `timeout 280` inside `Bash(timeout=300000)` gives a buffer for the outer timeout.
- **No code touched** in Phase 1 (gather target), internal reviewer prompts (Security/UX/DX role text), or verdict algorithm logic — as specified in the plan's "Do NOT touch" section.
- **Rule numbering**: Added Rule 7 (graceful degradation) without renumbering existing rules, maintaining backward compatibility with any references to Rule 1-6.

## Review-Driven Fixes

First real `/review` run with 4 reviewers uncovered 12 issues. Key learnings:

- **`$(cat ...)` in double-quoted Bash = shell injection**: Review targets (git diffs) can contain `$()` or backticks. Always use stdin redirection (`< file`) for external CLIs, never `-p "$(cat ...)"`.
- **`codex review` vs `codex exec`**: `codex review` does its own diff analysis and may ignore stdin prompt. Use `codex exec` for all modes to guarantee structured prompt delivery and output format compliance.
- **`codex exec -o` conflicts with stdout redirect**: The `-o` flag writes to a file while the Bash wrapper redirects stdout. Pick one mechanism — stdout redirect is simpler and consistent with the wrapper pattern.
- **Single quotes inside double-quoted Bash wrapper**: Config values like `model_reasoning_effort='high'` must use single quotes to avoid breaking the outer `command="..."` string.
- **`--approval-mode plan` requires experimental flag in Gemini CLI**: Not a stable feature. Removed from template.
- **`command -v npx` ≠ Gemini available**: npx exists on most Node.js installs. Renamed signal to `NPX_FOUND` (not `NPX_OK`) and documented that runtime failures are expected and handled.
- **exit=0 + empty output is a real failure mode**: CLIs can exit 0 with no output (auth redirect, silent config errors). Must be treated as failure.
- **Provenance schema consistency matters**: Having different field sets across variants (internal vs external-real vs fallback vs failed) complicates synthesis. Unified to same fields with `—` for inapplicable values.
- **FAILED provenance is intermediate, not final**: When a CLI fails and fallback runs, the final Provenance table shows the fallback's record. FAILED is only useful for the Confidence Note explanation.
- **Temp dir cleanup is easy to forget**: Added explicit `rm -rf {tmp_dir}` step after synthesis. Diffs in `/tmp/` can contain sensitive code.
