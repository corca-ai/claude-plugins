# Lessons — S13.5-B Expert-in-the-Loop + Remaining Workstreams

### Haiku advisory sub-agent의 "질문 되돌리기" 문제 — phase context가 failure/signal을 결정

- **Expected**: advisory α/β sub-agent(haiku)가 T3 결정 포인트에 대해 즉시 advisory output을 생산할 것
- **Actual**: 두 에이전트 모두 "Before I proceed, please clarify the scope..." 하며 질문만 되돌림. Output 없이 종료
- **Fix**: (1) "DO NOT ask questions" 명시적 제약 (2) T3-1 예시를 미리 채워 형식 시범 (3) 각 항목의 position/evidence 요약 제공
- **Takeaway**: sub-agent가 질문을 되돌리는 것이 failure인지 signal인지는 phase context에 따라 다름. Advisory phase에서는 failure (input이 이미 충분), Research/Analysis phase에서는 signal (boundary awareness)

When advisory sub-agent 프롬프트 작성 → 출력 형식 예시를 1개 이상 pre-fill하고, "No questions, no preamble" 제약 명시. Haiku는 open-ended 프롬프트에서 확인 루프에 빠지기 쉬움

### Expert advisor guide를 expert-lens-guide.md와 분리한 설계 판단

- **Expected**: expert-lens-guide.md를 확장하여 clarify/review 모드를 추가하면 될 것
- **Actual**: expert-lens-guide.md는 retro deep mode에 특화되어 있음 (CDM 결과 의존, Section 5 output format). 같은 파일에 3개 모드를 넣으면 복잡도가 급증하고, retro sub-agent 프롬프트가 불필요한 clarify/review context를 읽게 됨
- **Takeaway**: 공유 가이드(expert-advisor-guide.md)는 새로 만들고, retro 전용(expert-lens-guide.md)은 유지하되 "future migration" 경로를 명시. 패턴이 안정되면 통합하는 점진적 접근이 건강함

When 기존 reference guide 확장 vs 새 가이드 생성 → 기존 가이드의 consumer가 1개(특화)인지 N개(범용)인지가 판단 기준. 특화된 가이드를 강제로 범용화하면 모든 consumer에 불필요한 복잡도가 전파됨

### Review 스킬의 verdict logic이 reviewer-count-agnostic 설계의 가치

- **Expected**: 4→6 리뷰어 확장 시 verdict logic 수정이 필요할 것
- **Actual**: Phase 4.1 verdict rules가 "Any unchecked criterion", "Any Concern with severity" 등 개수 무관한 조건으로 설계되어 있어 수정 불필요
- **Takeaway**: S5b에서 "reviewer-count-agnostic" 주석을 명시적으로 남긴 것이 이번 확장을 무마찰로 만듦. 확장 가능성이 예상되는 로직에 "agnostic" 설계를 적용하고, 그 의도를 주석으로 남기는 것이 미래 세션의 작업량을 줄임

When 리뷰/합성 로직 설계 → 입력 개수에 무관한 조건(any/all/none)으로 작성하고, "count-agnostic" 의도를 주석에 명시

### Context clear 후 프로토콜 유실 — plan.md의 구조적 한계

- **Expected**: clarify → spec → context clear → impl에서 프로토콜이 유지될 것
- **Actual**: plan.md가 WHAT(무엇을 만들지)은 잘 전달하지만 HOW(어떻게 작업할지 — 프로토콜, 규칙, 읽어야 할 references, "하지 마라" 목록)가 유실됨
- **근본 원인**: plan.md는 스펙 문서로 설계됨. 작업 맥락(protocols, conventions, session rules)은 plan의 관심사가 아님
- **결정**: plan template 확장이 아닌 **phase handoff** 접근 채택. handoff 스킬에 "phase handoff" 모드를 추가하여, clarify/spec 종료 시 구현을 위한 맥락 전달 문서를 생성. plan은 WHAT, phase handoff는 HOW — 관심사 분리

When spec → impl 전환 시 맥락 전달 → phase handoff 문서로 HOW를 별도 전달. plan.md에 더 얹지 않음

### Retro 기본 모드 판단 — "Default bias: Light"의 문제

- **Expected**: 아키텍처 결정이 다수인 세션에서 deep retro가 자동 선택될 것
- **Actual**: SKILL.md의 "Default bias: Light. When in doubt, choose light."를 기계적으로 따라 light로 판단. 유저가 지적 후 deep으로 변경
- **근본 원인**: retro SKILL.md가 비용 절감 목적으로 light를 기본값으로 설정. 하지만 실제로 retro를 호출하는 시점은 이미 "세션 분석이 가치있다"고 판단한 후이므로, 기본값이 light일 이유가 약함
- **Takeaway**: `--light`를 명시적으로 지정하지 않았으면 deep으로 가야 함. "When in doubt, choose light"가 아니라 "When in doubt, choose deep" — retro를 호출한 것 자체가 분석 의도의 신호

When retro 모드 판단 → `--light` 명시가 없고 light하다고 판단하지 않았으면 deep. 비용 절감은 유저가 `--light`로 명시적으로 선택
