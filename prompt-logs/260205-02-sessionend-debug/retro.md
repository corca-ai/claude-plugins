# Retro: SessionEnd auto-commit 디버깅

> Session date: 2026-02-05

## 1. Context Worth Remembering

- `set -euo pipefail` 스크립트에서 early-exit 경로가 있으면, 스크립트 끝에 배치된 로직은 "해당 경로에서 도달 불가"가 됨. 새 코드를 기존 스크립트에 추가할 때 모든 exit 경로를 반드시 검토해야 함.
- async hook은 실행 결과를 어디에서도 관찰할 수 없음 (stderr/stdout 모두 보이지 않음). 불확실성이 높은 async 코드를 작성할 때는 debug logging을 **첫 구현에 포함**해야 함 — 나중에 추가하는 것은 "이미 문제가 발생한 후"가 됨.
- Stop과 SessionEnd가 같은 스크립트를 호출하는 구조에서, Stop이 먼저 실행되어 상태를 업데이트하면 SessionEnd는 "새 데이터 없음" 경로로 빠짐. 동일 스크립트를 공유하는 hook들의 상호작용을 반드시 분석해야 함.

## 2. Collaboration Preferences

- 사용자가 "안 되면 SessionStart에서 하자"라고 대안을 제시했을 때, 즉시 수용하지 않고 근본 원인을 계속 추적한 것이 결과적으로 올바른 판단이었음. 다만 이것은 디버그 로그 데이터가 "SessionEnd는 호출되지만 스크립트가 중간에 죽는다"는 증거를 보여줬기 때문에 정당화됨 — 데이터 없이 끈질기게 버티는 것과는 다름.
- 사용자가 retro에서 CDM 프레임워크를 직접 제안 — retro 스킬 자체의 개선에도 관심이 있음. 도구를 사용하면서 도구 자체를 개선하는 메타 워크플로.

### Suggested CLAUDE.md Updates

- 없음.

## 3. Prompting Habits

- 사용자가 retro 요청 시 구체적 분석 포인트 3개를 명시하고 CDM 프레임워크까지 제공 — 이를 통해 retro가 generic한 요약이 아닌 깊은 분석이 됨. 효과적인 패턴.
- "prompt-logs/sessions/260205-1fee62c1.md" 처럼 파일명만 전달하여 테스트 결과를 알린 것도 간결하고 효율적.

## 4. Critical Decision Analysis (CDM)

### CDM 1: 초기 구현에서 early-exit를 고려하지 못한 결정

| Probe | Analysis |
|-------|----------|
| **Cues** | SessionEnd hook 추가 요청. 기존 스크립트에 auto-commit 로직을 "마지막에 추가"하면 된다고 판단 |
| **Knowledge** | Stop hook의 incremental processing과 offset 업데이트 메커니즘을 이미 구현한 상태 |
| **Goals** | SessionEnd 시점에 세션 로그를 자동 커밋 |
| **Options** | (A) 기존 스크립트 끝에 auto-commit 추가 (선택됨) / (B) 별도 스크립트로 분리 / (C) early-exit 경로 분석 후 적절한 위치에 배치 |
| **Basis** | "같은 스크립트를 재사용하면 코드 중복을 피할 수 있다"는 판단. 하지만 **기존 스크립트의 제어 흐름을 추적하지 않았음** |
| **Hypothesis** | 만약 auto-commit을 별도 스크립트로 만들었다면, 이 버그는 발생하지 않았을 것. 또는 "TOTAL_LINES == LAST_OFFSET일 때 어떤 일이 일어나는가?"를 한 번이라도 물었다면 즉시 발견했을 것 |
| **Aiding** | 체크리스트: "새 코드를 기존 스크립트에 추가할 때, 모든 `exit` 경로에서 새 코드에 도달 가능한가?" |

**핵심 교훈**: 기존 스크립트에 새 기능을 추가할 때의 위험을 과소평가함. 스크립트를 "black box"로 취급하고 끝에 추가하면 된다고 생각했지만, 실제로는 스크립트 내부의 모든 exit 경로를 알아야 함.

### CDM 2: "Ctrl+C가 SessionEnd를 발화하지 않는다"는 잘못된 초기 가설

| Probe | Analysis |
|-------|----------|
| **Cues** | 사용자: "Ctrl+C 두 번으로 종료했는데 auto-commit 안 됨" |
| **Knowledge** | SIGINT 동작, graceful vs force shutdown 개념 |
| **Analogues** | 일반적인 서버/프로세스에서 Ctrl+C 두 번 = force kill |
| **Goals** | 왜 auto-commit이 안 되는지 파악 |
| **Options** | (A) 플랫폼 문제 (SessionEnd가 안 발화됨) — 선택됨 / (B) 스크립트 문제 (발화되지만 실패함) |
| **Basis** | "Ctrl+C 두 번 = force kill"이라는 기존 mental model이 지배적이었음 |
| **Time Pressure** | 낮음 — 디버깅 세션이므로 시간 제약 없음 |
| **Situation Assessment** | 잘못된 진단. 플랫폼 동작을 먼저 의심했지만, 실제로는 스크립트 내부 로직 문제 |
| **Hypothesis** | 사용자가 `:q`과 `exit`으로도 실패한다고 보고하지 않았다면, "Ctrl+C가 SessionEnd를 발화하지 않는다"는 결론으로 종료했을 가능성이 높음 |

**핵심 교훈**: 복수의 가설을 동시에 검증해야 함. "플랫폼이 안 됨" vs "스크립트가 실패함"은 동시에 테스트할 수 있었음 (debug log 한 줄이면 됨).

### CDM 3: 디버그 로깅을 2라운드 뒤에야 추가한 결정

| Probe | Analysis |
|-------|----------|
| **Cues** | `:q`, `exit`으로도 실패 → Ctrl+C 특유의 문제가 아님 |
| **Knowledge** | async hook의 stderr/stdout은 관찰 불가 |
| **Goals** | 실패 지점 특정 |
| **Options** | (A) 코드 리뷰로 문제 찾기 / (B) 디버그 로깅 추가 후 재테스트 |
| **Basis** | 처음에는 (A)를 시도 — 공식 문서를 읽고 코드를 읽음. 실패 후 (B)로 전환 |
| **Aiding** | **디버그 로깅은 첫 번째 수단이었어야 함.** 관찰 불가능한 시스템에서 코드 리뷰만으로 문제를 찾으려 한 것은 비효율적. "관찰 불가 = 즉시 계측" 원칙 |
| **Tools** | `/tmp/prompt-logger-debug.log`로의 파일 로깅 — 간단하지만 효과적 |

### CDM 4: SessionStart 대안 제안에도 계속 디버깅한 결정

| Probe | Analysis |
|-------|----------|
| **Cues** | 디버그 로그: `HOOK_TYPE=session_end` 라인이 존재 → SessionEnd는 발화됨 |
| **Knowledge** | "발화는 되지만 스크립트가 중간에 죽는다" — 이건 찾을 수 있는 버그 |
| **Goals** | 근본 원인 해결 vs workaround 도입 |
| **Options** | (A) SessionStart에서 이전 세션 로그를 커밋하는 workaround / (B) SessionEnd 스크립트 버그 수정 |
| **Basis** | 데이터가 "버그가 존재한다"고 말하고 있었음. Workaround은 복잡도를 추가하고 원래 설계 의도를 훼손 |

**이 결정은 올바름** — 데이터 기반 판단이었기 때문.

## 5. 자체 디버깅 역량: 가능 vs 불가능

### 환경적으로 가능했지만 하지 않은 것

1. **Mental execution trace**: `Stop → offset 업데이트 → SessionEnd → TOTAL_LINES == LAST_OFFSET → exit 0` 경로를 코드 리뷰만으로 추적할 수 있었음. 모든 `exit` 문과 조건문을 나열하면 발견 가능.
2. **정적 분석**: `grep -n 'exit' log-turn.sh`로 모든 exit 경로를 나열하고, 각 exit에서 auto-commit에 도달 가능한지 체크할 수 있었음.
3. **첫 라운드에서 debug log 추가**: "관찰 불가능한 async 시스템 → 즉시 계측"을 적용했어야 함.

### 환경적으로 불가능한 것

1. **별도 세션 실행 및 종료**: 새 Claude Code 세션을 시작/종료하여 hook 동작을 관찰하는 것은 불가.
2. **async hook의 실시간 출력 관찰**: async hook의 stderr/stdout에 접근 불가.
3. **SessionEnd 트리거**: 세션 내에서 SessionEnd를 의도적으로 발화시킬 수 없음.

## 6. Learning Resources

- [CDM - Critical Decision Method (Gary Klein)](https://www.gary-klein.com/cdm) — CDM은 비일상적 상황에서의 전문가 의사결정을 회고적으로 분석하는 인터뷰 기법. 원래 소방관, 군인 등을 대상으로 개발되었지만, 소프트웨어 디버깅/인시던트 회고에도 직접 적용 가능. 핵심은 "무엇을 했는가"가 아니라 "왜 그렇게 판단했는가"를 추적하는 것.
- [The Pre-Mortem: Software Engineering Best Practice (Josh Clemm)](https://joshclemm.com/writing/the-premortem-software-engineering-best-practice/) — "실패했다고 상상하고, 왜 실패했는지 역추적"하는 기법. 실패 원인 식별 능력을 30% 향상시킨다는 연구 결과. 이번 세션의 교훈: auto-commit을 구현할 때 "auto-commit이 실행되지 않았다. 왜?"를 먼저 물었다면, early-exit 경로를 즉시 발견했을 것.
- [Webhooks at Scale: Best Practices (Hookdeck)](https://hookdeck.com/blog/webhooks-at-scale) — 비동기 이벤트 기반 시스템의 디버깅 원칙. 핵심: 관찰 불가능한 시스템은 "사후 계측"이 아닌 "사전 계측(observability-first)"으로 설계해야 함. prompt-logger에도 동일 원칙 적용 필요.

## 7. Relevant Skills

### retro 스킬에 CDM 통합 제안

이번 세션에서 CDM 프레임워크가 디버깅 회고에 매우 효과적이었음. retro 스킬에 선택적 CDM 분석 섹션을 추가하면 가치가 있을 것:

- **적용 조건**: 디버깅, 인시던트 대응, 어려운 기술적 결정이 포함된 세션
- **구현 방식**: retro 스킬의 Section 4로 CDM 분석 추가 (조건부)
- **CDM probes 최소 세트**: Cues, Knowledge, Options, Basis, Hypothesis, Aiding (전체 12개 중 디버깅에 가장 유용한 6개)

구현 여부는 사용자 판단에 맡김.

### Post-Retro Findings

- 디버깅 과정에서 타임존 버그 추가 발견: transcript의 UTC timestamp(`2026-02-04T21:45:20.417Z`)를 로컬 시간으로 변환하지 않고 그대로 표시하고 있었음. `utc_to_epoch()` + `utc_to_local()` 헬퍼 함수를 추가하여 수정. 1.2.1에 함께 포함.
- 이 발견은 CDM 관점에서도 의미 있음: 초기 구현 시 "transcript timestamp가 어떤 timezone인가?"를 확인하지 않았음. 외부 데이터의 timezone을 항상 명시적으로 확인하는 습관 필요.
