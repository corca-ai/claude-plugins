# Retro: prompt-logger 팀 감지 + 시간 파일명

> Session date: 2026-02-08
> Mode: light

## 1. Context Worth Remembering

- prompt-logger의 auto-commit 기본값은 `false`이며 환경변수가 어디에도 설정되어 있지 않았음 — 사용자가 직접 확인하기 전까지 아무도 모르고 있었음
- Agent team 실행 시 sub-agent 세션마다 별도 `.md` 로그가 생성되지만, auto-commit은 현재 세션 파일 하나만 커밋하고 있었음
- Claude Code agent teams는 experimental feature (`CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`)
- Team config의 `agentId`는 `{name}@{team-name}` 형태이며 `session_id`와 무관
- Teammate의 transcript JSONL에는 `teamName`, `agentName` 필드가 첫 줄부터 있음 — 가장 신뢰할 수 있는 팀 식별 소스
- Leader의 transcript에는 `teamName: null`이지만, config의 `leadSessionId`로 매칭 가능
- 오늘 세션 로그만 10개 — 팀 실행 시 이 정도가 일상적

## 2. Collaboration Preferences

- 사용자는 "개밥먹기" 접근을 선호 — 추측보다 실제 테스트로 검증
- 공식 문서 확인을 요구함 (tool 명세만 믿지 말 것) — CLAUDE.md에 이미 반영된 규칙
- 제안에 대해 "어떻게 생각하세요?"로 counterargument를 구함 — 단순 동의보다 trade-off 분석 기대
- 한 번에 완결하기보다 점진적 접근 (auto-commit 먼저 → 팀 감지는 별도 논의)

### Suggested CLAUDE.md Updates

없음. 기존 규칙("공식 문서 검증", "dogfooding")이 이미 적절히 반영되어 있음.

## 3. Waste Reduction

### 초기 `agentId` 매칭 구현 → 전면 재작성

Tool 명세의 `agentId` 설명을 기반으로 `contains($sid)` 매칭을 구현했으나, 실제 config에서 `agentId = "test-worker@config-test"` 형태임이 확인되어 전체 팀 감지 로직을 재작성.

**5 Whys**:
1. 왜 재작성? → `agentId`와 `session_id`가 다른 식별자였음
2. 왜 몰랐나? → tool 명세에 `agentId: Unique identifier`로만 기술되어 실제 형태 불명
3. 왜 확인 안 했나? → 기존 팀 config가 없어서 실물 확인 불가
4. 왜 먼저 만들지 않았나? → 사용자가 "만들어봅시다"라고 제안하기 전까지 fixture 기반 테스트로 충분하다고 판단
5. **근본 원인**: 외부 시스템(Claude Code 내부)의 데이터 구조를 추측으로 구현한 것. 공식 문서도 `agentId` 형태를 명시하지 않았으므로, **실물 생성 → 구조 확인 → 구현** 순서가 필요했음.

→ **구조적 교훈**: 외부 시스템의 런타임 데이터 구조에 의존하는 코드는, 문서 확인 + 실물 샘플 확인을 구현 전에 반드시 수행. (process gap)

### `set -e` + `&&` 체인 버그

`[ -f "$f" ] && EXISTING="$f" && break` 패턴이 glob 미매칭 시 스크립트를 종료시킴. fixture 테스트에서 발견.

**5 Whys**:
1. 왜 종료? → `set -e`에서 `&&` 체인의 첫 조건 실패 시 exit code 1
2. 왜 `&&` 체인 사용? → 기존 코드 패턴을 모방
3. 왜 기존 코드는 문제없었나? → 기존에는 이 패턴이 없었음 (새로 추가한 glob 순회)
4. **근본 원인**: `set -e` 환경에서 `&&` 체인은 `if` 조건과 다르게 작동한다는 점을 간과.

→ **일회성 실수**: plugin-dev-cheatsheet.md에 `set -e` 관련 가이드가 이미 있으나 `&&` 체인 패턴은 명시되지 않음. 추가할 가치 있음.

## 4. Critical Decision Analysis (CDM)

### CDM 1: 팀 식별 데이터 소스 선택 (config vs transcript)

| Probe | Analysis |
|-------|----------|
| **Cues** | 실제 팀 생성 후 config에 `agentId: "test-worker@config-test"`, `leadSessionId`만 있고 teammate의 `sessionId` 없음 확인 |
| **Goals** | Leader와 teammate 모두 식별 vs 구현 복잡도 최소화 |
| **Options** | (1) config의 `agentId` 매칭, (2) transcript JSONL의 `teamName` 필드, (3) CWD+시간 근접성 휴리스틱, (4) 프로세스 트리/환경변수 |
| **Basis** | Transcript 필드가 가장 직접적이고 신뢰할 수 있음. config는 leader만 매칭 가능하지만 fallback으로 유용. 휴리스틱은 false positive 위험 |
| **Hypothesis** | Config만 사용했다면 teammate 식별 불가. Transcript만 사용했다면 leader(teamName=null) 식별 불가. 둘의 조합이 최적 |
| **Aiding** | 실제 팀 생성(dogfooding)이 없었다면 이 데이터 구조를 발견하지 못했을 것 |

**Key lesson**: 여러 데이터 소스가 있을 때, 각각의 커버리지 영역을 실물로 확인한 후 조합 전략을 결정하라.

### CDM 2: 파일명 시간 추가에 대한 trade-off 논의

| Probe | Analysis |
|-------|----------|
| **Cues** | 사용자의 "yymmdd-hhmm-hash 형태로 붙으면 좀 나을라나 싶은데 잘 모르겠네요" |
| **Knowledge** | 파일명에 시간이 있으면 정렬 편의, 헤더에 이미 시간 있으므로 중복 |
| **Options** | (1) 시간만 추가, (2) 팀 정보만 추가, (3) 둘 다, (4) 현상 유지 + retro에서 grep |
| **Basis** | 사용자에게 "시간만으로는 근본 문제(그룹핑) 해결 안 됨"이라고 counterargument 제시 → 팀 정보 병행 결정 |
| **Experience** | 경험 많은 엔지니어라면 단일 변경으로 두 문제를 해결하기보다, 각각의 문제에 맞는 솔루션을 조합하는 접근을 택함 |

**Key lesson**: 사용자 제안에 바로 동의하지 않고 근본 문제를 함께 분석하면, 더 완전한 해결책에 도달할 수 있다.

### CDM 3: 공식 문서 검증 타이밍

| Probe | Analysis |
|-------|----------|
| **Cues** | 사용자의 "공식문서상으로 team config라는 게 있는 거 맞죠?" |
| **Goals** | 구현 속도 vs 정확성 |
| **Options** | (1) 문서 확인 없이 tool 명세 기반 구현 진행, (2) 코드 작성 전 문서 확인, (3) 코드 작성 후 문서로 검증 |
| **Basis** | 첫 구현은 tool 명세 기반(option 1). 사용자 질문 후 문서 확인(option 3). 결과적으로 config 구조는 맞았지만 agentId 형태는 달랐음 |
| **Situation Assessment** | tool 명세의 `agentId: Unique identifier`만으로는 형태를 알 수 없었음. 문서에서도 형태 미명시. 실물 확인이 유일한 방법 |

**Key lesson**: 외부 시스템 연동 시, 문서 확인은 "구현 전"이 최적이지만, 문서가 충분하지 않으면 실물 생성이 불가피하다. 문서 + 실물 = 최소 검증 세트.

## 5. Expert Lens

> Run `/retro --deep` for expert analysis.

## 6. Learning Resources

> Run `/retro --deep` for learning resources.

## 7. Relevant Skills

### Installed Skills

| Skill | 이 세션과의 관련성 |
|-------|-------------------|
| **gather-context** | 공식 문서 확인 시 WebFetch를 직접 사용. `/gather-context` URL 모드가 더 효율적이었을 수 있음 |
| **refactor** | 변경 완료 후 `--code` 모드로 코드 품질 검증 가능 |
| **plugin-deploy** | 커밋 전 `/plugin-deploy`로 버전/marketplace/README 정합성 자동 확인 |

### Skill Gaps

이 세션에서 반복된 패턴: "외부 시스템 데이터 구조를 실물로 확인 → 구현". 현재 이를 자동화하는 스킬은 없으나, 빈도가 낮아 별도 스킬보다는 체크리스트(project-context.md)에 추가하는 것이 적절.

---

*이 세션은 유의미한 아키텍처 결정을 포함합니다. `/retro --deep`으로 전문가 분석과 학습 자료를 확인할 수 있습니다.*
