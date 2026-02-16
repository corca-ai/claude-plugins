# CWF (Corca Workflow Framework)

[English](README.md)

문서 동기화 정책: 이 파일([README.ko.md](README.ko.md))을 SoT로 유지합니다. 의도를 수정하면 [README.md](README.md)와 관련 스킬 설명도 함께 동기화합니다.

구조화된 개발 세션을 컨텍스트 수집부터 회고 분석까지 반복 가능한 워크플로우로 전환하는 Claude Code 및 Codex 플러그인입니다. [Corca](https://www.corca.ai/)가 [AI-Native Product Team](AI_NATIVE_PRODUCT_TEAM.ko.md)을 위해 개발했습니다.

## 설치

### 빠른 시작

```bash
# 마켓플레이스 추가
claude plugin marketplace add https://github.com/corca-ai/claude-plugins.git

# CWF 설치
claude plugin install cwf@corca-plugins

# 스킬 및 훅 적용을 위해 Claude Code 재시작
```

재시작 후 `cwf:setup`을 1회 실행하세요. 같은 저장소 기준으로는 한 번만 실행하면 충분합니다.

```text
cwf:setup
```

### Codex 사용자(권장)

Codex CLI도 함께 사용한다면, 우선 `cwf:setup`만 실행해도 기본 안내를 받을 수 있습니다. 아래 명령은 Codex 연동만 별도로 다시 적용할 때 사용하세요.

```bash
cwf:setup --codex
cwf:setup --codex-wrapper
```

### 사용 시나리오

Claude Code / Codex CLI에서 아래처럼 자연어로 시작하면 됩니다.

```text
<문제>를 해결하려고 합니다. CWF를 사용해 워크플로우를 진행해 주세요.
```

이렇게 하면 에이전트가 `cwf:run`을 호출해 gather → clarify → plan → review(plan) → impl → review(code) → refactor → retro → ship까지 이어갈 수 있습니다. 자동 리뷰만으로 불충분해 diff를 청크 단위로 사람 확인하고 싶다면 `cwf:hitl`을 사용하세요.

플러그인 내의 각 스킬은 기본적으로 에이전트를 위한 도구들이며, 최대한 자율적으로 실행되게 되어있으므로 사용자가 자세히 사용법을 이해하는 게 필수는 아닙니다. 각 스킬의 존재 이유와 구조가 궁금하신 분들은 하단에서 각 스킬에 대한 설명을 읽어보시길 바랍니다.

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

v3.0.0부터 레거시 독립 플러그인은 마켓플레이스에서 제거되었습니다. v3.0 이전의 플러그인이 설치되어있다면 제거하고 `cwf`를 설치하세요.

## 운영 원칙

### CWF의 역할

CWF는 컨텍스트 수집, 요구사항 명확화, 계획, 구현, 리뷰, 회고, 핸드오프, 배포를 통합한 단일 워크플로우 플러그인입니다. 세션 상태 기록, 세션 로그 산출물, 훅을 통해 페이즈/세션 경계를 넘어 컨텍스트를 보존합니다.

각 스킬은 전문가 자문, 티어 분류, 에이전트 조율, 결정 포인트, 핸드오프, 출처 추적이라는 공통 컨셉을 공유해 구성됩니다. 여기서 '컨셉'은 [Daniel Jackson의 정의](references/essence-of-software/distillation.md)를 따르며, 반복되는 설계 구조를 압축해 공유하고 재사용하는 추상 단위를 의미합니다. CWF는 이 컨셉을 스킬 간 공용 규약처럼 사용합니다.

### CWF의 범위 밖

- CWF는 프로젝트별 엔지니어링 표준, CI 게이트, 사람의 제품 책임 의사결정을 대체하지 않습니다.
- CWF는 모든 결정을 완전히 자동화할 수 있다고 보장하지 않으며, 주관적 결정에는 여전히 사용자 확인이 필요합니다.
- CWF 플러그인 내의 각 스킬을 독립적으로 설치해서 사용하는 것도 가능하나, 스킬간 강결합을 의도해서 설계했기 때문에 함께 사용하기를 권장합니다.

### 가정

- 사용자는 [`.cwf/projects/`](.cwf/projects/)와 [`.cwf/cwf-state.yaml`](.cwf/cwf-state.yaml) 같은 세션 산출물을 저장하고 활용할 수 있는 저장소에서 작업합니다.
- 사용자는 [AGENTS.md](AGENTS.md)에서 시작해 필요할 때 더 깊은 문서를 읽는 점진적 공개 방식에 동의합니다.
- 사용자는 반복되는 품질 검사를 행동 기억에 의존하기보다 결정적 검증 스크립트로 관리하는 방식을 선호합니다.

## 왜 CWF인가?

### 문제

AI 에이전트는 이미 충분히 똑똑하나, 아직까지는 긴 작업을 안정적으로 수행하려면 도구와 환경이 갖춰져야 합니다. 그 중 가장 중요한 것이 맥락과 결정 이력의 보존입니다. 세션/페이즈 경계에서 컨텍스트가 끊기면 다음 작업은 다시 탐색부터 시작되고, 사람과 합의한 제약도 쉽게 누락되기 때문입니다.

또 다른 핵심 환경 요소는 에이전트 동작을 지속적으로 교정하는 품질 게이트입니다. 프로젝트 규모가 커질수록 설계 문서, 스킬 동작, 훅/스크립트가 서로 어긋나기 쉬워지고, 검증 규칙이 실제 상태를 따라가지 못하는 문제가 반복됩니다.

### 접근

CWF는 13개 스킬 전반에 조합되는 6가지 빌딩 블록 개념으로 위 문제를 해결합니다.

핵심은 다음 다섯 가지입니다.

1. 충분한 맥락을 먼저 수집하고(가설보다 증거 우선)
2. 사람과 합의한 의사결정/계획을 파일 기반 지속 메모리로 남기며
3. 훅과 결정적 검증으로 실행 경로를 안정화하고
4. 회고로 프로세스와 도구를 계속 개선하는 자가 치유 루프를 유지하고
5. 필요한 지점에서는 사람이 쉽게 개입할 수 있게 한다

이 접근을 구성하는 운영 결정은 다음과 같습니다.

1. **독립 플러그인 대신 통합 플러그인**
   - 이유: 페이즈 간 컨텍스트 손실과 단계별 실행 규칙의 일관성 붕괴를 방지하기 위해서입니다.
2. **구현 전 인간 게이트, 구현 후 자율 체이닝(`cwf:run`)**
   - 이유: 높은 판단이 필요한 결정은 사람의 통제 하에 두고, 범위가 확정된 이후에는 실행 속도를 유지하기 위해서입니다.
3. **파일 경로만 입력해도 시작되는 핸드오프 계약**
   - 이유: 세션 연속성을 결정적으로 만들고 시작 시 모호성을 줄이기 위해서입니다.

또한 품질 기준의 노후화를 막기 위해 출처 추적 점검을 병행합니다. 이 항목은 아래 핵심 개념의 '출처 추적'과 직접 연결됩니다.

### 결과

결과: 하나의 플러그인(`cwf`), 13개 스킬, 7개 훅 그룹. 컨텍스트는 세션 경계를 넘어 유지되고, 의사결정은 증거 기반으로 이루어지며, 품질 기준은 시스템과 함께 진화합니다.

## 핵심 개념

CWF 스킬이 조합하는 6가지 재사용 가능한 행동 패턴입니다. 각 개념은 장기 세션을 안정적으로 운영하기 위해 CWF가 반드시 해결해야 하는 일을 정의합니다.

**전문가 자문** -- 뒤늦은 재작업으로 번지기 전에 숨은 가정을 드러냅니다. 서로 다른 분석 렌즈를 가진 전문가가 같은 문제를 독립적으로 검토해 사각지대를 조기에 노출합니다.

**티어 분류** -- 의사결정을 시점에 맞는 권한으로 라우팅합니다. 증거 기반 결정(T1/T2)은 자율 처리하고, 진정으로 주관적인 결정(T3)만 사용자에게 올립니다.

**에이전트 조율** -- 처리량을 늘리면서도 결과 일관성을 유지합니다. 복잡도에 맞춰 최소 팀을 구성하고 의존성 기반 배치로 실행한 뒤 결과를 하나로 종합합니다.

**결정 포인트** -- 모호한 요구를 검토 가능한 선택지로 변환합니다. 결정을 내리기 전에 질문 단위로 분해해 모든 선택의 근거를 기록합니다.

**핸드오프** -- 페이즈/세션 경계에서 다시 시작하는 비용을 없앱니다. 세션 핸드오프는 맥락과 교훈을, 페이즈 핸드오프는 프로토콜과 제약을 전달합니다.

**출처 추적** -- 오래된 기준이 현재 작업을 조용히 오염시키지 않게 합니다. 참조 문서의 시스템 상태 메타데이터를 확인한 뒤에만 기준을 재사용합니다.

## 워크플로우

CWF의 기본 실행 체인은 아래와 같습니다:

```text
gather → clarify → plan → review(plan) → impl → review(code) → refactor → retro → ship
```

| # | 스킬 | 트리거 | 하는 일 |
|---|------|--------|---------|
| 1 | [gather](#gather) | `cwf:gather` | 정보 수집 -- URL, 웹 검색, 로컬 코드 탐색 |
| 2 | [clarify](#clarify) | `cwf:clarify` | 모호한 요구사항을 리서치 + 티어 분류로 정밀한 스펙으로 전환 |
| 3 | [plan](#plan) | `cwf:plan` | 리서치 기반 구현 계획과 BDD 성공 기준 작성 |
| 4 | [impl](#impl) | `cwf:impl` | 계획에 따른 병렬 구현 조율 |
| 5 | [retro](#retro) | `cwf:retro` | CDM 분석과 전문가 렌즈를 통한 지속 가능한 교훈 추출 |
| 6 | [refactor](#refactor) | `cwf:refactor` | 다중 모드 코드/스킬 리뷰 -- 스캔, 정리, 심층 리뷰, 전체적 분석 |
| 7 | [handoff](#handoff) | `cwf:handoff` | 세션 또는 페이즈 핸드오프 문서 생성 |
| 8 | [ship](#ship) | `cwf:ship` | GitHub 워크플로우 자동화 -- 이슈 생성, PR, 머지 관리 |
| 9 | [review](#review) | `cwf:review` | 6명 병렬 리뷰어를 통한 다각도 리뷰 |
| 10 | [hitl](#hitl) | `cwf:hitl` | 재개 가능한 상태 저장과 룰 전파를 갖춘 사람 참여형 변경사항/청크 리뷰 |
| 11 | [run](#run) | `cwf:run` | gather부터 ship까지 전체 파이프라인을 단계 게이트와 함께 조율 |
| 12 | [setup](#setup) | `cwf:setup` | 훅 그룹 설정, 도구 감지, 프로젝트 인덱스 선택 생성 |
| 13 | [update](#update) | `cwf:update` | CWF 플러그인 업데이트 확인 및 적용 |

**개념 조합**: `gather`, `clarify`, `plan`, `impl`, `retro`, `refactor`, `review`, `hitl`, `run`은 모두 에이전트 조율 개념을 공유합니다. `clarify`는 전문가 자문, 티어 분류, 에이전트 조율, 결정 포인트를 하나의 워크플로우에서 함께 사용합니다. `review`와 `hitl`은 서로 다른 검토 단위(병렬 리뷰어 vs 청크 기반 상호작용 루프)에서 사람의 판단과 구조화된 리뷰 조율을 결합합니다. `handoff`는 핸드오프 개념의 주요 구현체이며, `refactor`는 전체 분석 모드에서 출처 추적을 활성화합니다.

## 스킬 레퍼런스

### [gather](plugins/cwf/skills/gather/SKILL.md)

흩어진 외부 컨텍스트를 로컬에서 재사용 가능한, 에이전트가 읽기 유리한 산출물로 바꿔 추론/구현 전에 기준 입력을 고정합니다.

```text
cwf:gather <url>                  # 서비스 자동 감지 (Google/Slack/Notion/GitHub/웹)
cwf:gather --search <query>       # 웹 검색 (Tavily)
cwf:gather --search code <query>  # 코드 검색 (Exa)
cwf:gather --local <topic>        # 로컬 코드베이스 탐색
```

Google Docs/Slides/Sheets, Slack 스레드, Notion 페이지, GitHub PR/이슈, 일반 웹 URL을 자동 감지합니다. 소스 내용을 [`.cwf/projects/`](.cwf/projects/)로 내려받아 에이전트 친화적인 포맷(대개 마크다운)으로 정규화하고 출처 링크를 남깁니다. Google Docs와 Notion 내보내기는 공개/퍼블릭 공유 설정이 필요합니다. 또한 검색 결과를 저장 가능한 동일 포맷으로 맞추기 위해, 내장 WebSearch 리다이렉트 훅이 Claude의 WebSearch를 `cwf:gather --search`로 라우팅합니다.

### [clarify](plugins/cwf/skills/clarify/SKILL.md)

구현 단계에서의 재작업 비용을 줄이기 위해 계획 전에 모호성을 제거합니다.

```text
cwf:clarify <requirement>          # 리서치 기반 (기본)
cwf:clarify <requirement> --light  # 직접 질의응답, 서브에이전트 없음
```

이 스킬은 모호함을 티어 1/2/3으로 분리합니다. 코드베이스 증거로 해소 가능한 결정(티어 1)과 외부 베스트 프랙티스로 정리 가능한 결정(티어 2)은 자율 처리하고, 정책/취향처럼 정답이 없는 결정(티어 3)만 사용자에게 올립니다.

기본 모드는 요구사항을 결정 포인트로 분해하고 병렬 리서치(코드베이스 + 웹)와 전문가 분석, 티어 분류(T1/T2 자동 결정, T3 사용자 질의)를 거쳐 이유를 반복 확인합니다. 라이트 모드는 서브에이전트 없이 빠른 질의응답 루프를 제공합니다.

### [plan](plugins/cwf/skills/plan/SKILL.md)

구현과 리뷰가 공통으로 따를 수 있는 실행 계약(범위/파일/성공 기준)을 만듭니다.

```text
cwf:plan <task description>
```

구현을 바로 시작하면 승인 지점과 편집 범위가 쉽게 흐려집니다. `plan.md`를 먼저 고정하면 사용자 승인 경계가 분명해지고, 구현 단계에서의 재작업과 누락을 줄일 수 있습니다.

병렬 선행 사례 + 코드베이스 리서치를 통해 단계, 파일, 성공 기준(BDD + 정성적)을 포함한 구조화된 계획을 만들고 `.cwf/projects/`에 저장합니다. 권장 흐름은 구현 전에 `cwf:review --mode plan`으로 계획 리스크를 먼저 제거하는 것입니다.

### [impl](plugins/cwf/skills/impl/SKILL.md)

승인된 계획을 제약 누락 없이 예측 가능한 실행으로 변환합니다.

```text
cwf:impl                    # 가장 최근 plan.md 자동 감지
cwf:impl <path/to/plan.md>  # 명시적 계획 경로
```

적응형 에이전트 팀은 작업 복잡도와 의존성에 따라 에이전트 수를 1~4명으로 자동 조정하는 방식입니다. 멀티 에이전트 협업 개념은 [Agent Teams 문서](https://code.claude.com/docs/ko/agent-teams)를 참고하세요.

계획(+ 페이즈 핸드오프)을 로드하고 도메인/의존성 단위 작업으로 분해한 뒤, 적응형 에이전트 팀(1-4명)으로 병렬 실행하고 BDD 기준으로 검증합니다. 일반 순서는 `cwf:plan` → `cwf:review --mode plan` → `cwf:impl` → `cwf:review --mode code`입니다.

### [retro](plugins/cwf/skills/retro/SKILL.md)

단발성 세션 결과를 재사용 가능한 운영 개선과 도구 전략으로 전환합니다.

```text
cwf:retro            # 적응형 (기본은 심층)
cwf:retro --deep     # 전문가 렌즈 포함 전체 분석
cwf:retro --light    # 핵심 항목만 빠르게 점검 (서브에이전트 없음)
```

회고는 세션이 끝난 뒤 학습 이자를 쌓는 단계입니다. 이 과정을 통해 다음 세션의 탐색 비용이 줄고, 사용자와 에이전트 모두의 의사결정 품질이 올라갑니다. 여기서 `관련 도구`는 이번 세션에서 실제로 사용했거나 활용 가능했던 도구를 뜻하고, `도구 갭`은 반복적인 마찰을 줄이기 위해 새로 도입/개선해야 할 후보를 뜻합니다.

섹션: 기억할 만한 컨텍스트, 협업 선호도, 낭비 감소(5 Whys), 핵심 의사결정 분석(CDM), 전문가 렌즈(심층), 학습 자료(심층), 관련 도구(설치된 스킬 포함), 도구 갭. 발견 사항은 프로젝트 수준 문서에 기록해 보존합니다.

### [refactor](plugins/cwf/skills/refactor/SKILL.md)

사용자가 스킬을 계속 설치/작성하는 환경에서 전체 생태계 일관성을 유지합니다.

```text
cwf:refactor                        # 모든 스킬 퀵 스캔
cwf:refactor --code [branch]        # 커밋 기반 정리
cwf:refactor --skill <name>         # 단일 스킬 심층 리뷰
cwf:refactor --skill --holistic     # 크로스 플러그인 분석
cwf:refactor --docs                 # 문서 일관성 리뷰
```

리포지토리에서 계속 문서/스크립트/스킬이 늘어나면, 코드만 정리해서는 운영 품질이 회복되지 않습니다. 그래서 `refactor`는 코드뿐 아니라 스킬/문서까지 같은 관점으로 점검해 환경 전체의 유지보수성을 관리합니다.

퀵 스캔은 설치된 스킬 전반의 드리프트를 빠르게 감지하기 위해 존재합니다. `--skill <name>`은 특정 스킬을 커스터마이즈하거나 이상 동작을 진단할 때 집중 분석하기 위한 모드입니다. 코드 정리는 커밋을 분석해 안전한 리팩토링을 찾고(Kent Beck의 "Tidy First?"), `--holistic`은 크로스 플러그인 패턴 이슈를 감지하며, `--docs`는 문서 간 일관성을 점검합니다.

### [handoff](plugins/cwf/skills/handoff/SKILL.md)

세션 전환, 페이즈 전환, auto-compact 이후에도 다시 시작 비용 없이 이어가기 위해 세션/페이즈 핸드오프 문서를 생성합니다.

```text
cwf:handoff                # next-session.md 생성 + 등록
cwf:handoff --register     # .cwf/cwf-state.yaml에 세션 등록만
cwf:handoff --phase        # phase-handoff.md 생성 (작동 방식 컨텍스트)
```

세션 핸드오프는 작업 범위, 교훈, 미해결 항목을 다음 세션으로 전달합니다. 페이즈 핸드오프는 프로토콜, 규칙, 제약 조건을 다음 워크플로우 단계의 작동 방식으로 전달하며, 계획 문서의 작업 내용 범위를 보완합니다. `next-session.md`에는 파일 경로만 입력해도 바로 시작할 수 있는 실행 계약이 포함되며, 베이스 브랜치 탈출(브랜치 게이트)과 의미 단위 커밋 정책도 함께 담습니다.

### [ship](plugins/cwf/skills/ship/SKILL.md)

GitHub 워크플로우에서 이슈/PR/머지 단계를 일관되게 연결하고, 사람의 최종 판단 지점을 명확히 유지합니다.

```text
cwf:ship                                   # 사용법 표시
cwf:ship issue [--base B] [--no-branch]    # 이슈 + 피처 브랜치 생성
cwf:ship pr [--base B] [--issue N] [--draft]  # PR 생성
cwf:ship merge [--squash|--merge|--rebase]    # 승인된 PR 머지
cwf:ship status                            # 이슈, PR, 체크 상태 조회
```

세션 컨텍스트(`plan.md`, `lessons.md`, `retro.md`)를 바탕으로 이슈/PR 본문을 구성하며, 머지 의사결정을 위한 CDM/결정 요약, 검증 체크리스트, 사람 판단 가드레일을 포함합니다. 필요하면 머지 전 `cwf:hitl`로 사람 검토를 추가해 세부 diff 기준을 강화할 수 있습니다.

### [review](plugins/cwf/skills/review/SKILL.md)

구현 전/후의 핵심 지점에 같은 품질 게이트를 적용해 리스크를 조기에 차단합니다.

```text
cwf:review                 # 코드 리뷰 (기본)
cwf:review --mode code     # 코드 리뷰 (명시적)
cwf:review --mode clarify  # 요구사항 리뷰
cwf:review --mode plan     # 계획/스펙 리뷰
```

`cwf:plan` 직후에는 `--mode plan`으로 스코프/가정 리스크를 확인하고, `cwf:impl` 직후에는 `--mode code`로 회귀와 품질 이슈를 점검하는 흐름이 기본입니다. 2명 내부 리뷰어(Security, UX/DX)는 Task agents로, 2명 외부 리뷰어(Codex, Gemini)는 CLI로, 2명 도메인 전문가는 Task agents로 병렬 리뷰하며, 외부 CLI를 사용할 수 없을 때는 대체 경로로 전환합니다.

### [hitl](plugins/cwf/skills/hitl/SKILL.md)

자동 리뷰만으로 불충분할 때 병합 전 사람의 판단을 청크 단위로 안정적으로 반영합니다.

```text
cwf:hitl                             # 기본 베이스(upstream/main) 기준으로 시작
cwf:hitl --base <branch>             # 명시적 베이스 브랜치 기준 리뷰
cwf:hitl --resume                    # 저장된 커서에서 재개
cwf:hitl --rule "<rule text>"        # 남은 큐에 적용할 리뷰 룰 추가
cwf:review --human                   # 호환 별칭 (내부적으로 cwf:hitl로 라우팅)
```

상태는 `.cwf/projects/<session-dir>/hitl/`(`state.yaml`, `rules.yaml`, `queue.json`, `fix-queue.yaml`, `events.log`)에 저장합니다. [`.cwf/cwf-state.yaml`](.cwf/cwf-state.yaml)에는 활성 HITL 세션 포인터 메타데이터만 저장합니다.

### [run](plugins/cwf/skills/run/SKILL.md)

개별 스킬 문법을 몰라도 문제 해결 흐름 전체를 위임할 수 있게 합니다.

```text
cwf:run <task description>           # 처음부터 전체 파이프라인 실행
cwf:run --from impl                  # impl 단계부터 재개
cwf:run --skip review-plan,retro     # 특정 단계 건너뛰기
```

기본 흐름은 gather → clarify → plan → review(plan) → impl → review(code) → refactor → retro → ship이며, 구현 전에는 인간 게이트를 두고 구현 후에는 기본적으로 자동 체이닝하며 `ship`에서 사용자 확인을 받습니다. `refactor`를 기본 체인에 포함해 회고/배포 전에 스킬·문서·코드 드리프트를 한 번 더 점검합니다.

### [setup](plugins/cwf/skills/setup/SKILL.md)

초기에 환경/도구 계약을 표준화해 이후 워크플로우의 재현성을 확보합니다.

```text
cwf:setup                # 전체 설정 (훅 + 도구 + repo-index 생성 여부 질문)
cwf:setup --hooks        # 훅 그룹 선택만
cwf:setup --tools        # 외부 도구 감지만
cwf:setup --env          # 환경 변수 마이그레이션/부트스트랩만
cwf:setup --codex        # Codex 사용자 스코프(~/.agents/*)에 CWF 스킬/레퍼런스 연결
cwf:setup --codex-wrapper # 세션 로그 자동 동기화를 위한 codex wrapper 설치
cwf:setup --cap-index    # CWF capability 인덱스만 생성/갱신 (.cwf/indexes/cwf-index.md)
cwf:setup --repo-index   # 저장소 인덱스 명시적 생성/갱신
cwf:setup --repo-index --target agents # AGENTS 기반 저장소용 AGENTS.md 관리 블록
```

대화형 훅 그룹 토글, 외부 AI CLI/API 키 감지(Codex, Gemini, Tavily, Exa), 환경 변수 마이그레이션/부트스트랩(레거시 키를 표준 `CWF_*`로 변환), 선택적 Codex 연동(스킬 + wrapper), 선택적 인덱스 생성을 제공합니다. `cwf:setup` 실행만으로도 환경을 단계별로 안내받을 수 있으며, `--codex`/`--codex-wrapper`는 Codex 연동만 재실행할 때 사용합니다. CWF capability 인덱스 생성은 `cwf:setup --cap-index`, 저장소 인덱스 갱신은 `cwf:setup --repo-index --target agents`로 수행합니다.

### [update](plugins/cwf/skills/update/SKILL.md)

로컬 CWF 동작을 최신 계약/수정사항/가드레일과 정렬된 상태로 유지합니다.

```text
cwf:update               # 새 버전이 있으면 확인 + 업데이트
cwf:update --check       # 버전 확인만
```

### Codex 연동

Codex CLI를 함께 쓴다면 아래 연동 명령을 1회 실행하세요(빠른 시작의 Codex 사용자 섹션과 동일). 이미 연동이 끝났다면 이 섹션은 동작 확인 용도로만 보면 됩니다.

```bash
cwf:setup --codex
cwf:setup --codex-wrapper
```

연동 후 동작:
- Codex에서도 CWF 스킬/레퍼런스를 같은 기준으로 불러옵니다.
- `codex` 실행 시 세션 로그가 `.cwf/projects/sessions/`로 자동 동기화됩니다.
- 동기화 대상은 현재 실행에서 갱신된 세션 기준으로 고정되어, 잘못된 세션 export를 줄입니다.
- 참고: Claude Code 훅은 Codex CLI에서 직접 실행되지 않습니다.

## 훅

CWF는 자동으로 실행되는 7개 훅 그룹을 포함합니다. 모두 기본 활성화되어 있으며, `cwf:setup --hooks`로 개별 그룹을 토글할 수 있습니다. 이 훅은 Claude Code 런타임에서 동작하며, Codex CLI에서는 동일 훅이 자동 실행되지 않습니다.

| 그룹 | 훅 유형 | 하는 일 |
|------|---------|---------|
| `attention` | Notification, Pre/PostToolUse | 유휴 상태 및 AskUserQuestion 시 Slack 알림 |
| `log` | Stop, SessionEnd | 대화 턴을 마크다운으로 자동 기록 |
| `read` | PreToolUse -> Read | 파일 크기 인식 읽기 가드 (500줄 이상 경고, 2000줄 이상 차단) |
| `lint_markdown` | PostToolUse -> Write\|Edit | 마크다운 린트 + 로컬 링크 검증 -- 린트 위반 시 자동 수정 유도, 깨진 링크 비동기 보고 |
| `lint_shell` | PostToolUse -> Write\|Edit | 셸 스크립트용 ShellCheck 검증 |
| `websearch_redirect` | PreToolUse -> WebSearch | Claude의 WebSearch를 `cwf:gather --search`로 리다이렉트 |
| `compact_recovery` | SessionStart -> compact | auto-compact 후 컨텍스트 복구를 위해 라이브 세션 상태 주입 |

## 설정

셸 프로파일(`~/.zshrc` 또는 `~/.bashrc`)에 환경 변수를 설정하세요. 표준 변수는 `CWF_*`를 사용합니다(`TAVILY_API_KEY`, `EXA_API_KEY`는 예외).

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
CWF_SESSION_LOG_DIR=".cwf/projects/sessions"        # 기본값: .cwf/projects/sessions
CWF_SESSION_LOG_ENABLED=false                       # 기본값: true
CWF_SESSION_LOG_TRUNCATE=20                         # 기본값: 10
CWF_SESSION_LOG_AUTO_COMMIT=true                    # 기본값: false

# 오버라이드 — 아티팩트 경로(고급)
# CWF_ARTIFACT_ROOT=".cwf-data"                     # 기본값: .cwf
# CWF_PROJECTS_DIR=".cwf/projects"                  # 기본값: {CWF_ARTIFACT_ROOT}/projects
```

## 라이선스

MIT
