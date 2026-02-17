Executive Summary
- lifecycle/operations 스킬 전반에서 운영자 UX와 배포 준비 흐름은 잘 커버되지만, 수동 호출 경로와 문서 중복 때문에 실수가 발생할 여지가 있습니다.
- stage gate는 `ship`/`retro`에서 스크립트 기반 검증을 요구하지만 수동 `/ship merge` 경로가 빠져 있어 gate가 우회될 수 있고, 문서간 참고 연계가 약해 향후 갱신에서 불일치가 생길 수 있습니다.
Findings (severity: high/medium/low)
- High: `plugins/cwf/skills/ship/SKILL.md`의 "Output Persistence"에서 `check-run-gate-artifacts.sh --stage ship`을 실행하라고 명시하는 조건이 "When running under `cwf:run`"으로 한정되어 있어서, 이용자가 `/ship merge`를 직접 호출하면 deterministic gate를 우회할 수 있습니다. 수동 병합도 동일한 stage gate를 통과하도록 문서와 실행 흐름을 정리하지 않으면 배포 준비 신뢰성이 손실됩니다.
- Medium: `plugins/cwf/skills/setup/SKILL.md`의 여러 AskUserQuestion(Phase 2.3.1~2.10)에는 `cwf-state.yaml`에 결정 내용을 다시 쓰는 설명이 없어서, 동일 repo/환경에서 `cwf:setup`을 재실행할 때마다 git hook 설치 모드, gate profile, Codex 옵션, Run-mode 등을 계속 묻습니다. 아무 변화 없더라도 자동화/CI 재작업 시 UX가 무의미하게 길어지므로, 이전 선택을 `cwf-state`나 프로젝트 config에 저장해 재질문을 건너뛰거나 다시 확인만 하도록 개선할 여지가 있습니다.
- Medium: Codex 관련 phases(2.4~2.6)는 integration level 선택, 재시작 안내, 상태 확인, wrapper 설치/롤백 안내 등을 거의 동일한 방식으로 반복하며, 후속 안내도 모두 동일한 상태/설치 메시지를 포함합니다. 이 반복은 문서 유지보수와 구현 일관성에 부담을 주므로, "Codex 통합 허브" 같은 재사용 가능한 하위 섹션/참고 문서로 분리하는 것이 중복 제거와 UX 일관성 측면에서 도움이 됩니다.
- Low: stage gate 검증(예: `retro` 단계 5.1의 `check-run-gate-artifacts.sh` 호출과 `ship`의 output persistence)과 관련해 통일된 문서(예: `docs/` 하위 gating 안내)가 없어, 각 스킬이 스크립트 사용을 개별적으로 기술하다 보니 누락/상충 가능성이 존재합니다. stage gate를 담당하는 스크립트 목록과 실행 조건을 하나의 참조 문서로 정리하면 업데이트 시 일관성을 확보할 수 있습니다.
Proposed Refactors (prioritized)
- 1) `/ship merge` 단계에서도 `scripts/check-run-gate-artifacts.sh --stage ship --strict --record-lessons`를 무조건 호출하도록 `ship` 스킬과 실행 흐름을 짜서 stage gate를 강제하고, 설명도 "-cwf:run" 여부와 관계없이 stage gate를 건너뛰지 않도록 명확히 기재합니다.
- 2) `cwf:setup`의 선택적 질문(툴 설치, Codex, Agent Team, ambiguity mode 등)을 `cwf-state.yaml`이나 `.cwf-config*.yaml`에 기록해 다음 실행 때 재질문을 생략하거나 "현재 저장된 값"을 보여주는 UX로 개선해 운영자가 불필요하게 반복 확인하지 않도록 합니다.
- 3) Codex 통합/래퍼 설치 처리(Phase 2.4~2.6)의 상세 절차를 별도 하위 섹션이나 `references` 문서로 추출하고, 단계별 스크립트/상태/후속 안내 메시지를 한 곳에서 관리해 반복을 줄입니다.
- 4) stage gate 스크립트/조건(`check-run-gate-artifacts.sh` 등)의 목적/대상을 `docs/`나 `AGENTS.md`의 참조 섹션에 정리하여 `retro`, `ship`, 다른 스킬들이 서로 다른 문구를 쓰는 일이 없도록 합니다.
Affected Files
- plugins/cwf/skills/setup/SKILL.md
- plugins/cwf/skills/retro/SKILL.md
- plugins/cwf/skills/ship/SKILL.md
- plugins/cwf/skills/update/SKILL.md
Open Questions
- `/ship merge`를 수동으로 호출할 때도 stage gate를 항상 돌리도록 권장할까요, 아니면 gate 작동 여부를 `live.ambiuity_mode`로 판단해 유연하게 적용할까요?
- `cwf:setup`이 적절히 원래 상태를 기억하도록 하려면 어떤 `cwf-state.yaml` 필드를 추가하거나 기존 `stage_checkpoints`를 어떻게 사용하는 것이 좋을까요?
