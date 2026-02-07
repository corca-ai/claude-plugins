# Retro: CodeRabbit PR #7 리뷰 적용 + plugin-deploy 개선

> Session date: 2026-02-07
> Mode: light

## 1. Context Worth Remembering

- CodeRabbit이 자동 생성한 리뷰 코멘트는 양이 많지만 (26개) triage 시 skip 비율이 높음 (6/26). 기계적으로 전부 적용하는 것보다 plan 단계에서 분류 후 실행하는 패턴이 효율적.
- 이 repo의 bash 스크립트들은 `set -euo pipefail` 조합을 일관되게 사용. curl 호출 시 `set +e` / `set -e` 가드 패턴이 표준.
- markdownlint는 nested code fence를 파싱하지 못함 — 이 repo에서 2건의 false positive가 구조적으로 불가피.
- deprecated 플러그인 정책: `plugin.json`에 `deprecated: true` → marketplace.json에서 제거가 올바른 방향. 양쪽 sync가 아님.

## 2. Collaboration Preferences

- 사전에 plan을 만들어두면 실행 세션이 매우 빠르고 질문 없이 진행됨. plan-first 워크플로우가 잘 맞는 사용자.
- "retro 후에 push하자"처럼 워크플로우 순서를 명시적으로 조정하는 스타일. CLAUDE.md의 단계 순서(3→4→5→6)와 약간 다를 수 있으나, 유연하게 대응하면 됨.
- 작업 도중 발생한 아이디어(markdownlint 준수 전략)를 별도 세션으로 분리하되 retro에 기록해두어 연속성을 유지하는 습관.

### Suggested CLAUDE.md Updates

- ✅ 반영됨: code fence language specifier 필수 규칙 추가 (Collaboration Style)
- ✅ 반영됨: deprecated 정책 project-context.md에 추가
- ✅ 반영됨: curl guard + empty array 패턴 plugin-dev-cheatsheet.md에 추가

## 3. Waste Reduction

**효율적이었던 부분:**
- Plan에서 4개 workstream으로 분리한 덕분에 독립적 변경을 병렬 처리 가능했음. 특히 WS3(markdown lint)에서 2개 sub-agent를 백그라운드로 돌리면서 WS4와 version bump을 동시에 진행 — 대기 시간 최소화.

**낭비 요소:**
- MD040 수정 범위가 plan 대비 확대됨 (9개 파일 → 30+ 파일). plan 단계에서 `grep -r '^```$' plugins/` 한 번 돌렸으면 정확한 범위를 미리 알 수 있었음. → **교훈: 기계적으로 검증 가능한 항목은 plan 단계에서 정확한 수를 세어야 plan 정밀도가 올라감.**
- markdownlint 첫 실행에서 MD060, MD031 등 noisy rule을 끄지 않아 356 errors가 나옴. config를 먼저 만들고 실행했으면 한 단계 절약. → 사소한 낭비.

## 4. Critical Decision Analysis (CDM)

### CDM 1: CodeRabbit deprecated 로직 재해석

| Probe | Analysis |
|-------|----------|
| **Cues** | CodeRabbit 코멘트: "Sync deprecated flag between marketplace.json and plugin.json". 기존 코드의 양방향 sync 로직. |
| **Knowledge** | 이전 세션에서 deprecated 플러그인을 marketplace에서 제거하는 작업을 수행한 경험. `deprecated: true`인 플러그인은 marketplace에 존재하면 안 된다는 도메인 규칙. |
| **Goals** | CodeRabbit 리뷰 반영 vs 실제 올바른 비즈니스 로직 |
| **Options** | (A) CodeRabbit 제안대로 양방향 sync (B) 단방향: deprecated + in_marketplace → gap으로 감지 |
| **Basis** | "sync"는 잘못된 모델 — deprecated 플러그인이 marketplace에 있는 것 자체가 에러이지, 양쪽 flag를 맞추는 게 아님. |
| **Hypothesis** | 양방향 sync를 구현했다면, deprecated 플러그인이 marketplace에 남아 있어도 양쪽 flag가 true이면 gap이 0으로 나와, 실제 문제를 놓쳤을 것. |

**Key lesson**: 자동화 도구(CodeRabbit)의 제안도 도메인 의미를 기준으로 재해석해야 한다. "flag sync"처럼 기계적으로 맞는 제안이 비즈니스 로직에서는 틀릴 수 있다.

### CDM 2: MD040 범위 확대 결정

| Probe | Analysis |
|-------|----------|
| **Cues** | plan에서 9개 파일로 한정했으나, grep 결과 30+ 파일에 bare code fence 존재. markdownlint config를 도입하므로 일관성 필요. |
| **Goals** | plan 준수 vs 완전한 lint 통과 |
| **Options** | (A) plan대로 9개만 수정 (B) 전체 코드베이스 수정 (C) plan 파일 + marketplace 플러그인만 |
| **Basis** | markdownlint config를 커밋하면서 기존 파일이 대량 fail하면 config의 의미가 없음. 전체 수정이 정합성 있음. |
| **Aiding** | sub-agent 2개를 백그라운드로 돌려 확대된 범위를 효율적으로 처리. plan 단계에서 정확한 scope를 잡았으면 더 좋았을 것. |
| **Hypothesis** | 9개만 수정했다면 lint 첫 실행에서 대량 MD040 error → "왜 도입했나?" 의문 발생. |

**Key lesson**: lint tool 도입 시 기존 코드베이스의 전체 compliance를 먼저 확인하고, config와 수정을 동시에 커밋해야 의미 있다.

## 5. Expert Lens

> Run `/retro --deep` for expert analysis.

## 6. Learning Resources

> Run `/retro --deep` for learning resources.

## 7. Relevant Skills

### Installed Skills

| Skill | 이 세션에서의 관련성 |
|-------|---------------------|
| **refactor** | quick-scan.sh를 수정했으므로 수정 후 `/refactor` quick scan으로 regression 확인 가능했음. 활용하지는 않았으나, 검증 단계에서 `bash quick-scan.sh`를 직접 실행하여 같은 효과 달성. |
| **plugin-deploy** | version bump + marketplace sync 검증에 `check-consistency.sh`를 직접 실행. `/plugin-deploy`로 전체 워크플로우를 돌리는 것은 push 후로 연기됨. |
| **gather-context** | 스크립트 수정 대상이었으나, 이 세션에서 정보 수집 용도로는 사용하지 않음. |
| **clarify** | 사전 plan이 충분했으므로 요구사항 명확화 불필요. |

### Skill Gaps

현재 설치된 스킬로 충분. 다만 **markdownlint 준수를 지속적으로 보장하는 메커니즘**이 없음 — 아래 "Next Session" 참조.

---

## Next Session: Markdownlint 준수 전략

사용자 의견을 기반으로 다음 세션에서 검토할 3가지 접근:

1. **템플릿 기반**: SKILL.md, reference 등 새 파일 생성 시 code fence에 language specifier가 포함된 템플릿을 사용. plugin-deploy나 skill-creator 같은 도구에서 생성 시 적용 가능.

2. **프롬프트 수정**: CLAUDE.md 또는 skill instructions에 "code fence를 만들 때 반드시 language specifier를 포함하라"는 규칙 추가. AI가 생성하는 문서에서의 준수율 향상.

3. **lint --fix 자동화**: `markdownlint-cli2 --fix`로 자동 수정 가능한 규칙 활용. PreToolUse/PostToolUse hook 또는 pre-commit hook으로 자동화 가능. MD040은 자동 fix 불가(language 추론 필요)이므로 이 부분은 1번 또는 2번에 의존.

**추천 조합**: 2번(프롬프트) + 3번(자동화 가능한 규칙) 병행. 1번(템플릿)은 새 스킬 생성 빈도가 높아지면 추가.
