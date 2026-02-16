### Expert alpha: W. Edwards Deming

**Framework**: 조직 성과를 개인 탓이 아닌 시스템 설계의 결과로 보고, 변동(common/special cause)을 구분해 장기적 학습 루프(PDSA)로 개선하는 관리 철학.
**Source**: W. Edwards Deming, *Out of the Crisis* (MIT Press, 1986; 특히 14 Points, pp.23-24), *The New Economics for Industry, Government, Education* (MIT Press); Deming Institute의 14 Points/SoPK 정리.
**Why this applies**: 이번 세션의 핵심 결정들은 개별 실패 대응이 아니라 워크플로 시스템 재설계(세션 분기, 의존성 계약 변경, SoT 전파 게이트)였다. 이는 Deming이 말한 "시스템을 바꾸지 않으면 같은 문제가 반복된다"는 관점과 정확히 맞닿아 있다.

토큰 한계 반복 후 세션 디렉토리를 분기한 결정(CDM 1)은, 현장 소방(firefighting)보다 시스템 안정성을 우선한 점에서 타당했다. Deming 관점에서 이는 단기 산출량 최적화가 아니라 "constancy of purpose"를 지킨 사례다. 같은 컨텍스트 압박을 계속 받는 환경에서 기존 세션을 유지했다면, 변동(압축/누락 리스크)에 대해 운영자가 과잉반응하거나 늦게 반응하는 "tampering"이 누적됐을 가능성이 높다.

누락 의존성을 경고-only에서 "설치 질의→설치 시도→1회 재시도"로 바꾼 결정(CDM 2)은, 결과 지표가 아니라 공정 자체를 개선한 조치다. 이는 14 Points의 "inspection 의존 중단"과 "시스템의 지속 개선"에 부합한다. 또한 README.ko를 SoT로 먼저 고정하고 전파를 검증한 결정(CDM 3), 그리고 deep retro 계약 누락을 즉시 백필한 결정(CDM 4)은 부서/문서 단절을 줄이고 학습 루프를 닫았다는 점에서 "break down barriers"와 "the transformation is everybody's job"에 가깝다. 다만 이번 세션은 계약 정합성 확인이 후행적으로 수행된 구간이 있어, 변동의 신호를 더 이른 시점에 통계적으로 식별하도록 게이트 설계를 앞당길 여지가 남아 있다.

**Recommendations**:
1. 세션 시작 게이트에 `dependency readiness`와 `deep-mode artifact completeness`를 체크리스트가 아닌 실행형 검증으로 넣고, 실패 시 즉시 설치/복구 질의를 강제하라. (시스템 원인 제거 우선)
2. `README.ko SoT 잠금 → 영문/스킬 문서 전파 확인`을 단일 PDSA 사이클로 표준화하고, 각 사이클 종료 시 누락률/재작업 시간을 기록해 다음 세션의 공통원인 개선 데이터로 축적하라.

<!-- AGENT_COMPLETE -->
