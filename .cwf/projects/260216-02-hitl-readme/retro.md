# Retro: 260216-02-hitl-readme

> Session date: 2026-02-16
> Mode: deep
> Evidence: `~/.codex/log/codex-tui.log`, `.cwf/projects/260216-02-hitl-readme/hitl/hitl-scratchpad.md`, `.cwf/projects/260216-02-hitl-readme/retro-cdm-analysis.md`, `.cwf/projects/260216-02-hitl-readme/retro-learning-resources.md`, `.cwf/projects/260216-02-hitl-readme/retro-expert-alpha.md`, `.cwf/projects/260216-02-hitl-readme/retro-expert-beta.md`

## 1. Context Worth Remembering

- 이번 세션의 문서 작업 기준은 `README.ko.md` SoT(단일 기준 문서)였다. 이후 영어 문서/스킬 문서는 SoT 의도를 반영하는 후속 동기화 대상으로 합의했다.
- HITL 운영 산출물에서 사실상 핵심은 `hitl-scratchpad.md`였고, D-001~D-038로 합의/적용 내역이 누적되었다. 이 문서가 없으면 중간 합의가 반복 손실된다.
- 사용자 피드백의 핵심은 "자율성 부족"이 아니라 "합의 해석 정확도 부족"이었다. 즉, 문제는 속도보다 합의 재현률이었다.
- 로그 기준으로 본 세션은 문서 편집 반복과 검증 반복이 매우 길었고, auto-compact 경계(`token_limit_reached=true`)를 여러 번 넘었다(예: 2026-02-16 07:43:11Z, 08:45:51Z).
- 이번 턴의 구현 범위는 wrapper 확장안 중 `2`(post-run quality checks)로 제한되었고, 최종 구현은 `warn` 기본 + `strict` 선택형으로 정리되었다.

## 2. Collaboration Preferences

- 사용자는 “다음으로 넘어갈지 묻지 말고, 합의된 청크를 연속 제시”를 원한다. 다만 이것은 "전체 자율 처리"가 아니라 "청크 단위 합의 루프 유지"라는 의미다.
- 사용자는 문체의 완전한 공식성보다 의도 보존을 우선한다. 따라서 과도한 윤문보다 "원문 의도 유지 + 어색한 최소 교정"이 선호된다.
- 사용자가 직접 파일을 고쳤다고 알린 경우, 우선순위는 즉시 재동기화다. 기존 버퍼 기반 진행을 계속하면 의도 불일치가 급격히 커진다.
- 구현 범위를 숫자/옵션으로 지정했을 때(예: "2만 구현"), 다른 개선안을 끼워 넣지 않는 범위 잠금이 중요하다.

### Suggested Agent-Guide Updates

- 제안 1: "사용자가 `N만 구현`처럼 범위를 잠그면, 해당 범위 외 변경은 명시 승인 없이는 금지" 규칙을 AGENTS 또는 HITL 규약에 명문화.
- 제안 2: "사용자가 직접 파일 수정(덮어쓰기 포함) 알림 시, 즉시 intent-resync 단계(전체 재읽기 + 변경 요약 확인)를 강제"를 HITL 규약에 추가.
- 제안 3: 문서 HITL에서 각 청크 적용 직후 `scratchpad` 갱신 여부를 체크하는 결정적 체크(스크립트/훅) 추가.

## 3. Waste Reduction

### 낭비 1: README 의도 불일치 반복

- 관찰: 사용자 코멘트 의도가 일부 문장에서 반복적으로 어긋났고, 같은 주제를 여러 차례 재협의했다.
- 5 Whys:
  - 왜 반복됐나? 합의 직후 전체 문맥 재검증 없이 국소 수정을 계속했다.
  - 왜 국소 수정에 머물렀나? 청크 단위 진행 규약은 있었지만, "사용자 직접 덮어쓰기 이후 전체 재동기화" 단계가 없었다.
  - 왜 재동기화 단계가 없었나? HITL이 diff 중심으로 설계되어 "파일 상태 변동 이벤트"를 강제하지 않았다.
  - 왜 이벤트를 강제하지 않았나? 현재 HITL 큐/상태 파일이 실행 큐 중심이고, 의도 재합의 체크포인트는 비결정적 텍스트 규약에 의존한다.
  - 왜 텍스트 규약에 의존했나? 자동 검증 가능한 규칙(훅/체크)으로 승격되지 않았다.
- 구조 원인: 프로세스 갭.
- 권장 티어: Tier 1 (Eval/Hook).
- 메커니즘: HITL 적용 스크립트에 `intent_resync_required` 플래그 도입(사용자 직접 수정 감지 시 true) + 다음 청크 진행 전 강제 확인.

### 낭비 2: 구현 범위 이탈 위험

- 관찰: `2만 구현` 요구 이후에도 범위 외 변경(대형 파일 동기화)이 잠깐 발생했고 되돌림 정리가 필요했다.
- 5 Whys:
  - 왜 이탈했나? mirror 일관성 유지 판단을 우선해 범위 해석이 넓어졌다.
  - 왜 넓어졌나? "무결성 유지"와 "요청 범위 제한" 충돌 시 우선순위 규칙이 명확하지 않았다.
  - 왜 우선순위가 불명확했나? 현재 규약에 scope lock 해제 조건이 없음.
  - 왜 조건이 없나? 구현 안전성 원칙은 있지만 사용자 지시 우선의 세부 규칙이 약하다.
  - 왜 약한가? 과거 자율 구현 패턴이 기본값으로 남아있다.
- 구조 원인: 프로세스 갭.
- 권장 티어: Tier 3 (Doc) + 가능하면 Tier 1.
- 메커니즘: HITL/구현 프로토콜에 "scope lock" 문구를 명시하고, 가능하면 pre-commit 검사에서 범위 외 파일 경고 출력.

### 낭비 3: 툴 호출 위생 오류

- 관찰: `apply_patch`를 `exec_command`로 호출해 경고가 발생했고, 사용자가 직접 지적했다.
- 5 Whys:
  - 왜 발생했나? 편집 흐름 중 습관적으로 셸 heredoc patch를 사용했다.
  - 왜 습관이 유지됐나? 도구 사용 규칙이 런타임에서 강제되지 않고 프롬프트 규약에만 있었다.
  - 왜 강제되지 않았나? hook gate가 해당 anti-pattern을 검사하지 않는다.
  - 왜 검사하지 않나? 도구 호출 메타 검사가 아직 미구현이다.
  - 왜 미구현인가? 문서 규약 우선으로 운영돼 자동화 전환이 늦었다.
- 구조 원인: 프로세스/자동화 갭.
- 권장 티어: Tier 1 (Eval/Hook).
- 메커니즘: Codex wrapper 또는 hook gate에서 `exec_command` payload 내 `apply_patch` 패턴 감지 시 실패/경고 처리.

## 4. Critical Decision Analysis (CDM)

### CDM-1: README.ko를 SoT로 고정

- Signal: 문서 방향/철학 논의가 길어지고 영어/스킬 문서 동기화 순서가 혼재됨.
- Decision: `README.ko.md`를 먼저 안정화하고, 다른 문서는 후속 반영.
- Alternatives:
  - A) 한/영 동시 수정
  - B) 스킬 문서부터 선행 수정
- Why chosen: 합의 기준점이 하나여야 해석 오차를 줄일 수 있음.
- Outcome: 합의 추적이 쉬워졌고 `hitl-scratchpad`의 D 항목 구조가 안정됨.
- Risk: 영어 문서 지연으로 일시적 불일치 발생 가능.
- Guardrail: SoT 변경 시 동기화 대상 목록을 scratchpad에 즉시 기록.

### CDM-2: HITL 개선은 플래그 추가 없이 기본 흐름에서 해결

- Signal: 사용자 피드백은 "플래그 부족"이 아니라 "진행 감각 경직" 문제였음.
- Decision: `cwf:hitl` 단일 흐름 유지 + 합의 라운드/청크 루프 품질 개선.
- Alternatives:
  - A) `--guided` 같은 새 플래그 추가
  - B) 완전 자율 모드 분리
- Why chosen: 모드 분기는 학습비용을 늘리고, 핵심 문제(합의 해석)와 직접 관련이 약함.
- Outcome: 운영 단순성 유지, 다만 규약 준수 품질이 실제 성패를 좌우.
- Risk: 구현체가 규약을 느슨하게 해석하면 동일 문제가 재발.
- Guardrail: HITL 규약의 체크리스트화를 통한 단계별 확인.

### CDM-3: Wrapper 옵션 2(post-run checks) 채택

- Signal: Codex wrapper 확장 논의에서 "어디까지 자동 검증할지"가 쟁점.
- Decision: 세션 후처리로 변경 파일 대상 품질 점검을 자동 실행 (`warn` 기본, `strict` 선택).
- Alternatives:
  - A) wrapper는 로그 동기화만 유지
  - B) pre-run 블로킹 검사 추가
- Why chosen: 사용자 흐름 방해를 최소화하면서 품질 안전망을 추가할 수 있음.
- Outcome: 구현 완료. `strict` 모드 종료코드 전파 버그를 추가 보정해 기대 동작을 맞춤.
- Risk: 체크 범위/비용이 커지면 체감 지연 증가.
- Guardrail: changed-files only 유지 + 모드/env 토글 제공.

## 5. Expert Lens

### Lens A: Concept-first Documentation (Daniel Jackson 계열)

- 평가: SoT를 중심으로 개념 경계를 고정한 점은 강점이지만, 실행 중에는 규약이 서술형으로 남아 자동 검증까지 연결되지 못했다.
- 보완점: `context-deficit resilience`가 retro 인사이트로만 남아 타 스킬 계약으로 승격되지 않은 상태였다.
- 제안: 공용 계약(단일 문구)을 정의하고 `skill-conventions`/`context-recovery-protocol`에 우선 반영한 뒤 스킬에서 참조하도록 강제.

### Lens B: Socio-technical Workflow Design

- 평가: 병목은 생성 속도가 아니라 합의 추적의 신뢰성이다. 상태가 파일에 남아도 전이 규칙이 느슨하면 다시 반복 손실이 생긴다.
- 보완점: `intent_resync_required`, scratchpad 동기화, tool hygiene의 3개 체크가 게이트화되지 않았다.
- 제안: HITL 상태 스키마 + post-run checks를 연결해 "다음 청크 진행 전 resync 확인"과 "문서 변경 후 scratchpad 업데이트"를 자동 검증.

## 6. Learning Resources

1. Vercel — AGENTS.md Outperforms Skills in Our Agent Evals  
   URL: <https://vercel.com/blog/agents-md-outperforms-skills-in-our-agent-evals>
   - 왜: 이번 세션의 SoT/인덱스 중심 구조 개편 논점과 직접 연결된다.
   - 무엇: 엔트리 문서 압축과 라우팅 중심 설계가 에이전트 성능에 미치는 효과를 사례로 제시한다.
   - 적용: 전역 계약은 AGENTS/README에 짧게 두고 실행 상세는 스킬/스크립트로 분리하는 근거로 사용.

2. HumanLayer — Writing a Good CLAUDE.md  
   URL: <https://www.humanlayer.dev/blog/writing-a-good-claude-md>
   - 왜: 규칙이 늘수록 준수율이 떨어지는 문제는 이번 회고의 "규약은 있으나 실행이 흔들림"과 동일한 패턴이다.
   - 무엇: 지시 과밀을 줄이고 자동화 가능한 항목을 도구로 승격해야 한다는 실무 원칙을 정리한다.
   - 적용: `intent_resync_required`, tool hygiene, scratchpad 동기화를 문장 규칙에서 게이트로 이동.

3. Google SRE Book — Postmortem Culture  
   URL: <https://sre.google/sre-book/postmortem-culture/>
   - 왜: 회고가 비난이 아니라 구조 개선으로 이어져야 한다는 기준을 제공한다.
   - 무엇: 사건 기록의 일관성과 재발 방지 액션의 추적 가능성을 강조한다.
   - 적용: `retro-collect-evidence` 자동화로 근거 수집을 정례화하고, 회고 항목을 즉시 실행 가능한 체크로 연결.

## 7. Relevant Tools (Capabilities Included)

### Installed Capabilities

- CWF skills: `hitl`, `retro`, `setup`, `run`, `refactor`, `review`.
- Deterministic checks/scripts used in this session:
  - `npx markdownlint-cli2`
  - `scripts/check-growth-drift.sh --level warn`
  - `.claude/skills/plugin-deploy/scripts/check-consistency.sh cwf`
  - `plugins/cwf/scripts/cwf-live-state.sh set . phase="retro"`
- New capability added this turn:
  - `plugins/cwf/scripts/codex/post-run-checks.sh` + wrapper 연동(`codex-with-log.sh`)

### Tool Gaps

- Gap 1: HITL intent-resync 자동화 부재
  - Signal: 사용자 직접 덮어쓰기 이후 의도 불일치 반복.
  - Candidate: HITL state에 `intent_resync_required`/`last_user_manual_edit_at` 필드 추가.
  - Integration: `cwf:hitl` 시작/청크 진행 전 검증.
  - Gain: 같은 쟁점 재협상 횟수 감소.
  - Risk/Cost: 상태 스키마/스킬 동시 변경 필요.

- Gap 2: Tool invocation hygiene gate 부재
  - Signal: `apply_patch via exec_command` 경고 재발.
  - Candidate: hook gate 또는 wrapper 검사 규칙 추가.
  - Integration: hook script에서 command payload 패턴 검사.
  - Gain: 반복 실수의 즉시 차단.
  - Risk/Cost: 오탐 방지 룰 필요.

- Gap 3: Retro evidence collector 부재
  - Signal: 로그/스크래치패드 근거 수집이 수동.
  - Candidate: `scripts/retro-collect-evidence.sh` (token-limit, warning, key decisions 추출).
  - Integration: `cwf:retro` 초반 단계 자동 호출.
  - Gain: 회고 품질과 일관성 향상.
  - Risk/Cost: 로그 포맷 변경에 대한 유지보수 필요.

- Skill-gap discovery evidence (`/find-skills`):
  - Command check: `command -v find-skills`
  - Result: unavailable (2026-02-16)
  - Fallback rationale: this session proceeded with in-repo implementation and records explicit install recommendation for future skill-gap scans.

### Post-Retro Findings

- 리트로 초안 작성 이후 `README.ko.md`에 남아 있던 `retro` 섹션 인라인 코멘트(저장 위치/의도 설명 누락)를 모두 반영했다.
- SoT 동기화로 `README.md`와 `plugins/cwf/skills/setup/SKILL.md`에서 Codex wrapper 설명을 구현 상태(세션 로그 동기화 + post-run 품질 점검)로 정합화했다.
- `check-growth-drift` 변경 의도는 wrapper 신설 스크립트(`post-run-checks.sh`)를 mirror drift 검사에 포함하기 위한 1줄 추가였고, 범위 외로 변형됐던 루트 스크립트는 wrapper 형태로 원복했다.
- deep mode 계약 보정으로 보조 산출물 4개를 생성하고, 각 파일 끝에 `<!-- AGENT_COMPLETE -->`를 남겨 회복/검증 경로를 고정했다.
