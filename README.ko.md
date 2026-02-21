# CWF (Corca Workflow Framework)

> **Disclaimer: Single Source Of Truth**  
> 이 문서는 CWF 플러그인의 단일 기준점(SSOT)입니다. 문서와 플러그인 구현이 다르면 문서 기준으로 구현을 고쳐야 하니, 사용 중 불일치를 발견하면 이슈/PR로 제보해주세요. CWF를 사용하는 에이전트도 동일하게 행동해주시면 감사하겠습니다.

[English](README.md)

구조화된 개발 세션을 컨텍스트 수집부터 회고 분석까지 반복 가능한 워크플로우로 전환하는 Claude Code 플러그인입니다. [Corca](https://www.corca.ai/)가 [AI-Native Product Team](AI_NATIVE_PRODUCT_TEAM.ko.md)을 위해 개발했습니다. Codex CLI에서도 대부분의 동작이 호환됩니다.

## 설치

### 빠른 시작

```bash
# 마켓플레이스 추가
claude plugin marketplace add https://github.com/corca-ai/claude-plugins.git

# CWF 설치
claude plugin install cwf@corca-plugins
```

이제 Claude Code에서 `cwf:setup`을 실행해주세요. setup은 다음과 같이 작동합니다.

- 프로젝트 설정 파일(`.cwf-config.yaml`, `.cwf-config.local.yaml`) 부트스트랩
- 외부 도구 감지(Codex/Gemini/Tavily/Exa) 및 선택적 Codex 연동
- 로컬 실행 의존성(`shellcheck`, `jq`, `gh`, `node`, `python3`, `lychee`, `markdownlint-cli2`) 점검 및 설치 선택
- 에이전트가 CWF 사용법 및 저장소 탐색을 돕는 인덱스 문서 생성(별도 파일로, 또는 AGENTS.md에 통합)

플래그별 세부 동작은 [setup](#setup) 섹션을 참고하세요.

### Codex 사용자용 설정

`cwf:setup`만 실행해도 Codex를 위한 안내를 받을 수 있습니다. Codex 연동은 기본적으로 활성 플러그인 스코프(`local > project > user`)를 따릅니다. 아래 명령은 Codex 연동만 별도로 다시 적용하고 싶을 때 사용하시면 됩니다. 자세한 내용은 [Codex 연동](#codex-연동) 섹션을 참고하세요.

```text
cwf:setup --codex
cwf:setup --codex-wrapper
```

### 사용 시나리오

Claude Code / Codex CLI에서 아래처럼 자연어로 시작하면 됩니다.

```text
<문제>를 해결하려고 합니다. CWF를 사용해 워크플로우를 진행해 주세요.
```

그러면 에이전트가 `cwf:run`을 호출해 정보 수집부터 배포 준비까지 전체 과정을 스스로 진행합니다(단, 초기에 사용자와 함께 해소해야만 하는 모호함이 있다면 멈출 수 있습니다). 에이전트가 무슨 일을 했는지 궁금하다면 `cwf:hitl`을 통해 주요 의사결정 포인트와 사용자 쟁점을 문서화한 뒤, 청크 단위로 검토해보세요.

플러그인을 구성하는 13개 스킬은 기본적으로 에이전트를 위한 도구들이며, 최대한 자율적으로 실행되게 되어있으므로 사용자가 자세히 사용법을 이해하는 게 필수는 아닙니다. 하지만 각 스킬의 존재 이유와 구조를 이해하면 CWF를 더 효과적으로 사용하면서 본인만의 워크플로우를 자라나게 하기 쉬워집니다. 자세한 내용이 궁금하신 분들은 하단에서 각 스킬에 대한 설명을 읽어보시길 바랍니다.

### 최신 버전으로 업데이트

```bash
claude plugin marketplace update corca-plugins
claude plugin update cwf@corca-plugins
```

또는 Claude Code / Codex CLI 내에서:

```text
cwf:update               # 새 버전이 있으면 확인 + 업데이트
cwf:update --check       # 버전 확인만
```

### 독립 플러그인 (레거시)

v3부터 레거시 독립 플러그인은 마켓플레이스에서 제거되었습니다. v3 이전의 플러그인이 설치되어 있다면 제거하고 CWF를 설치하세요.

## 운영 원칙

### CWF의 역할

CWF는 컨텍스트 수집 → 요구사항 명확화 → 계획 → 구현 → 리뷰 → 리팩토링 → 회고 → 배포 준비(GitHub 이슈 및 PR)를 하나의 반복 가능한 워크플로우로 통합해둔 플러그인입니다. 실제 머지 이후 CI/CD 실행은 각 저장소의 운영 책임 범위에 두고, CWF는 그 직전 단계까지를 자동화·정형화합니다. 사용자의 컨텍스트 관리 부담을 최소화하기 위해 세션 상태 기록, 세션 로그 산출물, 훅을 통해 페이즈/세션 경계를 넘어 의사결정 사항과 교훈을 보존합니다. 모든 스킬의 공통 계약은 `context-deficit resilience`입니다. 즉, auto-compact나 세션 재시작 이후에도 `.cwf/cwf-state.yaml`, 세션 산출물, 핸드오프 파일만으로 실행을 복구해야 하며, 암묵적 대화 메모리에 의존하면 계약 위반으로 간주합니다.

각 스킬은 전문가 자문, 티어 분류, 에이전트 조율, 의사결정 포인트, 핸드오프, 출처 추적, 적응형 setup 계약이라는 7가지 핵심 컨셉을 조립해 재구성한 것입니다. 여기서 '컨셉'이란 [Daniel Jackson의 정의](references/essence-of-software/distillation.md)에 따라, '사용자에게 보이는 기능을 명확하고 이해 가능한 목적으로 묶은 재사용 가능한 단위'를 뜻합니다. 각 컨셉은 자신의 상태를 유지하고 사용자(및 다른 컨셉)와 원자적 액션으로 상호작용하며, CWF는 이를 스킬 간 공용 설계 규약으로 사용합니다.

### CWF의 범위 밖

- CWF는 프로젝트별 엔지니어링 표준, CI 게이트, 사람의 제품 책임 의사결정을 대체하지 않습니다.
- CWF는 모든 결정을 완전히 자동화할 수 있다고 보장하지 않으며, 주관적 결정에는 여전히 사용자 확인이 필요합니다.
- CWF 플러그인 내의 각 스킬을 독립적으로 설치해서 사용하는 것도 가능하나, 스킬간 강결합을 의도해서 설계했기 때문에 함께 사용하기를 권장합니다.

### 가정

- 사용자는 `.cwf/projects`와 `.cwf/cwf-state.yaml` 같은 세션 산출물을 저장하고 활용할 수 있는 저장소에서 작업합니다.
- 사용자는 `AGENTS.md`에서 시작해 필요할 때 더 깊은 문서를 읽는 점진적 공개 방식에 동의합니다.
- 사용자는 반복되는 품질 검사를 행동 기억에 의존하기보다 결정적 검증 스크립트로 관리하는 방식을 선호합니다.
- 사용자는 필수 의존성/키가 없을 때 스킬이 즉시 설치·설정 여부를 묻고, 승인 시 설치/설정을 시도한 뒤 재시도하는 흐름을 기대합니다.
- 사용자는 이전 대화가 손실되어도 스킬이 상태/산출물/핸드오프로 복구되는 실행 계약(`context-deficit resilience`)을 전제로 작업합니다.
- 사용자는 토큰이 이미 충분히 싸고 앞으로 더 싸질 것이라는 전제를 수용합니다. CWF는 코딩 에이전트를 사실상 무제한(예: Claude Code / Codex $200 플랜)으로 사용할 수 있는 사람을 대상으로 설계됐습니다.

## 왜 CWF인가?

### 문제

AI 에이전트는 이미 충분히 똑똑하나, 아직까지는 긴 작업을 안정적으로 수행하려면 적절한 도구와 환경이 갖춰져야 합니다. 그 중 가장 중요한 것이 컨텍스트와 결정 이력의 보존입니다. 세션/페이즈 경계에서 컨텍스트가 끊기면 다음 작업은 다시 탐색부터 시작되고, 사람과 합의한 제약도 쉽게 누락되기 때문입니다.

또 다른 핵심 환경 요소는 에이전트 동작을 지속적으로 교정하는 품질 게이트입니다. 프로젝트 규모가 커질수록 설계 문서, 스킬 동작, 훅/스크립트가 서로 어긋나기 쉬워지고, 저품질 코드와 문서가 중구난방 양산되며, 검증 규칙이 실제 상태를 따라가지 못하는 문제가 반복됩니다.

마지막으로, 긴 작업을 병렬로 더 많이 돌릴수록 병목은 인간의 뇌로 이동합니다. 사람의 판단/검증 속도가 에이전트의 출력량을 따라가지 못한다면, 단순한 병렬화로는 전체 리드타임을 일정 이상 줄이기 어렵습니다.

### 접근

토큰은 이미 싸고 더 싸질 것이므로, CWF는 효율보다는 효과를 기준으로 설계되었습니다. 토큰을 많이 써서 사용자가 할 일을 줄일 수 있다면 그렇게 합니다. 사용자 검토가 필요한 지점에서는 `cwf:hitl`로 합의와 검토를 구조화합니다. 그렇다고 효율을 완전히 등한시한다는 뜻은 아닙니다. 토큰을 많이 쓰다 보면 결국 단위 시간당 토큰의 질이 높아져야 하므로, 회고를 통해 작업 방식과 프롬프트를 지속적으로 개선해 반복 세션에서 효율도 함께 높입니다.

핵심은 다음 다섯 가지입니다.

1. 충분한 맥락을 먼저 수집하고(가설보다 증거 우선)
2. 사용자와 합의한 의사결정/계획을 파일 기반 지속 메모리로 남기며
3. 훅과 결정적 검증으로 에이전트가 올바른 문서와 코드를 작성하도록 강제하고
4. 회고로 프로세스와 도구를 계속 개선하는 자가 치유 루프를 유지하고
5. 필요한 지점에서는 사용자가 쉽게 개입할 수 있게 한다

이를 위해 다음과 같이 의사결정했습니다.

- **독립 플러그인 대신 통합 플러그인**: 페이즈 간 컨텍스트 손실과 단계별 실행 규칙의 일관성 붕괴를 방지하기 위해서입니다.
- **사용자 개입은 앞뒤에, 나머지는 자율로**: 불확실성을 중요한 순간에 줄여주기만 하면 에이전트가 나머지는 지능적으로 실행할 수 있다고 믿기 때문입니다.
- **핸드오프 문서의 경로만 입력해도 다음 단계가 시작되도록 작성**: 세션 연속성을 신뢰할 수 있게 만들고, 다음 작업 시작 시의 모호성을 줄이기 위해서입니다.

### 결과

하나의 플러그인(CWF), 13개 스킬, 9개 훅 그룹. 컨텍스트는 세션 경계를 넘어 유지되고, 의사결정은 증거 기반으로 이루어지며, 품질 기준은 시스템과 함께 진화합니다.

## 핵심 개념: CWF의 빌딩 블록 7개

CWF 스킬이 조합하는 7가지 재사용 가능한 행동 패턴입니다. 아래 순서는 문제를 구조화하고(의사결정 포인트), 관점을 넓혀 검증하고(전문가 자문), 결정 권한을 배분한 뒤(티어 분류), 실행/연속성/기준 관리로 이어지는 운영 흐름을 반영합니다.

**의사결정 포인트** -- 모호한 요구를 검토 가능한 선택지로 변환합니다. 결정을 내리기 전에 질문 단위로 분해해 모든 선택의 근거를 기록합니다.

**전문가 자문** -- 같은 의사결정 포인트를 서로 다른 전문 프레임으로 재검토해 숨은 가정과 리스크를 조기에 드러냅니다. 의사결정 포인트가 "무엇을 결정할지"를 구조화한다면, 전문가 자문은 "그 결정을 어떤 관점으로 검증할지"를 보강합니다.

**티어 분류** -- 의사결정의 성격에 맞는 주체로 권한을 라우팅합니다. 코드베이스 증거 기반(T1)과 표준/모범사례 기반(T2)은 에이전트가 자율 처리하고, 선호·정책처럼 정답이 없는 결정(T3)만 사용자에게 올립니다.

**에이전트 조율** -- 처리량을 늘리면서도 결과 일관성을 유지합니다. 복잡도에 맞춰 최소 팀을 구성하고 의존성 기반 배치로 실행한 뒤 결과를 하나로 종합합니다.

**핸드오프** -- 페이즈/세션 경계에서 다시 시작하는 비용을 없앱니다. 세션 핸드오프는 맥락과 교훈을, 페이즈 핸드오프는 프로토콜과 제약을 전달합니다.

**출처 추적** -- 오래된 기준이 현재 작업을 조용히 오염시키지 않게 합니다. 여기서 기준은 리뷰 체크리스트, 설계 원칙, 운영 규칙 같은 작업 판단 근거를 뜻하며, CWF는 참조 문서의 시스템 상태 메타데이터를 확인한 뒤에만 이를 재사용합니다.

**적응형 setup 계약** -- setup의 이식성을 유지하면서도 현재 저장소 도구 체인에 맞게 초기 설정을 조정합니다. 첫 setup에서 계약 초안을 만들고(core baseline + repo 제안), repo 고유 도구는 명시적 승인 후에만 적용합니다.

## 워크플로우

CWF의 기본 실행 체인은 아래와 같습니다:

```text
gather → clarify → plan → review(plan) → impl → review(code) → refactor → retro → ship
```

| # | 스킬 | 트리거 | 하는 일 |
|---|------|--------|---------|
| 1 | [gather](#gather) | `cwf:gather` | URL/웹/로컬 증거를 수집해 에이전트 친화 산출물로 정리 |
| 2 | [clarify](#clarify) | `cwf:clarify` | 요구사항을 의사결정 포인트로 분해하고 티어 분류로 계획 입력을 정제 |
| 3 | [plan](#plan) | `cwf:plan` | 구현 범위/파일/검증 가능한 성공 기준을 명시한 실행 계약 작성 |
| 4 | [impl](#impl) | `cwf:impl` | 승인된 계획을 작업 단위로 분해해 실행하고 완료 기준으로 검증 |
| 5 | [retro](#retro) | `cwf:retro` | 세션 결과를 분석해 교훈과 도구/프로세스 개선 항목으로 환원 |
| 6 | [refactor](#refactor) | `cwf:refactor` | 코드·스킬·문서·스크립트를 함께 정리해 전역 정합성 회복 |
| 7 | [handoff](#handoff) | `cwf:handoff` | 세션/페이즈 전환용 핸드오프 문서 생성 및 상태 연결 |
| 8 | [ship](#ship) | `cwf:ship` | 이슈/PR/머지 단계를 템플릿과 가드레일로 일관되게 실행 |
| 9 | [review](#review) | `cwf:review` | 요구/계획/코드에 공통 품질 게이트를 적용하는 다각도 리뷰 |
| 10 | [hitl](#hitl) | `cwf:hitl` | 합의 라운드와 청크 검토를 재개 가능한 상태로 운영 |
| 11 | [run](#run) | `cwf:run` | gather부터 ship까지 전체 파이프라인을 단계 게이트로 조율 |
| 12 | [setup](#setup) | `cwf:setup` | 훅/도구/setup·설정/인덱스 계약을 초기 표준값으로 부트스트랩하고 repo별 제안을 분리 제시 |
| 13 | [update](#update) | `cwf:update` | CWF 동작을 최신 계약/수정사항과 동기화 |

## 스킬 레퍼런스

이 섹션은 의도적으로 결과 중심으로 작성되어 있습니다.

- 각 스킬을 `왜 필요한지(why)`와 `실행 시 무엇이 일어나는지(what happens)`로 정의합니다.
- 플래그별 명령 매트릭스, 예외 실행 플로우, 저수준 롤백 내부 동작은 포함하지 않습니다.
- 전체 실행 계약은 각 스킬의 `SKILL.md`와 스킬별 `references/`에서 확인하세요.
- 이 요약 포맷의 기준 문서는 [skill-conventions](plugins/cwf/references/skill-conventions.md#readme-skill-summary-format)입니다.

### [gather](plugins/cwf/skills/gather/SKILL.md)

주요 트리거: `cwf:gather`

**왜 필요한가**

추론/구현 전에 흩어진 외부 컨텍스트를 로컬 증거로 고정하기 위해 필요합니다.

**실행하면 무엇이 일어나는가**

URL/웹/로컬 컨텍스트를 수집해 `.cwf/projects/`에 재사용 가능한 산출물로 정규화하고, 출처 추적 정보를 함께 남깁니다.

**기대 아웃컴**

1. 흩어진 문서와 링크가 출처 추적 가능한 로컬 산출물로 정규화됩니다.
2. 외부 웹 검색 키가 없으면 setup 안내를 반환하고 가능한 수집 경로는 계속 진행합니다.
3. 후속 스킬은 암묵적 대화 기억 대신 수집된 파일 증거를 기준으로 동작합니다.

### [clarify](plugins/cwf/skills/clarify/SKILL.md)

주요 트리거: `cwf:clarify`

**왜 필요한가**

모호성을 구현 전에 제거해 불필요한 재작업 비용을 줄이기 위해 필요합니다.

**실행하면 무엇이 일어나는가**

요구사항을 의사결정 포인트로 분해하고 티어(증거/표준/선호)로 분류해, 자율 해결 가능한 항목은 처리하고 주관적 선택만 사용자에게 올립니다.

**기대 아웃컴**

1. 모호한 요청이 명시적 의사결정 포인트로 변환됩니다.
2. 증거 기반 질문에는 근거가 포함된 자율 답변이 생성됩니다.
3. 남은 선호/정책 선택은 트레이드오프와 함께 사용자 질문으로 승격됩니다.

### [plan](plugins/cwf/skills/plan/SKILL.md)

주요 트리거: `cwf:plan`

**왜 필요한가**

구현과 리뷰가 같은 기준으로 집행할 실행 계약을 만들기 위해 필요합니다.

**실행하면 무엇이 일어나는가**

범위, 변경 파일, 테스트 가능한 성공 기준이 포함된 `plan.md`를 생성하고, 다음 단계에 필요한 교훈을 함께 기록합니다.

**기대 아웃컴**

1. `plan.md`에 범위, 대상 파일, 검증 가능한 성공 기준이 명시됩니다.
2. 미해결 가정은 숨기지 않고 열린 항목으로 노출됩니다.
3. 구현 시작 전 `cwf:review --mode plan`으로 계약 품질을 선검증할 수 있습니다.

### [impl](plugins/cwf/skills/impl/SKILL.md)

주요 트리거: `cwf:impl`

**왜 필요한가**

승인된 계획을 제약 누락 없이 예측 가능한 실행으로 전환하기 위해 필요합니다.

**실행하면 무엇이 일어나는가**

계획을 의존성 기반 작업 단위로 분해하고, 병렬 가능한 작업은 동시 실행하며, 완료를 성공 기준으로 검증합니다.

**기대 아웃컴**

1. 실제 변경 결과가 승인된 계획 작업 단위와 추적 가능하게 대응됩니다.
2. 순서 의존 작업은 순차를 유지하고 독립 작업은 병렬화됩니다.
3. 남은 리스크와 후속 조치가 근거와 함께 기록됩니다.

### [retro](plugins/cwf/skills/retro/SKILL.md)

주요 트리거: `cwf:retro`

**왜 필요한가**

단일 세션 결과를 일회성 기록이 아니라 재사용 가능한 운영 개선으로 전환하기 위해 필요합니다.

**실행하면 무엇이 일어나는가**

세션 근거를 분석해 원인과 의사결정을 정리하고, 개선 항목을 문서/체크/프로세스 변경으로 연결 가능한 형태로 남깁니다.

**기대 아웃컴**

1. `retro.md`에 사실, 원인, 다음 변경이 구조화되어 남습니다.
2. 반복 마찰 패턴이 집행 티어 기준으로 분류됩니다.
3. 심층 모드에서는 전문가 렌즈 결과와 학습 리소스가 보조 산출물로 저장됩니다.

### [refactor](plugins/cwf/skills/refactor/SKILL.md)

주요 트리거: `cwf:refactor`

**왜 필요한가**

기능·스킬·문서·스크립트가 함께 늘어나는 환경에서 전역 드리프트를 통제하기 위해 필요합니다.

**실행하면 무엇이 일어나는가**

퀵/딥/문서 모드 점검을 통해 구조·품질·정합성 문제를 추출하고, 수정 대상과 근거를 명확히 남깁니다.

**기대 아웃컴**

1. 구조/품질 드리프트가 심각도와 영향 범위와 함께 보고됩니다.
2. docs 모드에서 일관성, 링크, 출처 추적 이슈가 결정론적으로 드러납니다.
3. 수정 후 재실행 시 경고/오류 지표가 근거와 함께 수렴합니다.

### [handoff](plugins/cwf/skills/handoff/SKILL.md)

주요 트리거: `cwf:handoff`

**왜 필요한가**

세션/페이즈 경계에서 대화 메모리에 의존하지 않고 작업 연속성을 유지하기 위해 필요합니다.

**실행하면 무엇이 일어나는가**

상태와 산출물을 바탕으로 세션/페이즈 핸드오프 문서를 생성해 범위, 제약, 미해결 항목, 재시작 지점을 전달합니다.

**기대 아웃컴**

1. 다음 세션 시작점이 파일 기반 계약으로 명확해집니다.
2. phase handoff가 WHAT 계획 문서에 HOW 제약을 보완합니다.
3. compact/restart 이후에도 저장된 아티팩트로 실행을 재개할 수 있습니다.

### [ship](plugins/cwf/skills/ship/SKILL.md)

주요 트리거: `cwf:ship`

**왜 필요한가**

이슈/PR/머지 준비를 표준화하면서 최종 인간 판단 지점을 명확히 유지하기 위해 필요합니다.

**실행하면 무엇이 일어나는가**

검증된 세션 산출물을 이슈/PR/머지 준비 산출물로 변환하고, 남은 리스크를 가드레일로 노출합니다.

**기대 아웃컴**

1. 이슈/PR 산출물에 결정 근거와 검증 맥락이 포함됩니다.
2. 차단 이슈가 남아 있으면 진행이 명시적으로 보류됩니다.
3. 머지는 사용자 명시 승인과 깨끗한 상태가 있을 때만 실행 가능해집니다.

### [review](plugins/cwf/skills/review/SKILL.md)

주요 트리거: `cwf:review`

**왜 필요한가**

구현 전후 핵심 지점에 동일한 품질 게이트를 적용해 리스크를 조기 차단하기 위해 필요합니다.

**실행하면 무엇이 일어나는가**

내부/외부/도메인 관점의 병렬 리뷰를 실행해 합성 결론을 만들고, 게이트 판정을 결정론적으로 남깁니다.

**기대 아웃컴**

1. 계획 리뷰 모드에서 코드 작성 전 명세 리스크가 드러납니다.
2. 코드 리뷰 모드에서 회귀/보안/아키텍처 우려가 명시적 findings로 정리됩니다.
3. 외부 제공자가 불가해도 fallback 라우팅으로 게이트 의미를 유지합니다.

### [hitl](plugins/cwf/skills/hitl/SKILL.md)

주요 트리거: `cwf:hitl`

**왜 필요한가**

자동 리뷰만으로 부족한 지점에 인간 판단을 안정적으로 주입하기 위해 필요합니다.

**실행하면 무엇이 일어나는가**

합의 라운드로 시작해 청크 단위 재개 가능한 리뷰를 수행하고, 룰/상태를 파일로 저장해 긴 검토를 통제 가능하게 만듭니다.

**기대 아웃컴**

1. 큰 diff가 재개 가능한 청크 리뷰 형태로 관리됩니다.
2. 새 리뷰 룰이 남은 큐 동작에 전파됩니다.
3. 중단된 리뷰도 저장된 커서/근거를 기준으로 재개됩니다.

### [run](plugins/cwf/skills/run/SKILL.md)

주요 트리거: `cwf:run`

**왜 필요한가**

개별 스킬 체인을 수동으로 조합하지 않고 end-to-end 흐름을 위임하기 위해 필요합니다.

**실행하면 무엇이 일어나는가**

기본 스테이지 체인을 오케스트레이션하고, 구현 전에는 사용자 게이트를 유지하며, 구현 후에는 자동 체이닝으로 진행합니다.

**기대 아웃컴**

1. 파이프라인이 단계별 게이트와 함께 end-to-end로 진행됩니다.
2. 구현 전 미해결 모호성은 비가역 실행 전에 사용자 결정을 강제합니다.
3. 저장된 run 상태 체크포인트로 compact/restart 이후 재개가 가능해집니다.

### [setup](plugins/cwf/skills/setup/SKILL.md)

주요 트리거: `cwf:setup`

**왜 필요한가**

초기에 런타임/도구 계약을 한 번 표준화해 이후 워크플로우를 재현 가능하게 만들기 위해 필요합니다.

**실행하면 무엇이 일어나는가**

훅/의존성/환경/설정/선택적 연동에 대한 초기 계약을 대화형으로 부트스트랩하고, 선택 결과를 지속 가능한 기준 상태로 저장합니다.

**기대 아웃컴**

1. 새 저장소에 기준 설정 아티팩트와 정책 컨텍스트가 생성됩니다.
2. 필수 의존성 누락 시 설치 여부를 상호작용으로 묻고 점검을 결정론적으로 재실행합니다.
3. 선택한 Codex 연동에 대해 스코프 인지형 링크/래퍼 상태가 정합되게 보고됩니다.

### [update](plugins/cwf/skills/update/SKILL.md)

주요 트리거: `cwf:update`

**왜 필요한가**

설치된 CWF 동작을 최신 계약/수정사항/가드레일과 정렬 상태로 유지하기 위해 필요합니다.

**실행하면 무엇이 일어나는가**

스코프별 현재 설치 상태와 최신 상태를 비교하고, 명시 승인 후 업데이트를 적용하며, 필요 시 스코프 인지형 Codex 연동 경로를 재정렬합니다.

**기대 아웃컴**

1. 새 버전 적용 전에는 사용자 명시 승인이 필수 게이트로 동작합니다.
2. check 모드에서는 설치/재정렬 변경 없이 상태만 보고합니다.
3. 업데이트 후 경로 드리프트가 있으면 재정렬 전후 상태를 명시적으로 보여줍니다.

### Codex 연동

Codex CLI를 함께 쓴다면 아래 연동 명령을 1회 실행하세요. 이미 연동이 끝났다면 이 섹션은 동작 확인 용도로만 보면 됩니다.

```text
cwf:setup --codex
cwf:setup --codex-wrapper
```

연동 후 동작:
- setup은 활성 플러그인 스코프를 `local > project > user` 순서로 결정하고, 그 스코프에 맞춰 Codex 경로를 설정합니다.
- 사용자 스코프 대상: `~/.agents/skills/*`, `~/.agents/references`, `~/.local/bin/codex`
- 프로젝트/로컬 스코프 대상: `{projectRoot}/.codex/skills/*`, `{projectRoot}/.codex/references`, `{projectRoot}/.codex/bin/codex`
- 프로젝트/로컬 스코프 실행 시 사용자 전역 경로(`~/.agents`, `~/.local/bin`)를 수정하려면 추가 명시적 확인이 필요합니다.
- `cwf:setup --codex`: 선택된 스코프 경로에 CWF 스킬/레퍼런스를 연결해 Codex에서도 동일한 CWF 지식을 사용합니다.
- `cwf:setup --codex-wrapper`: 선택된 스코프 경로에 codex wrapper를 설치해 Codex 실행 종료 후 세션 로그를 기본 `.cwf/sessions/`로 자동 동기화하고, 이번 실행에서 바뀐 파일 기준으로 post-run 품질 점검을 수행합니다.
- 세션 로그 동기화는 체크포인트 기반 append 우선(증분) 방식으로 동작해 종료 시 지연과 전체 재생성 비용을 줄이고, 상태 불일치 시 전체 재생성으로 안전하게 폴백합니다.
- 세션 아티팩트 디렉토리(`plan.md`, `retro.md`, `next-session.md`)는 기존처럼 `.cwf/projects/{YYMMDD}-{NN}-{title}/`에 유지됩니다.
- post-run 점검 항목은 기본 품질 체크(markdownlint, 로컬 링크, shellcheck, live state) 외에 `apply_patch via exec_command` 위생 감지와 HITL 활성 상태에서 문서 변경 대비 scratchpad 동기화 감지도 포함합니다.
- post-run 점검은 기본 `warn` 모드로 동작하며(실패를 경고로만 보고), 필요하면 `CWF_CODEX_POST_RUN_MODE=strict`로 실패를 종료코드에 반영할 수 있습니다. 끄려면 `CWF_CODEX_POST_RUN_CHECKS=false`, 로그를 줄이려면 `CWF_CODEX_POST_RUN_QUIET=true`를 사용하세요.
- `cwf:update`는 선택 스코프 업데이트 후 기존 Codex 연동이 있을 때 stale symlink/wrapper 경로를 재조정합니다.

## 훅

CWF는 자동으로 실행되는 9개 훅 그룹을 포함합니다. 모두 기본 활성화되어 있으며, `cwf:setup --hooks`로 개별 그룹을 토글할 수 있습니다. 이 훅은 Claude Code 런타임에서 동작하며, Codex CLI에서는 동일 훅이 자동 실행되지 않습니다.

| 그룹 | 훅 유형 | 하는 일 |
|------|---------|---------|
| `attention` | Notification, Pre/PostToolUse | 유휴 상태 및 AskUserQuestion 시 Slack 알림 |
| `log` | Stop, SessionEnd | 대화 턴을 마크다운으로 자동 기록 |
| `read` | PreToolUse → Read | 파일 크기 인식 읽기 가드 (500줄 이상 경고, 2000줄 이상 차단) |
| `lint_markdown` | PostToolUse → Write\|Edit | 마크다운 린트 + 로컬 링크 검증 -- 린트 위반 시 자동 수정 유도, 깨진 링크 비동기 보고 |
| `lint_shell` | PostToolUse → Write\|Edit | 셸 스크립트용 ShellCheck 검증 |
| `deletion_safety` | PreToolUse → Bash | 위험한 삭제 명령을 차단하고 정책 준수 근거를 요구 |
| `workflow_gate` | UserPromptSubmit | setup 선행 조건이 없으면 `cwf:run`을 차단하고, `cwf:run` 게이트가 남아 있으면 ship/push/merge 의도를 차단 |
| `websearch_redirect` | PreToolUse → WebSearch | Claude의 WebSearch를 `cwf:gather --search`로 리다이렉트 |
| `compact_recovery` | SessionStart → compact, UserPromptSubmit | auto-compact 후 라이브 상태를 주입하고, 프롬프트 제출 시 세션-워크트리 바인딩 불일치를 차단 |

## 환경 설정

CWF 런타임은 아래 우선순위로 설정을 읽습니다.

1. `.cwf-config.local.yaml` (로컬/비밀값, 최고 우선순위)
2. `.cwf-config.yaml` (팀 공유 기본값)
3. 프로세스 환경 변수
4. 셸 프로파일(`~/.zshenv`, `~/.zprofile`, `~/.zshrc`, `~/.bash_profile`, `~/.bashrc`, `~/.profile`)

`cwf:setup`을 수행하면 프로젝트 설정 템플릿을 부트스트랩하고, `.cwf-config.local.yaml`을 `.gitignore`에 등록합니다.

팀 공유 기본값은 `.cwf-config.yaml`에 두세요.

```yaml
# .cwf-config.yaml
# Optional artifact path overrides
# CWF_ARTIFACT_ROOT: ".cwf"
# CWF_PROJECTS_DIR: ".cwf/projects"
# CWF_STATE_FILE: ".cwf/cwf-state.yaml"

# Optional runtime overrides (non-secret)
# CWF_GATHER_OUTPUT_DIR: ".cwf/projects"
# CWF_READ_WARN_LINES: 500
# CWF_READ_DENY_LINES: 2000
# CWF_SESSION_LOG_DIR: ".cwf/sessions"
# CWF_SESSION_LOG_ENABLED: true
# CWF_SESSION_LOG_TRUNCATE: 10
# CWF_SESSION_LOG_AUTO_COMMIT: false
```

개인/비밀값은 `.cwf-config.local.yaml`에 두세요.

```yaml
# .cwf-config.local.yaml
SLACK_BOT_TOKEN: "xoxb-your-bot-token"
SLACK_CHANNEL_ID: "D0123456789"
TAVILY_API_KEY: "tvly-your-key"
EXA_API_KEY: "your-key"
# SLACK_WEBHOOK_URL: "https://hooks.slack.com/services/..."
```

프로젝트별 설정 파일을 쓰지 않거나, 전역 기본값을 유지하려면 쉘 프로파일을 통한 환경 변수 방식을 사용하시면 됩니다.

```bash
# 필수 — Slack 알림(attention 훅)
SLACK_BOT_TOKEN="xoxb-your-bot-token"            # chat:write + im:write 스코프를 가진 Slack App
SLACK_CHANNEL_ID="D0123456789"                   # 봇 DM 채널 ID (또는 C...로 시작하는 채널 ID)
# SLACK_WEBHOOK_URL="https://hooks.slack.com/services/..."  # 선택: 웹훅 폴백(스레딩 없음)

# 필수 — 검색 API(gather)
TAVILY_API_KEY="tvly-..."                        # 웹 검색 및 URL 추출 (https://app.tavily.com)
EXA_API_KEY="..."                                # 코드 검색 (https://dashboard.exa.ai)

# 오버라이드 — attention
CWF_ATTENTION_DELAY=45                           # 기본값: 30
CWF_ATTENTION_REPLY_BROADCAST=true               # 기본값: false
CWF_ATTENTION_TRUNCATE=20                        # 기본값: 10
CWF_ATTENTION_USER_ID="U0123456789"              # 기본값: 미설정
# CWF_ATTENTION_USER_HANDLE="your-handle"        # 기본값: 미설정
# CWF_ATTENTION_PARENT_MENTION="<@U0123456789>"  # 기본값: 미설정

# 오버라이드 — gather/read/session-log
CWF_GATHER_OUTPUT_DIR=".cwf/projects"               # 기본값: .cwf/projects
CWF_READ_WARN_LINES=700                             # 기본값: 500
CWF_READ_DENY_LINES=2500                            # 기본값: 2000
CWF_SESSION_LOG_DIR=".cwf/sessions"                 # 기본값: .cwf/sessions
CWF_SESSION_LOG_ENABLED=false                       # 기본값: true
CWF_SESSION_LOG_TRUNCATE=20                         # 기본값: 10
CWF_SESSION_LOG_AUTO_COMMIT=true                    # 기본값: false

# 오버라이드 — 아티팩트 경로(고급)
# CWF_ARTIFACT_ROOT=".cwf-data"                     # 기본값: .cwf
# CWF_PROJECTS_DIR=".cwf/projects"                  # 기본값: {CWF_ARTIFACT_ROOT}/projects
# CWF_STATE_FILE=".cwf/custom-state.yaml"           # 기본값: {CWF_ARTIFACT_ROOT}/cwf-state.yaml
```

v3에서는 레거시 env 마이그레이션을 기본 `cwf:setup` 흐름에서 분리했습니다. v3 이전 키(`CLAUDE_CORCA_*`, `CLAUDE_ATTENTION_*`)를 쓰던 사용자라면 Claude Code / Codex에서 아래 프롬프트를 실행하세요.

```text
pre-v3 CWF 환경에서 업그레이드해서 CLAUDE_CORCA_* / CLAUDE_ATTENTION_* 레거시 env 키가 남아 있을 수 있습니다.
설치된 CWF 플러그인 경로를 자동으로 찾고, migrate-env-vars.sh --scan 결과를 먼저 보여준 다음,
--apply --cleanup-legacy --include-placeholders 실행 전에 확인을 요청해 주세요.
```

## 라이선스

MIT
