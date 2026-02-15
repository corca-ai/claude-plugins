# S5a Plan: cwf:review Internal Reviewers

## Goal

CWF v3의 `/review` 스킬 첫 구현. Security + UX/DX 내부 리뷰어를 Task tool로
병렬 실행하고 narrative verdict로 합성.

## Steps

- ✅ Step 1: Session setup + master-plan.md update (S2/S3/S4 done, S4.5/S4.6 rows)
- ✅ Step 2: Create `references/prompts.md` — 6 variants (2 reviewers × 3 modes)
- ✅ Step 3: Create `SKILL.md` — mode routing, target detection, reviewer launch, synthesis
- ✅ Step 4: Test — self-review with parallel sub-agents, fix concerns from review
- ✅ Step 5: Session wrap-up — lessons.md, plan.md, next-session.md

## Key Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Default mode | `--mode code` | Most common use case |
| Base branch | Dynamic detection | Hardcoded `marketplace-v3` would break after merge |
| Write tool | Included in allowed-tools | User may request file output |
| Severity levels | Defined in prompts.md | Without definitions, reviewers classified inconsistently |
