# Retro: S13.5 C2/D/E — Docs Infrastructure & Hook Improvements

> Session date: 2026-02-09
> Mode: light

## 1. Context Worth Remembering

- 사용자는 AI 에이전트 최적화 문서 구조에 대한 외부 연구(Vercel, g15e, HumanLayer)를 적극 활용하며, 자체 프로젝트에 원칙으로 종합하는 것을 선호함
- "파일이 늘어나는 건 큰 문제가 없다" — 사용자는 문서 파일 수 증가보다 각 파일의 scope 명확성을 우선시
- codex exec를 실전에서 처음 사용. gpt-5.3-codex 모델, `--full-auto` 플래그로 비대화형 실행 확인
- `.codex/skills/` 심링크로 cwf 스킬을 codex에 공유하는 패턴 수립 (로컬 설정, 리포에 커밋되지 않음)

## 2. Collaboration Preferences

- 사용자가 외부 자료를 제시하면 반드시 읽고 종합한 뒤 의견을 제시할 것 — 이번 세션에서 3개 글을 순차 제시했고, 각각이 설계 방향에 영향을 줌
- 에이전트의 초기 의견이 사용자의 반론에 의해 수정되는 것을 긍정적으로 봄 ("솔직한 의견 주세요")
- "retro 하고 ship 합시다"처럼 여러 단계를 한 문장으로 지시하는 스타일 — 스킬 체이닝을 기대함

### Suggested CLAUDE.md Updates

- 없음. 이번 세션에서 추가한 persist routing 테이블과 documentation index가 이미 반영됨.

## 3. Waste Reduction

**Prescriptive routing → agent autonomy 전환 비용**: 초기에 "언제 무엇을 읽어라"는 prescriptive trigger 테이블을 설계했으나, 사용자가 g15e 원칙("readers are sufficiently intelligent")을 제시하면서 scope description 방식으로 전환. 이 과정에서 라우팅 테이블을 두 번 설계함.

- 5 Whys: 왜 prescriptive로 시작했나? → CLAUDE.md의 기존 "For deeper reference" 패턴이 prescriptive였음 → 기존 패턴을 관성적으로 따름 → **외부 연구를 먼저 읽었으면 첫 설계부터 scope description으로 갔을 것**
- Root cause: 연구 → 설계 순서가 아니라 설계 → 연구 순서로 진행
- Fix: clarify 단계에서 사용자가 제시한 참고자료가 있으면, 분석/설계 전에 먼저 읽을 것

**E2 transcript 구조 탐색**: codex에 위임하기 전에 메인 에이전트가 transcript JSON 구조를 직접 탐색하려 했음 (4-5 Bash 호출). 이후 codex에 위임하면서 그 탐색이 불필요해짐.

- 5 Whys: 왜 직접 탐색했나? → "codex로 위임하자"는 아이디어가 탐색 도중에 나왔기 때문 → 작업 시작 전 위임 여부를 먼저 결정하지 않았음
- Fix: 기존 코드 이해가 필요한 수정 작업을 시작하기 전에, "직접 vs 위임" 결정을 먼저 내릴 것. lessons #8의 "탐색 비용" 기준 활용

## 4. Critical Decision Analysis (CDM)

### CDM 1: catch-all 문서 분리 vs 유지

| Probe | Analysis |
|-------|----------|
| **Cues** | 사용자가 "project-context가 common.ts 같다"고 지적. 이후 3개 외부 글 제시 |
| **Goals** | (1) 각 문서의 retrieval trigger를 명확하게 (2) 파일 수 최소화 (3) retro persist 라우팅 유지 |
| **Options** | A: 유지 (shell gotchas만 cheatsheet로 이동) B: architecture-patterns.md 분리 C: 전면 재구조화 (5+ 파일) |
| **Basis** | 에이전트는 처음 A를 주장("파일만 늘고 실익 없다"). 사용자가 Vercel/g15e/HumanLayer 글을 제시하며 B의 근거를 보강. 에이전트가 의견 수정 |
| **Experience** | 경험 많은 문서 아키텍트라면 "이 파일의 trigger가 'always'가 되면 분리 시점"이라는 휴리스틱을 처음부터 적용했을 것 |
| **Hypothesis** | A(유지)를 택했다면: progressive disclosure가 계속 실패하고, 다음 세션에서 또 같은 문제 발생 |

**Key lesson**: 문서 분리의 기준은 파일 수가 아니라 "trigger condition의 독립성". 한 파일의 trigger가 모든 작업에 해당하면, 그 파일은 catch-all이 된 것이다.

### CDM 2: Codex exec 위임 결정

| Probe | Analysis |
|-------|----------|
| **Cues** | 사용자가 "메인 에이전트 컨텍스트 절약" 질문. 이미 E2 작업 중 transcript 탐색으로 컨텍스트 소모 체감 |
| **Goals** | (1) 메인 컨텍스트 절약 (2) 구현 정확성 유지 (3) 세션 내 완료 |
| **Options** | A: 직접 구현 계속 B: Task sub-agent 위임 C: codex exec 위임 |
| **Basis** | codex는 코드 수정에 특화. 명확한 스펙이 있으므로 위임 적합. agent-patterns.md에 이미 codex 호출 패턴 존재 |
| **Tools** | `codex exec --full-auto --reasoning high`. 이 프로젝트에서 review 스킬이 이미 codex를 external reviewer로 사용 중 |
| **Situation Assessment** | 위임 시점이 다소 늦었음 (이미 transcript 탐색 시작 후). 작업 시작 전에 결정했으면 더 효율적 |

**Key lesson**: "탐색 비용이 높은 구현"은 작업 시작 전에 위임 여부를 결정할 것. 탐색을 시작한 후 위임하면 탐색 비용이 이중으로 발생한다.

### CDM 3: 읽기/쓰기 비대칭 설계

| Probe | Analysis |
|-------|----------|
| **Cues** | g15e의 "readers are sufficiently intelligent" 원칙을 적용하려다, persist routing(쓰기)에는 적용 불가함을 발견 |
| **Goals** | (1) agent autonomy 존중 (2) persist 정확성 보장 |
| **Options** | A: 읽기/쓰기 모두 prescriptive B: 읽기/쓰기 모두 autonomous C: 읽기는 autonomous, 쓰기는 prescriptive |
| **Basis** | 읽기는 task context에서 추론 가능하지만, "어디에 쓸까"는 finding의 category에 의존 — task context와 무관 |
| **Analogues** | Unix 철학: read permissions은 넓게, write permissions은 좁게. 비슷한 비대칭 |
| **Knowledge** | CLAUDE.md의 행동 지시 slot은 제한적(HumanLayer: ~150-200). 읽기 라우팅까지 넣으면 slot 낭비 |

**Key lesson**: Agent autonomy의 수준은 작업 유형에 따라 다르다. 정보 소비(읽기)는 자율에 맡기고, 정보 생산(쓰기)은 명시적으로 지시하는 것이 효율적이다.

## 5. Expert Lens

> Run `/retro --deep` for expert analysis.

## 6. Learning Resources

> Run `/retro --deep` for learning resources.

## 7. Relevant Skills

### Installed Skills

- **clarify** — 이번 세션에서 적극 사용. 3개 외부 글과 코드베이스 분석을 병행하여 스코프 확정
- **plugin-deploy** — D(slack-send.sh)와 E1(commit-orphans.sh) 변경 시 version bump 필요 여부 검토에 활용 가능했으나 미사용. 이번은 feature branch라 deploy 불필요
- **refactor** — C2 문서 구조 개편 후 `--docs` 모드로 cross-reference 정합성 검증에 활용 가능했음

### Skill Gaps

- **codex 위임 스킬**: `codex exec`에 스펙을 전달하고 결과를 검증하는 패턴이 반복될 것. 현재는 수동으로 Bash에서 호출. `cwf:impl` 스킬이 codex 위임을 내장하면 스펙 작성 → 위임 → 검증 → 커밋 플로우가 자동화됨. S13.6의 full CWF protocol 설계에서 반영할 후보.
