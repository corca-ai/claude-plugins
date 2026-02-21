# PR Template

The agent reads this file and substitutes `{VARIABLES}` to compose the PR body.

## Body

<!-- BEGIN TEMPLATE -->

{ISSUE_LINK}

## 목적

{PURPOSE}

## 주요 결정사항

{DECISIONS}

## 검증 방법

{VERIFICATION}

## 인간 판단 필요 사항

{HUMAN_JUDGMENT}

## 머지 후 영향

### 시스템 동작 변경

{SYSTEM_IMPACT}

### 향후 작업 영향

{FUTURE_IMPACT}

## 회고 결과 요약

{RETRO_SUMMARY}

## 영속화 및 후속 제안

{RETRO_PERSIST_PROPOSALS}

<details>
<summary>상세 아티팩트 (diff stat, lessons, CDM)</summary>

### Diff Stat

{GIT_DIFF_STAT}

### Lessons Learned

{LESSONS}

### CDM (Critical Decision Moments)

{CDM}

</details>

## Review Checklist

- [ ] Code changes match PR description
- [ ] No unintended file changes
- [ ] Tests pass (if applicable)
- [ ] Retro persistence proposals are tracked as follow-up actions/issues
{CONDITIONAL_ITEMS}

---
*Created with `/ship pr`*

<!-- END TEMPLATE -->
