# Retro: S2 Refactor Convention Alignment

> Session date: 2026-02-08
> Mode: light

## 1. Context Worth Remembering

- S1(shebang/strict mode/eval 제거)에 이어 S2(convention alignment)까지 완료. refactor 리뷰 → 플랜 → 실행이 2세션에 걸쳐 진행됨.
- 이 프로젝트는 9개 플러그인을 관리하며, `scripts/update-all.sh`로 marketplace 업데이트 + 전체 플러그인 재설치가 한 번에 이루어짐.
- env var 네이밍 컨벤션 `CLAUDE_CORCA_{PLUGIN}_{SETTING}`이 이제 attention-hook에도 적용됨. backward-compat shim 패턴(`${NEW:-${OLD:-default}}`)이 표준 마이그레이션 패턴으로 확립됨.

## 2. Collaboration Preferences

- 유저가 사전에 매우 상세한 plan을 작성하여 제공 → 구현 세션에서 토론 최소화, 효율적 실행 가능.
- plan에서 발견된 부정확한 정보(bare fence 카운트가 실제로는 closing fence였음)를 실행 중 자동으로 식별하고 lessons.md에 기록하는 패턴이 CLAUDE.md에 이미 반영되어 있음.

### Suggested CLAUDE.md Updates

없음. 현재 CLAUDE.md의 "plan 실행 중 불일치 발견 시 lessons.md에 기록" 규칙이 이번 세션에서 잘 작동함.

## 3. Waste Reduction

### 8개 서브에이전트 중 6개가 "변경 불필요"를 보고

bare fence 수정을 위해 6개의 서브에이전트를 병렬 실행했지만, 모든 파일이 이미 올바른 상태였기 때문에 실질적 작업은 없었다. 각 에이전트가 파일을 읽고, grep으로 검증하고, markdownlint까지 실행하는 데 상당한 토큰을 소비함.

**5 Whys:**
1. 왜 불필요한 에이전트를 실행했나? → plan에 93개 bare fence가 있다고 기록되어 있었기 때문
2. 왜 plan이 잘못된 카운트를 포함했나? → `grep -c '^```$'`가 closing fence도 카운트했기 때문
3. 왜 plan 단계에서 이를 검증하지 않았나? → 실제 markdownlint를 돌려보지 않고 grep 결과만으로 plan을 작성했기 때문
4. 왜 구현 전에 먼저 markdownlint를 실행하지 않았나? → plan의 정확성을 신뢰하고 바로 병렬 실행에 들어갔기 때문

**분류**: 프로세스 갭 — plan에 기반한 대규모 병렬 작업 전, 대표 샘플 1개로 빠른 검증을 먼저 하는 것이 효율적.

**제안**: plan에서 대량 파일 수정을 제안할 때, 구현 시작 전 1-2개 파일로 spot-check를 먼저 수행. 특히 자동 도구(markdownlint 등)로 검증 가능한 항목은 도구를 먼저 실행.

### README env var 참조 누락

`/plugin-deploy`에서 gap_count=0이었지만, README.md/README.ko.md에 있는 `CLAUDE_ATTENTION_DELAY` 참조를 놓칠 뻔했다. check-consistency.sh가 README 내부의 env var name까지는 검사하지 않기 때문.

**분류**: 구조적 제약 — check-consistency.sh의 검사 범위 한계. 현재는 "README에 플러그인 이름이 언급되는지"만 검사하며, 내용 정합성까지는 커버하지 않음. 수동 리뷰가 필요한 영역.

## 4. Critical Decision Analysis (CDM)

### CDM 1: Plan의 bare fence 카운트를 신뢰하고 8개 에이전트를 바로 병렬 실행

| Probe | Analysis |
|-------|----------|
| **Cues** | Plan에 "93 fences across 22 files"이라고 명시됨. 파일별 라인 번호까지 제공됨 |
| **Goals** | 빠른 실행 vs 정확성 검증. 병렬화로 속도를 극대화하려는 목표 |
| **Options** | (A) 바로 8개 에이전트 병렬 실행, (B) 먼저 markdownlint 실행 후 실제 위반만 수정, (C) 1개 파일 spot-check 후 진행 |
| **Basis** | Plan이 이전 세션에서 refactor 에이전트가 분석한 결과이므로 신뢰. 병렬 실행의 효율성 우선 |
| **Hypothesis** | Option B를 선택했다면 markdownlint가 0 violations을 보고했을 것이고, Task 1b 전체를 스킵할 수 있었음. 6개 에이전트의 토큰 소비를 절감 |
| **Aiding** | "대량 수정 전 도구 검증 먼저" 규칙이 있었다면 즉시 Option B를 선택했을 것 |

**Key lesson**: Plan이 대량 파일 수정을 제안할 때, 자동 검증 도구가 있으면 에이전트 투입 전에 도구를 먼저 실행하라. `markdownlint-cli2`처럼 한 줄로 전체 검증이 가능한 경우 에이전트보다 도구가 효율적.

### CDM 2: Env var 마이그레이션 범위 결정 — 스크립트 + README vs 전체 코드베이스

| Probe | Analysis |
|-------|----------|
| **Cues** | Plan에 구체적 파일/라인 명시 (heartbeat.sh:34, heartbeat.sh:48, start-timer.sh:29, README.md:117-119) |
| **Goals** | 완전한 마이그레이션 vs 최소 변경. backward-compat을 유지하면서 새 이름으로 전환 |
| **Options** | (A) Plan에 명시된 4개 파일만 수정, (B) grep으로 전체 코드베이스에서 old name 참조를 찾아 수정 |
| **Basis** | Plan을 따르되, `/plugin-deploy` 후 추가 검증을 기대 |
| **Situation Assessment** | `/plugin-deploy` 후 root README에서 old name 발견. plan이 README.md/README.ko.md의 env var 참조를 누락하고 있었음 |
| **Aiding** | 마이그레이션 작업에서 `grep -r OLD_NAME` 전체 코드베이스 검색을 표준 단계로 추가하면 누락 방지 |

**Key lesson**: 변수 이름 변경(rename/migration)은 항상 전체 코드베이스 grep을 포함해야 한다. Plan에 명시된 파일 외에도 참조가 있을 수 있다.

## 5. Expert Lens

> `/retro --deep`으로 전문가 분석을 수행하세요.

## 6. Learning Resources

> `/retro --deep`으로 학습 자료를 확인하세요.

## 7. Relevant Skills

### Installed Skills

| Skill | 이 세션과의 관련성 |
|-------|-------------------|
| `refactor --docs` | S2 plan 자체가 `/refactor --docs`의 출력물에서 도출됨. 효과적으로 활용됨 |
| `plugin-deploy` | attention-hook 배포에 사용. gap_count=0 확인, 48/48 테스트 통과 |
| `markdown-guard` | PostToolUse 훅으로 마크다운 편집 시 자동 검증. 이번 세션에서 모든 편집이 통과 |

### Skill Gaps

추가 스킬 갭 없음. 이번 세션은 기존 도구로 충분히 커버됨.

---

### Post-Retro Findings

**next-session.md 핸드오프 chain 끊어짐**

S2 완료 후 S3용 `next-session.md`가 생성되지 않았음. 후속 세션에서 발견.

**5 Whys:**
1. 왜 next-session.md를 안 만들었나? → S2의 plan과 CLAUDE.md 워크플로우에 해당 단계가 없었기 때문
2. 왜 plan에 포함되지 않았나? → S1이 작성한 S2용 next-session.md에 "After Completion" 섹션이 없었기 때문
3. 왜 S1의 핸드오프에는 있고 S2에는 없었나? → S0의 next-session.md에만 명시적 체크리스트가 있었고, S1이 S2용을 작성할 때 해당 패턴을 전파하지 않았기 때문
4. 왜 프로토콜에 포함되지 않았나? → 핸드오프 컨벤션이 master-plan.md에만 존재하고, 매 세션이 자동으로 참조하는 문서(CLAUDE.md, retro, plan-and-lessons)에는 없기 때문

**분류**: 프로세스 갭 — 컨벤션이 참조 문서에만 있고, 실행 프로토콜에 포함되지 않아 전파가 끊어짐.

**해결**: S3용 next-session.md에 "After Completion" 체크리스트를 명시적으로 포함하여 chain 유지. CLAUDE.md 추가는 보류 (master plan 방식을 계속 쓸지 미정).
