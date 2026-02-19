# CWF 플러그인 외부 저장소 첫 설치/온보딩 흐름

README에서 안내하는 빠른 시작 흐름은 다음과 같습니다: 마켓플레이스를 등록하고 `claude plugin install cwf@corca-plugins`을 실행한 뒤 Claude Code를 재시작하고 `cwf:setup`을 한 번만 실행하면 설치·설정이 마무리된다고 명시합니다(README.md:10-37, README.ko.md:12-38). `cwf:setup`은 `.cwf-config*.yaml[ 부트스트랩, Codex/Gemini/Tavily/Exa 감지, 로컬 의존성 점검/선택적 설치(]( 부트스트랩, Codex/Gemini/Tavily/Exa 감지, 로컬 의존성 점검/선택적 설치()shellcheck`, `jq`, `gh`, `node`, `python3`, `lychee`, `markdownlint-cli2`), AGENTS.md/별도 인덱스 생성까지 담당하기 때문에 첫 실행 이후 워크플로우가 예측 가능한 상태로 안정화됩니다(README.ko.md:22-29, plugins/cwf/skills/setup/SKILL.md:8-177).

## 0단계: 명령 기반 초기화

- [claude plugin marketplace add https://github.com/corca-ai/claude-plugins.git](claude plugin marketplace add https://github.com/corca-ai/claude-plugins.git) → `claude plugin install cwf@corca-plugins` → Claude Code 재시작 → `cwf:setup`(README.md:12-37, README.ko.md:12-38).
- `cwf:setup` 기본 흐름은 훅, 도구, 설정/에이전트/런모드, Codex 통합, Git 훅 게이트, 인덱스/강화 학습까지 단계별로 실행하기 때문에 CLI에서 별도 분기 명령 없이 단일 진입점으로 대부분 설정을 끝낼 수 있습니다(plugins/cwf/skills/setup/SKILL.md:10-205).
- `cwf:setup`은 훅 그룹 정보를 [~/.claude/cwf-hooks-enabled.sh](~/.claude/cwf-hooks-enabled.sh)로 뽑고 `cwf-state.yaml` `hooks:`를 동기화하므로, 설정 직후 해당 파일과 상태값을 확인하면 어떤 보호/검사 훅이 켜졌는지 바로 알 수 있습니다(plugins/cwf/skills/setup/SKILL.md:65-139).

## 1단계: `cwf:setup` 내부 핵심 흐름

1. 훅 그룹 선택(Phase 1): `sync-hook-state.sh --enable ...` → [~/.claude/cwf-hooks-enabled.sh](~/.claude/cwf-hooks-enabled.sh) 생성 + `cwf-state.yaml` `hooks:` 기록 → `--check`로 검증(plugins/cwf/skills/setup/SKILL.md:65-139).
2. 외부 도구/로컬 의존성 감지(Phase 2): `codex`, `gemini`, API 키, `shellcheck`, `jq`, `gh`, `node`, `python3`, `lychee`, `markdownlint-cli2`를 `command -v`로 확인하고 결과를 `cwf-state.yaml` `tools:`에 쓴 뒤 두 그룹 결과를 보고함(plugins/cwf/skills/setup/SKILL.md:143-175, references/tool-detection-and-deps.md:11-71).
   - 결핍이 존재하면 `Some CWF runtime dependencies are missing. Install missing tools now?`라는 AskUserQuestion을 띄우고 `Install missing now`, `Show commands only`, `Skip for now` 옵션에 따라 `install-tooling-deps.sh`를 호출하며, 설치 후에는 `--check`를 다시 실행하고 `cwf-state.yaml`을 완전히 재작성해 설치 결과를 SSOT로 유지합니다(references/tool-detection-and-deps.md:73-154).
   - 의존성 설치는 [bash .../install-tooling-deps.sh --install missing](bash .../install-tooling-deps.sh --install missing)으로 시작하며, 스크립트는 Homebrew/Apt 또는 로컬 바이너리로 `shellcheck`, `jq`, `gh`, `node`, `python3`, `lychee`, `markdownlint-cli2`를 자동 설치하고, 실패 시 `brew install ...[/](/)sudo apt-get install -y ...` 등 수동 명령을 출력합니다(plugins/cwf/skills/setup/scripts/install-tooling-deps.sh:1-363, 221-259).
3. setup 계약/레포 제안(Phase 2.3.4): `bootstrap-setup-contract.sh --json` → [.cwf/setup-contract.yaml](.cwf/setup-contract.yaml) 생성·업데이트·기존 여부를 보고하고, repo-specific 제안을 `install-tooling-deps.sh`로 설치할지 결정(plugins/cwf/skills/setup/SKILL.md:143-177, references/tool-detection-and-deps.md:125-155).
4. Codex 통합(Phase 2.4~2.6): Codex CLI가 감지되면 `detect-plugin-scope.sh[로 스코프(사용자/프로젝트/로컬)를 파악하고 ](로 스코프(사용자/프로젝트/로컬)를 파악하고 )sync-skills.sh`, `install-wrapper.sh --enable[ 같은 스크립트를 scope-aware로 실행하며, 설치/롤백 상태와 ]( 같은 스크립트를 scope-aware로 실행하며, 설치/롤백 상태와 )type -a codex`를 항상 보고합니다(plugins/cwf/skills/setup/SKILL.md:181-375).
5. Git 훅 게이트, 프로젝트 config, 에이전트 팀, `cwf:run` 기본 모드, 색인 생성, 수업 수집(Phase 2.7~5): `configure-git-hooks.sh`, `bootstrap-project-config.sh`, `configure-agent-teams.sh`, `configure-run-mode.sh`, `check-index-coverage.sh` 등을 순차적으로 실행하고 `lessons.md[/](/)cwf-state.yaml` `stage_checkpoints`를 갱신합니다(plugins/cwf/skills/setup/SKILL.md:187-424).
6. 결과 아티팩트: [~/.claude/cwf-hooks-enabled.sh](~/.claude/cwf-hooks-enabled.sh), [.cwf/cwf-state.yaml](.cwf/cwf-state.yaml) (hooks/tools/stage_checkpoints), [.cwf-config.yaml/.cwf-config.local.yaml](.cwf-config.yaml/.cwf-config.local.yaml), [.cwf/setup-contract.yaml](.cwf/setup-contract.yaml), `lessons.md[, (선택적으로) AGENTS.md 블록 또는 별도 인덱스 파일, Codex 스킬/랩퍼 링크. 이들 파일이 생성되지 않았다면 ](, (선택적으로) AGENTS.md 블록 또는 별도 인덱스 파일, Codex 스킬/랩퍼 링크. 이들 파일이 생성되지 않았다면 )cwf:setup`이 전부 실행되지 않은 것이므로 재시작 후 다시 `cwf:setup`을 수행해야 합니다(plugins/cwf/skills/setup/SKILL.md:65-424).

## 2단계: 시나리오 트리 (zero-state → 첫 스킬 실행)

1. **초기 설치**
   - `claude plugin marketplace add ...` → `claude plugin install cwf@corca-plugins` → Claude Code 재시작 → `cwf:setup` 실행(README.md:12-37, README.ko.md:12-38).
   - 예상 아티팩트: 설치된 `.claude-plugin` 디렉터리, `cwf-state.yaml`, [~/.claude/cwf-hooks-enabled.sh](~/.claude/cwf-hooks-enabled.sh).
2. **`cwf:setup` 기본 흐름**
   - 훅 선택(Phase 1) → 도구 감지(Phase 2 → `cwf-state.yaml` `tools:` 업데이트) → 설정 계약/옵션 → Codex 통합 → Git 훅 게이트/에이전트 팀/런모드 → 색인/레슨(Phase 3~5)(plugins/cwf/skills/setup/SKILL.md:10-424).
   - Branch A: **의존성 모두 존재** → `cwf-state.yaml` 보고 + `setup-contract[/](/)config[/](/)run-mode[/](/)agent team[/](/)lessons` 만 실행. 별도 설치 명령 없음.
   - Branch B: **의존성 누락**
     - AskUserQuestion에서 `Install missing now (recommended)` 선택 → [bash .../install-tooling-deps.sh --install missing](bash .../install-tooling-deps.sh --install missing) 실행 → 자동 또는 홈브류/Apt 설치 시도 → [bash .../install-tooling-deps.sh --check](bash .../install-tooling-deps.sh --check)로 재점검(plugins/cwf/skills/setup/SKILL.md:143-177, references/tool-detection-and-deps.md:73-154).
     - 설치 실패 시 `manual_hint` 명령(예: `brew install shellcheck[/](/)sudo apt-get install -y jq[ 등)을 출력(plugins/cwf/skills/setup/scripts/install-tooling-deps.sh:221-259). 수행 후 ]( 등)을 출력(plugins/cwf/skills/setup/scripts/install-tooling-deps.sh:221-259). 수행 후 )cwf:setup`을 다시 시작하거나 계속 진행→ 의존성 확인 실패 리스트 보고 & 수동 설치 판단.
     - `Show commands only` 또는 `Skip for now` 선택 시에는 `install-tooling-deps.sh --check`를 실행해 수동 명령 목록을 출력하고, 여전히 부족한 툴을 명시적으로 언급한 뒤 진행 여부를 묻습니다(References: Tool Detection doc).
   - 기대 아티팩트: [.cwf/setup-contract.yaml](.cwf/setup-contract.yaml), `.cwf-config*.yaml`, `lessons.md` 업데이트.
3. **Codex/스코프 분기**
   - `cwf:setup`이 Codex CLI를 감지하면 `detect-plugin-scope.sh` → 스코프(`user`, `project`, `local[)와 설치 경로/프로젝트 경로 출력 → ]()와 설치 경로/프로젝트 경로 출력 → )Skills + wrapper`, `Skills only`, `Skip` 선택지를 AskUserQuestion으로 노출(plugins/cwf/skills/setup/SKILL.md:181-220).
   - `Skills + wrapper`: `sync-skills.sh` 실행 → `install-wrapper.sh --enable [--add-path|--project-root]` → 상태(`install-wrapper.sh --status`, `type -a codex`) 보고.
   - `Skills only`: `sync-skills.sh`만 실행.
   - `Skip`: 변경 없이 종료.
   - “프로젝트/로컬 → 사용자로 내려갈 때” 등 민감한 scope 전환은 명시적 재확인이 필요함(plugins/cwf/skills/setup/SKILL.md:181-375).
4. **추가 스코프/환경 분기**
   - `cwf:setup --repo-index`(`--target agents|file|both[) / ]() / )--cap-index` 사용자 요구 시 색인 생성 후 `check-index-coverage.sh` 검증(plugins/cwf/skills/setup/SKILL.md:385-410).
   - `cwf:setup --git-hooks ...`을 선택하면 `configure-git-hooks.sh`로 pre-commit/pre-push/both/none + gate profile(fast/balanced/strict)의 조합을 적용하고 상태 보고(plugins/cwf/skills/setup/SKILL.md:187-204).
   - `Agent Team`, `run-mode` 설정은 각기 `configure-agent-teams.sh`, `configure-run-mode.sh`를 호출해 `.cwf-config*.yaml`에 중복 없이 기록(plugins/cwf/skills/setup/SKILL.md:229-381).

## 3단계: 첫 스킬 실행

- `cwf:run` 프롬프트(`I need to solve ... Please use CWF...`)로 전체 워크플로우(gather → clarify → plan → review(plan) → impl → review(code) → refactor → retro → ship)를 시작하거나 `cwf:gather[/](/)cwf:clarify`처럼 개별 스킬을 호출함(README.ko.md:40-57). 첫 실행 이후 [.cwf/gather-*](.cwf/gather-*) 등 세션 아티팩트가 생성되고 `cwf-state.yaml`의 staged checkpoints가 계속 쌓입니다.

## 4단계: 유지보수 및 개발자 관점

- 새로운 CWF 버전이 나오면 `cwf:update`를 통해 스코프 해석 → `claude plugin marketplace update corca-plugins` → `claude plugin update "cwf@corca-plugins" --scope <scope>` 방식으로 점검/업데이트(plugins/cwf/skills/update/SKILL.md:6-158).
- 플러그인 수정을 했다면 [/plugin-deploy cwf](/plugin-deploy cwf) 플로우를 통해 `check-consistency.sh` → `marketplace.json`, README, Codex 링크 정합성 → Codex 동기화 → 로컬 테스트 → 요약을 순차 수행하며 배포를 준비할 수 있습니다(.claude/skills/plugin-deploy/SKILL.md:14-118).
- plugin-dev-cheatsheet는 개발자가 새로운 스킬/훅을 추가할 때 필요한 디렉터리 구조, `plugin.json[/](/).claude-plugin/marketplace.json` 규칙, SKILL.md/HOOKS 구조, 스크립트 스타일 가이드, 테스트/통합 방법을 요약합니다(docs/plugin-dev-cheatsheet.md:1-200).
- [/plugin-deploy](/plugin-deploy)는 `--dry-run`, `--skip-test`, `--skip-codex-sync[ 등을 받아 플러그인 유형(hook/skill/hybrid)에 따라 적절한 테스트/검증을 실행하고 실패 시 메시지를 출력하므로, 첫 설치/업데이트 이후에도 ]( 등을 받아 플러그인 유형(hook/skill/hybrid)에 따라 적절한 테스트/검증을 실행하고 실패 시 메시지를 출력하므로, 첫 설치/업데이트 이후에도 )check-consistency` → `sync-skills` 흐름을 반복해서 환경을 일관되게 유지할 수 있습니다(.claude/skills/plugin-deploy/SKILL.md:22-118).

<!-- AGENT_COMPLETE -->
