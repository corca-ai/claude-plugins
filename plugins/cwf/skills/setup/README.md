# setup Skill File Map

File-level map for [setup](SKILL.md).

- [README.md](README.md): File map for this skill directory.
- [SKILL.md](SKILL.md): Primary instructions and execution workflow for this skill.
- [scripts/check-index-coverage.sh](scripts/check-index-coverage.sh): Validates generated index coverage for cap/repo profiles.
- [scripts/configure-git-hooks.sh](scripts/configure-git-hooks.sh): Installs/removes repo git hooks and applies gate profiles (`fast`, `balanced`, `strict`).
- [scripts/migrate-env-vars.sh](scripts/migrate-env-vars.sh): Migrates legacy env keys to canonical `CWF_*` keys in shell profiles.
- [scripts/bootstrap-project-config.sh](scripts/bootstrap-project-config.sh): Bootstraps .cwf/config.yaml + .cwf/config.local.yaml and ensures local config gitignore.
