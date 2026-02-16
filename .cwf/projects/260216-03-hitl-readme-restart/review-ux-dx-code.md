## UX/DX Review

### Concerns (blocking)
- **[C1]** 여러 SKILL 문서가 여전히 `bash {SKILL_DIR}/../../scripts/...`로 루트 `scripts/` 하위 도구를 호출하도록 되어 있는데, 이번 커밋에서 해당 스크립트를 `plugins/cwf/scripts/`로 옮기고 루트 `scripts/next-prompt-dir.sh` 등은 제거했습니다. 예를 들어 `plugins/cwf/skills/run/SKILL.md:31-41`의 `next-prompt-dir.sh`/`cwf-live-state.sh` 호출과 `plugins/cwf/skills/setup/SKILL.md:342-356`의 `codex/codex-with-log.sh`, `codex/post-run-checks.sh` 경로는 더 이상 존재하지 않으며(루트 `scripts/` 디렉터리에는 `check-schemas.sh`, `doc-churn.sh` 정도만 남아 있어서 `No such file or directory`로 실패합니다), 이대로면 기본 파이프라인 초기화와 Codex 래퍼 옵트인 안내를 따라갈 수 없습니다.
  Severity: moderate

### Suggestions (non-blocking)
- **[S1]** 모든 SKILL/SKILL 참조 문서에서 `../../scripts/...` 경로를 `../../plugins/cwf/scripts/...` (혹은 `{SKILL_DIR}/../../plugins/cwf/scripts/...`) 방식으로 바꾸고, `plugins/cwf/scripts/README.md`처럼 운영 스크립트 맵에 링크된 경로와 일관성을 유지해 주세요. 리뷰에서는 `run`, `setup`, `impl`, `handoff` 등에서 옛 경로가 남아 있으므로 전체 SKILL을 검색해서 경로 누락이 없는지 확인하는 자동화도 고려해 주시기 바랍니다.

### Behavioral Criteria Assessment
- [x] `check-session --live` passes — `plugins/cwf/scripts/check-session.sh --live`를 실행했고, 모든 live 필드(session_id/dir/phase/task)가 채워져 PASS를 반환했습니다.
- [x] Session log file is generated under `.cwf/sessions/` (legacy alias preserved) — `.cwf/sessions/260216-1835-40949efd.codex.md`가 존재하여 세션 로그가 기록되고 있습니다.
- [x] Session baseline artifacts are complete — `.cwf/projects/260216-03-hitl-readme-restart/` 안에 `plan.md`, `lessons.md`, `next-session.md`, `retro.md`, `session-log.md`가 모두 있고 `session-logs/` 디렉터리도 있으므로 기본 아티팩트가 갖춰져 있습니다.

### Provenance
source: REAL_EXECUTION
tool: claude-task
reviewer: UX/DX
duration_ms: —
command: —

<!-- AGENT_COMPLETE -->
