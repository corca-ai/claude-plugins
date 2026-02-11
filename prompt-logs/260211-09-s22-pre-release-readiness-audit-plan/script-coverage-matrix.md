# S23 Script Coverage Matrix

Date: 2026-02-11
Scope paths audited:
- `plugins/cwf/hooks/scripts/*`
- `plugins/cwf/skills/*/scripts/*`
- `scripts/*`
- `scripts/codex/*`

## Deterministic Check Summary

- Files audited: **39**
- Syntax checks passed: **39/39**
- Syntax check failures: **0**

Deterministic commands used:

```bash
bash -n <*.sh>
node --check <*.mjs|*.js>
python3 -m py_compile <*.py>
perl -c <*.pl>
```

## File Matrix

| File | Type | Syntax | Strict Mode (`set -euo`) | Hook Gate |
|---|---|---|---|---|
| `plugins/cwf/hooks/scripts/attention.sh` | bash | PASS | yes | yes |
| `plugins/cwf/hooks/scripts/cancel-timer.sh` | bash | PASS | yes | yes |
| `plugins/cwf/hooks/scripts/check-markdown.sh` | bash | PASS | yes | yes |
| `plugins/cwf/hooks/scripts/check-shell.sh` | bash | PASS | yes | yes |
| `plugins/cwf/hooks/scripts/compact-context.sh` | bash | PASS | yes | yes |
| `plugins/cwf/hooks/scripts/cwf-hook-gate.sh` | bash | PASS | no | yes |
| `plugins/cwf/hooks/scripts/env-loader.sh` | bash | PASS | no | no |
| `plugins/cwf/hooks/scripts/heartbeat.sh` | bash | PASS | yes | yes |
| `plugins/cwf/hooks/scripts/log-turn.sh` | bash | PASS | yes | yes |
| `plugins/cwf/hooks/scripts/parse-transcript.sh` | bash | PASS | yes | no |
| `plugins/cwf/hooks/scripts/redirect-websearch.sh` | bash | PASS | yes | yes |
| `plugins/cwf/hooks/scripts/slack-send.sh` | bash | PASS | no | no |
| `plugins/cwf/hooks/scripts/smart-read.sh` | bash | PASS | yes | yes |
| `plugins/cwf/hooks/scripts/start-timer.sh` | bash | PASS | yes | yes |
| `plugins/cwf/hooks/scripts/text-format.sh` | bash | PASS | no | no |
| `plugins/cwf/hooks/scripts/track-user-input.sh` | bash | PASS | yes | yes |
| `plugins/cwf/skills/gather/scripts/code-search.sh` | bash | PASS | yes | no |
| `plugins/cwf/skills/gather/scripts/csv-to-toon.sh` | bash | PASS | no | no |
| `plugins/cwf/skills/gather/scripts/extract.sh` | bash | PASS | yes | no |
| `plugins/cwf/skills/gather/scripts/g-export.sh` | bash | PASS | no | no |
| `plugins/cwf/skills/gather/scripts/notion-to-md.py` | python | PASS | N/A | N/A |
| `plugins/cwf/skills/gather/scripts/search.sh` | bash | PASS | yes | no |
| `plugins/cwf/skills/gather/scripts/slack-api.mjs` | node | PASS | N/A | N/A |
| `plugins/cwf/skills/gather/scripts/slack-to-md.sh` | bash | PASS | no | no |
| `plugins/cwf/skills/refactor/scripts/quick-scan.sh` | bash | PASS | yes | no |
| `plugins/cwf/skills/refactor/scripts/tidy-target-commits.sh` | bash | PASS | yes | no |
| `scripts/check-session.sh` | bash | PASS | yes | no |
| `scripts/codex/codex-with-log.sh` | bash | PASS | yes | no |
| `scripts/codex/install-wrapper.sh` | bash | PASS | yes | no |
| `scripts/codex/redact-jsonl.sh` | bash | PASS | yes | no |
| `scripts/codex/redact-sensitive.pl` | perl | PASS | N/A | N/A |
| `scripts/codex/redact-session-logs.sh` | bash | PASS | yes | no |
| `scripts/codex/sync-session-logs.sh` | bash | PASS | yes | no |
| `scripts/codex/sync-skills.sh` | bash | PASS | yes | no |
| `scripts/codex/verify-skill-links.sh` | bash | PASS | yes | no |
| `scripts/install.sh` | bash | PASS | yes | no |
| `scripts/next-prompt-dir.sh` | bash | PASS | yes | no |
| `scripts/provenance-check.sh` | bash | PASS | yes | yes |
| `scripts/update-all.sh` | bash | PASS | yes | no |

## Manual Risk Findings

| Severity | Finding | Evidence |
|---|---|---|
| WARN | `eval` remains in runtime paths; usage is constrained but should stay under regression monitoring. | `plugins/cwf/hooks/scripts/attention.sh:65`, `plugins/cwf/hooks/scripts/heartbeat.sh:81`, `scripts/check-session.sh:79` |
| INFO | Non-executable helper scripts are intentionally sourced libraries. | `plugins/cwf/hooks/scripts/env-loader.sh`, `plugins/cwf/hooks/scripts/text-format.sh` |
| WARN | Gather script inventory includes an unreferenced executable (`csv-to-toon.sh`), increasing maintenance surface without documented route. | `plugins/cwf/skills/gather/scripts/csv-to-toon.sh`, quick-scan flag in `refactor-evidence.md` |

## Verdict

**PASS with advisories**: no deterministic syntax/runtime-parser failures; maintainability/security hygiene items remain.
