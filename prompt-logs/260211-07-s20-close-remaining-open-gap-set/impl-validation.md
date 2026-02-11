# Implementation Validation (S20)

## 1) Script Syntax
- PASS: `bash -n scripts/check-session.sh`

## 2) Semantic Check Positive (Real Session)
- PASS: `scripts/check-session.sh --semantic-gap S18`
- Evidence: SC-S1/SC-S2/SC-S3 all PASS on S18 artifacts.

## 3) Semantic Check Negative (Non-Semantic Session)
- PASS: `scripts/check-session.sh --semantic-gap S19` returns explicit precondition FAIL.
- Evidence: missing required files (`gap-candidates.md`, `discussion-backlog.md`, `consistency-check.md`).

## 4) Semantic Relation Failure Fixture
- PASS: synthetic fixture run returns relation-level failures with explicit causes.
- Failure messages verified:
  - `SC-S1 GAP(open)->BL linkage broken`
  - `SC-S2 CW rows linked to non-existent GAP ids`

## 5) Stage-Tier Policy Encoding
- PASS: context protocol now specifies critical hard gate / non-critical soft gate + bounded retry.
- PASS: plan/review/retro skill contracts reference the policy and gate visibility.

## 6) Session Checks
- PASS: `scripts/check-session.sh --impl S20`
- PASS: `scripts/check-session.sh --live`
