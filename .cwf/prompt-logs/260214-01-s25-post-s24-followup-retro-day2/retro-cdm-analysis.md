# S25 Follow-up Day2 CDM 분석

세션 요약(Sections 1-3)을 근거로, 방향을 바꾼 임계 의사결정 4건을 CDM 프로브로 분석했다.

### CDM 1: 과업 범위를 `S25 후속`에서 `저장소 전반 하드닝`으로 확장

| Probe | Analysis |
|-------|----------|
| **Cues** | 요약에 따르면 목표가 "`S25 follow-up`에서 `AGENTS.md, setup/refactor skill, markdown lint, link policy, git hook gate`까지" 확장되었다. 또한 사용자 메시지 패턴이 반복적으로 "`less-is-more`, `what/why over how`, `deterministic automation over prose`"를 강조해, 국소 수정으로는 종료되지 않는 신호를 줬다. |
| **Goals** | (1) 단기적으로 S25 후속 이슈를 닫는 것과 (2) 중장기적으로 문서/워크플로 드리프트를 줄이는 것 사이의 목표 충돌이 있었다. |
| **Options** | A안: S25 후속 범위만 최소 수정, B안: 영향 파일만 부분 보강, C안: 문서 구조+검증 게이트+설치 UX까지 함께 하드닝. |
| **Basis** | 실제 구현 결과가 C안으로 수렴했다. 요약의 "대규모 문서/워크플로 하드닝", "hook/lint scope 재논의 후 수렴"은 범위 확장이 의도적 판단이었음을 보여준다. |
| **Situation Assessment** | 문제를 "개별 문서 품질"이 아니라 "정책 전달 방식(서술)과 강제 방식(자동화) 불일치"로 재정의한 점이 핵심이었다. 이 재정의가 이후 모든 변경 축을 일관되게 만들었다. |
| **Hypothesis** | A안(최소 수정)을 택했다면 AGENTS 중복, 링크 경계 위반, 훅 미설치 같은 재발 이슈가 다음 세션으로 이월됐을 가능성이 높다. |
| **Time Pressure** | 범위 확장은 즉시 비용(수정면적/검증비용)을 증가시켰지만, 반복 ping-pong 비용을 줄이는 쪽을 선택했다는 점에서 시간 압박 하의 장기 최적화 결정이었다. |

**Key lesson**: 반복 피드백이 동일 원칙 위반을 가리킬 때는 티켓 범위보다 시스템 경계(문서 구조, 검증, 설치 경로)를 먼저 재정의하라.

### CDM 2: AGENTS.md를 `불변 원칙/편집 전 가이드/문서 맵` 3계층으로 재구성

| Probe | Analysis |
|-------|----------|
| **Cues** | 요약의 "중복/저신호 AGENTS 내용 제거를 위해 여러 번 반복", "docs-entry 명확화"가 직접 트리거였다. |
| **Goals** | (1) 런타임 불변식의 안정성 유지, (2) 편집 절차 안내의 실용성 확보, (3) 탐색 인덱스 가독성 확보를 동시에 달성해야 했다. |
| **Options** | A안: 기존 장문 유지, B안: 대폭 축약만 수행, C안: 책임 경계를 분리(Operating Invariants vs Before Editing Docs vs Document Map)하고 위치를 재배치. |
| **Basis** | 최종 결과가 C안이다. 요약에 명시된 "trimmed/reframed"와 "docs-entry clarified"는 단순 축약이 아니라 정보 아키텍처 재설계였음을 보여준다. |
| **Knowledge** | 사용자 원칙 "`what/why over how`", "`less-is-more`"가 설계 기준으로 직접 작동했다. 즉, '설명량'이 아니라 '의사결정에 필요한 신호밀도'가 선택 기준이 되었다. |
| **Aiding** | Document Map과 스코프 문서(운영 불변식 vs 구현 상세 분리)가 체크리스트 역할을 하며, 중복 문구를 구조적으로 제거하는 기준점이 됐다. |
| **Experience** | 숙련도가 낮으면 장문 보강으로 안정감을 얻으려 하지만, 숙련된 판단은 "규칙은 짧게, 실행 세부는 링크로"라는 분리 전략을 우선한다. |

**Key lesson**: 운영 규범 문서는 "규칙의 총량"이 아니라 "책임 경계의 선명도"로 품질을 측정해야 한다.

### CDM 3: 정책 집행을 `prose reminder`에서 `deterministic gate`로 이전

| Probe | Analysis |
|-------|----------|
| **Cues** | 사용자 핵심 요구가 "`deterministic automation over prose reminders`"였고, 실제로 "hook/lint scope와 gate placement를 여러 차례 재검토"했다는 요약이 집행 방식 전환의 근거였다. |
| **Goals** | (1) 정책 위반의 사전 차단, (2) 개발자 마찰 최소화, (3) 설치/운영 경로 단일화(single-entry setup UX)라는 상충 목표를 조율해야 했다. |
| **Options** | A안: 문서 규칙만 강화, B안: CI에서만 검사, C안: markdownlint 커스텀 룰 + 로컬 git hooks(pre-commit/pre-push) + setup에서 설치모드/게이트프로필 제어. |
| **Basis** | 결과는 C안으로 구현되었다. 요약의 "plugin boundary link/SKILL frontmatter schema 룰 추가", "staged/repo-wide deterministic checks", "setup script로 git-hook install mode 설정"이 선택 근거를 뒷받침한다. |
| **Tools** | 사용 도구 축은 `markdownlint custom rules`, `.githooks`(pre-commit/pre-push), 설치 스크립트 기반 모드/프로필 제어였다. 즉 정책-검증-배포가 하나의 체인으로 연결됐다. |
| **Situation Assessment** | 의도-결과 간격(intent-result gap)을 줄이는 방향이 정확했다. "문서에 써놨지만 지켜지지 않음" 문제를 "커밋/푸시 경로에서 자동 차단"으로 전환했기 때문이다. |
| **Hypothesis** | B안(CI-only)이었다면 로컬 피드백 지연으로 수정 왕복이 늘고, A안은 재발을 막지 못해 동일 원칙 충돌이 반복됐을 가능성이 높다. |

**Key lesson**: 반복 위반 정책은 문서 문구를 고치는 대신, 커밋 경로에 결정적 게이트를 삽입해 '실행 시점'에 강제하라.

### CDM 4: 디렉터리 날짜 혼선(`260213` vs `260214`)을 롤오버 프로토콜 이슈로 격상

| Probe | Analysis |
|-------|----------|
| **Cues** | 요약의 "directory-date semantics confusion ... required protocol clarification"이 직접 신호였다. 단순 오타가 아니라 세션 경계 해석 충돌이 발생했다. |
| **Goals** | (1) 세션 산출물의 날짜 일관성 유지, (2) 자정 경계/다음날 작업의 추적 가능성 확보, (3) 이후 자동화 스크립트와의 정합성 확보가 목표였다. |
| **Options** | A안: 이번 건만 수동 정정, B안: 관례로만 공유, C안: 날짜 롤오버 동작을 명시적 프로토콜로 정의해 재사용. |
| **Basis** | "프로토콜 명확화가 필요했다"는 결론 자체가 C안 선택을 의미한다. 혼선을 개별 사건으로 닫지 않고 규칙으로 승격한 점이 결정적이었다. |
| **Situation Assessment** | 문제를 파일명 실수로 축소하지 않고, 운영 의미론(언제 '오늘'로 간주하는가)의 결손으로 판단한 것이 정확했다. |
| **Tools** | 세션 체크 스크립트/경로 규칙과 결합 가능한 형태로 정리해야 향후 검증 자동화가 가능하다. 즉, 명명 규칙과 검증 스크립트의 인터페이스 관점이 중요했다. |
| **Experience** | 경험이 적으면 즉시 rename으로 종료하지만, 경험 많은 접근은 경계조건(자정 전후, 연속 세션)을 문서+검증 규칙으로 함께 고정한다. |

**Key lesson**: 경계 시점(날짜/단계 전환)에서 생긴 혼선은 예외 처리로 끝내지 말고, 의미론을 프로토콜과 검증 규칙으로 승격하라.

<!-- AGENT_COMPLETE -->
