# Retro: 260216-03-hitl-readme-restart

> Session date: 2026-02-16
> Mode: deep
> PERSISTENCE_GATE: PASS (Batch 1/2 outputs valid, sentinel checks passed without retry)

## 1. Context Worth Remembering

- 이번 세션의 실질 목표는 “누락 의존성 발견 시 보고만 하고 끝내는 흐름”을 끊고, setup/스킬 실행 단계에서 설치/설정 질의와 재시도를 기본 계약으로 만드는 것이었다.
- 작업 중점은 `README.ko.md` SoT 의도를 다른 문서/스킬 계약으로 반영하는 것이었고, 실제 반영 범위는 `AGENTS.md`, `README.md`, `README.ko.md`, `setup/gather/ship/review` 스킬 문서, 공통 conventions까지 확장됐다.
- 기존 세션이 길어지며 token-limit 신호가 누적되어, 새 세션 디렉토리(`260216-03-hitl-readme-restart`)로 분기해 상태를 복구 가능한 구조로 유지했다.
- 현재 워크플로 핵심은 “context-deficit resilience + interactive dependency handling”의 이중 안전장치다.

## 2. Collaboration Preferences

- 사용자는 한국어 기반의 직접적/압축형 커뮤니케이션을 선호한다.
- 누락 의존성에 대해 “못 함 보고”보다 “지금 설치/설정할지 질의 → 승인 시 즉시 처리 → 재시도”를 요구한다.
- 문서 작업에서는 `README.ko.md`를 SoT로 두고 다른 문서/스킬에 반영 여부를 명시적으로 검증하는 절차를 중요하게 본다.
- 세션이 과도하게 길어지면 같은 디렉토리에서 버티는 것보다 새 세션 디렉토리 분기를 선호한다.

### Suggested Agent-Guide Updates

- 추가 제안 없음. 이번 세션에서 필요한 항목은 이미 `AGENTS.md`와 `skill-conventions.md`에 반영됨.

## 3. Waste Reduction

### Waste A: 의존성 누락의 늦은 노출

- 관찰: `shellcheck` 부재가 후반 검증 단계에서 드러나 재작업이 발생했다.
- 5 Whys 요약:
  - 왜 늦게 드러났나? setup 초기에 필수 도구 readiness를 강제하지 않았다.
  - 왜 강제하지 않았나? 누락 처리 규약이 “보고 중심”으로 남아 있었다.
  - 왜 보고 중심이었나? 실행형 설치 스크립트/질의 루프가 공통 계약이 아니었다.
  - 왜 공통 계약이 아니었나? 스킬별 동작이 분산되어 누락 대응 일관성이 약했다.
  - 왜 분산되었나? deterministic gate보다 문서 규약 비중이 높았다.
- **Finding**: 누락 의존성은 개별 실패가 아니라 워크플로 설계 결함.
- **Recommended tier**: Tier 1 (Eval/Hook) + Tier 3(문서 보완 최소화).
- **Mechanism**: `install-tooling-deps.sh` 기반 선제 체크/설치 질의 + 승인 시 재시도 계약 유지.

### Waste B: 장기 세션에서의 컨텍스트 압력 누적

- 관찰: token-limit 경고 누적으로 회고 계약 보정/재확인 턴이 증가했다.
- 5 Whys 요약:
  - 왜 누적됐나? 동일 세션에 장시간 변경/검증을 계속 적재했다.
  - 왜 계속 적재했나? 분기 기준이 늦게 적용됐다.
  - 왜 늦었나? 임계치 기반 강제 전환 룰이 약했다.
  - 왜 약했나? 상태 파일의 신호를 운영 게이트로 바로 연결하지 않았다.
  - 왜 연결하지 않았나? 수동 판단 의존이 컸다.
- **Finding**: 세션 분기는 예외가 아니라 안정성 제어 수단.
- **Recommended tier**: Tier 2 (State) + Tier 1 (자동 경고/전환 보조).
- **Mechanism**: live/session state 신호를 분기/핸드오프 트리거와 결합.

### Waste C: deep 계약 정합성 확인의 후행화

- 관찰: deep retro 계약(보조 산출물/근거)이 한 번에 완결되지 않아 후속 보정이 필요했다.
- 5 Whys 요약:
  - 왜 후행화됐나? 모드 라벨과 산출물 게이트를 동시에 닫지 못했다.
  - 왜 못 닫았나? 실행 중 검증 포인트가 단계 말미에 집중됐다.
  - 왜 집중됐나? 배치 완료 후 통합 검증 루프가 암묵적이었다.
  - 왜 암묵적이었나? 파일 sentinel 중심의 체크가 초기엔 일관 적용되지 않았다.
  - 왜 일관성이 약했나? 계약은 있었지만 자동화 관성이 낮았다.
- **Finding**: 모드 정확성은 문서 표기가 아니라 파일 계약으로 보장돼야 함.
- **Recommended tier**: Tier 1.
- **Mechanism**: deep 파일 4종 + sentinel 검증을 완료 전 필수 게이트로 유지.

## 4. Critical Decision Analysis (CDM)

### CDM 1: 토큰 한계 반복 상황에서 세션 디렉토리 분기

| Probe | Analysis |
|-------|----------|
| **Cues** | `token_limit_reached=true`가 2026-02-16에 반복 기록됐고(02:59:48Z~08:45:51Z), 이후 `session_forked ... reason=long-session-new-dir` 이벤트가 발생했다 (근거: `.cwf/projects/260216-03-hitl-readme-restart/retro-evidence.md:19`, `.cwf/projects/260216-03-hitl-readme-restart/retro-evidence.md:24`, `.cwf/projects/260216-03-hitl-readme-restart/hitl/events.log:4`). |
| **Goals** | 기존 산출물을 보존하면서 컨텍스트 손실을 줄이고, 리트로/후속 구현을 끊김 없이 재개하는 것이 목표였다 (근거: `.cwf/projects/260216-03-hitl-readme-restart/hitl/hitl-scratchpad.md:322`). |
| **Options** | 1) 기존 세션 유지, 2) 작업 중단 후 핸드오프만 작성, 3) 새 세션 디렉토리로 분기 후 라이브 포인터 전환. |
| **Basis** | 반복된 auto-compact 경계 초과는 같은 세션 유지 시 재압축/누락 위험이 높다고 판단했고, 분기 시에도 연속성은 복사+포인터 전환으로 보장 가능했다 (근거: `.cwf/projects/260216-03-hitl-readme-restart/hitl/hitl-scratchpad.md:323`, `.cwf/projects/260216-03-hitl-readme-restart/hitl/hitl-scratchpad.md:326`). |
| **Tools** | 판단 근거는 Codex 로그 스냅샷(`retro-evidence.md`)과 HITL 이벤트 로그(`events.log`)였다. |
| **Time Pressure** | `needs_follow_up=true`가 함께 관측된 시점이 다수라, 같은 세션에 계속 붙잡히면 지연 비용이 누적되는 압박이 있었다 (근거: `.cwf/projects/260216-03-hitl-readme-restart/retro-evidence.md:20`, `.cwf/projects/260216-03-hitl-readme-restart/retro-evidence.md:24`). |
| **Hypothesis** | 분기하지 않았다면 deep retro 산출물 보정(D-044)과 의존성 정책 승격(D-047)이 또 뒤로 밀려 재작업이 커졌을 가능성이 높다. |

**Key lesson**: 토큰 한계 초과가 연속 발생하면(특히 `needs_follow_up=true` 동반), 기존 산출물 보존+라이브 포인터 전환을 포함한 세션 분기를 기본 대응으로 채택한다.

### CDM 2: 누락 의존성을 “보고”에서 “즉시 설치 질의+재시도”로 전환

| Probe | Analysis |
|-------|----------|
| **Cues** | 세션의 낭비 신호가 “shellcheck 부재로 인한 늦은 실패/재작업”을 지목했고, 결정 D-047/D-048이 이를 직접 해결 대상으로 기록했다 (근거: `.cwf/projects/260216-03-hitl-readme-restart/hitl/hitl-scratchpad.md:356`, `.cwf/projects/260216-03-hitl-readme-restart/hitl/hitl-scratchpad.md:370`). |
| **Goals** | 누락 의존성으로 작업이 뒤에서 깨지는 패턴을 끊고, setup 단계에서 선제적으로 실행 가능 상태를 만드는 것이 목표였다. |
| **Options** | 1) 누락만 경고, 2) 문서 안내만 추가, 3) setup에서 설치 여부 질의 후 설치 시도 + 스킬 실행 시 1회 재시도. |
| **Basis** | 사용자 협업 선호가 “누락 보고로 끝내지 말고 지금 설치/설정할지 물은 뒤 재시도”였고, 같은 의도가 규약/스킬 문서/AGENTS에 동시 반영됐다 (근거: `.cwf/projects/260216-03-hitl-readme-restart/hitl/hitl-scratchpad.md:357`, `.cwf/projects/260216-03-hitl-readme-restart/hitl/hitl-scratchpad.md:368`). |
| **Tools** | `install-tooling-deps.sh`를 setup 경로에 추가했고, 실제 런타임에는 `~/.local/bin/shellcheck` 설치로 즉시 검증 가능 상태를 만들었다 (근거: `.cwf/projects/260216-03-hitl-readme-restart/hitl/hitl-scratchpad.md:362`, `.cwf/projects/260216-03-hitl-readme-restart/hitl/hitl-scratchpad.md:375`). |
| **Situation Assessment** | 문제를 “개별 명령 실패”가 아니라 “워크플로 설계 결함(선제 점검 부재)”으로 해석한 것이 적절했다. 결과적으로 setup/skill-conventions/README까지 정책이 일관화됐다. |
| **Hypothesis** | 경고-only를 유지했다면 shell lint skip와 late failure가 반복되고, 세션 후반에 다시 환경 수정을 하느라 리드타임이 증가했을 것이다. |

**Key lesson**: 반복되는 의존성 실패는 기능 버그가 아니라 워크플로 버그로 취급하고, “질의→설치 시도→1회 재시도”를 기본 계약으로 올린다.

### CDM 3: README.ko SoT 우선 고정 후 README/스킬 문서 반영

| Probe | Analysis |
|-------|----------|
| **Cues** | 작업 프로세스가 시작부터 “`README.ko.md` 합의→적용→다른 문서 반영” 순서를 명시했고, D-040이 SoT 기준 동기화를 별도 결정으로 고정했다 (근거: `.cwf/projects/260216-03-hitl-readme-restart/hitl/hitl-scratchpad.md:12`, `.cwf/projects/260216-03-hitl-readme-restart/hitl/hitl-scratchpad.md:14`, `.cwf/projects/260216-03-hitl-readme-restart/hitl/hitl-scratchpad.md:299`). |
| **Goals** | 문서 의도 해석의 기준점을 단일화하고, 한국어 기준 의도를 영어 README/스킬 문서에 누락 없이 반영하는 것이 목표였다. |
| **Options** | 1) 한/영 동시 편집, 2) 영어 README 선행, 3) 한국어 SoT 고정 후 반영 체크를 명시적으로 수행. |
| **Basis** | 동시 편집은 해석 드리프트를 키웠던 과거 패턴과 충돌했고, SoT 잠금 후 반영이 합의 재현률을 가장 높였다. `Next Pending Item`도 이를 후속 게이트로 유지한다 (근거: `.cwf/projects/260216-03-hitl-readme-restart/hitl/hitl-scratchpad.md:435`). |
| **Knowledge** | 기존 HITL 합의 누적(D-001~)에서 기준 문서가 흔들릴수록 재협의 비용이 커진 경험이 이미 쌓여 있었다 (근거: `.cwf/projects/260216-03-hitl-readme-restart/hitl/hitl-scratchpad.md:18`). |
| **Tools** | `hitl-scratchpad.md`를 합의/적용 SSOT로 사용해 어떤 의도가 어디로 전파됐는지 추적 가능하게 유지했다. |
| **Hypothesis** | SoT 고정 없이 README/스킬 문서를 병렬 수정했다면, 반영 누락을 찾는 정리 라운드가 늘고 회고 시점의 불일치 수정 비용이 커졌을 것이다. |

**Key lesson**: 다국어/다문서 환경에서는 “기준 문서 잠금→전파 체크” 순서를 프로세스 자체로 강제해야 드리프트를 줄일 수 있다.

### CDM 4: deep retro 계약 누락을 즉시 보정(의도-결과 갭 복구)

| Probe | Analysis |
|-------|----------|
| **Cues** | D-044가 deep retro 계약 누락을 명시했고, 누락된 보조 산출물 4개 생성과 `/find-skills unavailable` 근거 명시까지 요구했다 (근거: `.cwf/projects/260216-03-hitl-readme-restart/hitl/hitl-scratchpad.md:330`, `.cwf/projects/260216-03-hitl-readme-restart/hitl/hitl-scratchpad.md:333`, `.cwf/projects/260216-03-hitl-readme-restart/retro-evidence.md:13`). |
| **Goals** | deep 모드의 결정적 계약(필수 산출물/근거)을 현재 세션에서 완결해 다음 세션 재진입 비용을 없애는 것이 목표였다. |
| **Options** | 1) `retro.md`만 수정하고 나머지는 TODO로 넘김, 2) 누락 파일 일부만 생성, 3) deep 계약 전체를 즉시 백필. |
| **Basis** | 이전에 deep-contract mismatch가 추가 턴 소모를 만든 경험이 이미 확인됐고, 부분 보정은 같은 실패를 반복할 확률이 높았다. 그래서 전체 백필을 선택했다. |
| **Tools** | 보정 대상은 `retro.md` + deep 보조 산출물(`retro-cdm-analysis.md`, `retro-learning-resources.md`, `retro-expert-*.md`)이며, evidence 파일을 참조해 근거 공백을 메웠다 (근거: `.cwf/projects/260216-03-hitl-readme-restart/hitl/hitl-scratchpad.md:335`). |
| **Time Pressure** | 세션 분기 직후(2026-02-16) 계약 누락을 오래 방치하면 다음 세션에서 다시 문맥을 복원해야 하므로, 즉시 보정의 시간 가치가 컸다. |
| **Aiding** | deep 모드 체크리스트를 next-session에 강제 항목으로 고정한 점(D-042)은 같은 유형의 누락을 예방하는 실질적 보조 장치였다 (근거: `.cwf/projects/260216-03-hitl-readme-restart/hitl/hitl-scratchpad.md:314`). |

**Key lesson**: 회고 산출물 계약 누락은 “나중에 보완” 항목이 아니라 즉시 백필해야 하는 블로커로 취급해야 한다.


## 5. Expert Lens
### Expert alpha: W. Edwards Deming

**Framework**: 조직 성과를 개인 탓이 아닌 시스템 설계의 결과로 보고, 변동(common/special cause)을 구분해 장기적 학습 루프(PDSA)로 개선하는 관리 철학.
**Source**: W. Edwards Deming, *Out of the Crisis* (MIT Press, 1986; 특히 14 Points, pp.23-24), *The New Economics for Industry, Government, Education* (MIT Press); Deming Institute의 14 Points/SoPK 정리.
**Why this applies**: 이번 세션의 핵심 결정들은 개별 실패 대응이 아니라 워크플로 시스템 재설계(세션 분기, 의존성 계약 변경, SoT 전파 게이트)였다. 이는 Deming이 말한 "시스템을 바꾸지 않으면 같은 문제가 반복된다"는 관점과 정확히 맞닿아 있다.

토큰 한계 반복 후 세션 디렉토리를 분기한 결정(CDM 1)은, 현장 소방(firefighting)보다 시스템 안정성을 우선한 점에서 타당했다. Deming 관점에서 이는 단기 산출량 최적화가 아니라 "constancy of purpose"를 지킨 사례다. 같은 컨텍스트 압박을 계속 받는 환경에서 기존 세션을 유지했다면, 변동(압축/누락 리스크)에 대해 운영자가 과잉반응하거나 늦게 반응하는 "tampering"이 누적됐을 가능성이 높다.

누락 의존성을 경고-only에서 "설치 질의→설치 시도→1회 재시도"로 바꾼 결정(CDM 2)은, 결과 지표가 아니라 공정 자체를 개선한 조치다. 이는 14 Points의 "inspection 의존 중단"과 "시스템의 지속 개선"에 부합한다. 또한 README.ko를 SoT로 먼저 고정하고 전파를 검증한 결정(CDM 3), 그리고 deep retro 계약 누락을 즉시 백필한 결정(CDM 4)은 부서/문서 단절을 줄이고 학습 루프를 닫았다는 점에서 "break down barriers"와 "the transformation is everybody's job"에 가깝다. 다만 이번 세션은 계약 정합성 확인이 후행적으로 수행된 구간이 있어, 변동의 신호를 더 이른 시점에 통계적으로 식별하도록 게이트 설계를 앞당길 여지가 남아 있다.

**Recommendations**:
1. 세션 시작 게이트에 `dependency readiness`와 `deep-mode artifact completeness`를 체크리스트가 아닌 실행형 검증으로 넣고, 실패 시 즉시 설치/복구 질의를 강제하라. (시스템 원인 제거 우선)
2. `README.ko SoT 잠금 → 영문/스킬 문서 전파 확인`을 단일 PDSA 사이클로 표준화하고, 각 사이클 종료 시 누락률/재작업 시간을 기록해 다음 세션의 공통원인 개선 데이터로 축적하라.


### Expert beta: Sidney Dekker

**Framework**: 복잡계 안전에서의 `drift into failure`와 New View(인간 오류를 개인 원인이 아니라 시스템 맥락의 신호로 해석)
**Source**: Griffith University Staff Directory (Professor Sidney Dekker) — https://app.griffith.edu.au/phonebook/phone-search.php?format=advanced&surname=Dekker ; Sidney Dekker, *Drift into Failure* (CRC Press, 2011) — https://www.routledge.com/Drift-into-Failure-From-Hunting-Broken-Components-to-Understanding-Complex/Dekker/p/book/9781409422211 ; Sidney Dekker, *The Field Guide to Understanding 'Human Error'* 3rd ed. (CRC Press, 2014) — https://www.routledge.com/The-Field-Guide-to-Understanding-Human-Error/Dekker/p/book/9781472439055 ; Dekker, “Safety after neoliberalism,” *Safety Science* 125 (2020), 104630 — https://doi.org/10.1016/j.ssci.2020.104630
**Why this applies**: 이번 세션의 핵심은 개인 실수 교정이 아니라 반복되는 실패 패턴(토큰 한계, 늦은 의존성 실패, 문서 전파 누락 위험)을 운영 설계로 바꾸는 일이었다. 아래 평가는 위 저작의 원칙을 세션 사건에 추론 적용한 것이다.

이 세션에서 가장 잘한 점은 의존성 누락을 “도구가 없어서 실패했다”는 개인/환경 탓으로 끝내지 않고, `질의→설치 시도→1회 재시도`라는 계약으로 재설계한 것이다. 이는 *The Field Guide to Understanding ‘Human Error’*가 말하는 Bad Apple 관점 탈피와 일치한다. 즉, 실패를 사람/단일 컴포넌트의 결함으로 닫지 않고, 목표 충돌과 자원 제약 속에서 실제 작업이 어떻게 이루어지는지(작업-as-done)를 프로세스에 반영했다.

토큰 한계 반복 후 세션 디렉토리를 분기한 결정도 `drift into failure` 관점에서 타당했다. *Drift into Failure*의 핵심처럼, 대형 실패는 대개 “합리적인 일상적 조정”이 누적되며 나타난다. 이 세션의 반복 `token_limit_reached`와 deep-contract 누락은 이미 약한 신호였고, 분기+포인터 전환+즉시 백필은 그 누적 드리프트를 조기 차단한 조치였다. 특히 README.ko SoT 고정 후 전파한 흐름은 맥락 붕괴를 막는 기준점 역할을 했다.

다만 개선점은 신호의 “조기 가시화”다. 이번에는 중요한 신호를 인지한 뒤 올바르게 대응했지만, 대응 시점이 뒤로 밀리며 재작업 비용이 이미 발생했다. Dekker의 복잡계 관점에서는 사후 통제보다 경계(boundary) 근처의 약신호를 운영 게이트로 끌어올려야 한다. 즉, 실패 후 설명보다 실패 전 조향이 필요하다.

**Recommendations**:
1. 세션 상태에 `drift signal register`를 추가해 `token_limit_reached`, `needs_follow_up`, 의존성 누락, deep-contract 미충족을 선행지표로 관리하고, 임계치별 강제 동작(예: 즉시 분기, 즉시 설치 질의, 즉시 백필)을 연결한다.
2. 규정 준수 중심 체크보다 “성공을 만들 수 있는 역량 확인” 중심 게이트를 강화한다: setup 시작 시 의존성 설치 의사 확인, 승인 시 즉시 설치/설정, 실행 1회 재시도, 그리고 README.ko SoT 전파 체크를 완료 조건으로 고정한다.

## 6. Learning Resources

## Web Research Trace

- Date: 2026-02-16
- Search intent:
  - setup/skills에서 누락 의존성 감지 시 수동 경고가 아닌 상호작용형 설치 UX 설계 근거
  - shell 스크립트 품질 게이트(`shellcheck`)와 post-run hygiene 자동화 근거
  - README.ko SoT 전파와 장기 세션/compact 이후에도 남는 증거 중심 운영 근거
- Verified external URLs:
  - <https://docs.npmjs.com/cli/v7/commands/npx>
  - <https://github.com/koalaman/shellcheck>
  - <https://www.writethedocs.org/guide/docs-as-code/>

## Recommended Resources

1. npm Docs — npx
   URL: <https://docs.npmjs.com/cli/v7/commands/npx>
   - Key takeaway: `npx`는 로컬에 없는 패키지를 실행할 때 설치 여부를 프롬프트로 확인하고, 자동화 환경에서는 `--yes`/`--no`로 동작을 명시적으로 고정할 수 있다. 즉, 같은 도구라도 인터랙티브 모드와 비대화형 모드를 분리해서 설계할 수 있다는 점이 핵심이다.
   - Why it matters: setup/skills의 "missing dependency" 처리도 단순 경고에서 끝내지 말고, 기본은 사용자 확인형 설치 플로우로 두고 CI/자동 실행에서는 명시 플래그로 우회하는 이중 경로를 설계하는 근거가 된다.

2. ShellCheck (koalaman/shellcheck)
   URL: <https://github.com/koalaman/shellcheck>
   - Key takeaway: ShellCheck는 쉘 스크립트의 정적 분석기로, 런타임 전에 quoting/word splitting/조건식 등 반복되는 결함 패턴을 자동으로 잡아낸다. 저장소 README는 이를 빌드/테스트 스위트(즉, 품질 게이트) 안에 넣어 지속적으로 실행하는 운영 방식을 직접 권장한다.
   - Why it matters: 이번 워크플로우의 post-run script hygiene를 "사람이 보는 권고"가 아니라 결정적 게이트로 승격할 때, changed-files 대상 `shellcheck` 실행과 모드별 실패 정책(`warn` vs `strict`)을 정당화하는 1차 근거다.

3. Write the Docs — Docs as Code
   URL: <https://www.writethedocs.org/guide/docs-as-code/>
   - Key takeaway: Docs as Code는 문서를 코드와 같은 방식으로 다루며, 이슈 트래커·버전 관리·코드 리뷰·자동 테스트를 문서 운영에 그대로 적용한다. 이렇게 하면 문서 변경의 근거와 이력이 분산되지 않고 동일한 개발 워크플로우 안에서 추적 가능해진다.
   - Why it matters: README.ko를 SoT로 두고 관련 docs/skills에 의도를 전파할 때 "어디서 무엇이 어긋났는지"를 PR/리뷰/검증 로그로 남길 수 있어, 장기 세션이나 compact 이후에도 상태 복구와 증거 기반 회고를 안정적으로 수행할 수 있다.


## 7. Relevant Tools (Capabilities Included)

### Installed Capabilities

- Local skills (`.claude/skills`): `plugin-deploy`.
- Marketplace skills (sample, currently installed): `clarify`, `gather-context`, `refactor`, `retro`, `frontend-design`, `plugin-dev/*` 계열.
- CWF deterministic runtime assets:
  - hooks: `plugins/cwf/hooks/scripts/*`
  - scripts: `plugins/cwf/scripts/*` (이번 세션에서 `cwf-live-state.sh`, `retro-collect-evidence.sh`, `codex/post-run-checks.sh` 활용)
- Tool availability at session end:
  - available: `shellcheck`, `jq`, `gh`, `node`, `python3`
  - unavailable: `find-skills` (skill-gap branch 실행 필요가 없어서 사용하지 않음)

### Used vs Available-but-Unused

- Used in this session:
  - `plugins/cwf/scripts/cwf-live-state.sh`
  - `plugins/cwf/scripts/retro-collect-evidence.sh`
  - `scripts/codex/sync-skills.sh`
  - `plugins/cwf/skills/setup/scripts/install-tooling-deps.sh`
  - `plugins/cwf/scripts/codex/post-run-checks.sh`
- Available but not used deeply this session:
  - `plugins/cwf/hooks/scripts/check-shell.sh` (직접 hook 경유 실행은 생략)
  - `scripts/check-session.sh` (session artifact 전체검사는 이번 턴 범위 외)

### Tool Gaps

- No additional tool gaps identified.
- 이번 세션의 핵심 gap(누락 의존성 인터랙션 부재)은 setup/skill 계약 및 설치 스크립트로 이미 1차 해소됨.

### Post-Retro Findings

- Finding 1: Session-log path migration(`.cwf/projects/sessions` -> `.cwf/sessions`) introduced gate mismatch in markdownlint/pre-commit filtering.
  - Recommended tier: Tier 1 (Eval/Hook)
  - Mechanism: Update `.markdownlint-cli2.jsonc`, git-hook generators, and post-run checks to exclude `.cwf/sessions`.
  - Status: Applied in this session.
- Finding 2: `check-session.sh` usability and parsing had practical gaps (`--help` missing, session-dir selector unsupported, nested `session_id` misread in live state).
  - Recommended tier: Tier 1 (Eval/Tooling)
  - Mechanism: Add CLI help + session-dir selector support + top-level live key parsing constraints.
  - Status: Applied in this session.
- Finding 3: Recent session directories were missing baseline artifacts (`plan.md`, `lessons.md`), causing late verification friction.
  - Recommended tier: Tier 2 (State) + Tier 1 (Check enforcement)
  - Mechanism: Backfill missing artifacts and keep `session_defaults.always` contract enforced through `check-session`.
  - Status: Backfill applied for `260216-01`, `260216-02`, `260216-03`.
- Finding 4: Generated Codex session markdown (`*.codex.md`) can block commits if staged unintentionally.
  - Recommended tier: Tier 1 (Gate policy)
  - Mechanism: Keep generated logs out of staged markdown lint scope; optionally add explicit ignore policy if commit-by-default is not desired.
  - Status: Gate scope updated; repository-level ignore policy remains optional.
