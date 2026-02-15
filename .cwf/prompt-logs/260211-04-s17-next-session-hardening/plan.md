# Plan: S17 — Harden S16 Gap-Analysis Handoff Protocol

## Context

`prompt-logs/260211-03-s16-v3-gap-analysis-handoff/next-session.review.integrated.md`
reported a `Revise` verdict with critical concerns in scope control,
reproducibility, and traceability.

## Goal

Revise the S16 handoff document so a new autonomous session can execute with:

1. Frozen analysis scope (`END_SHA`)
2. Full-scope manifest coverage
3. Stable cross-artifact traceability
4. Semantic (not existence-only) completion gates
5. Mandatory redaction for utterance extraction
6. Canonical milestone vocabulary aligned to `cwf-state.yaml`

## Scope

- Update S16 handoff document in place
- Record this implementation session in `cwf-state.yaml`
- Create S17 session artifacts (`plan.md`, `lessons.md`, `next-session.md`)
- Run `scripts/check-session.sh --impl`

## Steps

### Step 1: Apply integrated review fixes to S16 handoff

Edit:
- `prompt-logs/260211-03-s16-v3-gap-analysis-handoff/next-session.md`

Implement the integrated fix plan items in priority order:
- Scope freeze step
- Full-scope manifest intake
- Stable gap/backlog traceability
- Semantic completion checks
- Redaction policy
- Milestone mapping alignment

### Step 2: Add missing control gates

In the same handoff document, add:
- Manifest completeness hard gate before Phase 1
- Explicit ownership/bootstrap rules for required artifacts

### Step 3: Create S17 session artifacts

Create:
- `prompt-logs/260211-04-s17-next-session-hardening/plan.md`
- `prompt-logs/260211-04-s17-next-session-hardening/lessons.md`
- `prompt-logs/260211-04-s17-next-session-hardening/next-session.md`

### Step 4: Register session state

Edit:
- `cwf-state.yaml`

Append S17 session entry and update `live` section to reflect completion.

### Step 5: Validate session completeness

Run:
- `scripts/check-session.sh --impl`

Fix any FAIL items until the check passes.

## Success Criteria

### Behavioral (BDD)

```gherkin
Given the revised S16 handoff
When a new session runs Phase -1 and Phase 0
Then it can freeze RANGE once and collect every declared include bucket

Given unresolved and unknown gap candidates exist
When discussion backlog is produced
Then each candidate has a stable GAP-ID linked into backlog items

Given user utterances are extracted
When sensitive tokens or PII-like strings appear
Then they are masked or paraphrased per redaction policy

Given completion checks run
When artifacts exist but traceability/closure is broken
Then completion-check.md reports FAIL instead of pass
```

### Qualitative

- Protocol remains concise enough to execute in one session
- Required fields are concrete and machine-checkable where possible
- Changes preserve analysis-first intent (no implementation work in S17 run)

## Files to Create/Modify

| File | Action | Purpose |
|------|--------|---------|
| prompt-logs/260211-03-s16-v3-gap-analysis-handoff/next-session.md | Edit | Integrate review-driven hardening changes |
| prompt-logs/260211-04-s17-next-session-hardening/plan.md | Create | S17 implementation plan artifact |
| prompt-logs/260211-04-s17-next-session-hardening/lessons.md | Create | S17 lessons artifact |
| prompt-logs/260211-04-s17-next-session-hardening/next-session.md | Create | S17 handoff artifact for next work |
| cwf-state.yaml | Edit | Register S17 and update live state |

## Don't Touch

- `plugins/cwf/**`
- `docs/**` (except references already consumed)
- `README.md`, `README.ko.md`
