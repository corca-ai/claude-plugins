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

<!-- AGENT_COMPLETE -->
