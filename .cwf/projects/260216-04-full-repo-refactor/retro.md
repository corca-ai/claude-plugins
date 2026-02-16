# Retro: Full Repository Refactoring

> Session date: 2026-02-16
> Mode: deep
> Session ID: 260216-04
> Branch: marketplace-v3

## 1. Context Worth Remembering

- CWF 플러그인 아키텍처: 13개 스킬, 7개 훅 그룹, 단일 플러그인 구조 (`plugins/cwf/`)
- README.ko.md가 SSOT; README.md는 그 구조를 미러링해야 함 (콘텐츠뿐 아니라 **구조까지** 포함)
- Expert roster는 `cwf-state.yaml`에 15개 항목, `verified: true` 필드로 웹 검증 스킵 최적화
- 린트 규칙(CORCA003 등)이 컨벤션 문서보다 권위적인 SSOT — AUTO_EXISTING 원칙
- 스킬의 Language 선언은 "user's language" 패턴을 따라야 하며, 특정 언어 하드코딩 금지
- base branch 기본값은 `main`이어야 함 (개발 브랜치 하드코딩은 기술 부채)
- 세션 아티팩트는 `.cwf/projects/{YYMMDD}-{seq}-{title}/`에 저장
- 이 세션은 배포 전 전면 품질 점검으로, 4가지 refactor 모드 전부를 실행한 최초의 종합 세션

## 2. Collaboration Preferences

- 사용자는 토큰 비용보다 분석 깊이를 우선함 — "토큰이 많이 들어도 상관없으니 서브에이전트와 codex, gemini 최대한 활용"
- 중간 피드백을 실시간으로 제공하고 즉각 반영을 기대함 (roster 중복 지적 → 즉시 추출)
- 한국어 커뮤니케이션 선호
- 잘 정의된 범위 내에서는 자율 실행을 신뢰함
- 레슨을 참고한 retro를 명시적으로 요청 — 아티팩트 간 연결을 중시

### Suggested Agent-Guide Updates

- 없음 (이번 세션에서 기존 AGENTS.md 규약과 충돌하는 패턴 미발견)

## 3. Waste Reduction

### 낭비 1: CORCA003 린트 vs 컨벤션 문서 충돌로 인한 초기 혼란

- **관찰**: Holistic Analysis에서 13개 SKILL.md가 single-line `"` frontmatter를 사용하는데 `skill-conventions.md`는 multi-line `|`을 요구한다고 발견됨. 어느 쪽이 정답인지 판단하는 데 분석 시간 소요.
- **5 Whys**:
  - 왜 충돌이 존재했나? 린트 규칙(CORCA003)이 나중에 추가되면서 문서를 업데이트하지 않았음
  - 왜 업데이트하지 않았나? 린트 규칙 추가 시 컨벤션 문서 동기화 체크가 없었음
  - 왜 체크가 없었나? 린트 규칙과 문서 사이에 교차 참조(cross-reference)가 없어서 한쪽 변경 시 다른 쪽 존재를 인식하지 못함
  - 왜 교차 참조가 없었나? 린트 규칙과 문서를 별개의 관심사로 취급하는 관행
  - 왜 별개로 취급했나? 자동화(린트)와 산문(문서)의 동기화가 프로세스에 내장되지 않았음
- **구조 원인**: 프로세스 갭 — 린트-문서 간 양방향 참조 부재
- **권장 티어**: Tier 1 (Eval/Hook) — CORCA 린트 파일에 `# Convention doc: skill-conventions.md §{section}` 역참조, 컨벤션 문서에 `<!-- Gate: CORCA00N -->` 마커 추가

### 낭비 2: Ship 스킬 하드코딩 8개 — 체계적 탐색 미비

- **관찰**: ship SKILL.md에서 Language, base branch, 한국어 리터럴 등 8개 하드코딩을 개별적으로 발견하며 수정. 한 번에 패턴 검색으로 전부 잡을 수 있었음.
- **5 Whys**:
  - 왜 8개를 개별 발견했나? Deep Review quality agent가 콘텐츠 수준에서 발견했지만 패턴 목록을 제공하지 않았음
  - 왜 패턴 목록이 없었나? Deep Review가 개별 이슈를 나열하지 "같은 냄새의 모든 인스턴스"를 그룹화하지 않았음
  - 왜 그룹화하지 않았나? review-criteria.md에 "same smell grouping" 지침이 없음
  - 왜 지침이 없었나? 리뷰 기준이 개별 발견(finding) 중심이지 패턴(smell) 중심이 아님
  - 왜 패턴 중심이 아닌가? 리뷰와 리팩터링의 관심사를 분리하는 설계
- **구조 원인**: 리뷰 도구의 출력 형식 제한 (개별 발견 vs 패턴 그룹)
- **권장 티어**: Tier 3 (Doc) — review-criteria.md에 "같은 냄새의 인스턴스를 그룹화하여 보고" 지침 추가

### 낭비 3: 토큰 한도 반복 도달

- **관찰**: Codex 로그에서 `token_limit_reached=true` 이벤트 5회 이상 발생. 컨텍스트 압축(auto-compact) 반복.
- **5 Whys**:
  - 왜 한도에 도달했나? 13개 스킬 × 2 에이전트 + holistic 3 에이전트 + code tidying 5 에이전트 등 총 30+ 에이전트 결과를 하나의 세션에서 처리
  - 왜 하나의 세션에서 처리했나? 사용자가 "전부 한 번에" 실행을 요청
  - 왜 분할하지 않았나? 세션 분할은 컨텍스트 손실 위험이 있고, compact recovery가 100% 신뢰할 수 없음
  - 구조적 제약: 현재 아키텍처에서 분석→우선순위화→구현 흐름이 하나의 연속 컨텍스트를 필요로 함
- **구조 원인**: 구조적 제약 (일회성)
- **권장 티어**: 없음 — 세션 규모에 의한 본질적 제약. CDM 횡단 관찰에서 토큰 압력이 오히려 일괄 처리를 촉진하여 일관성을 높인 역설적 효과가 있었음

## 4. Critical Decision Analysis (CDM)

> 방법론: Gary Klein의 Critical Decision Method (CDM)
> 프로브 선택 기준: 설계/컨벤션 결정 → Cues, Goals, Options, Basis, Knowledge, Analogues, Experience, Hypothesis 중심

### CDM 1: CORCA003 린트 규칙 vs 컨벤션 문서 충돌 — 린트를 SSOT로 채택

| Probe | Analysis |
|-------|----------|
| **Cues** | Holistic Convention 분석에서 13개 SKILL.md 전부가 single-line `"` description 형식을 사용하고 있음이 확인됐다. 동시에 `skill-conventions.md:33-38`은 multi-line `\|` 블록 스칼라를 명시적으로 요구하고 있었다. 결정적 단서는 CORCA003 린트 규칙이 single-line 형식을 강제하고 있다는 점이었다. |
| **Knowledge** | AUTO_EXISTING 원칙 — 이미 자동화된 게이트(린트, 스크립트)가 존재하면 그것이 사실상의 기준이다. 문서는 코드/자동화와 불일치할 때 문서 쪽이 갱신 대상이 된다. |
| **Goals** | 두 가지 목표가 충돌: (1) 컨벤션 문서의 권위를 존중하여 13개 SKILL.md를 변환, (2) 이미 작동 중인 린트 규칙과 기존 13개 파일의 일관성 유지. 추가로 harden 단계에서의 안정성 유지. |
| **Options** | A) 13개 SKILL.md를 multi-line으로 일괄 변환. B) 컨벤션 문서를 수정하여 single-line 공식화. C) CORCA003 린트 규칙을 완화하여 양 형식 허용. |
| **Basis** | 옵션 B 선택. 13개 파일 전부가 이미 single-line이므로 실제 관행이 확립됨. CORCA003이 CI 수준에서 강제하므로 de facto standard. 옵션 A는 harden 단계의 안정성 원칙에 반함. |
| **Experience** | 경험이 적은 참여자라면 "문서가 정답"이라는 직관으로 옵션 A를 선택, 불필요한 대량 diff + 린트 재충돌 가능성. |
| **Hypothesis** | 옵션 A 선택 시 13개 SKILL.md 변환 커밋 → CORCA003 린트 실패 → 린트 규칙도 수정 필요한 2차 작업 발생. |
| **Aiding** | "컨벤션 문서 vs 자동화 규칙 충돌 시 자동화가 SSOT" 명시적 체크리스트가 있었다면 분석 시간 단축 가능. |

**핵심 교훈**: 자동화된 게이트(린트, CI 스크립트)와 서술형 컨벤션 문서가 충돌하면, 자동화가 de facto SSOT이다. 문서를 수정하라.

### CDM 2: Expert Roster Update 중복 — 공유 가이드로 추출

| Probe | Analysis |
|-------|----------|
| **Cues** | 사용자가 직접 중복을 지적 ("expert roster 업데이트가 여러 스킬에 걸쳐 중복된 느낌인데.."). clarify, review, retro 3개 스킬에 expert roster 관련 로직이 분산. |
| **Knowledge** | CWF에서 "3+ 스킬에서 동일 패턴이 반복되면 shared reference로 추출"이라는 실용적 임계값. `expert-advisor-guide.md`가 이미 clarify/review의 공유 가이드로 존재. |
| **Goals** | (1) 각 스킬의 자율성 유지, (2) 유지보수 부담 감소 — roster update 로직이 한 곳에만 존재, (3) 개념 무결성 — Expert Advisor 개념의 일관된 구현. |
| **Options** | A) 현상 유지. B) `expert-advisor-guide.md`에 Roster Maintenance 섹션 추가 + 3개 스킬이 참조. C) 별도 `expert-roster-protocol.md` 신설. |
| **Basis** | 옵션 B 선택. 기존 가이드의 자연스러운 확장점. retro의 별도 가이드 유지는 개념 분열을 영속화. 옵션 C는 과도한 문서 분리. |
| **Analogues** | Context Recovery Protocol이 5개 스킬에서 참조되던 것을 공유 reference로 추출한 전례. |
| **Situation Assessment** | 단순 텍스트 중복이 아니라 **개념 구현의 비대칭**(retro만 update, clarify/review는 read)이 핵심. |
| **Hypothesis** | 현상 유지 시 비대칭이 암묵적으로 유지, 새 스킬 추가 시 참조 혼란 발생. |

**핵심 교훈**: 동일 개념을 조합하는 스킬이 3개 이상이면 공유 가이드로 추출하라. 추출의 가치는 텍스트 중복 제거가 아니라 **개념 구현의 비대칭 가시화**에 있다.

### CDM 3: Ship 스킬 언어/브랜치 하드코딩 — 동적 패턴으로 전환

| Probe | Analysis |
|-------|----------|
| **Cues** | Deep Review에서 ship SKILL.md에 8개의 하드코딩 값 발견: `Language: Korean`, `marketplace-v3` base branch, 한국어 테이블 헤더, PR 템플릿 내 한국어 리터럴. 다른 12개 스킬은 모두 "user's language" 패턴 사용. |
| **Knowledge** | CWF의 Language 선언 컨벤션: `Write {artifact type} in English. Communicate with the user in their prompt language.` Ship만 이 패턴 미준수. |
| **Goals** | (1) 포터빌리티, (2) harden 단계 안정성, (3) 13개 스킬 Language 선언 패턴 통일. |
| **Options** | A) 하드코딩 유지. B) 8개 값 전부 동적 패턴으로 전환. C) Language만 변경, branch 유지. |
| **Basis** | 옵션 B 선택. 부분 수정은 비일관성을 남김. marketplace-v3는 배포 후 main이 기본. 8개 전부 변경해도 논리 구조 불변. |
| **Tools** | Deep Review의 quality agent가 콘텐츠 레벨 하드코딩 포착. Quick Scan만으로는 불가. |
| **Time Pressure** | `token_limit_reached=true` 복수 발생 상태. 한 번에 8개 처리가 토큰 효율적. |
| **Hypothesis** | 현상 유지 시 비한국어 사용자에게 한국어 PR 템플릿 생성 — 배포 직전 P0급 이슈화. |

**핵심 교훈**: Language 선언과 브랜치 기본값은 스킬의 "환경 변수"다. 하드코딩하면 포터빌리티가 즉시 0이 된다.

### CDM 4: README 구조 정렬 — SSOT 구조를 영문에 미러링

| Probe | Analysis |
|-------|----------|
| **Cues** | Docs Review에서 한국어 README(SSOT)에 "설계 의도" + "무엇을 하는가" 서브섹션이 있으나 영문 README에 없음 발견. |
| **Knowledge** | README.ko.md가 SSOT로 선언됨. SSOT 선언의 의미는 콘텐츠뿐 아니라 구조도 기준. |
| **Goals** | (1) SSOT 원칙 준수, (2) 정보 밀도 유지, (3) 유지보수 비용 최소화. |
| **Options** | A) 13개 스킬 전부에 Design Intent + What It Does 추가 (완전 미러링). B) 영문은 단일 단락 유지, 내용만 동기화. C) 한국어 서브섹션 제거 (역방향 정렬). |
| **Basis** | 옵션 A 선택. SSOT 선언의 목적은 "한 곳에서 결정하고 나머지가 따르는 것." 구조 차이 허용은 SSOT 의미 희석. |
| **Analogues** | 소프트웨어 i18n에서 "번역 파일의 키 구조가 원본과 일치해야 한다"는 원칙과 동일. |
| **Experience** | 경험이 적은 참여자라면 "내용만 동기화, 구조 차이 허용" 선택. 스킬 증가 시 구조 괴리 기하급수적 증가. |
| **Hypothesis** | 옵션 B 시 향후 스킬 추가마다 "영문에는 서브섹션 없으니 단락만 추가" 패턴 고착, 자동화 동기화 검증 도입 시 구조 차이가 걸림돌. |

**핵심 교훈**: SSOT 선언은 콘텐츠뿐 아니라 **구조까지 포함**한다. 구조적으로 달라지는 순간 SSOT는 권고로 격하된다.

### 세션 횡단 관찰

1. **"무엇이 이미 작동하고 있는가"가 "무엇이 문서에 쓰여 있는가"보다 우선한다.** CDM 1과 CDM 3에서 동일한 AUTO_EXISTING 판단 기준 적용.
2. **harden 단계에서의 안정성 vs 정합성 긴장.** CDM 1에서는 안정성이, CDM 4에서는 정합성이 우선. **리스크 비대칭이 결정을 좌우한다.**
3. **사용자 피드백이 분석을 확인하는 trigger.** CDM 2에서 사용자의 중복 지적은 Holistic Analysis에서 이미 파악된 사항이었지만, 피드백이 우선순위를 P1으로 확정.
4. **토큰 압력이 일괄 처리를 촉진.** CDM 3에서 `token_limit_reached=true` 상황이 "8개 값을 한 번에 처리"하는 방향을 강화. 자원 제약이 오히려 일관된 변경을 유도하는 역설적 효과.

## 5. Expert Lens

### Expert α: Martin Fowler

**Framework**: 리팩터링 패턴, 지식 중복의 Rule of Three, 공유 추상화, 진화적 설계
**Source**: *Refactoring: Improving the Design of Existing Code* 2nd ed. (2018), *Is Design Dead?* (martinfowler.com), *BeckDesignRules* (martinfowler.com/bliki)
**Why this applies**: 13개 스킬과 7개 훅 그룹에 대한 전면 리팩터링 세션. 리팩터링 시기 판단, 추출 임계값, 문서-코드 관계의 긴장이 세션 전반에 걸쳐 반복.

**Moment 1 — CORCA003 린트 vs 컨벤션 문서**: CDM 1의 "린트가 SSOT" 판단에 동의하되, 린트 규칙이 **없는** 5개 Universal Rule의 준수율(0~1/13)이 Shotgun Surgery 냄새라고 진단. BeckDesignRules의 "Fewest Elements" 관점에서, 자동 강제 수단 없는 컨벤션은 해결됐다는 착시를 만듦. "린트 없는 컨벤션"을 `Aspirational (not enforced)` 섹션으로 명시적 격하 제안.

**Moment 2 — Expert Roster 추출**: Rule of Three의 교과서적 적용이었으나, 더 큰 중복(Pattern 1: Sub-Agent Output Persistence Block, 5 스킬 25+ 인스턴스)이 미뤄진 점을 지적. "변경 빈도 × 인스턴스 수" 기준으로 추출 우선순위 재정렬 제안.

**Moment 3 — Ship 하드코딩 일괄 수정**: 같은 냄새(Hardcoded Environment Assumption)의 모든 인스턴스를 한 번에 수정하는 것은 리팩터링 원칙에 부합. 다만 review와 plugin-deploy의 Language 선언 변형도 같은 커밋에 포함시켰으면 더 일관된 리팩터링이 됐을 것.

**Recommendations**:
1. 린트 없는 컨벤션 항목을 `Aspirational (not enforced)` 섹션으로 명시적 격하
2. 추출 후보를 "변경 빈도 × 인스턴스 수" 기준으로 재정렬하여 Pattern 1, Pattern 6 우선 처리

### Expert β: Sidney Dekker

**Framework**: 실패로의 표류(drift into failure) — 국소적으로 합리적인 결정들의 누적이 시스템을 점진적으로 안전 경계 밖으로 밀어냄
**Source**: *Drift into Failure* (Ashgate, 2011)
**Why this applies**: 30회 이상의 세션을 거친 CWF 프로젝트에서, 이 세션은 "누적된 미세 표류의 일괄 발견 및 교정" 세션. CDM이 각 결정의 구조를 해부했다면, 이 분석은 **그 결정들이 왜 그토록 오래 보이지 않았는가**를 다룸.

**순간 1 — Ship 스킬의 점진적 환경 고착**: S3→S4.5→현재에 걸쳐 `Language: Korean`이 축적된 과정은 "practical drift"의 전형. 각 결정이 이전 결정과 국소적으로 일관되었기 때문에 합리적으로 보였으나, 이전 결정 자체가 전역 컨벤션에서 이미 이탈. **국소적 일관성이 전역적 비일관성을 은폐.**

**순간 2 — 린트와 컨벤션 문서의 침묵하는 괴리**: "decrementalism" — 린트 규칙 추가 시 문서 업데이트가 빠지고, 괴리가 결과를 낳지 않는 동안 **괴리 자체가 정상 상태로 편입**. 린트-문서 교차 참조 주석으로 "침묵하는 괴리"를 "발화하는 괴리"로 전환 제안.

**순간 3 — README 구조 불일치의 세션간 축적**: SSOT의 "안전 마진"이 매 세션마다 잠식. holistic refactor 모드가 이 표류를 한번에 포착하고 리셋한 것이 이 프로젝트의 구조적 강점. 전체를 동시에 조망하는 분석에서만 표류가 드러남.

**Recommendations**:
1. 정기적 holistic scan 주기를 `cwf-state.yaml`에 `last_holistic_scan` + `holistic_scan_interval`로 명시 설정
2. 자동화 규칙과 컨벤션 문서 사이에 교차 참조 주석 의무화 (`# Convention doc: ...` / `<!-- Gate: CORCA00N -->`)

## 6. Learning Resources

### 1. Localization as Code: A Composable Approach to Localization

**URL**: https://phrase.com/blog/posts/localization-as-code-composable-workflow/

SSOT 다국어 문서 관리 패턴. 선언적 설정 파일로 소스/파생 언어를 정의하고, CI/CD 게이팅으로 drift를 자동 방지하는 "as code" 패러다임. 세션에서 한국어 SSOT/영어 미러 간 구조 불일치를 수동으로 발견한 경험을 **자동화된 검증 게이트로 발전**시킬 수 있는 방법론. CORCA003의 "자동화 > 문서" 교훈과 일맥상통.

### 2. Towards a Science of Scaling Agent Systems (arXiv 2512.08296)

**URL**: https://arxiv.org/html/2512.08296v1

멀티 에이전트 스케일링 정량 연구. 180개 실험 기반으로 도구-조정 트레이드오프, 역량 천장(45%), 아키텍처별 에러 증폭 계수 도출. 세션에서 30+ 서브 에이전트 병렬 실행 시 토큰 한도 도달 문제에 대한 이론적 프레임워크. "Hybrid 아키텍처가 Centralized 대비 230% 추가 비용으로 2%만 개선"이라는 수치는 CWF 오케스트레이터의 비용 최적화에 직접 적용 가능.

### 3. Designing Cooperative Agent Architectures in 2025

**URL**: https://samiranama.com/posts/Designing-Cooperative-Agent-Architectures-in-2025/

프로덕션 멀티 에이전트의 4대 설계 축: 다층 메모리, 조정 토폴로지, MCP 프로토콜, 거버넌스. CWF의 현재 manager-worker 구조에서 MCP 래핑, 최소 권한 훅 거버넌스, 세션 아티팩트 지식 그래프 확장으로 이어지는 진화 경로 제시. `cwf-hooks-enabled.sh` 선택적 토글 거버넌스의 가치를 정량적으로 뒷받침.

## 7. Relevant Tools (Capabilities Included)

### Installed Capabilities

**CWF 스킬** (13개, `plugins/cwf/skills/`):
- setup, gather, clarify, plan, impl, review, refactor, retro, run, ship, handoff, hitl, update

**로컬 스킬** (1개, `.claude/skills/`):
- plugin-deploy

**외부 도구** (`cwf-state.yaml tools:`):
- codex: available
- gemini: available
- agent_browser: available
- tavily: available
- exa: available

**결정적 도구/스크립트** (이 세션에서 사용):
- `retro-collect-evidence.sh` — retro 증거 수집
- `cwf-live-state.sh` — 라이브 상태 전이
- CORCA003 린트 — frontmatter 형식 강제
- `markdownlint-cli2` — 마크다운 린트

**이 세션에서 활용한 주요 도구**:
- `cwf:refactor` (4개 모드 전부): holistic (3 에이전트), deep (26 에이전트), code (5 에이전트), docs (인라인)
- `cwf:retro` (deep mode): CDM (1 에이전트), Learning Resources (1 에이전트), Expert α/β (2 에이전트)
- 총 38+ 서브 에이전트 실행

**미사용 도구**:
- `find-skills` (Vercel): 미설치 (`command -v find-skills` → unavailable)
- `skill-creator` (Anthropic): 미확인

### Tool Gaps

**Gap 1: README 구조 동기화 자동 검증 부재**
- **Signal**: SSOT(한국어)와 파생(영문) README 간 구조 불일치가 13개 스킬에서 축적
- **Category**: Missing validation check
- **Candidate**: SSOT 구조 스키마 정의 + CI 검증 스크립트 (`check-readme-structure.sh`)
- **Integration**: `cwf:refactor --docs` 또는 pre-commit hook
- **Expected gain**: 구조 drift 자동 감지
- **Risk/Cost**: 스키마 유지보수 비용
- **Pilot**: 섹션 헤더 수준만 비교하는 최소 스크립트

**Gap 2: 린트-컨벤션 문서 교차 참조**
- **Signal**: CORCA003과 skill-conventions.md가 충돌하면서도 미감지
- **Category**: Missing workflow automation
- **Candidate**: CORCA 규칙에 역참조 주석, 컨벤션 문서에 gate 마커
- **Integration**: 린트 규칙 변경 시 문서 동기화 검사
- **Expected gain**: 침묵하는 괴리 방지
- **Risk/Cost**: 주석 유지보수 최소
- **Pilot**: CORCA003과 `skill-conventions.md` §Frontmatter에 교차 참조 추가

**No additional skill gaps identified** — 현재 설치된 13 CWF 스킬 + 1 로컬 스킬이 워크플로우를 충분히 커버.
