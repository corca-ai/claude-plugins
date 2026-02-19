# Retro Evidence Snapshot

- Generated at: 2026-02-16T23:33:48Z
- Repository root: /home/hwidong/codes/claude-plugins
- Session dir: .cwf/projects/260217-03-refactor-review-prevention-impl
- Since epoch filter: not set

## Sources

- scratchpad: .cwf/projects/260217-03-refactor-review-prevention-impl/hitl/hitl-scratchpad.md (missing)
- hitl events: .cwf/projects/260217-03-refactor-review-prevention-impl/hitl/events.log (missing)
- codex tui log: /home/hwidong/.codex/log/codex-tui.log
- session logs dir: .cwf/projects/260217-03-refactor-review-prevention-impl/session-logs
- find-skills: unavailable

## Token Limit Signals

```text
407359:2026-02-16T08:45:51.992893Z  INFO session_loop{thread_id=019c639e-690f-7eb0-ae6b-cce149866653}: codex_core::codex: post sampling token usage turn_id=019c659e-40e8-7da1-ad25-7c075bca5aed total_usage_tokens=245570 estimated_token_count=Some(227257) auto_compact_limit=244800 token_limit_reached=true needs_follow_up=true
407533:2026-02-16T08:51:22.143548Z  INFO session_loop{thread_id=019c639e-690f-7eb0-ae6b-cce149866653}: codex_core::stream_events_utils: ToolCall: exec_command {"cmd":"rg -n \"apply_patch was requested via exec_command|token_limit_reached=true|hitl-scratchpad|README.ko\" ~/.codex/log/codex-tui.log | tail -n 200"} thread_id=019c639e-690f-7eb0-ae6b-cce149866653
407537:2026-02-16T08:51:48.654383Z  INFO session_loop{thread_id=019c639e-690f-7eb0-ae6b-cce149866653}: codex_core::stream_events_utils: ToolCall: exec_command {"cmd":"rg -n \"token_limit_reached=true|token_limit_reached=false\" ~/.codex/log/codex-tui.log | tail -n 20"} thread_id=019c639e-690f-7eb0-ae6b-cce149866653
407539:2026-02-16T08:51:52.224487Z  INFO session_loop{thread_id=019c639e-690f-7eb0-ae6b-cce149866653}: codex_core::stream_events_utils: ToolCall: exec_command {"cmd":"rg -n \"token_limit_reached=true\" ~/.codex/log/codex-tui.log | tail -n 40"} thread_id=019c639e-690f-7eb0-ae6b-cce149866653
407541:2026-02-16T08:53:14.212578Z  INFO session_loop{thread_id=019c639e-690f-7eb0-ae6b-cce149866653}: codex_core::stream_events_utils: ToolCall: exec_command {"cmd":"cat > .cwf/projects/260216-02-hitl-readme/retro.md <<'EOF'\n# Retro: 260216-02-hitl-readme\n\n> Session date: 2026-02-16\n> Mode: deep\n> Evidence: `~/.codex/log/codex-tui.log`, `.cwf/projects/260216-02-hitl-readme/hitl/hitl-scratchpad.md`\n\n## 1. Context Worth Remembering\n\n- 이번 세션의 문서 작업 기준은 `README.ko.md` SoT(단일 기준 문서)였다. 이후 영어 문서/스킬 문서는 SoT 의도를 반영하는 후속 동기화 대상으로 합의했다.\n- HITL 운영 산출물에서 사실상 핵심은 `hitl-scratchpad.md`였고, D-001~D-038로 합의/적용 내역이 누적되었다. 이 문서가 없으면 중간 합의가 반복 손실된다.\n- 사용자 피드백의 핵심은 \"자율성 부족\"이 아니라 \"합의 해석 정확도 부족\"이었다. 즉, 문제는 속도보다 합의 재현률이었다.\n- 로그 기준으로 본 세션은 문서 편집 반복과 검증 반복이 매우 길었고, auto-compact 경계(`token_limit_reached=true`)를 여러 번 넘었다(예: 2026-02-16 07:43:11Z, 08:45:51Z).\n- 이번 턴의 구현 범위는 wrapper 확장안 중 `2`(post-run quality checks)로 제한되었고, 최종 구현은 `warn` 기본 + `strict` 선택형으로 정리되었다.\n\n## 2. Collaboration Preferences\n\n- 사용자는 “다음으로 넘어갈지 묻지 말고, 합의된 청크를 연속 제시”를 원한다. 다만 이것은 \"전체 자율 처리\"가 아니라 \"청크 단위 합의 루프 유지\"라는 의미다.\n- 사용자는 문체의 완전한 공식성보다 의도 보존을 우선한다. 따라서 과도한 윤문보다 \"원문 의도 유지 + 어색한 최소 교정\"이 선호된다.\n- 사용자가 직접 파일을 고쳤다고 알린 경우, 우선순위는 즉시 재동기화다. 기존 버퍼 기반 진행을 계속하면 의도 불일치가 급격히 커진다.\n- 구현 범위를 숫자/옵션으로 지정했을 때(예: \"2만 구현\"), 다른 개선안을 끼워 넣지 않는 범위 잠금이 중요하다.\n\n### Suggested Agent-Guide Updates\n\n- 제안 1: \"사용자가 `N만 구현`처럼 범위를 잠그면, 해당 범위 외 변경은 명시 승인 없이는 금지\" 규칙을 AGENTS 또는 HITL 규약에 명문화.\n- 제안 2: \"사용자가 직접 파일 수정(덮어쓰기 포함) 알림 시, 즉시 intent-resync 단계(전체 재읽기 + 변경 요약 확인)를 강제\"를 HITL 규약에 추가.\n- 제안 3: 문서 HITL에서 각 청크 적용 직후 `scratchpad` 갱신 여부를 체크하는 결정적 체크(스크립트/훅) 추가.\n\n## 3. Waste Reduction\n\n### 낭비 1: README 의도 불일치 반복\n\n- 관찰: 사용자 코멘트 의도가 일부 문장에서 반복적으로 어긋났고, 같은 주제를 여러 차례 재협의했다.\n- 5 Whys:\n  - 왜 반복됐나? 합의 직후 전체 문맥 재검증 없이 국소 수정을 계속했다.\n  - 왜 국소 수정에 머물렀나? 청크 단위 진행 규약은 있었지만, \"사용자 직접 덮어쓰기 이후 전체 재동기화\" 단계가 없었다.\n  - 왜 재동기화 단계가 없었나? HITL이 diff 중심으로 설계되어 \"파일 상태 변동 이벤트\"를 강제하지 않았다.\n  - 왜 이벤트를 강제하지 않았나? 현재 HITL 큐/상태 파일이 실행 큐 중심이고, 의도 재합의 체크포인트는 비결정적 텍스트 규약에 의존한다.\n  - 왜 텍스트 규약에 의존했나? 자동 검증 가능한 규칙(훅/체크)으로 승격되지 않았다.\n- 구조 원인: 프로세스 갭.\n- 권장 티어: Tier 1 (Eval/Hook).\n- 메커니즘: HITL 적용 스크립트에 `intent_resync_required` 플래그 도입(사용자 직접 수정 감지 시 true) + 다음 청크 진행 전 강제 확인.\n\n### 낭비 2: 구현 범위 이탈 위험\n\n- 관찰: `2만 구현` 요구 이후에도 범위 외 변경(대형 파일 동기화)이 잠깐 발생했고 되돌림 정리가 필요했다.\n- 5 Whys:\n  - 왜 이탈했나? mirror 일관성 유지 판단을 우선해 범위 해석이 넓어졌다.\n  - 왜 넓어졌나? \"무결성 유지\"와 \"요청 범위 제한\" 충돌 시 우선순위 규칙이 명확하지 않았다.\n  - 왜 우선순위가 불명확했나? 현재 규약에 scope lock 해제 조건이 없음.\n  - 왜 조건이 없나? 구현 안전성 원칙은 있지만 사용자 지시 우선의 세부 규칙이 약하다.\n  - 왜 약한가? 과거 자율 구현 패턴이 기본값으로 남아있다.\n- 구조 원인: 프로세스 갭.\n- 권장 티어: Tier 3 (Doc) + 가능하면 Tier 1.\n- 메커니즘: HITL/구현 프로토콜에 \"scope lock\" 문구를 명시하고, 가능하면 pre-commit 검사에서 범위 외 파일 경고 출력.\n\n### 낭비 3: 툴 호출 위생 오류\n\n- 관찰: `apply_patch`를 `exec_command`로 호출해 경고가 발생했고, 사용자가 직접 지적했다.\n- 5 Whys:\n  - 왜 발생했나? 편집 흐름 중 습관적으로 셸 heredoc patch를 사용했다.\n  - 왜 습관이 유지됐나? 도구 사용 규칙이 런타임에서 강제되지 않고 프롬프트 규약에만 있었다.\n  - 왜 강제되지 않았나? hook gate가 해당 anti-pattern을 검사하지 않는다.\n  - 왜 검사하지 않나? 도구 호출 메타 검사가 아직 미구현이다.\n  - 왜 미구현인가? 문서 규약 우선으로 운영돼 자동화 전환이 늦었다.\n- 구조 원인: 프로세스/자동화 갭.\n- 권장 티어: Tier 1 (Eval/Hook).\n- 메커니즘: Codex wrapper 또는 hook gate에서 `exec_command` payload 내 `apply_patch` 패턴 감지 시 실패/경고 처리.\n\n## 4. Critical Decision Analysis (CDM)\n\n### CDM-1: README.ko를 SoT로 고정\n\n- Signal: 문서 방향/철학 논의가 길어지고 영어/스킬 문서 동기화 순서가 혼재됨.\n- Decision: `README.ko.md`를 먼저 안정화하고, 다른 문서는 후속 반영.\n- Alternatives:\n  - A) 한/영 동시 수정\n  - B) 스킬 문서부터 선행 수정\n- Why chosen: 합의 기준점이 하나여야 해석 오차를 줄일 수 있음.\n- Outcome: 합의 추적이 쉬워졌고 `hitl-scratchpad`의 D 항목 구조가 안정됨.\n- Risk: 영어 문서 지연으로 일시적 불일치 발생 가능.\n- Guardrail: SoT 변경 시 동기화 대상 목록을 scratchpad에 즉시 기록.\n\n### CDM-2: HITL 개선은 플래그 추가 없이 기본 흐름에서 해결\n\n- Signal: 사용자 피드백은 \"플래그 부족\"이 아니라 \"진행 감각 경직\" 문제였음.\n- Decision: `cwf:hitl` 단일 흐름 유지 + 합의 라운드/청크 루프 품질 개선.\n- Alternatives:\n  - A) `--guided` 같은 새 플래그 추가\n  - B) 완전 자율 모드 분리\n- Why chosen: 모드 분기는 학습비용을 늘리고, 핵심 문제(합의 해석)와 직접 관련이 약함.\n- Outcome: 운영 단순성 유지, 다만 규약 준수 품질이 실제 성패를 좌우.\n- Risk: 구현체가 규약을 느슨하게 해석하면 동일 문제가 재발.\n- Guardrail: HITL 규약의 체크리스트화를 통한 단계별 확인.\n\n### CDM-3: Wrapper 옵션 2(post-run checks) 채택\n\n- Signal: Codex wrapper 확장 논의에서 \"어디까지 자동 검증할지\"가 쟁점.\n- Decision: 세션 후처리로 변경 파일 대상 품질 점검을 자동 실행 (`warn` 기본, `strict` 선택).\n- Alternatives:\n  - A) wrapper는 로그 동기화만 유지\n  - B) pre-run 블로킹 검사 추가\n- Why chosen: 사용자 흐름 방해를 최소화하면서 품질 안전망을 추가할 수 있음.\n- Outcome: 구현 완료. `strict` 모드 종료코드 전파 버그를 추가 보정해 기대 동작을 맞춤.\n- Risk: 체크 범위/비용이 커지면 체감 지연 증가.\n- Guardrail: changed-files only 유지 + 모드/env 토글 제공.\n\n## 5. Expert Lens\n\n### Lens A: Concept-first Documentation (Daniel Jackson 계열)\n\n- 평가: 이번 세션의 핵심 성과는 \"what/why 우선\" 원칙을 문서 전반으로 확대한 점이다.\n- 보완점: 실제 편집 단계에서 how-수정이 다시 앞서며 원칙이 흔들린 순간이 있었다.\n- 제안: 각 청크 시작 시 \"이번 수정의 why 한 줄\"을 먼저 고정하고 문장 수정을 시작.\n\n### Lens B: Socio-technical Workflow Design\n\n- 평가: 병목은 코드 생성이 아니라 인간 합의/리뷰 대역폭이었다. 사용자 피로가 누적되면 문장 정확도보다 상호 신뢰가 먼저 무너진다.\n- 보완점: 범위 잠금, 재동기화 체크, 툴 위생이 자동화되지 않아 인지부하를 사람에게 남겼다.\n- 제안: HITL을 \"문서 편집 프로토콜\"이 아니라 \"합의 상태 머신\"으로 명시하고, 상태 전이 실패를 deterministic gate로 잡는다.\n\n## 6. Learning Resources\n\n1. `references/essence-of-software/distillation.md`\n- 왜: 이번 세션의 \"컨셉/why 중심\" 논의의 기준 문서였다.\n- 무엇: 개념 단위를 기능이 아니라 명확한 목적/상태/행동 묶음으로 다루는 관점을 제공.\n- 적용: README의 핵심 개념 설명이나 스킬 설계 의도 문장을 다시 쓸 때 우선 참조.\n\n2. `docs/documentation-guide.md`\n- 왜: 문서 톤, 범위, 소유권을 통일하지 않으면 HITL 회차가 길어질수록 충돌이 커진다.\n- 무엇: 문서에서 규칙화할 것과 코드/게이트로 옮길 것을 분리하는 기준 제공.\n- 적용: \"문장으로만 강제\"하던 항목을 hook/check로 승격할 후보를 추출.\n\n3. `plugins/cwf/skills/refactor/references/docs-criteria.md` (Section 0)\n- 왜: 좋은 문서화 기준(명확성, 독자 맥락, 근거)을 실무 판단으로 연결할 때 기준점이 필요했다.\n- 무엇: 문장 개선이 아닌 정보 설계 관점에서 문서를 평가하는 프레임 제공.\n- 적용: README chunk review에서 Before/After 평가 축으로 직접 사용.\n\n## 7. Relevant Tools (Capabilities Included)\n\n### Installed Capabilities\n\n- CWF skills: `hitl`, `retro`, `setup`, `run`, `refactor`, `review`.\n- Deterministic checks/scripts used in this session:\n  - `npx markdownlint-cli2`\n  - `scripts/check-growth-drift.sh --level warn`\n  - `.claude/skills/plugin-deploy/scripts/check-consistency.sh cwf`\n  - `plugins/cwf/scripts/cwf-live-state.sh set . phase=\"retro\"`\n- New capability added this turn:\n  - `plugins/cwf/scripts/codex/post-run-checks.sh` + wrapper 연동(`codex-with-log.sh`)\n\n### Tool Gaps\n\n- Gap 1: HITL intent-resync 자동화 부재\n  - Signal: 사용자 직접 덮어쓰기 이후 의도 불일치 반복.\n  - Candidate: HITL state에 `intent_resync_required`/`last_user_manual_edit_at` 필드 추가.\n  - Integration: `cwf:hitl` 시작/청크 진행 전 검증.\n  - Gain: 같은 쟁점 재협상 횟수 감소.\n  - Risk/Cost: 상태 스키마/스킬 동시 변경 필요.\n\n- Gap 2: Tool invocation hygiene gate 부재\n  - Signal: `apply_patch via exec_command` 경고 재발.\n  - Candidate: hook gate 또는 wrapper 검사 규칙 추가.\n  - Integration: hook script에서 command payload 패턴 검사.\n  - Gain: 반복 실수의 즉시 차단.\n  - Risk/Cost: 오탐 방지 룰 필요.\n\n- Gap 3: Retro evidence collector 부재\n  - Signal: 로그/스크래치패드 근거 수집이 수동.\n  - Candidate: `scripts/retro-collect-evidence.sh` (token-limit, warning, key decisions 추출).\n  - Integration: `cwf:retro` 초반 단계 자동 호출.\n  - Gain: 회고 품질과 일관성 향상.\n  - Risk/Cost: 로그 포맷 변경에 대한 유지보수 필요.\nEOF"} thread_id=019c639e-690f-7eb0-ae6b-cce149866653
408893:+  token_limit_hits="$(grep -n 'token_limit_reached=true' "$codex_tui_log" | tail -n 12 || true)"
410418:2026-02-16T10:10:34.135200Z  INFO session_loop{thread_id=019c65ce-1ea1-7e52-96fa-870f8ee5f94a}: codex_core::codex: post sampling token usage turn_id=019c65e6-f52c-7240-a49c-cb2b5d519c3b total_usage_tokens=245076 estimated_token_count=Some(239498) auto_compact_limit=244800 token_limit_reached=true needs_follow_up=true
410551:2026-02-16T10:17:27.459363Z  INFO session_loop{thread_id=019c65ce-1ea1-7e52-96fa-870f8ee5f94a}:session_loop{thread_id=019c65f3-d291-7052-9a41-237c491a04d7}: codex_core::stream_events_utils: ToolCall: exec_command {"cmd":"rg -n \"D-043|D-044|D-047|D-048|D-040|session_forked|token_limit_reached=true|shellcheck|missing dependency|README\\.ko|SoT\" /home/hwidong/codes/claude-plugins/.cwf/projects/260216-03-hitl-readme-restart/hitl/hitl-scratchpad.md /home/hwidong/codes/claude-plugins/.cwf/projects/260216-03-hitl-readme-restart/hitl/events.log /home/hwidong/codes/claude-plugins/.cwf/projects/260216-03-hitl-readme-restart/retro-evidence.md"} thread_id=019c65f3-d291-7052-9a41-237c491a04d7
410564:+| **Cues** | `token_limit_reached=true`가 2026-02-16에 반복 기록됐고(02:59:48Z~08:45:51Z), 이후 `session_forked ... reason=long-session-new-dir` 이벤트가 발생했다 (근거: `.cwf/projects/260216-03-hitl-readme-restart/retro-evidence.md:19`, `.cwf/projects/260216-03-hitl-readme-restart/retro-evidence.md:24`, `.cwf/projects/260216-03-hitl-readme-restart/hitl/events.log:4`). |
411801:2026-02-16T10:50:15.912346Z  INFO session_loop{thread_id=019c65ce-1ea1-7e52-96fa-870f8ee5f94a}: codex_core::codex: post sampling token usage turn_id=019c6612-344a-7562-a272-8007480fb1ce total_usage_tokens=246747 estimated_token_count=Some(231976) auto_compact_limit=244800 token_limit_reached=true needs_follow_up=true
413222:2026-02-16T11:17:24.805245Z  INFO session_loop{thread_id=019c65ce-1ea1-7e52-96fa-870f8ee5f94a}: codex_core::codex: post sampling token usage turn_id=019c6620-cf4d-7891-929f-1ec141a75f8f total_usage_tokens=245243 estimated_token_count=Some(234755) auto_compact_limit=244800 token_limit_reached=true needs_follow_up=true
416476:2026-02-16T22:55:23.770856Z  INFO session_loop{thread_id=019c6888-018d-7661-a40f-da19be5a21a3}: codex_core::codex: post sampling token usage turn_id=019c68a9-a34a-7dc1-952b-36b49a111f9a total_usage_tokens=248242 estimated_token_count=Some(232022) auto_compact_limit=244800 token_limit_reached=true needs_follow_up=true
```

## HITL Decisions (Recent)

- Decision count: 0

```text
_none_
```

## HITL Event Tail

```text
_none_
```

## Session Warning Signals

```text
_none_
```

## Scratchpad Freshness

- n/a

## Changed Files Snapshot

```text
 M .cwf/cwf-state.yaml
 M .cwf/projects/260216-03-hitl-readme-restart/session-state.yaml
 M .cwf/projects/260217-03-refactor-review-prevention-impl/review-correctness-code.md
 M .cwf/projects/260217-03-refactor-review-prevention-impl/review-synthesis-code.md
 M .cwf/sessions/260217-0722-95c970d6.claude.md
 M plugins/cwf/hooks/README.md
 M plugins/cwf/hooks/hooks.json
 M plugins/cwf/hooks/scripts/compact-context.sh
 M plugins/cwf/hooks/scripts/track-user-input.sh
 M plugins/cwf/skills/run/SKILL.md
?? .cwf/projects/260217-03-refactor-review-prevention-impl/retro-cdm-analysis.md
?? .cwf/projects/260217-03-refactor-review-prevention-impl/retro-learning-resources.md
```
