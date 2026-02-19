# cwf:setup 분기 매트릭스 (첫 실행, 별도 repo 기준)

## 진입점 & 참조 자료

- 기본 진입점은 `cwf:setup`이며 [plugins/cwf/skills/setup/SKILL.md](plugins/cwf/skills/setup/SKILL.md)의 Quick Start 표에 나열된 서브 명령(`--hooks`, `--tools`, `--env`, `--agent-teams`, `--run-mode`, `--codex`, `--codex-wrapper`, `--git-hooks`, `--cap-index`, `--repo-index`)이 모두 사용자에게 유의미한 branch 도구이다.
- 요구된 [scripts/install.sh](scripts/install.sh)는 이 저장소에 존재하지 않으며, 대신 [plugins/cwf/skills/setup/scripts/install-tooling-deps.sh](plugins/cwf/skills/setup/scripts/install-tooling-deps.sh)가 의존성 설치/체크 엔트리로 사용된다.
- 각 branch 설명은 해당 단계에 대한 SKILL 본문과 참조 문서([plugins/cwf/skills/setup/references/*.md](plugins/cwf/skills/setup/references/*.md))를 근거로 작성하였다.

## 사용자-visible 분기 목록

### Branch A: Hook group 선택 (Phase 1)

- branch_id: `setup-branch-hook-selection`
- trigger/command: `cwf:setup`에서 무조건 초기 실행 (Phase 1)이며 [plugins/cwf/skills/setup/SKILL.md](plugins/cwf/skills/setup/SKILL.md) 1장 설명 기반
- preconditions: `cwf-state.yaml`에 `hooks:` 구역 존재(기본값은 모두 true) → 현재 상태를 읽고 multiSelect 를 제시
- user choices:
  - 9개 hook 그룹(예: `attention`, `log`, `read`, `lint_markdown`, ... , `compact_recovery`) 중 다선택으로 켜고 끔; 기본값은 모두 켜져 있음
- expected behavior: [plugins/cwf/skills/setup/scripts/sync-hook-state.sh --enable "<선택된 그룹>"](plugins/cwf/skills/setup/scripts/sync-hook-state.sh --enable "<선택된 그룹>") 실행 후 [~/.claude/cwf-hooks-enabled.sh](~/.claude/cwf-hooks-enabled.sh)에 export 라인 갱신, 이어서 `--check`로 `cwf-state.yaml` `hooks:` 섹션 동기화
- touched files: [~/.claude/cwf-hooks-enabled.sh](~/.claude/cwf-hooks-enabled.sh), `cwf-state.yaml` (동기화와 저장)
- failure/stop conditions: `sync-hook-state.sh` 실패 또는 `--check` 불일치 → 즉시 중단
- 근거: [plugins/cwf/skills/setup/SKILL.md](plugins/cwf/skills/setup/SKILL.md) Phase 1 및 [scripts/sync-hook-state.sh](scripts/sync-hook-state.sh) 사용(경로: [plugins/cwf/skills/setup/scripts/sync-hook-state.sh](plugins/cwf/skills/setup/scripts/sync-hook-state.sh)).

### Branch B: 외부 도구/의존성 감지 (Phase 2.1~2.2)

- branch_id: `setup-branch-tools-detect`
- trigger/command: `cwf:setup` 또는 `cwf:setup --tools` (Mode routing 표에서 Phase 2 실행됨)
- preconditions: 전체/도구 전용 실행, `tool-detection-and-deps.md`에 정의된 codex/gemini/shellcheck/jq/gh/node/python3/lychee/markdownlint-cli2 및 Tavily/Exa 환경변수 체크
- user choices: 없음 (자동 감지만); 단 감지 결과에 따라 바로 다음 Branch C로 이동
- expected behavior: 모든 체크 명령 실행 → `cwf-state.yaml` `tools:` 업데이트 → AI/API 도구 + 로컬 런타임 결과 2블럭으로 보고
- touched files: `cwf-state.yaml`
- failure/stop: 감지 명령이 비정상 종료하면 중단 및 수동 문제 해결 요구
- 근거: [plugins/cwf/skills/setup/references/tool-detection-and-deps.md](plugins/cwf/skills/setup/references/tool-detection-and-deps.md) 2.1~2.2

### Branch C: 누락 의존성 처리 선택 (Phase 2.3.1~2.3.3)

- branch_id: `setup-branch-missing-deps`
- trigger/command: `branch B` 결과로 `tool-detection`이 누락 항목을 발견한 경우
- preconditions: `tool-detection` 결과 중 하나라도 `available`이 아닌 로컬 의존성
- user choices:
  1. `Install missing now (recommended)` → `install-tooling-deps.sh --install missing` 실행 후 `install-tooling-deps.sh --check`로 재감지 및 `cwf-state.yaml` 재작성
  2. `Show commands only` → `install-tooling-deps.sh --check` 실행, 출력 명령만 보여주고 계속
  3. `Skip for now` → 설치 수행하지 않음, 미해결 항목과 위험을 보고하고 흐름 유지
- expected behavior: 선택에 따라 설치/체크 실행, `cwf-state.yaml` 재기록, `Phase 2.3` 이후 경고 메시지와 함께 계속 여부 묻기 (설치 후에도 미해결 시 수동 중단 권장)
- touched files: `cwf-state.yaml` (재감지 결과), [plugins/cwf/skills/setup/scripts/install-tooling-deps.sh](plugins/cwf/skills/setup/scripts/install-tooling-deps.sh) 실행 (로그와 환경 영향)
- failure/stop: `Install missing now` 중 설치 실패 또는 재감지에서 여전히 누락 → 사용자에게 수동 종료 여부 요청, `Skip` 선택시에도 향후 워크플로우 실패 가능
- 근거: `tool-detection-and-deps.md` 2.3.1~2.3.3, [plugins/cwf/skills/setup/scripts/install-tooling-deps.sh](plugins/cwf/skills/setup/scripts/install-tooling-deps.sh)

### Branch D: setup-contract 부트스트랩 및 repo 도구 제안 (Phase 2.3.4)

- branch_id: `setup-branch-contract`
- trigger/command: `cwf:setup` 또는 `cwf:setup --tools` (Phase 2.3 완료 직후, `tools` 명령도 항상 실행)
- preconditions: [bash plugins/cwf/skills/setup/scripts/bootstrap-setup-contract.sh --json](bash plugins/cwf/skills/setup/scripts/bootstrap-setup-contract.sh --json) 실행, `status`가 `fallback`이 아닌 경우
- user choices:
  1. `Apply suggested repo tools now (recommended for this repo)` → 제안된 `repo_tools` 목록(예: `yq`, `rg`)을 `install-tooling-deps.sh --install <list>`로 적용
  2. `Keep proposal only` → 계약 파일은 남기되 추가 설치는 하지 않음
  3. `Skip repo-specific suggestions` → Core baseline 만 유지
- expected behavior: [.cwf/setup-contract.yaml](.cwf/setup-contract.yaml) 생성/갱신, `repo_tools` 목록에 따라 추가 설치 스크립트 실행(또는 생략)
- touched files: [.cwf/setup-contract.yaml](.cwf/setup-contract.yaml), 상황에 따라 `cwf-state.yaml` (설치 여부 반영)
- failure/stop: `bootstrap-setup-contract.sh`가 `fallback`을 반환하면 경고 출력 후 전체 `cwf:setup` 실행 중단 (경로/권한 문제 해결 후 재실행 필요)
- 근거: [plugins/cwf/skills/setup/references/setup-contract.md](plugins/cwf/skills/setup/references/setup-contract.md), [scripts/bootstrap-setup-contract.sh](scripts/bootstrap-setup-contract.sh)

### Branch E: Codex 통합 (Phase 2.4, full setup)

- branch_id: `setup-branch-codex-full`
- trigger/command: `cwf:setup` (SKILL에서 full setup인 경우, Codex CLI 감지 완료)
- preconditions: `tool-detection`에서 `codex` 사용 가능, [scripts/detect-plugin-scope.sh](scripts/detect-plugin-scope.sh)가 scope 정보를 제공하거나 실패 시 사용자에게 scope 선택 강제
- user choices:
  1. Scope 결정(감지 실패/`none` 또는 비-user scope에서 user으로 변경 시 명시 확인) → `User`, `Project`, `Local`, `Skip` 중 선택
  2. Integration level 선택 → `Skills + wrapper (recommended)`, `Skills only`, `Skip for now`
  3. (비-user→user 전환) 추가 확인 → 비사용자 범위에서 user scope 선택 시 두 번째 확인
- expected behavior: `sync-skills.sh --scope <selected>` 실행, wrapper 선택 시 `install-wrapper.sh --enable` (user scope은 `--add-path[, project/local은 ](, project/local은 )--project-root`), 최종적으로 `install-wrapper.sh --status` + `type -a codex` 보고, 필요 시 rollback 명령 안내
- touched files: 사용자 범위의 경우 [~/.agents/skills](~/.agents/skills), [~/.agents/references](~/.agents/references), `.agents[ wrapper 파일; 프로젝트/로컬 범위의 경우 ]( wrapper 파일; 프로젝트/로컬 범위의 경우 ){projectRoot}/.codex/skills`, [{projectRoot}/.codex/references]({projectRoot}/.codex/references), [{projectRoot}/.codex/bin/codex]({projectRoot}/.codex/bin/codex), [.cwf/sessions/*.codex.md](.cwf/sessions/*.codex.md) (로그), [scripts/codex/install-wrapper.sh](scripts/codex/install-wrapper.sh) outputs
- failure/stop: scope 감지가 `none`인데 사용자 선택도 없거나 wrapper 설치 실패 시 중단, `install-wrapper` 비정상 종료는 즉시 롤백 옵션 요청
- 근거: [plugins/cwf/skills/setup/SKILL.md](plugins/cwf/skills/setup/SKILL.md) Phase 2.4, [references/codex-scope-integration.md](references/codex-scope-integration.md) 2.4.x, [scripts/detect-plugin-scope.sh](scripts/detect-plugin-scope.sh)

### Branch F: `cwf:setup --codex` skill sync 재실행 (Phase 2.5)

- branch_id: `setup-branch-codex-sync`
- trigger/command: `cwf:setup --codex`
- preconditions: Codex CLI 탐지 (때로는 범위 감지가 실패하면 사용자 명시 선택 필요)
- user choices: scope 선택(감지 실패 시 직접 입력, user>project/local 변경 시 확인)
- expected behavior: `sync-skills.sh --scope <selected> ${projectRoot:+--project-root <root>}[ 실행, 링크된 스킬/참조 목록 생성, 백업 위치(]( 실행, 링크된 스킬/참조 목록 생성, 백업 위치().skill-sync-backup`) 안내
- touched files: [~/.agents/skills](~/.agents/skills) 또는 [{projectRoot}/.codex/skills]({projectRoot}/.codex/skills), [{projectRoot}/.codex/references]({projectRoot}/.codex/references)
- failure/stop: scope 정보 누락, `sync-skills` 실패, 검증 스크립트(`verify-skill-links.sh`) 경고
- 근거: [references/codex-scope-integration.md](references/codex-scope-integration.md) 2.5.x

### Branch G: `cwf:setup --codex-wrapper` 래퍼 재실행 (Phase 2.6)

- branch_id: `setup-branch-codex-wrapper`
- trigger/command: `cwf:setup --codex-wrapper`
- preconditions: Codex CLI 존재, scope 감지 또는 수동 선택
- user choices:
  - `Enable Codex wrapper for scope {selected_scope}...` 질문에 대해 `예` 또는 `거절` 선택 (거절 시 Phase 종료)
- expected behavior: `install-wrapper.sh --enable` (user scope은 `--add-path[, project/local은 ](, project/local은 )--project-root`), post-run `sync-session-logs.sh`, `post-run-checks.sh --mode warn`, `install-wrapper.sh --status` 실행, PATH/환경 변수 안내 정리
- touched files: wrapper 바이너리([~/.local/bin/codex](~/.local/bin/codex) 또는 [{projectRoot}/.codex/bin/codex]({projectRoot}/.codex/bin/codex)), [.cwf/sessions/*.codex.md](.cwf/sessions/*.codex.md), [scripts/codex/post-run-checks.sh](scripts/codex/post-run-checks.sh) 로그
- failure/stop: wrapper 설치/동기화 실패 → 즉시 롤백(`install-wrapper.sh --disable`), PATH 업데이트 실패 시 수동 안내
- 근거: [references/codex-scope-integration.md](references/codex-scope-integration.md) 2.6.x

### Branch H: Git hook gate 설치 (Phase 2.7)

- branch_id: `setup-branch-git-hooks`
- trigger/command: `cwf:setup` 전체 또는 `cwf:setup --git-hooks <mode>` (Phase 2.7은 full setup 시 필수)
- preconditions: CLI `--git-hooks <mode>` 또는 AskUserQuestion (기본 `both` 추천)
- user choices:
  1. 설치 모드: `both`, `pre-commit`, `pre-push`, `none`
  2. (mode ≠ none) 게이트 프로파일: `balanced (추천)`, `fast`, `strict`
- expected behavior: [bash plugins/cwf/skills/setup/scripts/configure-git-hooks.sh --install <mode> --profile <profile>](bash plugins/cwf/skills/setup/scripts/configure-git-hooks.sh --install <mode> --profile <profile>) 실행, [.githooks/pre-commit](.githooks/pre-commit)/`pre-push` 스크립트 생성, `git config core.hooksPath` 업데이트, `check-configure-git-hooks-runtime.sh`로 behaviors validation
- touched files: [.githooks/pre-commit](.githooks/pre-commit), [.githooks/pre-push](.githooks/pre-push), `.metadata 예: git config core.hooksPath`, `AGENTS`? (config). 실제 hook 템플릿은 [plugins/cwf/skills/setup/assets/githooks/*.template.sh](plugins/cwf/skills/setup/assets/githooks/*.template.sh)
- failure/stop: `configure-git-hooks.sh[ 실패(권한/경로 점검) 또는 ]( 실패(권한/경로 점검) 또는 )git config` 설정 불일치 시 중단
- 근거: [references/runtime-and-index-phases.md](references/runtime-and-index-phases.md) Phase 2.7

### Branch I: 프로젝트 구성 부트스트랩 (Phase 2.8)

- branch_id: `setup-branch-project-config`
- trigger/command: `cwf:setup`, `cwf:setup --tools`, `cwf:setup --env`
- preconditions: AskUserQuestion (default 추천 `Yes`) → `.cwf-config*.yaml` 템플릿 존재 여부 확인
- user choices:
  1. `Yes (recommended)` → [scripts/bootstrap-project-config.sh](scripts/bootstrap-project-config.sh)
  2. `Overwrite templates` → [scripts/bootstrap-project-config.sh --force](scripts/bootstrap-project-config.sh --force)
  3. `Skip for now`
- expected behavior: 필요한 템플릿 생성/재생성, `.gitignore`에 `.cwf-config.local.yaml` 명시, 실행 후 config priority 안내
- touched files: `.cwf-config.yaml`, `.cwf-config.local.yaml`, `.gitignore`
- failure/stop: 스크립트 쓰기 실패 또는 `.gitignore` 동기화 실패 시 경고 후 중단
- 근거: [references/runtime-and-index-phases.md](references/runtime-and-index-phases.md) Phase 2.8, [plugins/cwf/skills/setup/scripts/bootstrap-project-config.sh](plugins/cwf/skills/setup/scripts/bootstrap-project-config.sh)

### Branch J: Agent Team 모드 설정 (Phase 2.9)

- branch_id: `setup-branch-agent-teams`
- trigger/command: `cwf:setup`, `cwf:setup --tools`, `cwf:setup --agent-teams`
- preconditions: [~/.claude/settings.json](~/.claude/settings.json) 대상; AskUserQuestion으로 현재 상태 묻기
- user choices:
  1. `Enable Agent Team mode (recommended)` → `configure-agent-teams.sh --enable`
  2. `Keep current setting` → `configure-agent-teams.sh --status`
  3. `Disable Agent Team mode` → `configure-agent-teams.sh --disable`
- expected behavior: 설정 JSON `env` 섹션에 `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` 추가/제거, 상태 보고 후 새 세션/재시작 안내
- touched files: [~/.claude/settings.json](~/.claude/settings.json)
- failure/stop: JSON 파싱 오류 또는 [~/.claude](~/.claude) 디렉터리 접근 실패 시 중단
- 근거: [references/runtime-and-index-phases.md](references/runtime-and-index-phases.md) Phase 2.9, [plugins/cwf/skills/setup/scripts/configure-agent-teams.sh](plugins/cwf/skills/setup/scripts/configure-agent-teams.sh)

### Branch K: cwf:run 모드 기본 (Phase 2.10)

- branch_id: `setup-branch-run-mode`
- trigger/command: `cwf:setup`, `cwf:setup --tools`, `cwf:setup --env`, `cwf:setup --run-mode`
- preconditions: [hooks/scripts/env-loader.sh](hooks/scripts/env-loader.sh)로 `CWF_RUN_AMBIGUITY_MODE` 감지, `bootstrap-project-config.sh`가 누락 시 자동 호출
- user choices:
  1. `Select default ambiguity handling mode`: `defer-blocking (추천)`, `strict`, `defer-reversible`, `explore-worktrees`
  2. `Where save`: `Shared config (추천)` → `.cwf-config.yaml`, `Local config` → `.cwf-config.local.yaml`
- expected behavior: `configure-run-mode.sh --mode <mode> --scope <scope>` 실행, (템플릿 누락 시 `bootstrap-project-config.sh` 선행), 선택 결과 보고 및 우선순위 안내
- touched files: `.cwf-config.yaml`, `.cwf-config.local.yaml`
- failure/stop: `configure-run-mode.sh` 쓰기 실패 또는 템플릿 생성 실패, 스코프 파일에 대한 권한 문제
- 근거: [references/runtime-and-index-phases.md](references/runtime-and-index-phases.md) Phase 2.10, [plugins/cwf/skills/setup/scripts/configure-run-mode.sh](plugins/cwf/skills/setup/scripts/configure-run-mode.sh)

### Branch L: CWF capability index 생성 (Phase 3)

- branch_id: `setup-branch-cap-index`
- trigger/command: `cwf:setup --cap-index`
- preconditions: `--cap-index` 명시적 요청, CWF 내부 인벤토리 스캔(스크립트 `check-index-coverage.sh` 입력 목록 순서 참고)
- user choices: 없음 (자동 생성), 다만 검증 실패 시 수정 후 재실행 필요
- expected behavior: [.cwf/indexes/cwf-index.md](.cwf/indexes/cwf-index.md) 생성, `check-index-coverage.sh --profile cap` 실행하여 도구/스크립트/skill coverage 확인, 실패하면 재생성
- touched files: [.cwf/indexes/cwf-index.md](.cwf/indexes/cwf-index.md), 인덱스 생성 중 [plugins/cwf/skills](plugins/cwf/skills) 및 [scripts/README.md](scripts/README.md) 등의 참조 링크 포함
- failure/stop: `check-index-coverage` 실패 → 수정/재검증 전까지 종료
- 근거: [plugins/cwf/skills/setup/SKILL.md](plugins/cwf/skills/setup/SKILL.md) Phase 3, [references/runtime-and-index-phases.md](references/runtime-and-index-phases.md) Phase 3, [scripts/check-index-coverage.sh](scripts/check-index-coverage.sh)

### Branch M: Repository index 생성 (Phase 4)

- branch_id: `setup-branch-repo-index`
- trigger/command: `cwf:setup --repo-index [--target <agents|file|both>]` 또는 `cwf:setup` 실행 중 `Generate repository index` 질문에 `예`
- preconditions: `--target` 플래그 또는 AGENTS.md 존재 유무(자동 선택: AGENTS 가 있으면 `agents`, 없으면 `file`), AGENTS managed block 존재 여부 검토
- user choices:
  1. `Generate repository index for this repo as well?` (full setup 진행 시) → [Yes/No](Yes/No)
  2. `target selection`: `agents`, `file`, `both` (CLI 우선, 없으면 자동)
- expected behavior: 루트/skills/references/hook/scripts/others를 모두 스캔하여 인덱스 문서 생성, 선택된 target(AGENTS 블록과/또는 [.cwf/indexes/repo-index.md](.cwf/indexes/repo-index.md))에 내용 쓰기, `check-index-coverage.sh --profile repo` 실행
- touched files: [AGENTS.md](../../../AGENTS.md) (managed block), [.cwf/indexes/repo-index.md](.cwf/indexes/repo-index.md), optional scaffold additions, `AGENTS` block markers, [.cwf-index-ignore](../../../.cwf-index-ignore) 적용
- failure/stop: coverage 검증 실패,쓰기 권한 오류, AGENTS 파일에 marker 주석 누락으로 coverage check 실패
- 근거: [plugins/cwf/skills/setup/SKILL.md](plugins/cwf/skills/setup/SKILL.md) Phase 4, [references/runtime-and-index-phases.md](references/runtime-and-index-phases.md) Phase 4

### Branch N: Lessons/체크포인트 (Phase 5)

- branch_id: `setup-branch-lessons`
- trigger/command: 모든 모드 종료 직전 (full/setup/tools/run-mode 등)
- preconditions: 이전 phases 완료한 상태
- user choices: `Any learnings from the setup process?` 질문에 대해 `예[/](/)아니오` 선택
- expected behavior: 예 → `lessons.md`에 `Expected[/](/)Actual[/](/)Takeaway` 3항목으로 항목 추가, `cwf-state.yaml` `stage_checkpoints`에 `setup` 추가; 아니오 → 체크포인트만 업데이트
- touched files: `lessons.md` (세션 아티팩트 폴더), `cwf-state.yaml`
- failure/stop: `lessons.md` 쓰기 불가 또는 `cwf-state.yaml` stage 체크포인트 수정 실패 시 경고
- 근거: [plugins/cwf/skills/setup/SKILL.md](plugins/cwf/skills/setup/SKILL.md) Phase 5, [references/runtime-and-index-phases.md](references/runtime-and-index-phases.md) Phase 5

## 명백한 후행 실패(스킵 가능 후보)

1. `setup-branch-contract`에서 `bootstrap-setup-contract.sh`가 `fallback`을 반환하면 `cwf:setup` 전체 흐름 중단 → 이후 Branch E~N 모두 실행 불가
2. `setup-branch-missing-deps`에서 `Install missing now`를 수행했는데도 재검지에서 의존성이 해소되지 않은 상태로 `Stop for manual install`을 선택하면 이후 Codex 통합/Hook/Git index 등 모든 숙제 반복 불가
3. `setup-branch-cap-index` 또는 `setup-branch-repo-index`에서 `check-index-coverage.sh` 검증 실패 시 `cwf:setup`은 재생성/수정 전까지 사용자에게 수정 명령을 요구하고 이후 branch를 실행할 수 없음(커버리지 실패가 해결될 때까지 진행 금지)

<!-- AGENT_COMPLETE -->
