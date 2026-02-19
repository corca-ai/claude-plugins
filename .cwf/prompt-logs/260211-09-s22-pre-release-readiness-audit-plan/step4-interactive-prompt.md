# Step 4 Interactive Prompt Package

Use this prompt in the next session to run the onboarding walkthrough **with the user**.

## Prompt to Run

```text
@prompt-logs/260211-09-s22-pre-release-readiness-audit-plan/step4-interactive-prompt.md 실행

You are executing Step 4 (interactive) of S22/S23 release-readiness audit.

Read first:
1) prompt-logs/260211-09-s22-pre-release-readiness-audit-plan/readiness-prestep4.md
2) prompt-logs/260211-09-s22-pre-release-readiness-audit-plan/refactor-evidence.md
3) prompt-logs/260211-09-s22-pre-release-readiness-audit-plan/readme-framing-audit.md
4) prompt-logs/260211-09-s22-pre-release-readiness-audit-plan/discoverability-audit.md
5) README.md
6) README.ko.md
7) AGENTS.md
8) cwf-index.md

Mission:
- Perform a first-install user walkthrough interactively.
- Validate: what to do first, which skill/hook/script exists for what purpose, and expected sequence/outcomes.
- Produce onboarding-scenario.md with command-level evidence and friction points.
- Then produce readiness-report.md with final Go/No-Go.

Interaction contract:
- Ask the user for explicit choices at each branch where multiple plausible onboarding paths exist.
- Do not auto-resolve subjective path choices without user confirmation.
- Keep high-stakes claims evidence-backed with file references.

Walkthrough structure:
A. Entry understanding
- From AGENTS.md and README, derive “first 10 minutes” for a new user.
- Confirm user intent profile: evaluator, new adopter, or maintainer.

B. Install + setup path simulation
- Simulate command sequence from marketplace add/install through setup.
- For each step: expected output, failure mode, recovery path.

C. Capability discoverability
- For each user intent (research, clarify, plan, implement, review, retro, ship):
  - identify expected skill trigger
  - verify docs make that trigger discoverable without tribal knowledge

D. Hook and script observability
- Explain what runs automatically vs manually.
- Verify whether users can discover why a hook fired and how to configure/disable it.

E. Drift and ambiguity checks
- Identify points where docs and runtime inventory diverge.
- Classify each friction as blocker/non-blocker for first-user success.

Required outputs:
1) prompt-logs/260211-09-s22-pre-release-readiness-audit-plan/onboarding-scenario.md
   - scenario timeline
   - command-by-command expectations
   - decision forks + user choices
   - friction log with severity and file references
2) prompt-logs/260211-09-s22-pre-release-readiness-audit-plan/readiness-report.md
   - final Concern 1-4 status table
   - explicit Go/No-Go
   - blockers with required remediation set

Quality gates:
- No final verdict without user-confirmed branch decisions during walkthrough.
- Every blocker must have concrete evidence and target file references.
- Distinguish “doc issue” vs “runtime behavior issue” vs “discoverability issue”.
```

## Operator Notes

- This file is a reusable launch prompt, not the final report.
- It assumes concerns 1-3 are already captured in pre-Step4 artifacts.
- Step 4 is intentionally interactive; do not run it as autonomous-only execution.
