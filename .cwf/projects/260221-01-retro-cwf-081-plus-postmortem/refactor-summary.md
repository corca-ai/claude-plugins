# Refactor Quick Scan Summary

## Refactor Summary
- Mode: `cwf:refactor (Quick Scan)`
- Scan command: `bash plugins/cwf/skills/refactor/scripts/quick-scan.sh /home/hwidong/codes/claude-plugins`
- Source JSON: `.cwf/projects/260221-01-retro-cwf-081-plus-postmortem/refactor-quick-scan.json`
- Total skills: 13
- Flagged skills: 4
- Warnings: 6
- Errors: 0

| Plugin | Skill | Words | Lines | Flags |
|---|---|---:|---:|---|
| cwf | clarify | 2080 | 456 | - |
| cwf | gather | 1981 | 358 | - |
| cwf | handoff | 2110 | 358 | - |
| cwf | hitl | 1407 | 204 | - |
| cwf | impl | 2690 | 465 | - |
| cwf | plan | 1596 | 292 | - |
| cwf | refactor | 1572 | 331 | - |
| cwf | retro | 3033 | 498 | word_count_warning (3033w > 3000) |
| cwf | review | 3083 | 523 | word_count_warning (3083w > 3000); line_count_warning (523L > 500) |
| cwf | run | 2911 | 552 | line_count_warning (552L > 500) |
| cwf | setup | 2833 | 532 | line_count_warning (532L > 500); unreferenced: scripts/migrate-env-vars.sh |
| cwf | ship | 1941 | 364 | - |
| cwf | update | 1395 | 316 | - |

## Flagged Skills
### cwf/retro
- word_count_warning (3033w > 3000)

### cwf/review
- word_count_warning (3083w > 3000)
- line_count_warning (523L > 500)

### cwf/run
- line_count_warning (552L > 500)

### cwf/setup
- line_count_warning (532L > 500)
- unreferenced: scripts/migrate-env-vars.sh

Run `cwf:refactor --skill <name>` for deep review on flagged skills.
