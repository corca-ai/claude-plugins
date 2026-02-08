# Retro: S11b — Migrate refactor → cwf:refactor

> Session date: 2026-02-08
> Mode: light

## 1. Context Worth Remembering

- CWF 스킬 마이그레이션 패턴이 S7–S11b까지 7회 반복되며 완전히 안정화됨. 플랜에 기재된 대로 실행하면 오차 없음.
- refactor는 5개 모드(quick scan, --code, --skill, --holistic, --docs)가 있는 가장 복잡한 스킬이지만, 마이그레이션 자체는 정형화된 작업.
- parallel sub-agent 설계에서 "perspective-based division"이 핵심 원칙. Deep Review는 structural(1–5) + quality(6–8)로 자연스러운 2분할, Holistic은 3개 독립 차원으로 분할.

## 2. Collaboration Preferences

- 유저는 "commit and next"처럼 간결한 지시를 선호하며, 에이전트가 자율적으로 다음 단계를 파악하길 기대함.
- 세션 완료 후 핸드오프 문서 작성은 당연히 포함된 작업으로 간주 — 명시적 요청 없이도 수행해야 함.
- "Why u couldnt?" — 프로토콜에 명시된 작업을 놓쳤을 때 유저의 신뢰가 떨어짐. 사전 방지가 중요.

### Suggested CLAUDE.md Updates

- `Collaboration Style`에 추가 제안: "세션 완료 시 next-session.md 작성과 master plan 확인은 자동으로 수행. 유저가 'next'라고 하면 다음 세션 핸드오프까지 완성한 뒤 보고."

## 3. Waste Reduction

**핸드오프 누락으로 인한 추가 턴**: "commit and next" 후 에이전트가 유저에게 "다음 뭘 하실 건가요?"라고 되물었음. 유저가 직접 master plan을 확인하라고 지시하는 추가 턴이 발생.

**5 Whys 분석**:
1. 왜 핸드오프를 자동 작성하지 않았나? → "next"를 "다음 뭘 할지 물어보기"로 해석
2. 왜 그렇게 해석했나? → master plan과 next-session.md 패턴을 세션 중 능동적으로 참조하지 않음
3. 왜 참조하지 않았나? → 구현 완료 → 커밋이 "끝"이라고 인식
4. 왜 그렇게 인식했나? → CLAUDE.md의 "register session in cwf-state.yaml and run check-session.sh"가 최종 단계로 보임. 핸드오프 문서 작성은 명시되지 않음.
5. 근본 원인: **CLAUDE.md Plan Mode 섹션에 핸드오프 문서 작성 단계가 없음**. check-session.sh가 next-session.md를 검증하지만, 그 전에 작성하라는 지시가 빠져있음.

**분류**: Process gap — CLAUDE.md에 "After implementation" 체크리스트가 불완전.

**권장 조치**: CLAUDE.md `Plan Mode` 섹션을 확장하여 핸드오프 문서 작성을 명시. 또는 더 나은 방법: check-session.sh가 next-session.md FAIL을 내므로, "Fix all FAIL items" 지시를 제대로 따르면 자연히 해결됨. 이번에는 check-session.sh의 FAIL을 "세션 진행 중이라 예상된 결과"로 무시한 것이 문제. 실제로는 next-session.md를 작성하고 나서 check-session.sh를 돌려야 함.

## 4. Critical Decision Analysis (CDM)

### CDM 1: check-session.sh FAIL 무시 판단

| Probe | Analysis |
|-------|----------|
| **Cues** | check-session.sh가 retro.md, next-session.md 누락으로 FAIL 반환 |
| **Goals** | 구현 완료 확인 vs 세션 아티팩트 완성 |
| **Options** | (A) FAIL을 "세션 진행 중" 사유로 수용, (B) retro.md/next-session.md를 먼저 작성 후 재실행 |
| **Basis** | retro와 next-session은 세션 종료 시점 산출물이므로 구현 중 없는 것이 정상이라고 판단 |
| **Situation Assessment** | 부분적으로 맞음 — retro.md는 세션 끝에 생성하지만, next-session.md는 구현 완료 직후 작성 가능하고 작성해야 함 |
| **Aiding** | check-session.sh를 2단계로 분리하면 도움: (1) 구현 완료 체크 (plan.md, lessons.md), (2) 세션 종료 체크 (retro.md, next-session.md) |
| **Hypothesis** | 옵션 B를 택했다면 next-session.md를 먼저 작성하고, 유저의 "next" 요청에 바로 핸드오프를 제시할 수 있었음 |

**Key lesson**: check-session.sh FAIL은 무시 대상이 아님. "세션 진행 중"이라는 사유는 retro.md에만 적용 가능하고, next-session.md는 구현 직후 작성할 수 있으므로 FAIL 발생 시 가능한 항목부터 해결해야 함.

### CDM 2: Deep Review 에이전트 수 결정 (2 vs 3)

| Probe | Analysis |
|-------|----------|
| **Cues** | review-criteria.md의 8개 기준을 분할해야 함 |
| **Knowledge** | S11a retro의 2-batch 설계 경험, agent-patterns.md의 perspective-based division 원칙 |
| **Options** | (A) 2 에이전트: structural(1–5) + quality(6–8), (B) 3 에이전트: mechanical(1–3) + structural(4–5) + quality(6–8) |
| **Basis** | 기준 1–5는 모두 구조적/기계적(카운트, 경로, 파일 스캔), 6–8은 정성적/판단. 자연스러운 2분할. 3분할하면 한 그룹이 2개만 담당하여 비효율 |
| **Analogues** | Holistic은 3개 독립 차원이 명확해서 3 에이전트가 자연스러움. Deep Review는 그런 명확한 3분할 경계가 없음 |

**Key lesson**: 에이전트 수는 "작업의 자연스러운 경계"에 맞춰야 함. 숫자를 먼저 정하고 작업을 나누면 불균형이 생김.

## 5. Expert Lens

> Run `/retro --deep` for expert analysis.

## 6. Learning Resources

> Run `/retro --deep` for learning resources.

## 7. Relevant Skills

### Installed Skills

- **cwf:refactor** (방금 마이그레이션 완료): S13에서 `cwf:refactor --holistic`을 CWF 전체에 실행할 예정. 이번 세션에서 만든 parallel sub-agent 설계가 그때 실전 테스트됨.
- **cwf:handoff** (S12 예정): 이번 세션에서 수동 작성한 next-session.md를 자동화할 스킬. S12에서 구축되면 이번 같은 핸드오프 누락 문제가 구조적으로 해결됨.

### Skill Gaps

cwf:handoff가 S12에서 구현되면 핸드오프 자동화 갭이 해소됨. 추가 스킬 갭은 식별되지 않음.
