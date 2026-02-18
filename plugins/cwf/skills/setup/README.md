# setup Skill File Map

File-level map for [setup](SKILL.md).

- [README.md](README.md): File map for this skill directory.
- [SKILL.md](SKILL.md): Primary instructions and execution workflow for this skill.
- [references/tool-detection-and-deps.md](references/tool-detection-and-deps.md): Detailed checks/prompts for setup phase `2` (external tool detection and dependency handling).
- [references/setup-contract.md](references/setup-contract.md): Setup-contract bootstrap and repo-specific tool suggestion flow for first-run setup.
- [references/codex-scope-integration.md](references/codex-scope-integration.md): Detailed prompts/commands for scope-aware Codex integration phases (`2.4`/`2.5`/`2.6`).
- [references/runtime-and-index-phases.md](references/runtime-and-index-phases.md): Detailed prompts/commands for setup phases `2.7`~`2.10` and index/lessons phases (`3`/`4`/`5`).
- [scripts/bootstrap-setup-contract.sh](scripts/bootstrap-setup-contract.sh): Bootstraps a repository-local setup contract file under the configured CWF artifact root with core + repo-specific tool scopes.
- [scripts/check-setup-contract-runtime.sh](scripts/check-setup-contract-runtime.sh): Runtime regression check for setup-contract status flow (`created|existing|updated|fallback`).
- [scripts/check-index-coverage.sh](scripts/check-index-coverage.sh): Validates generated index coverage for cap/repo profiles.
- [scripts/configure-git-hooks.sh](scripts/configure-git-hooks.sh): Installs/removes repo git hooks and applies gate profiles (`fast`, `balanced`, `strict`).
- [scripts/migrate-env-vars.sh](scripts/migrate-env-vars.sh): Migrates legacy env keys to canonical `CWF_*` keys in shell profiles.
- [scripts/bootstrap-project-config.sh](scripts/bootstrap-project-config.sh): Bootstraps .cwf-config.yaml + .cwf-config.local.yaml and ensures local config gitignore.
- [scripts/configure-agent-teams.sh](scripts/configure-agent-teams.sh): Toggles Claude Agent Team runtime mode by editing `~/.claude/settings.json` env key.
- [scripts/configure-run-mode.sh](scripts/configure-run-mode.sh): Persists `cwf:run` ambiguity mode (`strict|defer-blocking|defer-reversible|explore-worktrees`) into project config.
- [scripts/install-tooling-deps.sh](scripts/install-tooling-deps.sh): Checks/installs setup dependencies (core: `shellcheck`, `jq`, `gh`, `node`, `python3`, `lychee`, `markdownlint-cli2`; optional repo suggestions: `yq`, `rg`, `realpath`, `perl`).
