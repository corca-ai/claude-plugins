# Retro: retro-cwf-081-plus-postmortem

- Session date: 2026-02-21
- Mode: deep

## 1. Context Worth Remembering

- 이번 회고의 직접 트리거는 사용자 환경에서 `cwf:update`가 `Current=Latest=0.8.2`로 보였지만, 동일 환경에서 `claude plugin update cwf@corca-plugins`는 `0.8.7`까지 정상 업데이트된 불일치다.
- post-`0.8.1` 구간(`0.8.2`~`0.8.8`)은 기능 추가와 런타임 하드닝이 매우 빠르게 진행되었고, 안정화 우선순위가 주로 timeout/무출력 잔여 리스크(`K46`, `S10`)에 집중됐다.
- `update` 경로의 핵심 리스크는 “오라클 불일치”다. 구현은 캐시 스냅샷을 최신 버전 근거로 사용했는데, 실사용 관점의 진실원천은 마켓플레이스 메타데이터/업데이트 결과다.
- 이전 감사 산출물에서 이미 update 포터빌리티/판정 취약성이 경고되었지만, 런타임 안정화 작업군에 밀려 하드 게이트로 승격되지 못했다.

## 2. Collaboration Preferences

- 사용자는 복잡한 방어적 UX보다 “실제 동작 중심”을 선호한다. 이번 요청도 `scope 확인 -> 즉시 update -> changelog opt-in`처럼 최소 단계와 명확한 결과를 요구했다.
- 문제 논의 방식도 동일했다. “원인 추정”보다 “실제 명령/출력 증거”를 기준으로 판단하고, 불필요한 설명보다 개선된 운영 흐름을 빠르게 확정하는 협업 스타일이다.
- 이번 세션에서 유효했던 응답 방식은 다음과 같다:
  - 재현 출력을 바로 근거로 채택
  - 기존 구현 범위와 사용자 기대 경로를 분리해 설명
  - 설계 변경은 즉시 문서/버전/게이트까지 일괄 반영

### Suggested Agent-Guide Updates

- 없음. 이번 이슈의 1차 소유는 `owner=plugin`이며, 로컬 AGENTS 정책 추가보다 `plugins/cwf`의 판정 로직/게이트 강화가 우선이다.

## 3. Waste Reduction

### 낭비 1: 최신 버전 판정 오라클 불일치로 인한 재진단 왕복

증상:
- 캐시 기반 latest 판정이 실사용 최신 버전과 어긋나 사용자가 수동 `claude plugin update`로 우회.

5 Whys:
1. 왜 어긋났나? `latest`를 캐시 파일 탐색 결과로 판정했기 때문이다.
2. 왜 캐시를 진실원천처럼 썼나? 로컬 결정론/단순 구현이 우선순위를 가졌다.
3. 왜 교차검증이 없었나? update 의미론 검증이 run/release 하드 게이트에 독립 항목으로 없었다.
4. 왜 게이트가 없었나? 릴리스 위험 관리가 timeout/무출력 안정화에 집중됐다.
5. 왜 우선순위가 기울었나? 사용자 체감 정확도 지표(`latest 판정 정합성`)가 별도 추적 지표로 정의되지 않았다.

구조 원인:
- 의미론 품질 지표 부재 + 캐시 프록시의 과신.

### 낭비 2: nested 컨텍스트 결과를 실사용 대표값처럼 소비

증상:
- nested 세션에서 marketplace refresh 불가인데도 cached parity로 사실상 “업데이트 불필요” 인상을 줄 수 있는 출력 경로가 유지됨.

5 Whys:
1. 왜 nested 결과가 확정처럼 쓰였나? 상태 모델이 `UP_TO_DATE`/`UNVERIFIED`를 분리하지 않았다.
2. 왜 상태 분리가 없었나? 불확실성 노출보다 흐름 연속성을 우선했다.
3. 왜 흐름 연속성이 우선됐나? smoke 자동화 안정성 요구가 강했다.
4. 왜 안정성 요구가 균형을 잃었나? 환경 대표성 검증(top-level 실사용 경로)이 릴리스 필수 체크가 아니었다.
5. 왜 필수 체크가 아니었나? “실행 가능”과 “실제 사용자 경로에서의 정합성”을 구분한 체크리스트가 부족했다.

구조 원인:
- 테스트 환경 대표성 계약 미흡.

### 낭비 3: 교훈의 문서화와 강제 적용 사이 단절

증상:
- `Release Metadata Drift` 같은 교훈이 lessons에는 남았지만, 즉시 hard gate로 승격되지 않아 반복 위험이 유지됨.

5 Whys:
1. 왜 반복 위험이 남았나? 교훈이 실행 정책으로 자동 승격되지 않았다.
2. 왜 승격이 안 됐나? 교훈 항목에 owner/apply-layer/기한/검증 조건이 강제되지 않았다.
3. 왜 메타데이터가 없었나? 회고 산출물과 게이트 변경 파이프라인이 느슨하게 연결됐다.
4. 왜 연결이 느슨했나? 릴리스 직전에는 즉시 결함 봉합 작업이 우선되었다.
5. 왜 봉합 우선이 반복됐나? 예방성 변경을 추적하는 별도 완료 조건이 부족했다.

구조 원인:
- retro -> gate 승격 워크플로우 자동성 부족.

### 낭비 4: 사용자 기대 UX와 내부 보수적 흐름 간 괴리

증상:
- 사용자는 즉시 업데이트를 원했지만, 기존 흐름은 update 전 확인 질문/중첩 상태 설명 등으로 경로가 길어졌다.

5 Whys:
1. 왜 경로가 길었나? 안전장치가 상호작용 단계에 집중 배치되었다.
2. 왜 그렇게 설계됐나? 오조작 방지 기준을 보수적으로 잡았다.
3. 왜 보수성의 비용이 커졌나? 정확도 문제는 유지된 채 UX만 복잡해졌다.
4. 왜 정확도와 UX를 분리하지 못했나? 핵심 위험(오라클 정합성)보다 절차적 확인에 자원이 배분됐다.
5. 왜 자원 배분이 그렇게 됐나? 위험 우선순위 모델에 사용자 체감 불일치 비용이 낮게 반영됐다.

구조 원인:
- 리스크 우선순위 모델에서 UX-정확도 결합비용 과소평가.

## 4. Critical Decision Analysis (CDM)

### CDM 1: `latest_version` 오라클을 캐시 스냅샷으로 고정한 결정

| Probe | Analysis |
|-------|----------|
| **Cues** | `plugins/cwf/skills/update/SKILL.md` Phase 1.3는 `cache_roots`를 순회해 `ls -1dt "$cache_root"/*/cwf/*/.claude-plugin/plugin.json | head -n1` 결과를 `latest_plugin_json`으로 채택한다. 즉, 최신성 판단의 1차 근거가 marketplace manifest가 아니라 로컬 캐시 파일 시각/경로다. |
| **Goals** | 목표는 (1) scope-aware 업데이트를 유지하면서 (2) 빠르게 `Current version` vs `Latest version`을 비교해 자동 업데이트 여부를 결정하는 것이었다 (`plugins/cwf/skills/update/SKILL.md`). |
| **Options** | 선택지는 최소 3개였다: A) 캐시 기반 단일 판정(현재 선택), B) 캐시 + 원본 소스(예: marketplace manifest/API) 교차검증, C) 원본 소스 불가 시 `unknown latest`로 fail-closed. |
| **Basis** | 당시 구현은 결정론적 로컬 접근성과 실행 단순성에 가중치를 두었다. 이 선택은 `plugins/cwf/skills/update/references/scope-reconcile.md`의 캐시 루트 확장 정책과 결합되어 “찾을 수 있는 최신 캐시”를 사실상 최신 버전으로 간주했다. |
| **Situation Assessment** | 사후 증거에서 오판이 확인됐다. `.cwf/projects/260221-01-retro-cwf-081-plus-postmortem/retro-sections-1-3-summary.md`는 실제 사용자 환경에서 `cwf:update`가 stale한 `Current == Latest`를 출력했지만 direct `claude plugin update`는 성공했다고 기록한다. |
| **Hypothesis** | B 또는 C를 택했다면, post-`0.8.1` 구간의 버전 진행(`0.8.2`~`0.8.8`, 같은 요약 파일) 중 적어도 일부에서 “업데이트 없음” 오판 대신 “검증 불충분/업데이트 필요”로 분기됐을 가능성이 높다. |
| **Aiding** | `latest_version` 판정 체크리스트에 “캐시는 후보, 원본은 오라클” 불변식을 추가하고, 불일치 시 종료 코드를 분리(`INCONCLUSIVE`)했어야 한다. |

**Key lesson**: 업데이트 시스템에서 캐시는 성능 계층이지 진실 계층이 아니다. `latest`는 반드시 authoritative source로 확정하고, 불가하면 성공 판정을 금지해야 한다.

### CDM 2: nested 세션에서 marketplace refresh 불가 시에도 캐시 동등값을 최종 결론으로 채택한 결정

| Probe | Analysis |
|-------|----------|
| **Cues** | `.cwf/projects/260219-01-pre-release-audit-pass2/iter2/artifacts/skill-smoke-260219-145730-postfix/12-update_.log`에 `claude plugin marketplace update`가 nested 세션에서 blocked 되며, 그럼에도 `Current version: 0.8.0 / Latest version: 0.8.0 (cached)` 후 `No update needed`가 출력됐다. |
| **Goals** | smoke/자동화 흐름을 끊지 않고 종료 가능한 판정을 제공하려는 목표와, 최신성 판정의 정확성 목표가 충돌했다. |
| **Options** | A) 현재처럼 cached parity로 종료, B) nested에서 refresh 실패 시 즉시 중단 + top-level 재실행 요구, C) 결과 상태를 `unknown`으로 남기고 mutation 금지. |
| **Basis** | 구현/운영은 연속 실행성(파이프라인 지속)을 우선했다. 그러나 로그 자체가 “marketplace refresh unavailable”을 선언하면서도 최종 결론을 확정해, 불확실성을 성공 케이스로 흡수했다. |
| **Time Pressure** | 비대화형 smoke 문맥에서는 빠른 판정 압력이 강했다. `.cwf/projects/260219-01-pre-release-audit-pass2/lessons.md`의 여러 항목이 timeout/NO_OUTPUT 대응에 집중된 점도 동일 압력을 뒷받침한다. |
| **Situation Assessment** | 상황 인식은 부분적으로 정확했다(“definitive check는 top-level에서 필요” 문구 존재). 다만 상태 모델이 이 인식을 실행 결과에 반영하지 못해, 사용자 관점에선 “업데이트 불필요”로 오해될 여지를 남겼다. |
| **Aiding** | verdict를 `UP_TO_DATE`/`OUTDATED`/`UNVERIFIED` 3상태로 강제하고, `UNVERIFIED`에서는 성공 메시지와 무변경 결론 출력을 금지하는 게이트가 필요하다. |

**Key lesson**: 외부 동기화가 막힌 상태에서의 “동등 비교”는 결론이 아니라 보류 신호다. 불확실성은 성공으로 포장하지 말고 상태로 노출해야 한다.

### CDM 3: run gate를 산출물 형식 검증 중심으로 유지하고 update 의미론 검증을 제외한 결정

| Probe | Analysis |
|-------|----------|
| **Goals** | 게이트의 결정론/속도/재현성을 높여 파이프라인 안정성을 확보하려는 목표가 있었다. |
| **Options** | A) 형식 중심 게이트 유지(현재), B) 형식 + 핵심 의미론(버전 오라클 일치, scope별 e2e) 혼합 게이트, C) update 전용 별도 hard gate 추가. |
| **Basis** | 산출물 검증은 구현/운영 비용이 낮고 flaky 위험이 적다. 실제로 `.cwf/projects/260219-01-pre-release-audit-pass2/lessons.md`의 Run Gate Violation 기록도 `refactor-summary` 헤더, `retro.md` Mode 누락처럼 형식 위반 중심으로 관리됐다. |
| **Tools** | 사용 도구는 artifact gate 스크립트 하나에 집중되었고, update 경로의 oracle 정확성 검증 도구(예: marketplace truth cross-check fixture)는 부재했다. |
| **Hypothesis** | B 또는 C를 적용했다면 `cwf:update latest-version mismatch`는 post-`0.8.1` 릴리스 체인에서 더 이른 시점에 차단됐을 가능성이 높다. |
| **Experience** | 경험 많은 릴리스 엔지니어는 “문서/산출물 완결성”과 “사용자 체감 동작 정확성”을 분리 게이트로 운영한다. 현재 구조는 전자에 치우쳐 있었다. |

**Key lesson**: 게이트는 문서 완결성만으로 충분하지 않다. 사용자에게 직접 영향을 주는 의미론(여기서는 최신 버전 판정)은 별도 하드 게이트로 독립시켜야 한다.

### CDM 4: `Release Metadata Drift` 교훈을 기록했지만 즉시 강제 게이트로 승격하지 않은 결정

| Probe | Analysis |
|-------|----------|
| **Cues** | `.cwf/projects/260219-01-pre-release-audit-pass2/lessons.md`는 `Iteration 2 Lesson — Release Metadata Drift`에서 `plugin.json`과 `.claude-plugin/marketplace.json` 불일치 위험, 그리고 `plugin-deploy` consistency check 필요를 이미 명시했다. |
| **Goals** | 당시 목표는 다수의 runtime 이슈(timeout, NO_OUTPUT, hook 계약 drift)와 릴리스 진행을 병행 처리하는 것이었다. |
| **Options** | A) lesson으로만 보관(현재), B) 즉시 pre-release hard gate에 `check-consistency.sh cwf`를 필수화, C) B + update e2e 회귀 테스트를 같은 릴리스 체크리스트에 결합. |
| **Basis** | `.cwf/projects/260221-01-retro-cwf-081-plus-postmortem/retro-sections-1-3-summary.md`의 진단처럼 우선순위가 runtime timeout closure(`K46`, `S10`) 쪽으로 기울었고, update 의미론 강화는 후순위가 됐다. |
| **Knowledge** | 팀은 이미 메타데이터 드리프트 위험을 인지하고 재현 가능한 체크 명령까지 확보했다(lessons.md). 즉, 지식 부족이 아니라 적용/강제의 문제였다. |
| **Hypothesis** | B 또는 C를 즉시 적용했다면 `post-0.8.1` 버전 상승 구간에서 “릴리스 메타데이터는 맞지만 update 체감은 어긋나는” 상태를 조기 탐지했을 확률이 높다. |
| **Aiding** | lesson 항목마다 `Owner`, `Promotion Target (soft->hard gate)`, `Due release`를 강제 기입하는 운영 계약이 필요하다. 현재처럼 교훈이 기록만 되고 미전이되는 경로를 닫아야 한다. |

**Key lesson**: 이미 발견된 교훈은 “문서화 완료”가 끝이 아니다. 다음 릴리스 전까지 하드 게이트로 승격되지 않으면 동일 결함이 반복된다.


## 5. Expert Lens

### Expert alpha: Gary Klein

**Framework**: 자연주의적 의사결정(NDM)과 Recognition-Primed Decision(RPD) — 시간 압박·불완전 정보 환경에서 경험 기반 단서 인식 후, 단일 유력안을 정신 시뮬레이션으로 검증하는 접근.
**Source**: Gary Klein, *Sources of Power: How People Make Decisions* (MIT Press, 1998, https://mitpress.mit.edu/9780262611466/sources-of-power/); Gary Klein, “Naturalistic decision making,” *Human Factors* 50(3), 2008, doi:10.1518/001872008X288385 (https://pubmed.ncbi.nlm.nih.gov/18689053/); Gary Klein, “Performing a Project Premortem,” *Harvard Business Review* (September 2007, https://hbr.org/2007/09/performing-a-project-premortem).
**Why this applies**: post-`0.8.1` 버그 윈도우는 nested 제약, 캐시 의존, 빠른 게이트 통과 압력이 겹친 고전적 NDM 상황이다. 대조적으로 예상되는 Kahneman 렌즈가 편향 진단에 무게를 둔다면, 이 렌즈는 “어떤 단서를 패턴으로 읽었고 어떤 정신 시뮬레이션이 생략됐는가”를 본다(참고: Kahneman & Klein, *Am Psychol*, 2009, doi:10.1037/a0016755, https://pubmed.ncbi.nlm.nih.gov/19739881/).

이번 세션에서 잘 작동한 부분은, 팀이 반복되는 운영 마찰을 빠르게 패턴화해 결정론적 대응으로 전환했다는 점이다. `lessons.md`에 남은 `Smoke False PASS Hardening`, `Retro Light Deterministic Fast-Path`, `Setup NO_OUTPUT` 대응은 모두 “현장 단서(cues)를 재사용 가능한 실행 규칙으로 압축”한 사례다. 이는 NDM의 강점과 맞닿아 있다. 즉, 완전한 정보가 없어도 팀이 실제 제약(타임아웃, non-interactive 실패 신호)에서 유효한 조치를 빠르게 선택해 파이프라인 연속성을 지켰다.

문제는 같은 강점이 update 의미론에서는 약점으로 뒤집혔다는 점이다. `12-update_.log`가 이미 “marketplace refresh unavailable in nested session”을 보여줬는데도 `Current == Latest (cached)`를 최종 결론으로 사용했다. RPD 관점에서 보면, 팀은 익숙한 패턴(캐시 동등값 = 무변경)을 즉시 채택했지만, 핵심 정신 시뮬레이션(“top-level 사용자 환경에서 같은 결론이 유지되는가?”)이 빠졌다. 그 결과 post-`0.8.1` 실제 사용자 경로에서 `cwf:update` stale 판정이 발생했고, 직접 `claude plugin update` 성공이라는 반증 신호가 뒤늦게 나타났다.

또 하나의 실패는 “실패 후 학습”이 “다음 릴리스 결정 규칙”으로 승격되지 못한 것이다. `Release Metadata Drift` 교훈은 이미 기록됐지만, update 오라클 정확도(마켓플레이스 진실원천 대조)를 강제하는 하드 게이트로 전환되지 않았다. Klein식으로 말하면, 팀은 경험을 얻었지만 decision requirement(결정 전에 반드시 만족해야 할 검증 조건)를 작업기억 밖의 문서에 남겨두었고, 다음 의사결정 루프에 강제 주입하지 못했다.

**Recommendations**:
1. `cwf:update`에 Premortem 게이트를 추가하라: 릴리스 직전 “이미 stale 판정 장애가 발생했다”고 가정하고, 최소 증거 3가지를 통과해야만 `UP_TO_DATE`를 허용한다. (a) top-level에서 marketplace refresh 성공, (b) authoritative manifest와 reported latest 일치, (c) 하나라도 불가하면 `UNVERIFIED`로 fail-closed.
2. update 의사결정에 NDM 체크포인트를 도입하라: 최종 결론 직전 `반증 단서`와 `환경 전이 시뮬레이션`을 2항목으로 강제 기록하고, 누락 시 gate 실패로 처리한다. 특히 nested/CI 결과를 사용자 현실로 일반화할 때는 “대표성 근거” 없으면 결론 승인을 금지한다.


### Expert beta: Daniel Kahneman

**Framework**: 불확실성 하 인간 판단의 휴리스틱/편향과 `System 1`(빠른 직관) vs `System 2`(느린 숙고) 프레임.
**Source**: Daniel Kahneman, *Thinking, Fast and Slow* (2011, https://us.macmillan.com/books/9780374533557/thinkingfastandslow); Amos Tversky & Daniel Kahneman, “Judgment under Uncertainty: Heuristics and Biases,” *Science* 185(4157), 1974, doi:10.1126/science.185.4157.1124 (https://pubmed.ncbi.nlm.nih.gov/17835457/); Amos Tversky & Daniel Kahneman, “Prospect Theory: An Analysis of Decision under Risk,” *Econometrica* 47(2), 1979, pp.263-292 (https://www.econometricsociety.org/publications/econometrica/1979/03/01/prospect-theory-analysis-decision-under-risk); Nobel Prize in Economic Sciences 2002 facts (https://www.nobelprize.org/prizes/economic-sciences/2002/kahneman/facts/).
**Why this applies**: 이번 세션의 핵심 실패는 불확실한 최신 버전 판정을 프록시 신호(캐시)로 종결한 판단 오류였고, 이는 Kahneman의 휴리스틱 기반 오판 모델과 직접 맞닿아 있다.

post-`0.8.1` 구간에서 잘된 점도 분명했다. 산출물 게이트와 smoke 흐름은 반복 가능한 절차를 제공해 즉흥 판단을 줄였고, `lessons.md`에 `Release Metadata Drift`를 이미 기록한 것은 이상 징후를 탐지하는 감각이 살아 있었다는 증거다. Kahneman 관점에서 보면, 이는 `System 2`를 보조하는 구조(체크리스트/기록)의 초기 형태를 갖춘 상태였다.

실패는 “어려운 질문을 쉬운 질문으로 치환”한 지점에서 발생했다. 실제 질문은 “시장(authoritative source) 기준 최신 버전이 무엇인가?”였는데, 실행은 “로컬 캐시에서 가장 최신 파일이 무엇인가?”로 수렴했다(`retro-sections-1-3-summary.md`, `retro-cdm-analysis.md`). 또 nested 세션에서 marketplace refresh가 막혔는데도 cached 동등값으로 `No update needed`를 확정한 사례는, 1974년 논문이 설명한 “효율적이지만 체계적으로 틀릴 수 있는 휴리스틱”과 동일한 패턴이다.

추가로, `0.8.2`~`0.8.8` 연속 릴리스 구간에서 시간압력(런타임 timeout 대응 우선) 하에 캐시 동등값에 높은 확신을 부여한 것은, Kahneman이 경고한 통계적 사고 회피와 과신 편향의 조합으로 해석된다. 즉, 팀은 절차를 운영했지만 “확신의 질”을 검증하는 장치(오라클 교차검증, 불확실성 상태 분리)가 없어 실사용 환경에서만 오판이 드러났다.

**Recommendations**:
1. `cwf:update`의 성공 판정 전제에 “authoritative latest 확인”을 하드 게이트로 추가하라. marketplace/API/top-level refresh 확인이 실패하면 `UP_TO_DATE`를 금지하고 `UNVERIFIED`로 종료해 사용자에게 재검증 경로를 강제하라.
2. 업데이트 판정 직전에 2문항 bias-check를 의무화하라: “지금 쓰는 신호는 오라클인가 프록시인가?”, “실사용 환경 반례(top-level scope) 1개를 확인했는가?”를 로그에 남기고, 둘 중 하나라도 `no`면 자동 동작을 중단하라.


### Agreement and Disagreement Synthesis

공통 합의(Shared Conclusions):
1. 최신 버전 판정에서 캐시는 진실원천이 아니며, authoritative source 교차검증이 필수다.
2. nested/제약 환경 결과를 실사용 대표값으로 일반화하면 체계적 오판이 생긴다.
3. 교훈 기록만으로는 재발을 막지 못하며, 하드 게이트 승격까지 완료되어야 한다.

명시적 불일치(Disagreements):
1. 우선 개입 지점:
- Klein 렌즈: 의사결정 순간의 반증 시뮬레이션 체크포인트를 먼저 강제.
- Kahneman 렌즈: 편향 방지용 판정 질문/상태모델(`UNVERIFIED`)을 먼저 강제.
- 가정 차이: 실행 행위 개선(행동 설계) vs 판정 프레임 개선(인지 설계) 중 무엇이 선행 효과가 큰가.
2. 운영 전략:
- Klein 렌즈: 현장 패턴 기반 프리모템과 체크포인트로 빠른 적응.
- Kahneman 렌즈: 분류 체계/오라클 정의를 먼저 고정하고 자동화로 일탈 차단.
- 가정 차이: 경험 기반 적응의 민첩성 vs 규칙 기반 일관성의 안정성.

Synthesis Decision:
- 지금 즉시 채택:
  1. `latest` 판정에 `authoritative source` 확인을 하드 게이트로 추가.
  2. refresh 실패/불확실성은 `UNVERIFIED` 상태로 노출하고 자동 성공판정을 금지.
  3. top-level 실사용 경로 update 검증을 릴리스 체크리스트에 추가.
- 보류:
  - 프리모템 템플릿 고도화와 심층 bias-check 문항 확장(운영 부담 대비 효과 검증 필요).
- 추가 증거가 필요:
  - 2주 이상 릴리스/업데이트 로그에서 `UNVERIFIED` 발생 빈도, 오탐/미탐 비율, 사용자 우회율 추세.

## 6. Learning Resources

### 1) 릴리스 엔지니어링 신뢰성 / 배포 신뢰도
- 제목 + URL: Release Engineering (Google SRE Book) — https://sre.google/sre-book/release-engineering/
- 핵심 요약:
  이 장은 릴리스 프로세스를 개별 엔지니어의 수작업이 아니라, 일관된 도구체계와 자동화된 파이프라인으로 다뤄야 한다고 강조한다. 특히 빠른 배포 속도와 높은 안정성을 동시에 달성하려면 빌드/릴리스 단계를 표준화하고 재현 가능하게 만들어야 한다는 점을 명확히 한다. 결과적으로 "무엇이 최신인지" 같은 핵심 판단은 로컬 상태가 아니라 신뢰 가능한 릴리스 메타데이터 체계에 의존해야 한다.
- 이번 0.8.1+ 버그 회고 맥락에서의 적용 포인트:
  `cwf:update`의 최신 버전 판정을 캐시 스냅샷이 아닌 단일 진실원천(마켓플레이스 매니페스트/서명된 릴리스 메타데이터)으로 고정하는 릴리스 불변식을 추가해야 한다. 또한 릴리스 게이트에 "reported latest == marketplace truth" 검증을 필수 항목으로 넣어 배포 신뢰도를 사전에 보장한다.

### 2) 포스트모템 / 사고 학습 품질
- 제목 + URL: Postmortem Culture: Learning from Failure (Google SRE Book) — https://sre.google/sre-book/postmortem-culture/
- 핵심 요약:
  이 문서는 비난 없는(blameless) 포스트모템 문화가 재발 방지의 핵심이라고 설명하며, 개인 책임 추궁보다 시스템적 원인 분석에 집중하도록 안내한다. 또한 포스트모템은 사건 서술로 끝나면 안 되고, 소유자와 기한이 명시된 실행 가능한 후속 조치까지 연결되어야 학습 품질이 올라간다고 강조한다. 좋은 포스트모템은 "무엇이 깨졌는가"뿐 아니라 "왜 그 신호를 놓쳤는가"를 구조적으로 다룬다.
- 이번 0.8.1+ 버그 회고 맥락에서의 적용 포인트:
  이번 건의 핵심인 오라클 불일치(캐시 vs 마켓플레이스)를 포스트모템 템플릿의 고정 항목으로 승격해, 모든 업데이트 회고에서 동일 질문을 강제한다. 후속 액션은 "게이트 추가", "실사용 경로 테스트", "교훈의 소유팀/기한/검증 조건"까지 명시해 재발 방지 완료 여부를 추적 가능하게 만든다.

### 3) 불확실성 하 의사결정 품질 (엔지니어링 팀)
- 제목 + URL: Embracing Risk (Google SRE Book) — https://sre.google/sre-book/embracing-risk/
- 핵심 요약:
  이 장은 신뢰성 의사결정을 절대 안전/절대 속도의 이분법으로 보지 않고, 측정 가능한 리스크 예산(error budget) 관점에서 다루도록 제안한다. 즉, 불확실성이 있는 상황에서도 서비스 목표(SLO)와 현재 리스크 소모량을 기준으로 배포/변경 의사결정을 체계화해야 한다. 핵심은 감(직관) 기반 판단을 줄이고, 팀이 합의한 계량 기준으로 의사결정 품질을 높이는 것이다.
- 이번 0.8.1+ 버그 회고 맥락에서의 적용 포인트:
  업데이트 정확도(최신 판정 정합성)를 별도 SLI/SLO로 정의하고, 허용 오차를 넘으면 기능 확장보다 정합성 복구를 우선하는 의사결정 규칙을 도입한다. 또한 "중첩 세션 결과를 실사용 대표값으로 간주할 수 있는가" 같은 불확실성 항목을 사전 리스크 레지스터로 관리해, 릴리스 전 판단 근거를 명시적으로 남긴다.


## 7. Relevant Tools (Capabilities Included)

### Installed Capabilities

- Skills inventory evidence:
  - marketplace skill files: 68 (`find ~/.claude/plugins -path '*/skills/*/SKILL.md'`)
  - local skill files: 1 (`.claude/skills/plugin-deploy/SKILL.md`)
- Core capabilities used in this retro:
  - `cwf:retro` deep batch flow (sub-agent output persistence)
  - `agent-slot-preflight.sh` for batch launch safety
  - `retro-collect-evidence.sh` for evidence snapshot
  - `check-run-gate-artifacts.sh` for deterministic retro gate
- Available-but-underused in this session:
  - release-time semantic validation dedicated to `cwf:update` latest-version truth path
  - explicit top-level vs nested update-path differential check script

### Tool Gaps

1. Category: Missing validation/reachability check
- Problem signal: update latest-version 판정이 캐시 기반으로 오판 가능.
- Candidate: `plugins/cwf/scripts/check-update-latest-consistency.sh` (신규)
- Integration point: premerge/predeploy gate + `cwf:update --check` 내부 self-check
- Expected gain: 캐시/오라클 불일치 조기 탐지, 사용자 체감 오판 감소
- Risk/cost: 외부 의존(마켓플레이스 접근)으로 테스트 변동성 증가
- Pilot scope: warn mode로 시작 후 2주 관찰 뒤 strict 승격

2. Category: Missing workflow automation (gate policy)
- Problem signal: lessons에 기록된 교훈이 hard gate로 늦게 승격됨.
- Candidate: `retro-to-gate` 승격 체크 규약(신규 문서+스크립트)
- Integration point: `cwf:retro` Phase 7 persist proposal + `scripts/premerge-cwf-gate.sh`
- Expected gain: “기록됨 but 미적용” 반복 감소
- Risk/cost: 초기에 false positive/과도한 게이트 가능성
- Pilot scope: `owner=plugin` high-impact 항목(업데이트/릴리스)만 우선 적용

3. Category: Missing static analysis check/tool
- Problem signal: authoritative source 대신 proxy(cache)로 최신 판정을 확정하는 로직이 리뷰에서 누락.
- Candidate: update skill contract lint (forbidden patterns + required fallback states)
- Integration point: `scripts/check-cwf-authoring-contract.sh` 확장
- Expected gain: 설계 재회귀 방지
- Risk/cost: 규칙 과적합 위험
- Pilot scope: `latest_version` 관련 패턴만 최소 규칙으로 도입

Skill-gap 여부:
- 이번 건은 “새 스킬 부재”보다 “기존 update/gate의 의미론 검증 부족”이 핵심이다.
- `find-skills`/`skill-creator` CLI 명령은 현재 환경에 없음 (`command -v find-skills`, `command -v skill-creator` 결과 없음).
- 따라서 우선순위는 신규 스킬 탐색보다 기존 deterministic gate 강화다.

### Post-Retro Findings (Expanded Scope Re-run)

#### Coverage Matrix (Full Re-run)

- Diff corpus (`git diff --name-only 0.8.1..HEAD`, excluding `.cwf/sessions/**`):
  - Total changed files reviewed: 1067 (`coverage/diff-all-excl-session-logs.txt`)
  - Top-level breakdown: `.cwf` 1021, `plugins` 32, `scripts` 8, plus root/docs/config (`coverage/diff-top-level-breakdown.txt`)
  - Non-`.cwf` changed files fully reviewed: 46, with 2719 insertions / 164 deletions (`coverage/diff-non-cwf.txt`, `coverage/diff-non-cwf-stat.txt`)
  - `plugins/cwf` changed files: 32 (`coverage/diff-plugins-cwf.txt`)
- Historical lessons/retro corpus:
  - Total lesson/retro artifacts found: 64 (`coverage/project-lessons-retro-files.txt`)
  - Primary artifacts reviewed (sandbox excluded): 51 files across 27 projects (`coverage/project-lessons-retro-primary.txt`)
  - Historical signal matches extracted: 145 (`coverage/historical-signals-grep.txt`)
- Current ping-pong context included:
  - 사용자 요구 흐름 확정: `scope 확인 -> update는 즉시 실행(질문 없이) -> changelog는 opt-in`.
  - “0.8.1 이후 전체를 보라”는 범위 요구와 “왜 좁아졌는지 설명” 요구를 회고 범위/원인분석에 반영.

#### Why the Initial Pass Looked Narrow (5 Whys)

1. 왜 27개 파일 중심으로 보였나?
   - 첫 패스가 `plugins/cwf` 변경 27개에 문제 초점을 맞췄기 때문이다.
2. 왜 그 범위를 우선했나?
   - 장애 표면이 `cwf:update` 스킬/스크립트에 직접 연결되어 “원인 근접 코드”를 먼저 파고들었다.
3. 왜 전체 diff(1067개) 병행 명시가 누락됐나?
   - 분석 경로를 “원인 추적 우선”으로 시작했지만, 커버리지 매트릭스를 선행 산출물로 고정하지 않았다.
4. 왜 커버리지 매트릭스가 선행되지 않았나?
   - 회고 절차에서 “문제 집중 분석”과 “범위 증빙”의 순서를 하드 규칙으로 강제하지 않았다.
5. 왜 하드 규칙이 없었나?
   - 기존 retro 게이트가 산출물 존재/형식 중심이고, “요청 범위 충족 증빙” 검증은 자동화되지 않았다.

구조 원인:
- 회고 실행의 초기 단계에 `coverage contract`(요청 범위/제외 범위/총 파일수)를 고정하지 않은 프로세스 결함.

#### Additional Findings from Expanded Corpus

1. 반복 패턴은 단일 버그가 아니라 “신호 승격 실패”다.
- 과거 lessons/retro(51개 primary)에서 `drift`, `timeout`, `NO_OUTPUT`, `fail-open` 신호가 반복되는데, 재발 지점은 “문서화된 교훈이 다음 게이트로 승격되지 않는 구간”에 집중된다.
- `coverage/historical-signals-grep.txt`와 `coverage/historical-signal-file-frequency.txt` 근거.

2. 이번 update 이슈는 동일 패턴의 최신 사례다.
- `Release Metadata Drift`가 이전에 기록됐지만, `latest 판정 오라클 정합성` 검증이 release hard gate로 독립되지 않아 재발 허용 창이 남았다.

3. 핑퐁 구간에서 사용자 기대는 일관되게 “동작 우선 + 설명 opt-in”이었다.
- 즉시 업데이트를 기본 경로로 두고(`ask` 제거), changelog는 선택적으로 노출하는 UX가 실제 운영 선호와 정합한다.

#### Expanded Persist Proposals

1. Finding: retro 시작 시 coverage contract 부재로 분석 범위가 좁아 보이는 리스크.
- Owner: `plugin`
- Apply layer: `upstream`
- Promotion target: `plugins/cwf/scripts/retro-coverage-contract.sh`
- Due release: `0.8.9`
- Recommended tier: `Eval-Hook`
- Mechanism: `cwf:retro` 시작 단계에 `coverage/*.txt` 생성 및 최소 카운트 출력 강제.
- Evidence: `coverage/diff-all-excl-session-logs.txt`, `coverage/diff-top-level-breakdown.txt`.

2. Finding: lessons -> hard gate 승격 지연.
- Owner: `plugin`
- Apply layer: `upstream`
- Promotion target: `plugins/cwf/scripts/check-lessons-metadata.sh` + `scripts/premerge-cwf-gate.sh`
- Due release: `0.8.9`
- Recommended tier: `State` + `Eval-Hook`
- Mechanism: lessons 항목에 `owner/apply-layer/promotion-target/due-release` 메타데이터를 필수 필드로 강제하고 premerge 검사 추가.
- Evidence: historical corpus 51 files + recurring drift/timeout/fail-open matches (`coverage/historical-signals-grep.txt`).

3. Finding: update 최신성 판정 오라클 불일치.
- Owner: `plugin`
- Apply layer: `upstream`
- Promotion target: `plugins/cwf/scripts/check-update-latest-consistency.sh` + `scripts/premerge-cwf-gate.sh`
- Due release: `0.8.9`
- Recommended tier: `Eval-Hook`
- Mechanism: `check-update-latest-consistency` 계열 검증을 premerge/predeploy hard gate로 추가하고, 불확실 시 `UNVERIFIED` 상태 강제.
- Evidence: 사용자 재현(`cwf:update` 0.8.2 stale vs direct `claude plugin update` 0.8.7 성공), 기존 CDM 1/2 근거.
