# SoT Conformance Audit

- Date: 2026-02-18
- Scope: Verify claims from `README.md` / `README.ko.md` against implementing skills/hooks/scripts and deterministic checks.

## Claim 1 — 단일 `cwf` 플러그인이 컨텍스트 수집 → 요구사항 명확화 → 계획 → 구현 → 리뷰 → 회고 → 핸드오프 → 배포 준비 일련의 워크플로우를 통합한다
- SoT source: `README.md:83-87`, `README.ko.md:75-78`
- Implementation evidence: `plugins/cwf/skills/run/SKILL.md:1-24` describes the `cwf:run` skill as the centralized orchestrator, and `plugins/cwf/skills/run/SKILL.md:122-132` enumerates the stage table that invokes each skill in the stated sequence.
- Classification: MATCH
- Notes: `cwf:run` is the single entry point that obeys Decision #19 (human gates pre-impl, autonomy afterward) while chaining every skill listed in the SoT claim, so the implementation aligns with the documented promise.

## Claim 2 — `.cwf/cwf-state.yaml`, 세션 로그, 훅이 페이즈/세션 경계를 넘어 상태/교훈을 보존하는 stateful 워크플로우
- SoT source: `README.md:84-101` (stateful workflow plus assumptions about artifacts), `README.ko.md:75-92`
- Implementation evidence: `.cwf/cwf-state.yaml:1-120` holds the workflow stages, session defaults, and history referenced by the SoT; `plugins/cwf/hooks/scripts/workflow-gate.sh:190-229` loads the live state file (falling back to `BASE/.cwf/cwf-state.yaml`) whenever the workflow gate runs, proving hooks depend on that persistence; deterministic-check evidence: `scripts/check-schemas.sh:150-179` always validates `.cwf/cwf-state.yaml` (among other files) before declaring schema compliance, so the state file is both present and syntactically enforced.
- Classification: MATCH
- Notes: The SoT claim is upheld by the tracked state file plus gate enforcement and schema validation, giving deterministic proof that the implementation preserves context as described.

## Claim 3 — `context-deficit resilience` 계약에서 skills는 오토컴팩트/재시작 이후에 암묵적 채팅 대신 persisted artifacts/핸드오프로 복구한다
- SoT source: `README.md:86, 99-101`, `README.ko.md:75-91`
- Implementation evidence: `plugins/cwf/references/context-recovery-protocol.md:17-120` codifies the global contract (persisted files only, sentinel markers, file validation loops, agent self-persistence); `plugins/cwf/skills/run/SKILL.md:20-24` stresses `cwf:run` recovers from persisted artifacts and `plugins/cwf/skills/run/SKILL.md:469-485` enumerates context-deficit resilience rules enforced at runtime (state tracking, recovery before downstream invocation, gating on stored worktree/root data).
- Classification: MATCH
- Notes: Both the protocol reference and the orchestrator enforce the exact recovery behavior described in the SoT claim.

## Claim 4 — `cwf:setup` 표준화: 훅 그룹 선택, 외부 도구 탐지, env 마이그레이션/프로젝트 config 부트스트랩, 선택적 Codex/인덱스 통합이 포함됨
- SoT source: `README.md:171-173` (setup row in skill table), `README.ko.md:152-167` (setup row and adaptive setup contract description)
- Implementation evidence: `plugins/cwf/skills/setup/SKILL.md:37-179` details the full phase routing (hook toggles, tool detection + dependency installs, agent team/run-mode prompts, codex integration, cap-index/repo-index options, plus deterministic rewrite of `cwf-state.yaml`); `plugins/cwf/skills/setup/SKILL.md:65-140` describes hook group sync and `plugins/cwf/skills/setup/SKILL.md:145-177` spells out the required external/local dependency checks and re-runs, satisfying every piece of the SoT description.
- Classification: MATCH
- Notes: The implementation keeps `cwf:setup` as the comprehensive entry point with the documented optional sub-flows (hooks, tools, codex, indexes).

## Claim 5 — `cwf:handoff`는 `cwf-state.yaml`과 세션 산출물을 읽어서 `next-session.md` 혹은 `phase-handoff.md`를 만들고 `cwf-state`를 갱신한다
- SoT source: `README.md:167`, `README.ko.md:160-167`
- Implementation evidence: `plugins/cwf/skills/handoff/SKILL.md:1-65` shows the skill is described as generating handoff docs from `cwf-state.yaml` and artifacts, `plugins/cwf/skills/handoff/SKILL.md:22-58` explains how the `sessions` history and `session_defaults` guide the process, and `plugins/cwf/skills/handoff/SKILL.md:85-132` documents how canonical sections are filled before updating `cwf-state.yaml` with the new artifacts/summary (including `phase-handoff` options and registration rules).
- Classification: MATCH
- Notes: The doc proves the implementation meets the SoT claim about file-based handoffs.

## Claim 6 — `/review`은 6명의 병렬 리뷰어(2 내·부, 2 외부 CLI/대체, 2 도메인 전문가)를 사용하는 다각도 품질 게이트임
- SoT source: `README.md:169`, `README.ko.md:323-337`
- Implementation evidence: `plugins/cwf/skills/review/SKILL.md:1-35` states the 6-reviewer composition in the description and quick reference, and `plugins/cwf/skills/review/SKILL.md:186-218` describes Phase 2 launching six reviewers with the slot table (Security, UX/DX, Correctness, Architecture, Expert α, Expert β) and parallel persistence requirements.
- Classification: MATCH
- Notes: The skill documentation shows the six-reviewer runtime exactly as the SoT text states.

<!-- AGENT_COMPLETE -->
