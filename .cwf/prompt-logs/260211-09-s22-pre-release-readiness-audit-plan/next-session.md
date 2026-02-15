# Next Session: S25 — Interactive Readthrough First, Then Step 4 Simulation

## Context

S24 completed Phase A remediation for Concern 1-3 and produced implementation evidence.
The next session is interactive-only and must prioritize collaborative reading/discussion
before walkthrough simulation.

## Decision Locks (Confirmed for S25 Start)

1. Concern 1-3 blockers are treated as remediated baseline unless explicitly reopened.
2. Mention-only start must enter interactive mode immediately (not summary-only mode).
3. Execution order is fixed:
   - **Step 1**: chunked, no-skip document readthrough + discussion
   - **Step 2**: first-user scenario simulation
4. Scenario simulation must not start until the user confirms readthrough completion.

## Readthrough Queue (In-Order, No Skip)

1. `prompt-logs/260211-09-s22-pre-release-readiness-audit-plan/no-go-remediation-plan.md`
2. `prompt-logs/260211-09-s22-pre-release-readiness-audit-plan/no-go-remediation-impl.md`
3. `prompt-logs/260211-09-s22-pre-release-readiness-audit-plan/readiness-prestep4.md`
4. `prompt-logs/260211-09-s22-pre-release-readiness-audit-plan/refactor-evidence.md`
5. `prompt-logs/260211-09-s22-pre-release-readiness-audit-plan/skill-coverage-matrix.md`
6. `prompt-logs/260211-09-s22-pre-release-readiness-audit-plan/script-coverage-matrix.md`
7. `prompt-logs/260211-09-s22-pre-release-readiness-audit-plan/readme-framing-audit.md`
8. `prompt-logs/260211-09-s22-pre-release-readiness-audit-plan/discoverability-audit.md`
9. `README.md`
10. `README.ko.md`
11. `AGENTS.md`
12. `cwf-index.md`
13. `prompt-logs/260211-09-s22-pre-release-readiness-audit-plan/step4-interactive-prompt.md`

## Execution Contract (Mention-Only Safe)

If the user mentions only this file, treat it as an instruction to start S25
interactive flow immediately.

### Step 1 — Interactive Readthrough (Mandatory)

- Open files in the exact queue order above.
- Read each file in sequential chunks (recommended 80-160 lines per chunk).
- Do not skip chunks; cover each file to EOF.
- After each chunk:
  - present the chunk to the user,
  - pause for discussion/questions,
  - continue only with user acknowledgement.
- Maintain a coverage log in-session (`file`, `last line shown`, `EOF reached`).
- At each file boundary, confirm with the user before moving to the next file.

### Step 2 — Discussion Consolidation Gate

- Summarize agreed points, open questions, and disputed interpretations from Step 1.
- Ask explicit confirmation: proceed to scenario simulation or continue readthrough discussion.

### Step 3 — Interactive Step 4 Scenario Simulation

- Run first-user walkthrough with explicit user choices at each branch.
- Validate onboarding sequence, skill/hook discoverability, and expected outcomes.
- Classify friction points as doc/runtime/discoverability and blocker/non-blocker.

## Required Outputs

1. `prompt-logs/260211-09-s22-pre-release-readiness-audit-plan/interactive-readthrough-log.md`
   - file-by-file chunk coverage
   - key discussion points
   - unresolved questions
2. `prompt-logs/260211-09-s22-pre-release-readiness-audit-plan/onboarding-scenario.md`
   - scenario timeline
   - command-by-command expectations
   - decision forks + user choices
   - friction log with severity and file references
3. `prompt-logs/260211-09-s22-pre-release-readiness-audit-plan/readiness-report.md`
   - final Concern 1-4 status table
   - explicit Go/No-Go
   - blockers with required remediation set

## Completion Policy

- Final verdict must be evidence-backed and reflect post-remediation state.
- No final Go/No-Go without user-confirmed branch decisions during simulation.
- Register session state and run `scripts/check-session.sh --impl` before close.

## Task

Execute the full interactive readthrough/discussion first, then run Step 4 simulation
and publish readiness outputs.

## Success Criteria

```gherkin
Given S24 remediation outputs and the S25 readthrough queue
When S25 executes chunked in-order readthrough with no skipped chunks
Then interactive-readthrough-log.md records complete file coverage and discussion points

Given user-confirmed readthrough completion
When S25 runs interactive onboarding simulation with explicit branch choices
Then onboarding-scenario.md and readiness-report.md capture final Concern 1-4 status and Go/No-Go rationale
```

## Start Command

```text
@prompt-logs/260211-09-s22-pre-release-readiness-audit-plan/next-session.md 시작합니다
```
