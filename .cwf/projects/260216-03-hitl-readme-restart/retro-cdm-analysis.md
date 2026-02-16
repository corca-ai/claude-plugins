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

<!-- AGENT_COMPLETE -->
