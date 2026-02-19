# Plan — S4.5: /ship Skill Improvement

## Context

The `/ship` skill (created in S3) produces low-quality Issue/PR output compared to
moonlight's `document-pr-process`. Identified problems from S4 real usage:

1. Issue/PR body written in English — should be Korean (human-facing docs)
2. PR lacks decision rationale ("why this approach?")
3. PR verification steps too brief for reviewers
4. No autonomous merge — blocked by `reviewDecision = APPROVED` in solo projects
5. Self-approve impossible (GitHub limitation)

## Files to Modify

1. `.claude/skills/ship/references/pr-template.md` — restructure
2. `.claude/skills/ship/references/issue-template.md` — restructure
3. `.claude/skills/ship/SKILL.md` — language rule, merge logic, decision extraction

## Changes

### 1. PR Template Redesign (`references/pr-template.md`)

Replace current Summary/Changes/Lessons/CDM/Checklist with reviewer-focused structure
(modeled on moonlight):

```markdown
{ISSUE_LINK}

## 목적

{PURPOSE}

## 주요 결정사항

| 항목 | 결정 | 근거 |
|------|------|------|
{DECISIONS}

## 검증 방법

{VERIFICATION}

## 인간 판단 필요 사항

{HUMAN_JUDGMENT}

## 머지 후 영향

**시스템**: {SYSTEM_IMPACT}
**향후 개발**: {FUTURE_IMPACT}

<details>
<summary>세션 아티팩트</summary>

### Changes

{GIT_DIFF_STAT}

### Lessons Learned

{LESSONS}

### CDM (Critical Decision Moments)

{CDM}

</details>

## Review Checklist

- [ ] Code changes match PR description
- [ ] No unintended file changes
{CONDITIONAL_ITEMS}
```

Key design decisions:
- **`{PURPOSE}`**: 1-2 sentence summary of why this PR exists (from commits + plan.md)
- **`{DECISIONS}`**: Synthesized from lessons.md, retro.md CDM, plan.md — not raw dump
- **`{VERIFICATION}`**: Concrete steps a reviewer can follow
- **`{HUMAN_JUDGMENT}`**: Agent self-assesses; "없음 — 자율 머지 가능" when no human input needed
- Raw artifacts (diff stat, lessons, CDM) preserved in collapsible `<details>` for reference
- Remove `{SUMMARY}` (commit list) — `{PURPOSE}` replaces it

### 2. Issue Template Redesign (`references/issue-template.md`)

Replace Purpose/Success Criteria/Scope/Session Info with moonlight-style:

```markdown
## 배경

{BACKGROUND}

## 문제

{PROBLEM}

## 목표

{GOAL}

## 작업 범위

{SCOPE}

## 세션 정보

- **Branch**: `{BRANCH}`
- **Base**: `{BASE}`
- **Plan**: `{PLAN_LINK}`
```

- `{BACKGROUND}` — from plan.md context/background or master-plan
- `{PROBLEM}` — specific problem statement
- `{GOAL}` — success criteria
- `{SCOPE}` — files/areas affected
- Session info kept for traceability

### 3. SKILL.md — Language Rule (line 17)

Change:
```
**Language**: Match the user's language.
```
To:
```
**Language**: Issue/PR body는 한글로 작성. 단, code blocks, commit hashes,
file paths, branch names, CLI commands는 원문 유지.
Conversation with the user follows the user's language.
```

### 4. SKILL.md — `/ship merge` Autonomous Merge Logic (lines 153-191)

Replace the current "all must be true" readiness check with conditional logic:

```
1. gh pr view --json number,state,reviewDecision,statusCheckRollup,mergeable,body
2. Parse body for "## 인간 판단 필요 사항" section
3. Extract content between this heading and the next ## heading
4. Autonomous merge eligible if content matches: "없음", "없음 —", or is empty
5. If human judgment items listed → report them, stop (do not merge)
6. Check branch protection:
   gh api repos/{owner}/{repo}/branches/{base}/protection (expect 404 if none)
7. If branch protection exists AND reviewDecision != APPROVED → stop
8. If no branch protection → skip reviewDecision check
9. Other checks remain: state=OPEN, checks passed, mergeable=MERGEABLE
10. Merge: gh pr merge {N} --squash --delete-branch
```

### 5. SKILL.md — `/ship pr` Decision Extraction Logic (lines 97-150)

Add instructions for populating new template variables:

```
Building {DECISIONS} table:
1. Read prompt-logs/{session}/lessons.md → extract "Takeaway" items
2. Read prompt-logs/{session}/retro.md → extract CDM section decisions
3. Read prompt-logs/{session}/plan.md → extract design decisions from plan
4. Synthesize into | 항목 | 결정 | 근거 | table rows
5. If no artifacts found, write "이 PR에서 특별한 설계 결정 없음"

Building {HUMAN_JUDGMENT}:
1. Agent self-assesses: are there items requiring human review?
   - Architecture decisions not validated by tests
   - UX/UI choices
   - Security-sensitive changes
   - Breaking changes to external APIs
2. If none → "없음 — 자율 머지 가능"
3. If exists → list specific items needing human review

Building {PURPOSE}: from git log summary + plan.md context
Building {VERIFICATION}: concrete reproducible steps (commands, URLs, expected output)
Building {SYSTEM_IMPACT} / {FUTURE_IMPACT}: describe behavioral changes and developer impact
```

## Success Criteria

```gherkin
Given the /ship skill with updated templates and SKILL.md
When /ship issue is invoked
Then the created issue body is in Korean
And follows 배경/문제/목표/작업 범위 structure

Given a session with lessons.md and retro.md artifacts
When /ship pr is invoked
Then the PR body contains 주요 결정사항 table populated from session artifacts
And contains 검증 방법 with concrete steps
And contains 인간 판단 필요 사항 section

Given a PR with "인간 판단 필요 사항: 없음"
And the repo has no branch protection on the base branch
When /ship merge is invoked
Then the PR is merged without requiring reviewDecision = APPROVED

Given a PR with "인간 판단 필요 사항: 없음"
And the repo has branch protection requiring reviews
When /ship merge is invoked
Then the merge blocks on reviewDecision = APPROVED as before

Given a PR with specific human judgment items listed
When /ship merge is invoked
Then the merge is blocked and the items are reported to the user
```

## Verification

1. Read the modified SKILL.md and verify all sections are coherent
2. Read pr-template.md and issue-template.md — confirm variable names match SKILL.md instructions
3. Verify SKILL.md stays under 500 lines (current: 259 lines, adding ~60 lines)
4. Test `/ship issue` on next session to verify Korean output + new structure
5. Test `/ship pr` on current session changes to verify decision extraction
6. Test `/ship merge` on a repo without branch protection

## Deferred Actions

- [ ] None identified
