# Section 4: Critical Decision Analysis (CDM)

> 세션: 260216-04 (full-repo-refactor)
> 분석 대상: 4개 핵심 결정
> 방법론: Gary Klein의 Critical Decision Method (CDM)
> 프로브 선택 기준: 설계/컨벤션 결정 → Cues, Goals, Options, Basis, Knowledge, Analogues, Experience, Hypothesis 중심

---

### CDM 1: CORCA003 린트 규칙 vs 컨벤션 문서 충돌 — 린트를 SSOT로 채택

| Probe | Analysis |
|-------|----------|
| **Cues** | Holistic Convention 분석에서 13개 SKILL.md 전부가 single-line `"` description 형식을 사용하고 있음이 확인됐다. 동시에 `skill-conventions.md:33-38`은 multi-line `\|` 블록 스칼라를 명시적으로 요구하고 있었다. 결정적 단서는 CORCA003 린트 규칙이 single-line 형식을 강제하고 있다는 점이었다. (근거: `refactor-holistic-convention.md:66` — "This is a systematic, consistent deviation — the convention says `\|` but every CWF skill uses `\"`") |
| **Knowledge** | AUTO_EXISTING 원칙 — 이미 자동화된 게이트(린트, 스크립트)가 존재하면 그것이 사실상의 기준이다. 문서는 코드/자동화와 불일치할 때 문서 쪽이 갱신 대상이 된다. 이 원칙은 CWF 프로젝트의 `project-context.md`와 AGENTS.md에 내재되어 있다. |
| **Goals** | 두 가지 목표가 충돌했다. (1) 컨벤션 문서의 권위를 존중하여 13개 SKILL.md를 multi-line으로 일괄 변환하는 방향, (2) 이미 작동 중인 린트 규칙과 기존 13개 파일의 일관성을 유지하는 방향. 추가로 harden 단계(S11-S13)에서의 안정성 유지라는 상위 목표가 있었다. |
| **Options** | A) 13개 SKILL.md를 multi-line `\|` 형식으로 일괄 변환 (컨벤션 문서 준수). B) 컨벤션 문서를 수정하여 single-line 형식을 공식화 (린트 규칙 준수). C) CORCA003 린트 규칙을 완화하여 양 형식을 허용. |
| **Basis** | 옵션 B를 선택했다. 근거: (1) 13개 파일 전부가 이미 single-line이므로 실제 운영 관행이 확립됨, (2) CORCA003이 CI 수준에서 자동 강제하므로 린트가 de facto standard, (3) 옵션 A는 13개 파일의 대량 변경이라 harden 단계의 안정성 원칙에 반함, (4) 옵션 C는 린트 게이트의 결정력을 약화시킴. |
| **Experience** | 경험이 적은 참여자라면 "문서가 정답"이라는 직관으로 옵션 A(13파일 일괄 변환)를 선택했을 가능성이 높다. 이 경우 불필요한 대량 diff가 발생하고, 린트 규칙과의 재충돌 가능성이 남는다. 반대로 경험이 풍부한 참여자는 "자동화된 게이트가 문서보다 우선"이라는 패턴을 빠르게 인식한다. |
| **Hypothesis** | 만약 옵션 A를 선택했다면: 13개 SKILL.md에 multi-line 변환 커밋이 생기고, 이후 CORCA003 린트가 실패하여 린트 규칙도 수정해야 하는 2차 작업이 발생했을 것이다. 또는 린트를 비활성화하는 방향으로 가면 자동화 게이트가 약화되는 역효과가 나타났을 것이다. |
| **Aiding** | "컨벤션 문서 vs 자동화 규칙 충돌 시 자동화가 SSOT"라는 명시적 의사결정 체크리스트가 있었다면 분석 시간을 단축할 수 있었다. 실제로 이 세션 이후 lessons.md에 해당 원칙이 기록되었다. |

**핵심 교훈**: 자동화된 게이트(린트, CI 스크립트)와 서술형 컨벤션 문서가 충돌하면, 자동화가 de facto SSOT이다. 문서를 수정하라. 코드 13곳을 고치지 마라.

---

### CDM 2: Expert Roster Update 중복 — 공유 가이드로 추출

| Probe | Analysis |
|-------|----------|
| **Cues** | 사용자가 직접 중복을 지적했다 ("expert roster 업데이트가 여러 스킬에 걸쳐 중복된 느낌인데.."). Holistic Concept 분석에서도 이미 확인된 사항이었다: clarify, review, retro 3개 스킬에 expert roster 관련 로직이 분산되어 있었고, retro만 roster update를 수행하고 clarify/review는 roster read만 했다. (근거: `refactor-holistic-concept.md:50` — "Only retro performs expert roster maintenance") |
| **Knowledge** | DRY(Don't Repeat Yourself) 원칙의 변형으로서, CWF 프로젝트에서는 "3+ 스킬에서 동일 패턴이 반복되면 shared reference로 추출"이라는 실용적 임계값이 형성되어 있었다. 또한 기존에 `expert-advisor-guide.md`가 clarify와 review의 공유 가이드로 이미 존재했으나, retro는 별도의 `expert-lens-guide.md`를 사용 중이었다. |
| **Goals** | (1) 각 스킬의 자율성 유지 — 스킬별로 expert를 다르게 활용할 수 있는 유연성, (2) 유지보수 부담 감소 — roster update 로직이 한 곳에만 존재, (3) 개념 무결성 — Expert Advisor 개념이 3개 스킬에서 일관되게 구현됨. |
| **Options** | A) 현상 유지 — 각 스킬에서 인라인으로 roster 관련 로직 관리. B) `expert-advisor-guide.md`에 Roster Maintenance 섹션을 추가하고, 3개 스킬 모두 이 가이드를 참조하도록 통합. C) 별도의 `expert-roster-protocol.md`를 신설하여 roster 전용 문서로 분리. |
| **Basis** | 옵션 B를 선택했다. 근거: (1) `expert-advisor-guide.md`가 이미 clarify/review의 공유 참조로 존재하므로 자연스러운 확장점, (2) retro의 `expert-lens-guide.md`를 별도 유지하는 것은 개념 분열(같은 Expert Advisor 개념에 두 개의 가이드)을 영속화함, (3) 옵션 C는 과도한 문서 분리로 인지 부하 증가. |
| **Analogues** | CWF 내에서 이미 유사한 추출 사례가 있었다. Context Recovery Protocol이 5개 스킬에서 참조되던 것을 공유 reference로 추출한 전례가 있으며 (`analysis.md:47` — "Referenced by 5 skills — already extracted to shared reference"), 이번 결정도 같은 패턴을 따른 것이다. |
| **Situation Assessment** | 상황 파악은 정확했다. 단순한 텍스트 중복이 아니라 **개념 구현의 비대칭**(retro만 update, clarify/review는 read만)이 핵심 문제였다. 추출을 통해 "누가 roster를 update하고 누가 read하는가"를 한 곳에서 명시할 수 있게 되었다. |
| **Hypothesis** | 옵션 A(현상 유지)를 선택했다면: retro가 roster를 update하고 clarify/review가 read하는 비대칭이 계속 암묵적으로 유지되어, 향후 새 스킬이 Expert Advisor를 조합할 때 어떤 파일을 참조해야 하는지 혼란이 발생했을 것이다. usage_count도 retro 사용만 반영하는 편향이 지속됐을 것이다. |

**핵심 교훈**: 동일 개념을 조합하는 스킬이 3개 이상이면, 인라인 로직을 공유 가이드로 추출하라. 추출의 가치는 텍스트 중복 제거가 아니라 **개념 구현의 비대칭을 가시화**하는 데 있다.

---

### CDM 3: Ship 스킬 언어/브랜치 하드코딩 — 동적 패턴으로 전환

| Probe | Analysis |
|-------|----------|
| **Cues** | Deep Review에서 ship SKILL.md에 8개의 하드코딩 값이 발견됐다: `Language: Korean` 선언, `marketplace-v3` base branch, 한국어 테이블 헤더, PR 템플릿 내 한국어 리터럴 등. (근거: `analysis.md:133` — "Hardcoded Korean language policy and marketplace-v3 base branch") 동시에 다른 12개 스킬은 모두 "user's language" 패턴을 사용하고 있었다. |
| **Knowledge** | CWF의 Language 선언 컨벤션은 `Write {artifact type} in English. Communicate with the user in their prompt language.`이다. (근거: `refactor-holistic-convention.md:78`) ship만 이 패턴을 따르지 않고 `Korean`으로 고정한 것은 초기 개발 시점의 단일 사용자 가정이 잔존한 것이다. |
| **Goals** | (1) 포터빌리티 — 다른 언어 사용자, 다른 브랜치에서도 ship 스킬이 작동, (2) 안정성 — harden 단계에서 기존 사용자(한국어, marketplace-v3 브랜치)의 워크플로우가 깨지지 않음, (3) 컨벤션 일관성 — 13개 스킬의 Language 선언 패턴이 통일됨. |
| **Options** | A) 한국어/marketplace-v3 하드코딩 유지 (현상 유지). B) 8개 값 전부를 동적 패턴으로 변환 ("user's language", `main` default, 변수화된 테이블 헤더). C) Language만 동적으로 바꾸고 branch는 유지. |
| **Basis** | 옵션 B를 선택했다. 근거: (1) 부분 수정(옵션 C)은 같은 파일 내에서 "일부는 동적, 일부는 정적"이라는 비일관성을 남김, (2) marketplace-v3는 현재 개발 브랜치일 뿐 배포 후에는 main이 기본이 되므로 하드코딩이 기술 부채, (3) 8개 항목 전부 변경해도 스킬의 논리 구조는 변하지 않으므로 리스크가 낮음, (4) 다른 12개 스킬과의 일관성 확보. |
| **Tools** | Deep Review의 per-skill 구조/품질 이중 분석(structural + quality 2개 에이전트)이 이 하드코딩을 포착했다. Quick Scan만으로는 word count/line count 수준의 플래그만 나왔을 것이고, 콘텐츠 레벨의 하드코딩은 Deep Review의 quality 에이전트가 발견한 것이다. |
| **Time Pressure** | 이 결정 시점에서 Codex 로그에 `token_limit_reached=true` 이벤트가 이미 복수 회 발생한 상태였다 (근거: `retro-evidence.md:19-20`, 07:43:11Z와 08:45:51Z). 컨텍스트 압축(auto-compact)이 진행 중이었으므로, 한 번에 8개 값을 모두 처리하는 것이 컨텍스트를 아끼는 방향이기도 했다. 분할 처리는 각 라운드마다 ship SKILL.md를 다시 읽어야 하므로 토큰 비용이 증가한다. |
| **Hypothesis** | 옵션 A(현상 유지)를 선택했다면: ship 스킬이 한국어/marketplace-v3 전용으로 남아, 플러그인 배포(marketplace 등록) 시 비한국어 사용자에게 한국어 PR 템플릿이 생성되는 문제가 발생했을 것이다. 이는 배포 직전에 발견될 경우 긴급 수정이 필요한 P0급 이슈가 된다. |

**핵심 교훈**: Language 선언과 브랜치 기본값은 스킬의 "환경 변수"다. 특정 값으로 하드코딩하면 해당 스킬의 포터빌리티가 즉시 0이 된다. "user's language" + `main` default 패턴을 컨벤션으로 강제하라.

---

### CDM 4: README 구조 정렬 — SSOT 구조를 영문에 미러링

| Probe | Analysis |
|-------|----------|
| **Cues** | Docs Review에서 한국어 README(SSOT)와 영문 README 간 구조적 불일치가 발견됐다. 한국어 버전은 각 스킬마다 "설계 의도"(Design Intent) + "무엇을 하는가"(What It Does) 서브섹션이 있었으나, 영문 버전은 통합된 단일 단락이었다. (근거: `refactor-docs-review.md:69` — "Korean version has '설계 의도' + '무엇을 하는가' structure per skill that English version lacks") |
| **Knowledge** | README.ko.md가 SSOT로 선언되어 있다는 프로젝트 규칙. SSOT 선언의 의미는 "콘텐츠뿐만 아니라 구조도 기준"이라는 점이 이전 세션(260216-02, 260216-03)에서 합의되었다. (근거: `retro-evidence.md:24` 내 CDM-1에서 "README.ko를 SoT로 고정" 결정이 기록됨) |
| **Goals** | (1) SSOT 원칙 준수 — 한국어 README의 구조를 영문에 반영, (2) 정보 밀도 유지 — 영문 README가 불필요하게 길어지지 않도록, (3) 유지보수 가능성 — 향후 스킬 추가/변경 시 양쪽 README를 동기화하는 비용 최소화. |
| **Options** | A) 영문 README에 Design Intent + What It Does 서브섹션을 13개 스킬 전부에 추가 (SSOT 완전 미러링). B) 영문 README는 현재 단일 단락 스타일을 유지하되, 내용만 한국어와 동기화 (구조 차이 허용). C) 한국어 README의 서브섹션을 제거하여 양쪽을 단일 단락으로 통일 (역방향 정렬). |
| **Basis** | 옵션 A를 선택했다. 근거: (1) SSOT 선언의 목적은 "한 곳에서 결정하고 나머지가 따르는 것"이므로 구조 차이를 허용하면 SSOT의 의미가 희석됨, (2) 옵션 C는 SSOT인 한국어 README를 변경하는 것이므로 원칙에 반함, (3) Design Intent 서브섹션은 각 스킬이 "왜 존재하는가"를 설명하는 핵심 정보이므로 영문 독자에게도 가치가 있음. 최종적으로 커밋 `9c3ca07`에서 13개 스킬 전부에 Design Intent + What It Does를 추가하여 구현됨. |
| **Analogues** | 소프트웨어 i18n에서 "번역 파일의 키 구조가 원본과 반드시 일치해야 한다"는 원칙과 동일하다. 콘텐츠는 번역될 수 있지만, 구조(섹션, 키, 계층)가 다르면 동기화 자동화가 불가능해지고 수동 대조 비용이 누적된다. |
| **Experience** | 경험이 적은 참여자라면 옵션 B(내용만 동기화, 구조 차이 허용)를 선택했을 가능성이 높다. "어차피 같은 내용이니 형식은 달라도 된다"는 판단이다. 그러나 이 접근은 스킬이 13개에서 더 늘어날 때 구조 차이가 누적되어 동기화 비용이 기하급수적으로 증가한다. |
| **Situation Assessment** | 상황 파악은 정확했다. 단, 13개 스킬 전부에 2개 서브섹션을 추가하는 것은 상당한 분량의 변경(커밋 `9c3ca07`)이었다. harden 단계에서 이 규모의 README 변경이 적절한지에 대한 긴장이 있었으나, "배포 전 문서 정비"라는 세션 목표에 부합했다. |
| **Hypothesis** | 옵션 B(구조 차이 허용)를 선택했다면: 단기적으로는 변경량이 적어 안전하지만, 향후 스킬 추가 시 "영문에는 서브섹션이 없으니 단락만 추가"하는 패턴이 고착되어 두 README 간 구조 괴리가 점점 커졌을 것이다. 특히 자동화된 동기화 검증(marketplace.json ↔ README 같은)을 도입할 때 구조 차이가 걸림돌이 된다. |

**핵심 교훈**: SSOT 선언은 콘텐츠뿐 아니라 **구조까지 포함**한다. 번역 문서가 원본과 구조적으로 달라지는 순간, SSOT는 "권고"로 격하되고 동기화 비용이 선형에서 이차로 증가한다.

---

## 세션 횡단 관찰

네 가지 결정에서 공통적으로 나타나는 패턴:

1. **"무엇이 이미 작동하고 있는가"가 "무엇이 문서에 쓰여 있는가"보다 우선한다.** CDM 1(린트 > 컨벤션 문서)과 CDM 3(12개 스킬의 기존 패턴 > ship의 하드코딩)에서 동일한 판단 기준이 적용됐다. 이는 AUTO_EXISTING 원칙의 실제 적용 사례다.

2. **harden 단계에서의 안정성 vs 정합성 긴장.** CDM 1에서는 안정성(13파일 변경 회피)이, CDM 4에서는 정합성(13스킬 서브섹션 추가)이 우선했다. 차이점은 CDM 1의 변경이 린트 충돌을 유발할 수 있었던 반면 CDM 4의 변경은 순수 문서 추가여서 기존 동작에 영향이 없었다는 점이다. **리스크 비대칭이 결정을 좌우한다.**

3. **사용자 피드백이 분석을 확인하는 trigger 역할.** CDM 2에서 사용자의 중복 지적은 Holistic Analysis에서 이미 파악된 사항이었지만, 사용자 피드백이 우선순위를 P1으로 확정하는 계기가 됐다. 데이터 기반 분석 + 사용자 직관의 교차 검증이 결정의 신뢰도를 높인다.

4. **토큰 압력이 일괄 처리를 촉진.** CDM 3에서 `token_limit_reached=true` 상황이 "8개 값을 한 번에 처리"하는 방향을 강화했다. 자원 제약이 오히려 더 일관된 변경을 유도하는 역설적 효과가 있었다.

<!-- AGENT_COMPLETE -->
