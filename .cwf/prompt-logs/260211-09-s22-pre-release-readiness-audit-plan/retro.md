# Retro: S23 — Execute S22 Concerns 1-3 + Prepare Step 4 Prompt

> Session date: 2026-02-11
> Mode: deep

## 1. Context Worth Remembering

- S23는 S22 계획의 Phase A(Concern 1-3)와 Step4 인터랙티브 프롬프트 준비까지를 완료했다.
- 계획 문서에는 11개 스킬 기준이었지만 실제 코드베이스는 12개 스킬(`run` 포함)로 드리프트되어, 실행 중 범위를 12개로 재정의했다.
- Concern 1-3 결과는 모두 FAIL(블로커 존재)로 정리했고, 최종 Go/No-Go는 Step4 인터랙션 이후로 의도적으로 연기했다.
- 세션 중간에 실행 계약의 커밋 게이트 누락이 발생했고, 즉시 사용자에게 보고 후 브랜치 분기 + 의미 단위 커밋으로 복구했다.
- 재발 방지를 위해 실행 계약에 "첫 단위 완료 후 commit checkpoint" 규칙을 영구 반영했다.

## 2. Collaboration Preferences

- 사용자는 "계획 대비 실제 실행 일치"를 매우 중요하게 본다. 특히 실행 계약(브랜치/커밋 게이트) 위반은 즉시 지적한다.
- 위반이 발견되면 빠른 인정, 현재 상태 공개, 복구 옵션 제시(1/2/3) 방식이 효과적이었다.
- 단순 상태 질의에도 "실제로 멘션만으로 시작 가능한지" 같은 실행 가능성 검증을 선호한다.
- 산출물 작성 자체보다 "프로세스 준수 증거(체크포인트, 분할 커밋, 검증 실행)"를 명시하는 것이 신뢰에 중요했다.

### Suggested Agent-Guide Updates

- 없음. 이번 세션에서 필요한 항목은 이미 `plan-protocol.md`, `handoff/SKILL.md`, `project-context.md`에 반영 완료.

## 3. Waste Reduction

### Waste item A — 커밋 게이트 누락으로 인한 재작업

- Symptom: 산출물을 먼저 몰아서 작성한 뒤 사용자 지적으로 브랜치/커밋 전략을 재적용.
- Why 1: 실행 계약을 읽었지만 "중간 체크포인트"를 작업 루프에 강제하지 못함.
- Why 2: 산출물 생성 흐름에 집중하면서 상태 점검(`git status`) 타이밍이 누락됨.
- Why 3: 계약 문구가 "의미 단위 커밋"까지는 있었지만 "언제 점검할지"가 약했음.
- Root cause: 프로세스 제어점(checkpoint) 부재.
- Durable fix: 실행 계약 자체에 "첫 단위 완료 후 `git status --short` + 다음 커밋 경계 확정"을 명문화.

### Waste item B — 11 vs 12 스킬 범위 재조정 비용

- Symptom: 감사 중간에 범위 드리프트를 발견하고 재합의 필요.
- Why 1: 계획(S22)은 11개 스킬 기준, 코드베이스는 12개 스킬 상태.
- Why 2: 계획 수립 시점 이후 인벤토리 변경을 계획 본문이 반영하지 못함.
- Root cause: 고정 숫자 기반 실행 계약.
- Durable fix: "live inventory 우선" 규칙을 lessons로 기록하고 이후 계약 작성 시 드리프트 규칙 포함.

## 4. Critical Decision Analysis (CDM)

### Decision 1 — 11개 계획 범위를 12개 live 범위로 확장할지

- **Cue**: 감사 실행 중 `plugins/cwf/skills/run` 존재 확인.
- **Options**:
  1. 원계획 11개 고수
  2. live 기준 12개 확장
- **Chosen**: 2번 (사용자 승인 후 확장)
- **Why**: release-readiness 전수 감사 목적에서 실제 런타임 인벤토리를 제외하면 근거가 약해짐.
- **Risk**: 계획 대비 실행 드리프트.
- **Mitigation**: `lessons.md`에 즉시 드리프트 기록 + 사용자 명시 승인 확보.

### Decision 2 — 커밋 게이트 위반 발견 시 즉시 중단/보고 여부

- **Cue**: 사용자가 "브랜치 체크아웃 + 단위 커밋" 누락 지적.
- **Options**:
  1. 내부적으로만 수정 후 계속 진행
  2. 즉시 중단, 불일치 기록, 사용자 결정 요청
- **Chosen**: 2번
- **Why**: AGENTS 협업 규칙(사전 설계 플랜 이탈 시 즉시 보고 및 의사결정 요청) 준수.
- **Outcome**: feature branch 재분기 + 3개 의미 단위 커밋으로 복구.

### Decision 3 — 레슨을 세션 기록에만 둘지, 운영 규칙으로 승격할지

- **Cue**: 동일 유형 실수(end-loaded commit) 재발 가능성.
- **Options**:
  1. lessons.md에만 기록
  2. plan-protocol/handoff 템플릿/프로젝트 휴리스틱으로 승격
- **Chosen**: 2번
- **Why**: 구조적 예방이 행동 지침보다 내구성이 높음.
- **Outcome**: 실행 계약 commit-checkpoint 규칙이 문서 체계에 반영됨.

## 5. Expert Lens

### Expert Alpha — W. Edwards Deming (variation + built-in quality)

- Observation: 커밋 게이트 누락은 개인 실수라기보다 프로세스의 common cause variation으로 볼 수 있다.
- Interpretation: 품질을 결과 검수에 의존하면(마지막 커밋 직전 확인) 변동이 반복된다.
- Recommendation: 작업 흐름 중간에 강제 제어점(checkpoint)을 넣어 품질을 공정 안으로 이동시켜야 한다.

### Expert Beta — Nancy Leveson (control structure + feedback)

- Observation: 실행 계약은 있었지만 제어 루프가 open-loop에 가까웠다(계약 존재 ↔ 실행 확인 사이 결합 약함).
- Interpretation: "commit gate"는 제약 조건인데, 트리거 이벤트와 피드백 이벤트가 명확히 연결되지 않으면 위반을 늦게 감지한다.
- Recommendation: "첫 산출물 완료"라는 명시적 이벤트를 제어 입력으로 지정해 피드백 루프를 폐쇄해야 한다.

### Synthesis

- 두 관점 모두 같은 결론: 문서 규칙의 존재만으로는 불충분하며, 실행 시점 기반 체크포인트가 필요하다.
- 이번 세션에서 해당 체크포인트를 계약 규칙으로 승격한 것은 재발 방지 측면에서 정합적이다.

## 6. Learning Resources

1. **W. Edwards Deming — _Out of the Crisis_**  
   URL: https://mitpress.mit.edu/9780262541164/out-of-the-crisis/  
   핵심: 품질을 사후검사로 관리하지 말고 프로세스 내부 제어로 설계해야 한다는 원칙을 제시한다. 이번 세션의 commit gate 누락 사례를 "개인 실수"보다 "시스템 변동"으로 해석하는 데 직접적 프레임을 준다.  
   왜 중요한가: 실행 계약을 지키는 팀 운영에서, 체크포인트 설계를 구조화하는 근거가 된다.

2. **Nancy Leveson — _Engineering a Safer World_**  
   URL: https://mitpress.mit.edu/9780262016624/engineering-a-safer-world/  
   핵심: 사고를 구성요소 고장만이 아니라 제어 구조와 피드백 결함으로 분석한다. 문서 규칙이 있어도 피드백 루프가 약하면 위반이 지연 감지된다는 점을 설명한다.  
   왜 중요한가: SKILL/프로토콜 규칙을 실제 실행 이벤트와 연결하는 통제 설계에 유용하다.

3. **Martin Fowler — _Refactoring (2nd ed.)_**  
   URL: https://martinfowler.com/books/refactoring.html  
   핵심: 중복 제거와 작은 안전한 단계의 누적이 변경 안정성을 높인다는 실천 원리를 제시한다. 이번 세션처럼 규칙 승격을 작은 문서 변경 단위로 분리 커밋하는 전략과 맞닿아 있다.  
   왜 중요한가: 운영 규칙 개선을 코드 개선처럼 다루는 실무 감각을 강화한다.

## 7. Relevant Skills

### Installed Skills

- `cwf:retro`  
  이번처럼 프로세스 위반/복구 사례를 구조적으로 남기고, 세션 학습을 영구 규칙으로 승격할 때 핵심.

- `cwf:handoff`  
  다음 세션의 실행 계약 품질(멘션-온리 실행, 브랜치/커밋 게이트)을 안정적으로 전달할 때 필요.

- `cwf:ship`  
  retro 결과(CDM/lessons)를 PR 본문에 자동 반영해 의사결정 맥락을 유지하는 데 직접 연결됨.

- `cwf:review --mode plan`  
  실행 계약이 포함된 plan/next-session 문서를 사전 검증해 drift를 조기에 차단할 수 있음.

### Skill Gaps

- 현재 설치 스킬로 이번 워크플로우는 충분히 커버됨.
- 추가 스킬 갭 없음.
