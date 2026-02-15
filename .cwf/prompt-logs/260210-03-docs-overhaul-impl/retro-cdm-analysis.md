# CDM Analysis — Session S32-impl (L1-L3+L9 Implementation)

Gary Klein의 Critical Decision Method를 적용하여 S32-impl 세션의 핵심 결정 지점
4개를 분석한다. 각 결정에 대해 5-8개의 CDM 프로브를 세션 내 구체적 증거와 함께
적용한다.

---

## CDM 1: 9x 중복 context recovery 패턴 — 추출 vs 인라인 반복

Review 단계에서 5개 skill에 걸쳐 context recovery 로직이 9회 중복된 것이
발견되었다. 이 중복은 impl 단계에서 방지 가능했으나, plan이 "동일 패턴 적용"이라고만
기술하고 공유 참조 문서 추출을 명시하지 않았기 때문에 각 skill에 개별 복사되었다.

| Probe | Analysis |
|-------|----------|
| **Cues** | Plan Step 4에 "Common pattern (applies to all sub-agent persistence steps 4-9)"라는 텍스트 블록이 있었고, Steps 5-9가 "Apply the same context recovery pattern from Step 4"라고 참조했다. 그러나 이 참조는 plan 내부 참조일 뿐, SKILL.md 간 공유 메커니즘을 지정하지 않았다. Impl agent들은 각자의 SKILL.md에 전체 패턴을 인라인으로 복사했다. |
| **Knowledge** | CWF에는 이미 `plugins/cwf/skills/references/` 디렉토리에 공유 참조 문서 패턴이 존재한다 (예: `expert-advisor-guide.md`, `skill-conventions.md`). 이 패턴을 알고 있었다면 plan 단계에서 `context-recovery-protocol.md`를 별도 파일로 설계했을 것이다. |
| **Goals** | 경쟁 목표: (a) 5개 skill 전체에 일관된 recovery 로직 적용, (b) 각 skill의 자기완결성(self-containment) 유지, (c) impl 속도 — 4개 parallel agent가 독립적으로 작업. Agent 병렬성(c)이 공유 추출(a)보다 우선시되었다. |
| **Options** | (1) Plan에서 공유 참조 파일 생성을 별도 Step으로 명시 → 각 skill이 참조, (2) 현재 방식: plan이 인라인 패턴을 기술하고 "동일 적용"이라고만 표기, (3) Impl orchestrator가 첫 번째 skill 작업 후 공통 부분을 추출하여 나머지에 적용. |
| **Basis** | Option 2가 선택된 이유: plan이 "구현 방법"이 아닌 "무엇을 구현할지"에 집중했기 때문. 공유 파일 추출은 구현 세부사항으로 간주되어 plan에서 생략되었다. 하지만 4개 parallel agent가 독립적으로 작업하는 구조에서는, 공유 추출 결정이 plan 수준에서 내려져야 한다 — agent들은 서로의 작업을 볼 수 없기 때문이다. |
| **Analogues** | S13.5-B에서 `expert-advisor-guide.md`를 만들어 clarify, review, retro 3개 skill이 공유 참조한 선례가 있다. 그때도 처음에는 각 skill에 인라인으로 작성했다가 review에서 중복이 발견되어 추출했다. 동일 패턴이 반복된 것이다. |
| **Experience** | 경험 많은 설계자라면 "5개 skill에 동일 로직"이라는 plan 문구를 보고 즉시 DRY 위반을 감지했을 것이다. 반면 경험이 적은 agent는 plan의 문자 그대로 — 각 skill에 개별 적용 — 를 따른다. Parallel agent 구조에서는 "공유 추출" 결정이 orchestrator 수준에서 선행되어야 한다는 점이 핵심이다. |
| **Aiding** | Plan 템플릿에 "Cross-cutting Pattern Check" 항목 추가: "동일 로직이 3개 이상 파일에 적용되면, 공유 참조 파일(.md)을 먼저 생성하고 각 대상이 참조하도록 설계하라." 이 체크리스트가 있었다면 plan 단계에서 방지 가능했다. |
| **Hypothesis** | Plan Step 0으로 `context-recovery-protocol.md` 생성을 포함했다면: impl agent들이 각자 인라인 복사 대신 참조 한 줄을 삽입했을 것이고, review에서 중복 concern이 발생하지 않았을 것이며, 사용자가 수동으로 추출하는 시간(review → fix 사이클)이 절약되었을 것이다. |

**핵심 교훈**: Parallel agent 구조에서 cross-cutting 패턴은 plan 수준에서 공유
파일로 선언해야 한다. Agent들은 서로의 작업을 볼 수 없으므로, "동일 적용"이라는
지시는 반드시 중복을 낳는다. **"3개 이상 대상에 동일 로직 → 공유 참조 파일 우선
생성"** 규칙을 plan 템플릿에 추가해야 한다.

---

## CDM 2: Single commit vs fine-grained per-work-item commits

Plan에서 "per-work-item commits"를 명시적으로 결정했으나(Decision #2: "더 잘게
쪼개도 됨"), 실제 impl에서는 파일 간 변경 겹침으로 단일 커밋으로 진행했다. Plan의
결정과 실행이 괴리된 intent-result gap이다.

| Probe | Analysis |
|-------|----------|
| **Cues** | Impl 실행 중 발견된 현실: Step 4(clarify persistence)와 Step 7(review persistence)이 동일한 context recovery 패턴을 사용하여, 한 skill의 변경이 다른 skill의 변경과 의미적으로 결합되었다. `git add`로 파일 단위 분리가 가능하지만, 커밋 메시지가 "clarify에 persistence 추가"와 "review에 persistence 추가"로 분리되면 패턴의 일관성이 보이지 않는다. |
| **Knowledge** | L3 교훈: "Post-hoc commit organization is viable but wasteful." S32 이전 세션에서 93파일 monolithic diff를 8개 커밋으로 수동 분리한 경험이 있었다. 그 경험이 "fine-grained가 낫다"는 판단의 근거였으나, 이번 세션의 변경은 cross-cutting 성격이 달랐다. |
| **Goals** | (a) Atomic, reviewable commits (plan의 목표), (b) 커밋 간 의미적 일관성 (하나의 패턴 변경이 5개 파일에 걸침), (c) Impl 속도 — 커밋 분리에 시간 소요. 목표 (a)와 (b)가 충돌: atomic이면 의미가 분산되고, 의미 단위면 atomic이 아니다. |
| **Options** | (1) Plan대로 per-work-item commit (Step별 1커밋, 총 11커밋), (2) 패턴별 commit ("persistence 패턴" 1커밋 + "git gate" 1커밋 + "log-turn fix" 1커밋 = 3커밋), (3) 단일 커밋 (실제 선택), (4) Hybrid — 독립적 변경(log-turn fix)만 분리하고 나머지 통합. |
| **Basis** | 단일 커밋이 선택된 pragmatic 이유: (a) 변경의 cross-cutting 성격상 깔끔한 분리가 어려웠고, (b) review에서 3개 concern이 발견되어 수정이 필요했는데, 이미 커밋된 상태에서 concern fix를 하면 fixup commit이 추가로 필요해지고, (c) 시간 압박 — compaction이 여러 차례 발생한 긴 세션에서 커밋 분리에 추가 시간을 투자하기 어려웠다. |
| **Time Pressure** | 세션 중 여러 차례 auto-compaction이 발생하여 맥락이 반복적으로 유실되었다. Compaction 후 이전 결정 재질문이 발생한 상황에서, 커밋 분리라는 추가 작업은 또 다른 compaction 리스크를 높인다. "일단 완성하고 나중에 정리"라는 판단이 합리적이었다. |
| **Situation Assessment** | Plan 작성 시점의 상황 인식: "각 work item이 독립적이므로 per-work-item commit이 자연스럽다." 실제 구현 시점의 상황: "context recovery 패턴이 cross-cutting이므로 work item 경계와 commit 경계가 일치하지 않는다." 상황 평가가 plan 시점에서 부정확했다. |
| **Hypothesis** | Option 4 (hybrid)를 선택했다면: log-turn.sh fix는 완전히 독립적이므로 별도 커밋으로 분리 가능했고, persistence 패턴은 하나의 커밋, git gate는 하나의 커밋으로 총 3커밋이 되었을 것이다. Review concern fix도 각 패턴 커밋에 squash 가능했다. 이 방식이 plan의 의도(reviewable)와 현실(cross-cutting)의 균형점이었을 것이다. |

**핵심 교훈**: Cross-cutting 변경에서 "per-work-item commit"은 오히려 의미를
분산시킨다. Commit 경계는 work item이 아니라 **변경 패턴**(pattern of change)
기준으로 결정해야 한다. Plan에서 commit 전략을 결정할 때 "변경이 cross-cutting
인가?"를 먼저 판단하고, 그렇다면 패턴별 커밋 전략을 명시해야 한다.

---

## CDM 3: Compaction 후 결정 재질문 — decisions 필드의 해상도 문제

사용자 피드백: "어느 순간부터 자꾸 내게 물어봐서." Context compaction 후 이전에
내린 결정을 잃어버려 동일한 질문을 반복한 것으로 추정된다. cwf-state.yaml의
decisions 필드가 5개 고수준 항목만 보존했기 때문이다.

| Probe | Analysis |
|-------|----------|
| **Cues** | 사용자의 직접 피드백이 핵심 cue였다. "어느 순간부터 자꾸 내게 물어봐서"라는 표현은 특정 시점(compaction) 이후 질문 빈도가 급증했음을 나타낸다. Compact recovery hook이 cwf-state.yaml의 live 섹션을 주입하지만, decisions 필드에는 "Always feature branch", "Fine-grained per-work-item commits" 등 고수준 원칙만 있었다. |
| **Knowledge** | S29에서 구축한 compact recovery hook의 설계 의도: "세션의 핵심 맥락을 최소한으로 보존하여 compaction 후 재시작 가능하게 한다." 이 설계에서 "최소한"의 기준이 "5개 고수준 결정"이었다. 하지만 실제로 impl 단계에서는 세부 결정(예: "sentinel marker로 `<!-- AGENT_COMPLETE -->` 사용", "max_turns: research ≤20, expert ≤12")이 수십 개 존재한다. |
| **Goals** | (a) Compact recovery의 간결성 — cwf-state.yaml이 비대해지면 recovery 자체가 context를 소비, (b) 결정 보존의 완전성 — 모든 세부 결정 보존, (c) 사용자 경험 — 이미 답한 질문을 다시 받지 않음. 목표 (a)와 (b)가 직접 충돌한다. |
| **Options** | (1) decisions 필드에 모든 세부 결정 나열 (20-30개), (2) 현재 방식: 5개 고수준 결정만 (실제 선택), (3) decisions 필드는 고수준 유지 + plan.md의 구체적 결정을 key_files에 포함하여 compaction 후 재참조, (4) 결정 발생 시 즉시 plan.md에 추가 기록하고 recovery hook이 plan.md를 자동 로드. |
| **Basis** | Option 2가 선택된 이유: cwf-state.yaml의 live 섹션 설계 시 "compact recovery에 필요한 최소 정보"라는 원칙을 따랐고, decisions를 5개로 제한한 것은 YAML 파일 크기와 가독성을 고려한 것이다. 하지만 "최소 정보"의 정의가 plan/clarify 단계 기준이었지 impl 단계 기준이 아니었다. Impl은 결정 밀도가 훨씬 높다. |
| **Aiding** | 두 가지 보조 수단이 가능했다: (a) Plan.md를 key_files에 포함 — 이미 포함되어 있었지만(`prompt-logs/260210-03-docs-overhaul-impl/plan.md`), compact recovery hook이 key_files를 자동 로드하지는 않았다. (b) Impl 시작 시 plan.md의 모든 구체적 결정을 session_dir에 `decisions-detail.md`로 추출하여 recovery 대상에 포함. |
| **Situation Assessment** | Compact recovery hook은 "세션 재시작"을 위해 설계되었지 "세션 중간 compaction"을 위해 설계된 것이 아니었을 가능성이 있다. 세션 중간 compaction에서는 이미 진행 중인 작업의 미시적 결정들이 중요한데, recovery hook은 거시적 맥락만 복원한다. 이 gap이 "자꾸 물어보는" 현상의 구조적 원인이다. |

**핵심 교훈**: Compact recovery의 결정 보존 해상도는 **현재 phase의 결정 밀도**에
비례해야 한다. Clarify/plan 단계에서는 5개 고수준 결정으로 충분하지만, impl
단계에서는 수십 개의 세부 결정이 존재한다. **Phase별 recovery 전략 분화** — impl
단계에서는 plan.md 전문을 recovery context에 포함하거나, 구현 중 발생하는 세부
결정을 파일에 즉시 기록하는 메커니즘이 필요하다.

---

## CDM 4: Gemini CLI 실패 시 104초 대기 후 fallback — fail-fast 부재

Review 단계에서 Gemini CLI (gemini-2.5-pro)가 MODEL_CAPACITY_EXHAUSTED (429)로
실패했다. 3회 retry를 포함하여 104초를 소비한 후에야 Task agent fallback으로
전환되었다.

| Probe | Analysis |
|-------|----------|
| **Cues** | Gemini CLI의 stderr.log에 HTTP 429 MODEL_CAPACITY_EXHAUSTED 에러가 기록되었다. 하지만 review SKILL.md의 Phase 3.2 에러 처리는 exit code만 확인하고 "FAILED → fallback"으로 분류했다. 에러의 성격(일시적 capacity vs 영구적 auth 실패)을 구분하지 않았다. |
| **Knowledge** | L9 교훈에 기록된 대로, exit code 기반 분류는 "왜?"에 답할 수 없다. HTTP 429는 재시도로 해결될 수 있는 에러이지만, MODEL_CAPACITY_EXHAUSTED는 서버 측 용량 문제로 단기간 내 해결 가능성이 낮다. 이 구분을 아는 것과 모르는 것의 차이가 104초다. |
| **Goals** | (a) External CLI 활용 극대화 — Gemini의 독립적 관점 확보, (b) Review 단계 전체 소요 시간 최소화, (c) Fallback 품질 — Task agent가 Gemini만큼의 관점을 제공하는가. 104초 대기는 목표 (a)를 추구하다 목표 (b)를 희생한 것이다. |
| **Options** | (1) 현재 방식: 3회 retry + 전체 timeout 후 fallback (104초), (2) Fail-fast: 첫 429 응답에서 capacity 에러 감지 → 즉시 fallback (10초 이내), (3) Parallel hedging: Gemini 요청과 동시에 Task agent를 예비 실행, 먼저 완료된 쪽 채택, (4) Pre-flight check: Gemini CLI 호출 전 간단한 health check로 capacity 확인. |
| **Basis** | Option 1이 사용된 이유: review SKILL.md가 retry 로직을 CLI 자체에 위임했기 때문. CLI 내부의 retry 정책을 SKILL.md가 제어하지 못한다. 또한 Phase 3.2의 에러 분류가 binary (성공/실패)여서, "실패의 종류"에 따른 분기가 없었다. |
| **Tools** | Gemini CLI (`gemini` command)는 내장 retry 로직을 갖고 있다. 이 retry가 429에 대해 exponential backoff을 적용하여 총 104초를 소비했다. SKILL.md에서 CLI의 `--max-retries 0` 또는 `--timeout 30s` 옵션을 지정했다면 대기 시간을 줄일 수 있었다. 하지만 이 옵션의 존재 여부가 plan/impl 시점에서 조사되지 않았다. |
| **Time Pressure** | Review 단계에서 6개 reviewer를 parallel로 실행하므로, 하나의 실패가 전체를 blocking하지는 않는다. 하지만 Gemini slot이 실패하면 fallback agent가 추가 실행되므로, 전체 review 시간이 `max(정상 5개, Gemini 104초 + fallback)` = 104초 + alpha가 된다. 가장 느린 slot이 전체를 결정하는 구조에서 104초 낭비는 크다. |
| **Hypothesis** | Option 2 (fail-fast)를 적용했다면: 첫 429 응답(약 5-10초)에서 에러 메시지를 파싱하여 CAPACITY 키워드를 감지하고 즉시 fallback을 실행했을 것이다. 전체 review 시간이 ~100초 단축되었을 것이며, 이 시간은 compaction이 빈번한 긴 세션에서 특히 가치가 높다. |

**핵심 교훈**: External CLI 호출에서 **에러 종류별 전략 분화**가 필요하다. 429
CAPACITY는 retry가 무의미하므로 fail-fast, 500 INTERNAL은 1회 retry 후 fallback,
401 AUTH는 즉시 중단. **"exit code만 보지 말고 stderr의 에러 메시지를 파싱하여
fail-fast 조건을 판단하라"**는 규칙을 review SKILL.md Phase 3.2에 추가해야 한다.

---

## 종합 패턴

4개 결정을 관통하는 구조적 패턴이 보인다:

### 1. Plan-time 결정의 해상도 부족

CDM 1 (공유 파일 미추출)과 CDM 2 (commit 전략 불일치) 모두 plan 단계에서의 결정이
impl 현실과 괴리된 사례다. Plan이 "무엇을"에 집중하면서 "어떻게"의 cross-cutting
측면을 생략했다. Parallel agent 구조에서는 "어떻게"의 일부(공유 자원 설계, commit
경계 전략)가 plan 수준의 결정이 되어야 한다.

### 2. Recovery 설계의 phase-awareness 부족

CDM 3 (결정 재질문)과 CDM 4 (fail-fast 부재) 모두 "현재 phase의 특성"을 고려하지
않은 일률적 recovery/fallback 설계에서 비롯되었다. Compact recovery는 phase별 결정
밀도를, 에러 처리는 에러 종류별 심각도를 고려해야 한다.

### 3. Intent-result gap의 반복적 패턴

이번 세션에서 가장 주목할 점은 **의도와 결과의 괴리가 여러 수준에서 반복**되었다는
것이다:
- Plan의 per-work-item commit 의도 → 실제 single commit
- Plan의 "동일 패턴 적용" 의도 → 실제 9x 중복
- Compact recovery의 결정 보존 의도 → 실제 세부 결정 유실
- Gemini retry의 복구 의도 → 실제 104초 무의미한 대기

이 패턴은 **설계 시점의 가정이 실행 시점에서 무효화되는 구조적 문제**를 시사한다.
James Reason의 Swiss cheese model 관점에서, 각 gap은 개별 layer의 hole이지만,
여러 hole이 정렬되면 전체 시스템의 실패로 이어진다. 이번 세션에서는 사용자가 모든
gap을 수동으로 보정했지만, 이는 지속 가능한 방어가 아니다.

### 실행 항목

| # | 항목 | 대상 파일 | 근거 |
|---|------|----------|------|
| 1 | Plan 템플릿에 "Cross-cutting Pattern Check" 추가 | `plugins/cwf/skills/plan/SKILL.md` | CDM 1 |
| 2 | Impl commit 전략에 "cross-cutting 여부 판단" 분기 추가 | `plugins/cwf/skills/impl/SKILL.md` | CDM 2 |
| 3 | Compact recovery에 phase별 결정 밀도 대응 검토 | `plugins/cwf/hooks/scripts/session-start-compact.sh` | CDM 3 |
| 4 | Review Phase 3.2에 에러 종류별 fail-fast 조건 추가 | `plugins/cwf/skills/review/SKILL.md` | CDM 4 |

<!-- AGENT_COMPLETE -->
