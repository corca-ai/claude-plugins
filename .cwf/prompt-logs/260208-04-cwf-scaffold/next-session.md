# Next Session: S4.5 — /ship 스킬 개선

## What This Is

CWF v3 마이그레이션 중간 개선 세션. S4에서 `/ship`을 실사용하면서 발견된 품질 문제를 해결한다.
마스터 플랜 로드맵의 S5a 전에 끼워넣는 세션.

Full context: `prompt-logs/260208-03-cwf-v3-master-plan/master-plan.md`

## Background

S3에서 만든 `/ship` 스킬의 이슈/PR 출력 품질이 moonlight 레포의 `document-pr-process` 스킬 대비 부족하다.
S4에서 실사용하며 구체적 문제를 확인했다.

## Problem

1. **언어**: Issue/PR 본문이 영어로 작성됨 — 사람이 읽는 문서이므로 한글이어야 함
2. **의사결정 부재**: PR에 "왜 이런 결정을 했는가", "인간이 판단해야 할 사항"이 없음
3. **검증 방법 부재**: "어떻게 검증하는가"가 너무 간략하여 리뷰어가 별도 조사 필요
4. **셀프 머지**: 인간 판단이 불필요한 PR은 에이전트가 자율적으로 머지할 수 있어야 함
5. **셀프 어프루브 불가**: PR 작성자가 본인 PR을 approve할 수 없는 GitHub 제약

## Goal

- Issue/PR을 moonlight의 `document-pr-process` 수준으로 개선
- 에이전트 자율 머지 판단 로직 추가
- 1인 프로젝트에서의 리뷰 워크플로우 현실적 해결

## Scope

### 1. PR 템플릿 재설계 (`references/pr-template.md`)

moonlight 패턴을 참고하여 리뷰어 관점 구조로 변경:

```markdown
Resolves #{issue}

## 목적
[이 PR이 왜 필요한가 — 1-2문장]

## 주요 결정사항
| 항목 | 결정 | 근거 |
|------|------|------|
| ... | ... | ... |

## 검증 방법
1. [구체적 검증 단계]
2. ...

## 인간 판단 필요 사항
[에이전트가 판단할 수 없는 항목. 없으면 "없음 — 자율 머지 가능"으로 명시]

## 머지 후 영향
**시스템**: ...
**향후 개발**: ...
```

### 2. Issue 템플릿 재설계 (`references/issue-template.md`)

moonlight 패턴 참고:

```markdown
## 배경
[왜 이 작업이 필요한가]

## 문제
[구체적으로 무엇을 해결하는가]

## 목표
[성공 기준]

## 작업 범위
[구체적 파일/영역]
```

### 3. SKILL.md — `/ship merge` 자율 머지 로직

현재: `reviewDecision = APPROVED` 필수 → 1인 프로젝트에서 작동 불가

변경:
- PR body에서 "인간 판단 필요 사항" 섹션 파싱
- "없음" 또는 비어있으면 → 자율 머지 가능으로 판단
- 자율 머지 시 `--admin` 없이 직접 `gh pr merge --squash --delete-branch`
- `reviewDecision` 체크를 조건부로 변경: branch protection이 있으면 체크, 없으면 skip

### 4. SKILL.md — 언어 규칙 강화

현재: `**Language**: Match the user's language.`

변경: Issue/PR body는 한글로 작성. 단, 코드 블록/커밋 해시/파일 경로는 원문 유지.

### 5. `/ship pr` — 의사결정 추출 로직

PR 생성 시 세션 아티팩트에서 의사결정 정보 추출:
- `lessons.md`에서 핵심 결정사항 추출
- `retro.md` CDM 섹션에서 주요 결정 추출
- `plan.md`에서 설계 결정 추출
- 에이전트가 "인간 판단 필요 사항"을 자율적으로 판단하여 기재

## Reference

- moonlight `document-pr-process`: `gh api repos/corca-ai/moonlight/contents/.claude/skills/document-pr-process/SKILL.md --jq '.content' | base64 -d`
- moonlight PR 예시: `gh pr view 1517 --repo corca-ai/moonlight`
- moonlight Issue 예시: `gh issue view 1515 --repo corca-ai/moonlight`
- 현재 ship 스킬: `.claude/skills/ship/`

## Don't Touch

- cwf 플러그인 코드 (S5a에서 진행)
- 마스터 플랜 세션 로드맵 (S4.5는 삽입 세션이므로 기존 번호 체계 유지)

## Success Criteria

- `/ship issue`로 생성된 이슈가 한글이고 Background/Problem/Goal 구조를 따름
- `/ship pr`로 생성된 PR이 주요 결정사항/검증 방법/인간 판단 필요 사항을 포함
- `/ship merge`가 "인간 판단 필요 사항: 없음"인 PR을 자율적으로 머지할 수 있음
- branch protection이 없는 레포에서 review 체크 없이 머지 가능

## Dependencies

- Requires: S4 completed (scaffold merged)
- Blocks: 없음 (S5a와 독립적이나, S5a 이전에 완료하면 이후 세션에서 개선된 /ship 사용 가능)

## After Completion

1. Create session dir: `prompt-logs/{YYMMDD}-{NN}-ship-improve/`
2. Write plan.md, lessons.md
3. Write next-session.md (**S4.6** 핸드오프 — 아래 참조)
4. `/retro`
5. Commit & push

## Start Command

```text
@prompt-logs/260208-04-cwf-scaffold/next-session.md S4.5 시작합니다
```

---

# Next Session: S4.6 — SW Factory 분석 + CWF v3 설계 논의

## What This Is

`cwf:review` 구현(S5a) 전에 SW Factory 분석을 함께 읽고,
CWF v3에 반영할 개념들을 설계 토론하는 세션. **구현 세션이 아닌 논의 세션**.

Full context: `prompt-logs/260208-03-cwf-v3-master-plan/master-plan.md`

## Background

StrongDM의 "Software Factories and the Agentic Moment" 분석(`references/sw-factory/analysis.md`,
origin/main)이 CWF v3의 검증/리뷰 설계에 직접적으로 관련된다. 특히:

- **시나리오 테스팅 + 홀드아웃 세트**: 에이전트가 접근할 수 없는 별도 폴더에 시나리오를
  저장하여, 코드와 테스트의 공모(reward hacking)를 구조적으로 방지하는 전략
- **만족도(satisfaction) 스펙트럼**: boolean pass/fail이 아닌 확률적 품질 판정
- **Shift Work**: 대화형 vs 비대화형 작업 분리 — 스펙이 완전하면 에이전트가 자율 실행
- **Pyramid Summaries**: 대규모 코드베이스의 컨텍스트 관리 전략
- **의도적 순진함(deliberate naivete)**: 기존 관행의 자기검열을 벗어나는 것

## Goal

1. `references/sw-factory/analysis.md`를 함께 읽고 논의
2. CWF v3 (특히 `cwf:review`, `agent-patterns.md`)에 반영할 개념 식별
3. 시나리오 테스팅의 구체적 적용 방안 설계 토론
   - 홀드아웃 세트 구조: 에이전트 접근 차단용 폴더 분리가 맞는 전략인가?
   - 우리 맥락(플러그인 개발, 스킬 품질 검증)에서의 시나리오란 무엇인가?
   - 만족도 측정을 어떻게 정의할 것인가?
4. 논의 결과를 마스터 플랜 또는 `cwf:review` 설계에 반영하는 구체적 항목 도출

## Scope

- **읽기**: `references/sw-factory/analysis.md` (origin/main에서 checkout 또는 직접 읽기)
- **논의**: 위 Goal의 3-4번 항목에 대한 설계 토론
- **산출물**: 논의 결과 정리 문서 + 마스터 플랜/agent-patterns.md 업데이트 항목 목록
- **구현 없음**: 코드 변경 없이 설계만

## Don't Touch

- `cwf:review` 구현 (S5a에서)
- 기존 hook/skill 코드

## Dependencies

- Requires: S4.5 completed (/ship 개선)
- Blocks: S5a (cwf:review — 이 논의 결과가 설계에 반영됨)

## Known Issue

`git fetch origin`이 Claude Code Bash 환경에서 hang될 수 있음 (S4에서 발생, 원인 미확인).
hang 감지 시 "터미널에서 직접 `git fetch origin main`을 실행해주세요"로 안내하고 진행할 것.

## After Completion

1. Create session dir: `prompt-logs/{YYMMDD}-{NN}-sw-factory-discussion/`
2. Write plan.md (논의 결과), lessons.md
3. Write next-session.md (S5a 핸드오프 — cwf:review 구현)
4. `/retro`
5. Commit & push

## Start Command

```text
@prompt-logs/{S4.5-session-dir}/next-session.md S4.6 시작합니다
```
