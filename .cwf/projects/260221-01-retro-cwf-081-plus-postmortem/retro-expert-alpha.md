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

<!-- AGENT_COMPLETE -->
