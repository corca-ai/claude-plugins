# Retro: deep-clarify 구현

> Session date: 2026-02-04

## 1. Context Worth Remembering

- deep-clarify는 이 프로젝트의 첫 번째 멀티 서브에이전트 스킬 — 4개의 서브에이전트(코드베이스 리서처, 베스트 프랙티스 리서처, Advisor α, Advisor β)를 오케스트레이션하는 6단계 워크플로우
- 이전 세션(260204-01)에서 설계 토론만 진행하고 구현을 별도 세션으로 분리한 경우. 설계 플랜이 충분히 상세했기 때문에 구현은 기계적으로 진행됨
- suggest-tidyings의 fan-out 패턴과 tidying-guide.md의 role/context/methodology/constraints/output 구조가 deep-clarify의 4개 레퍼런스 가이드에 재사용됨 — 이 프로젝트에서 서브에이전트 가이드 작성의 사실상 표준 패턴

## 2. Collaboration Preferences

- 사용자가 하나의 프롬프트에 여러 작업을 결합하는 패턴 확인: "디렉토리 리네임 + 새 세션 생성 + 플랜대로 구현 + lessons 기록 + retro + 커밋 + 푸시" — 에이전트가 전체 워크플로우를 자율적으로 처리하기를 기대
- 사용자가 날짜 오류를 발견하면서 "plugin-deploy 스킬이 있었는데?"라고 언급 — 기존 자동화 도구를 활용하지 않은 것에 대한 암시적 피드백. 에이전트가 deploy 워크플로우에서 plugin-deploy 스킬을 자발적으로 사용해야 함

### Suggested CLAUDE.md Updates

- Plan Mode 섹션의 워크플로우 항목 4에 추가: "For plugin changes: use `/plugin-deploy` skill to automate version checks, marketplace sync, README updates, and local testing"

## 3. Prompting Habits

이 세션에서 사용자의 프롬프팅은 효율적이었음. 하나의 메시지에 전체 작업 흐름을 명확하게 지시.

한 가지 관찰:
- "왜 날짜를 틀렸을까요? 뭔가 개선이 필요한듯.." — 이것은 에이전트에게 직접적인 지시가 아니라 사고의 흐름을 공유한 것. 에이전트 입장에서는 "날짜 검증 프로세스 개선안을 제안해줘"인지 "그냥 내 생각을 말한 것"인지 모호함. 명시적으로 "날짜 검증 방법을 개선하자" 또는 "(그냥 독백)"처럼 의도를 표시하면 에이전트가 더 정확하게 반응할 수 있음

## 4. Learning Resources

- [Skill authoring best practices — Claude API Docs](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices) — Anthropic 공식 스킬 작성 가이드. progressive disclosure, reference file bundling, workflow pattern 등 deep-clarify 구조와 직접 관련
- [Architecting Multi-Agent Systems: Evolving Proven Patterns](https://medium.com/@chris.p.hughes10/architecting-multi-agent-systems-evolving-proven-patterns-to-agentic-systems-01b2b90799b6) — 멀티에이전트 시스템의 레이어드 아키텍처. orchestrator → agents → tools → services 분리가 deep-clarify의 SKILL.md(orchestrator) → reference guides(agent instructions) 패턴과 유사
- [Architectures for Multi-Agent Systems — Galileo](https://galileo.ai/blog/architectures-for-multi-agent-systems) — supervisor, network, orchestrator 등 멀티에이전트 아키텍처 패턴 비교. deep-clarify의 Phase 2(parallel fan-out) + Phase 3(aggregation) 패턴의 이론적 배경

## 5. Relevant Skills

- **plugin-deploy**: 이미 존재하는 스킬. 사용자가 직접 언급함. 이번 세션에서 marketplace.json, README 업데이트, 버전 관리를 수동으로 했는데, `/plugin-deploy`를 사용했으면 자동화할 수 있었음. 향후 플러그인 작업 시 반드시 활용할 것
- **plan-and-lessons 프로토콜 개선 2가지**:
  1. **세션 넘버링**: 같은 날 여러 세션이 있을 때 `{YYMMDD}-{title}` 포맷은 충돌하거나 구분이 안 됨. 이번 세션에서 사용자가 `-01-`, `-02-` 넘버링을 도입함 (예: `260204-01-deep-clarify`, `260204-02-deep-clarify-impl`). 프로토콜에 `{YYMMDD}-{NN}-{title}` 포맷을 명시하고, 기존 `prompt-logs/` 디렉토리를 스캔하여 다음 번호를 자동 결정하는 로직을 추가할 수 있음
  2. **날짜 자동화**: 이전 세션에서 날짜를 2025년으로 잘못 기입함 (모델의 knowledge cutoff 혼동). 프로토콜에서 `date +%y%m%d` 등 bash 명령으로 시스템 날짜를 가져오도록 명시하면 구조적으로 방지 가능. 현재 프로토콜은 에이전트가 날짜를 "알아서" 넣도록 되어 있어, 모델이 현재 날짜를 착각하면 방어할 수단이 없음
