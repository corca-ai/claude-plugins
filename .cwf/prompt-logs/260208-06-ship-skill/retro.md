# Retro: /ship Skill (S3)

> Session date: 2026-02-08
> Mode: light

## 1. Context Worth Remembering

- `/ship`은 repo-level skill (`.claude/skills/ship/`)로 구현됨 — cwf v3 migration 동안 매 세션 GitHub 워크플로우 자동화에 사용될 예정
- `marketplace-v3` 브랜치가 이 세션에서 생성됨 — cwf v3 작업의 첫 커밋
- Instruction-only skill (스크립트 없음)은 258줄로 완성 — 에이전트의 판단 자유도가 높은 워크플로우에 적합
- 템플릿 파일에서 nested code fence 대신 HTML comment (`<!-- BEGIN TEMPLATE -->`)로 구간 표시하는 패턴 확립

## 2. Collaboration Preferences

- 유저는 plan이 이미 충분히 설계된 상태에서 "implement this plan"으로 세션을 시작 — 추가 clarify 없이 바로 구현 진행하는 것을 선호
- 세션 중간에 별개 이슈(markdownlint 규칙)를 자연스럽게 끼워넣는 스타일 — 에이전트가 현재 작업 완료 후 대응하는 것을 기대
- wrap-up 절차(next-session.md 포함)를 직접 확인하고 리마인드 — 프로토콜 준수에 대한 높은 기대

### Suggested CLAUDE.md Updates

- (없음 — 현재 CLAUDE.md가 이미 적절히 커버하고 있음)

## 3. Waste Reduction

### next-session.md 생성 타이밍 문제

유저가 명시적으로 "next-session은 잘 만들어져 있나요?"라고 물어본 시점에서 next-session.md가 없었다. 이전 세션(S2) retro에서 "next-session.md를 빠뜨린" 것이 이미 lesson으로 기록되었음에도 반복됨.

**5 Whys**:
1. 왜 next-session.md가 없었나? → wrap-up 단계에서 만들려고 계획했지만 유저가 먼저 물어봄
2. 왜 wrap-up에서야 만들려 했나? → plan.md의 step 6에 "session wrap-up: lessons.md, next-session.md, /retro, commit & push"로 묶여 있었고, 순차적으로 처리
3. 왜 구현 완료 직후 바로 만들지 않았나? → 커밋과 retro를 먼저 하려는 관성 — next-session은 "부가 산출물"로 인식
4. 근본 원인: next-session.md는 다음 세션의 시작점이라는 중요도에 비해 wrap-up 체크리스트에서 후순위

**분류**: 프로세스 갭 — plan.md 템플릿에서 next-session.md를 커밋 전 필수 산출물로 명시하면 해결

### Nested code fence 문제

PR 템플릿 첫 작성에서 ```` ```markdown ```` 안에 ```` ```text ```` 를 넣어서 markdownlint 오류 발생. 한 번 수정으로 해결했지만 1회 추가 턴 소모.

**분류**: 일회성 실수 — lessons.md에 기록됨. 향후 반복 가능성 낮음.

## 4. Critical Decision Analysis (CDM)

### CDM 1: Instruction-only skill vs script-based skill

| Probe | Analysis |
|-------|----------|
| **Cues** | Plan에서 "Type: Instruction-only SKILL.md with reference templates (no scripts)"로 이미 결정됨 |
| **Goals** | 빠른 구현 vs 안정적 실행 — gh CLI 호출은 에이전트가 bash로 직접 할 수 있으므로 스크립트 래핑의 이점이 낮음 |
| **Options** | (1) Instruction-only SKILL.md (2) 스크립트 기반 (gh 호출 래핑) (3) 하이브리드 (SKILL.md + helper scripts) |
| **Basis** | gh CLI는 이미 idempotent하고 에이전트가 직접 호출 가능. 스크립트 래핑은 env loading이나 복잡한 파싱이 필요할 때만 가치 있음 |
| **Experience** | gather-context는 curl + API key + JSON 파싱이 있어서 스크립트가 필수였음. /ship은 gh CLI만 사용하므로 스크립트 불필요 |
| **Hypothesis** | 스크립트로 만들었다면 구현 시간 2-3배, 유지보수 부담 증가, 유연성 감소 |

**Key lesson**: CLI가 이미 충분히 추상화된 경우(gh CLI), 스크립트 래핑은 오버헤드. Instruction-only가 적합.

### CDM 2: 템플릿을 별도 파일로 분리 vs SKILL.md 인라인

| Probe | Analysis |
|-------|----------|
| **Cues** | Plan에서 `references/` 디렉토리 구조가 명시됨. SKILL.md 500줄 제한 |
| **Goals** | SKILL.md 간결성 유지 vs 파일 수 최소화 |
| **Options** | (1) 별도 references 파일 (2) SKILL.md 내 인라인 (3) HEREDOC 문자열로 스크립트에 내장 |
| **Basis** | 템플릿은 {VARIABLE} 치환이 필요하므로 에이전트가 읽고 조합하기 편한 별도 파일이 적합. SKILL.md에 넣으면 지시사항과 템플릿이 섞여 가독성 하락 |
| **Aiding** | skills-guide.md의 "Progressive Disclosure" 원칙 — SKILL.md는 간결하게, 상세는 references/로 |

**Key lesson**: 에이전트가 읽어서 치환하는 콘텐츠는 references/로 분리. SKILL.md는 워크플로우 지시사항만.

## 5. Expert Lens

> Run `/retro --deep` for expert analysis.

## 6. Learning Resources

> Run `/retro --deep` for learning resources.

## 7. Relevant Skills

### Installed Skills

| Skill | 이 세션에서의 관련성 |
|-------|---------------------|
| `/retro` | 현재 실행 중 |
| `/plugin-deploy` | 해당 없음 — `/ship`은 local skill이라 marketplace deploy 불필요 |
| `/refactor` | 향후 `/ship` SKILL.md 리뷰에 `--skill ship` 모드 사용 가능 (local skill 지원 시) |
| `/gather-context` | 세션에서 직접 사용하지 않았으나, `/ship issue`가 session context 수집 시 간접적으로 관련 |
| `/clarify` | Plan이 이미 상세해서 이 세션에서는 불필요했음 |

### Skill Gaps

`/ship` 자체가 이 세션에서 확인된 워크플로우 갭(매뉴얼 gh CLI 호출)에 대한 해결책. 추가 skill gap 없음.
