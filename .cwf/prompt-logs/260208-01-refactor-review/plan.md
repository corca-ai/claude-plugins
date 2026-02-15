# Comprehensive Codebase Improvement Plan

## Context

Agent team review completed 2026-02-08:
- **refactor-agent**: Code/skill quality review (4 critical, 12 important, 8 nice-to-have)
- **docs-agent**: Documentation consistency review (2 critical, 8 important, 5 nice-to-have)
- **research-agent**: Linting/static analysis tool research

---

## Phase 1: Critical Bug Fixes

### 1.1 JSON Escaping Bugs
- [ ] Fix `refactor/quick-scan.sh` lines 155, 167 — `unreferenced_json` and `large_refs` arrays don't escape quotes (apply same pattern as `flags_json` line 147)
- [ ] Fix `plugin-deploy/check-consistency.sh` `json_str()` — add double-quote escaping
- [ ] Audit all other scripts that build JSON via string concatenation — consider migrating to `jq` for JSON construction

### 1.2 Shell Safety Issues
- [ ] Quote `kill $(cat "$TIMER_FILE")` → `kill "$(cat "$TIMER_FILE")"` in:
  - `attention-hook/cancel-timer.sh:34`
  - `attention-hook/start-timer.sh:37`
  - `attention-hook/track-user-input.sh:34`
- [ ] Add stale lock cleanup/timeout to `attention-hook/track-user-input.sh` mkdir lock
- [ ] Replace unsafe `eval "$(grep ...)"` in gather-context scripts (`search.sh:37`, `code-search.sh:29`, `extract.sh:36`) with safer sourcing pattern

### 1.3 Documentation Bugs
- [ ] Fix `prompt-logger/README.md` line 77 — wrong install command (`claude mcp add-plugin` → `claude plugin install prompt-logger@corca-plugins`)
- [ ] Fix line 83 — add `@corca-plugins` suffix

---

## Phase 2: Convention Alignment

### 2.1 Script Headers (systemic — all hook scripts)
- [ ] Add `set -euo pipefail` to 11 hook scripts missing it (all except markdown-guard and prompt-logger)
- [ ] Change `#!/bin/bash` → `#!/usr/bin/env bash` in 11 scripts
- Target scripts: all attention-hook scripts (8), gather-context redirect, plan-and-lessons enter-plan-mode, smart-read

### 2.2 Bare Code Fence Cleanup (MD040)
- [ ] Run `npx markdownlint-cli2 "**/*.md"` to get full list
- [ ] Fix ~25 active files with bare code fences (add language specifiers)
- [ ] Key offenders: README.md (9), README.ko.md (9), docs/ (17), SKILL.md files (~36), plugin READMEs (~8)
- [ ] Decide policy for `references/anthropic-skills-guide/` — fix or exclude via `.markdownlint-cli2.jsonc`

### 2.3 Metadata Sync
- [ ] Sync `marketplace.json` descriptions with `plugin.json` for: attention-hook, clarify, gather-context
- [ ] Update `docs/project-context.md` version numbers: refactor v1.1.0→v1.1.1, gather-context v2.0.0→v2.0.1
- [ ] Add `__pycache__/` to `.gitignore`

### 2.4 Environment Variable Naming
- [ ] Evaluate migrating `attention-hook` from `CLAUDE_ATTENTION_*` to `CLAUDE_CORCA_ATTENTION_*`
- [ ] Evaluate migrating `gather-context` from bare `SLACK_BOT_TOKEN`/`TAVILY_API_KEY`/`EXA_API_KEY` to `CLAUDE_CORCA_*` prefix
- **Decision needed**: Breaking change for users — may need migration guide or backward-compat shim

---

## Phase 3: New Tooling — shell-guard Plugin

### 3.1 ShellCheck Integration (HIGH PRIORITY)
- [ ] Create `plugins/shell-guard/` following markdown-guard pattern
- [ ] Implement `check-shell.sh` — PostToolUse hook on Write|Edit for `.sh` files
- [ ] Use `shellcheck -f json` for structured output
- [ ] Install shellcheck: `apt install shellcheck` or `brew install shellcheck`

### 3.2 JSON Validation (MEDIUM PRIORITY)
- [ ] Add `check-json.sh` to shell-guard — PostToolUse hook for `.json` files
- [ ] Use `jq . file.json > /dev/null` (jq already installed)

### 3.3 shfmt (LOWER PRIORITY)
- [ ] Evaluate adding `format-shell.sh` — auto-format on write
- [ ] Decide: auto-fix vs report-only mode

### Architecture Decision
- **Chosen**: Separate `shell-guard` plugin (not merging with markdown-guard)
- **Reason**: Avoid breaking existing markdown-guard users; each plugin has clear scope

---

## Phase 4: Code Quality Improvements

### 4.1 Duplicate Logic
- [ ] Deduplicate prompt-logger auto-commit logic (lines 99-109 and 385-394) into shared function
- [ ] Add TOC to `refactor/references/review-criteria.md` (>100 lines)

### 4.2 Cross-Platform Concerns
- [ ] Replace `grep -P` (PCRE) in `update-all.sh:25` and `check-consistency.sh:44` with portable alternatives
- [ ] Review `date +%s` usage in attention-hook for macOS compatibility

### 4.3 Documentation Polish
- [ ] Add note to clarify SKILL.md about WebSearch redirect when gather-context is installed
- [ ] Add "Explore agent read doesn't satisfy Edit pre-read" caveat to project-context.md
- [ ] Remove CHANGELOG reference from cheatsheet (or decide to adopt CHANGELOGs)
- [ ] Remove unused `assets/g-export-sheet-md-example.png`

---

## Priority Summary

| Phase | Items | Severity | Scope |
|-------|-------|----------|-------|
| Phase 1 | 8 items | 🔴 Critical | Bug fixes |
| Phase 2 | 6 groups | 🟡 Important | Convention alignment |
| Phase 3 | 3 tools | 🟡 Important | New tooling |
| Phase 4 | 6 items | 🟢 Nice-to-have | Polish |

---

## Notes

- Phase 2.4 (env var naming) needs user decision on breaking changes
- Phase 3 (shell-guard) is a standalone new plugin — can be done independently
- Bare code fence cleanup (Phase 2.2) is high volume but mechanical — good candidate for batch fix
- Python `__pycache__` in git (Phase 2.3) should be cleaned up with `git rm --cached`
