# Analysis Manifest

## Frozen Range

- START_SHA: 42d2cd9
- END_SHA: 01293b3e2501153789e40699c09777ac6df64624
- RANGE: 42d2cd9..01293b3e2501153789e40699c09777ac6df64624

## Declared Include Buckets

| Bucket | Status | Notes |
|---|---|---|
| prompt-logs/** | collected | 257 files collected |
| prompt-logs/sessions/*.md | collected | 60 files collected |
| prompt-logs/sessions-codex/*.md | collected | 4 files collected |
| cwf-state.yaml | collected | 1 file |
| prompt-logs/260208-03-cwf-v3-master-plan/master-plan.md | collected | 1 file |
| docs/v3-migration-decisions.md | collected | 1 file |
| plugins/cwf/** | collected | 73 files collected |

## Collected Files by Bucket

- Full explicit lists: prompt-logs/260211-05-s18-v3-gap-analysis-execution/analysis-manifest-files.md

## Counts by Category

- Session directories (prompt-logs/YYMMDD-NN-*): 37
- prompt-logs/sessions/*.md: 60
- prompt-logs/sessions-codex/*.md: 4
- plugins/cwf/** touched files: 73

## Missing/Unreadable

- None.

## Phase 0.5 Manifest Completeness Gate

- [x] Every declared include bucket has status collected or explicitly empty.
- [x] Missing/Unreadable is empty (or mitigated per entry).
- [x] RANGE matches scope-freeze.md exactly.

Gate result: PASS
