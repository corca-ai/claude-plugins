# setup Skill File Map

File-level map for [setup](SKILL.md).

- [README.md](README.md): File map for this skill directory.
- [SKILL.md](SKILL.md): Primary instructions and execution workflow for this skill.
- [scripts/check-index-coverage.sh](scripts/check-index-coverage.sh): Validates generated index coverage for cap/repo profiles.
- [scripts/configure-git-hooks.sh](scripts/configure-git-hooks.sh): Installs/removes repo git hooks and applies gate profiles (`fast`, `balanced`, `strict`).
- [scripts/migrate-env-vars.sh](scripts/migrate-env-vars.sh): Migrates legacy env keys to canonical `CWF_*` keys in shell profiles.
- [scripts/bootstrap-project-config.sh](scripts/bootstrap-project-config.sh): Bootstraps .cwf/config.yaml + .cwf/config.local.yaml and ensures local config gitignore.
- [scripts/configure-agent-teams.sh](scripts/configure-agent-teams.sh): Toggles Claude Agent Team runtime mode by editing `~/.claude/settings.json` env key.
- [scripts/configure-run-mode.sh](scripts/configure-run-mode.sh): Persists `cwf:run` ambiguity mode (`strict|defer-blocking|defer-reversible|explore-worktrees`) into project config.
- [scripts/install-tooling-deps.sh](scripts/install-tooling-deps.sh): Checks and installs common local tooling dependencies (`shellcheck`, `jq`, `gh`, `node`, `python3`) for setup/ship/review flows.
