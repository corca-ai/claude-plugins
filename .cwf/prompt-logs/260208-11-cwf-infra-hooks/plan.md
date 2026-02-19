# S6a: Migrate Simple Infra Hooks into CWF Plugin

## Status: Done

## Scope

Migrate 3 hooks from source plugins into CWF stubs:

| # | Hook | Source Plugin | Lines |
|---|------|-------------|-------|
| 1 | check-markdown | markdown-guard | 72 |
| 2 | smart-read | smart-read | 95 |
| 3 | log-turn | prompt-logger | 486 |

## Steps

- [x] Step 1: Migrate check-markdown.sh (gate + source lines 10-72)
- [x] Step 2: Migrate smart-read.sh (gate + source lines 10-95)
- [x] Step 3: Migrate log-turn.sh (gate + source lines 9-486)
- [x] Step 4: Verify hooks.json (read-only check) — all matchers/async flags match
- [x] Step 5: Test gate disable/enable + hook behavior — 8/8 tests pass
- [x] Step 6: Session artifacts (plan.md, lessons.md)

## Verification

- All 3 diffs (CWF vs source) are byte-identical for the logic portion
- Gate disable: all 3 hooks exit 0 when HOOK_{GROUP}_ENABLED=false
- Gate enable (default): all 3 hooks execute normally
- hooks.json: matchers and async flags match source plugins exactly
