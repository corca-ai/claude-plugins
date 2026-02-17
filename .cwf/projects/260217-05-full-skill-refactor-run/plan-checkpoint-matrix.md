# Plan Checkpoint Matrix

This matrix follows `.cwf/projects/260217-05-full-skill-refactor-run/clarify-result.md` and enforces fail-fast verification per stage.

## review-plan

Required artifacts:
- `review-security-plan.md`
- `review-ux-dx-plan.md`
- `review-correctness-plan.md`
- `review-architecture-plan.md`
- `review-expert-alpha-plan.md`
- `review-expert-beta-plan.md`
- `review-synthesis-plan.md`

Verification command:
```bash
set -euo pipefail
session_dir="$(bash plugins/cwf/scripts/cwf-live-state.sh get . dir)"
for f in \
  review-security-plan.md \
  review-ux-dx-plan.md \
  review-correctness-plan.md \
  review-architecture-plan.md \
  review-expert-alpha-plan.md \
  review-expert-beta-plan.md
 do
  test -s "$session_dir/$f"
  grep -q '<!-- AGENT_COMPLETE -->' "$session_dir/$f"
done

grep -Eq '^## Review Synthesis' "$session_dir/review-synthesis-plan.md"
grep -Eq '^### Verdict: ' "$session_dir/review-synthesis-plan.md"
grep -Eq '^### Concerns \(must address\)' "$session_dir/review-synthesis-plan.md"
grep -Eq '^### Reviewer Provenance' "$session_dir/review-synthesis-plan.md"
```

Pass condition:
- All six reviewer files exist, are non-empty, include sentinel.
- Synthesis contains mandatory sections.
- External-provider policy is enforced by `check-run-gate-artifacts.sh` using active contract (`provider_gemini_mode`).

## review-code

Required artifacts:
- Six `review-*-code.md` reviewer files with sentinel.
- `review-synthesis-code.md` with `session_log_*` fields.

Verification command:
```bash
set -euo pipefail
session_dir="$(bash plugins/cwf/scripts/cwf-live-state.sh get . dir)"
bash plugins/cwf/scripts/check-run-gate-artifacts.sh \
  --session-dir "$session_dir" \
  --stage review-code \
  --strict \
  --record-lessons
```

Pass condition:
- Gate exits zero.

## refactor

Required artifacts:
- Gate artifacts accepted by `check-run-gate-artifacts.sh --stage refactor`.
- Per-skill completion snapshots:
  - `refactor-skill-clarify.md`
  - `refactor-skill-gather.md`
  - `refactor-skill-handoff.md`
  - `refactor-skill-hitl.md`
  - `refactor-skill-impl.md`
  - `refactor-skill-plan.md`
  - `refactor-skill-refactor.md`
  - `refactor-skill-retro.md`
  - `refactor-skill-review.md`
  - `refactor-skill-run.md`
  - `refactor-skill-setup.md`
  - `refactor-skill-ship.md`
  - `refactor-skill-update.md`

Verification command:
```bash
set -euo pipefail
session_dir="$(bash plugins/cwf/scripts/cwf-live-state.sh get . dir)"
bash plugins/cwf/scripts/check-run-gate-artifacts.sh \
  --session-dir "$session_dir" \
  --stage refactor \
  --strict \
  --record-lessons

for skill in \
  clarify gather handoff hitl impl plan refactor retro review run setup ship update
 do
  test -s "$session_dir/refactor-skill-$skill.md"
done
```

Pass condition:
- Refactor gate exits zero.
- All 13 per-skill snapshot files exist and are non-empty.

## retro

Required artifacts:
- `retro.md` and deep attachments when deep mode is used.

Verification command:
```bash
set -euo pipefail
session_dir="$(bash plugins/cwf/scripts/cwf-live-state.sh get . dir)"
bash plugins/cwf/scripts/check-run-gate-artifacts.sh \
  --session-dir "$session_dir" \
  --stage retro \
  --strict \
  --record-lessons
```

Pass condition:
- Retro gate exits zero.

## ship

Required artifacts:
- `ship.md` with all required metadata fields/patterns.

Verification command:
```bash
set -euo pipefail
session_dir="$(bash plugins/cwf/scripts/cwf-live-state.sh get . dir)"
bash plugins/cwf/scripts/check-run-gate-artifacts.sh \
  --session-dir "$session_dir" \
  --stage ship \
  --strict \
  --record-lessons
```

Pass condition:
- Ship gate exits zero.

## final completion

Required artifacts:
- Session-level implementation closure artifacts.
- Successful rerun of all post-impl stage gates.

Verification command:
```bash
set -euo pipefail
session_dir="$(bash plugins/cwf/scripts/cwf-live-state.sh get . dir)"
bash plugins/cwf/scripts/check-session.sh --impl "$session_dir"
bash plugins/cwf/scripts/check-run-gate-artifacts.sh \
  --session-dir "$session_dir" \
  --stage review-code \
  --stage refactor \
  --stage retro \
  --stage ship \
  --strict \
  --record-lessons
```

Pass condition:
- Both commands exit zero.
