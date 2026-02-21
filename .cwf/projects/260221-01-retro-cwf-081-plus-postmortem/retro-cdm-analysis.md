## Section 4. Critical Decision Analysis (CDM)

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
| **Cues** | `plugins/cwf/scripts/check-run-gate-artifacts.sh`는 `review-code/refactor/retro/ship` 산출물 존재, 헤더 패턴, sentinel(`<!-- AGENT_COMPLETE -->`)을 검사한다. 반면 `update` 단계의 semantic assertion(시장 최신 버전 일치, nested 제약 분기 등)은 없다. |
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

<!-- AGENT_COMPLETE -->
