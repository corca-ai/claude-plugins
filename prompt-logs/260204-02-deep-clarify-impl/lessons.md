# Lessons: deep-clarify Implementation

## Reference guide pattern: role → context → methodology → constraints → output

- **Expected**: Each reference guide needs unique structure tailored to its purpose
- **Actual**: The suggest-tidyings tidying-guide.md pattern (role statement → context → methodology → constraints → output format) works well for all four guides despite very different purposes (research, aggregation, advisory)
- **Takeaway**: When creating sub-agent instruction documents, the role → context → methodology → constraints → output pattern is a reliable skeleton

When writing sub-agent reference guides → start with the role/context/methodology/constraints/output skeleton, then customize

## SKILL.md as orchestrator vs executor

- **Expected**: SKILL.md would need detailed logic for each phase
- **Actual**: SKILL.md works best as a thin orchestrator that delegates to reference guides. The actual intelligence is in the guides — SKILL.md just sequences the phases and passes data between them. This kept SKILL.md at 230 lines (well under 500 limit) while the guides hold the domain knowledge.
- **Takeaway**: For multi-phase skills with sub-agents, SKILL.md should be a workflow coordinator, not an instruction manual

When designing multi-phase skills → keep SKILL.md as sequencer + data router, put domain knowledge in reference guides

## Advisory guide side-assignment needs to be deterministic

- **Expected**: Could just tell advisors "pick a side"
- **Actual**: Without deterministic side-assignment rules, both advisors might argue for the same side. The advisory-guide.md explicitly defines which side α and β take based on the conflict type (codebase vs best practice → α=codebase, β=best practice; both silent → α=conservative, β=innovative)
- **Takeaway**: When designing adversarial sub-agents, the conflict framing must be deterministic to guarantee genuine difference

When creating adversarial sub-agent pairs → define explicit, deterministic side-assignment rules based on the nature of the disagreement

## prompt-logs 디렉토리 날짜: 모델 추론 vs 시스템 날짜

- **Expected**: 에이전트가 현재 날짜를 정확하게 알고 있을 것
- **Actual**: 이전 세션에서 2025년으로 날짜를 잘못 기입 (250204). knowledge cutoff 근처 날짜와 혼동한 것으로 보임. 프로토콜에 날짜를 에이전트 판단에 맡기는 구조적 약점이 있음
- **Takeaway**: 정확성이 중요한 값(날짜, 버전 등)은 에이전트의 추론에 의존하지 말고 시스템에서 가져와야 함

When prompt-logs 디렉토리를 생성할 때 → `date +%y%m%d`로 시스템 날짜를 가져와서 사용하라

## 같은 날 복수 세션: 넘버링 패턴

- **Expected**: `{YYMMDD}-{title}` 포맷이면 충분
- **Actual**: 같은 날 설계 세션과 구현 세션을 분리하니 `260204-deep-clarify`와 `260204-deep-clarify-impl`처럼 이름만으로 구분해야 하는 상황 발생. 사용자가 `-01-`, `-02-` 넘버링을 도입하여 `260204-01-deep-clarify`, `260204-02-deep-clarify-impl`로 시간 순서와 관계를 명확히 함
- **Takeaway**: 프로토콜 포맷을 `{YYMMDD}-{NN}-{title}`로 확장하면 같은 날 복수 세션의 순서가 자명해짐. 기존 `prompt-logs/`를 스캔하여 다음 번호를 자동 결정 가능

When 같은 날 여러 세션이 있을 때 → `{YYMMDD}-{NN}-{title}` 포맷으로 넘버링하여 순서를 명시하라
