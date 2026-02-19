# Plugin Development Cheat Sheet

Quick reference for developing, testing, and deploying plugins.

## Directory Patterns

```text
# Skill-only (e.g., clarify, retro)
plugins/{name}/
├── .claude-plugin/plugin.json
└── skills/{name}/
    ├── SKILL.md
    ├── references/          # optional
    └── scripts/             # optional

# Hook-only (e.g., read-guard, session-log)
plugins/{name}/
├── .claude-plugin/plugin.json
└── hooks/
    ├── hooks.json
    └── scripts/

# Hybrid (e.g., cwf)
plugins/{name}/
├── .claude-plugin/plugin.json
├── hooks/
│   ├── hooks.json
│   └── scripts/
└── skills/{name}/
    ├── SKILL.md
    ├── references/
    └── scripts/
```

## plugin.json

```json
{
  "name": "{name}",
  "description": "A {skill|hook} that ...",
  "version": "1.0.0",
  "author": { "name": "Corca", "url": "https://www.corca.ai/" },
  "repository": "https://github.com/corca-ai/claude-plugins"
}
```

## marketplace.json Entry

Add to [.claude-plugin/marketplace.json](../.claude-plugin/marketplace.json) → `plugins[]`:

```json
{
  "name": "{name}",
  "source": "./plugins/{name}",
  "description": "Same as plugin.json description",
  "keywords": ["keyword1", "keyword2"]
}
```

Rules: `name` = kebab-case matching directory name. `source` = relative path. `description` should match plugin.json.

**Plugin caching**: Plugins are copied to a cache location on install. Files outside the plugin directory won't be available. Use `${CLAUDE_PLUGIN_ROOT}` in hooks and MCP configs to reference files within the installed plugin.

## SKILL.md

### Frontmatter

```yaml
---
name: {name}
description: |
  One-line description.
  Triggers: "/{name}", or when user says "..."
allowed-tools:
  - Bash
  - Read
---
```

Keep SKILL.md < 500 lines. Move details to `references/`.

### Content Rules

1. Keep SKILL.md concise — move details to `references/`
2. No duplication between SKILL.md and references
3. Progressive disclosure — SKILL.md loads on trigger, references load as needed
4. English only for all skill files

### Design Principles

- **Concise is Key**: Context window is shared resource. Don't explain what the agent already knows
- **Degrees of Freedom**: High (text) for multiple valid approaches, medium (pseudocode) for preferred patterns, low (scripts) for exact sequences
- **Execution-heavy skills** (API calls, file processing): delegate to wrapper scripts. SKILL.md handles intent; scripts handle execution

## hooks.json

```json
{
  "hooks": {
    "PreToolUse": [{
      "matcher": "ToolName",
      "hooks": [{
        "type": "command",
        "command": "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/{script}.sh"
      }]
    }]
  }
}
```

Matchers: `PreToolUse`, `PostToolUse`, `Notification` (idle_prompt, etc.)

For simple context injection (no JSON formatting), use `"type": "prompt"` instead of `"type": "command"`.

Hooks are **snapshots at session start** (no hot-reload).

## Environment Variables

Naming: `CWF_{DOMAIN}_{SETTING}`

Priority: CLI argument > environment variable > hardcoded default

Plugin directories are replaced on update (version-specific cache). User config **must** live outside the skill directory — environment variables in shell profile survive any plugin update.

Use the shared loader ([plugins/cwf/hooks/scripts/env-loader.sh](../plugins/cwf/hooks/scripts/env-loader.sh)) and keep this source order:
- project-local config (.cwf-config.local.yaml)
- project-shared config (.cwf-config.yaml)
- process env
- shell profiles (`~/.zshenv`, `~/.zprofile`, `~/.zshrc`, `~/.bash_profile`, `~/.bashrc`, `~/.profile`)

This is needed because Claude Code runs non-interactive Bash sessions — profile files are not auto-sourced.
```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../../hooks/scripts/env-loader.sh"
cwf_env_load_vars CWF_FOO_BAR
```

## Script Guidelines

- Cross-platform (macOS + Linux): avoid `sed -i ''` (macOS-only); avoid Bash 4+ features (`declare -A`, nameref `${!var}`, `|&`) — macOS ships Bash 3.2
- Minimal deps: prefer bash + curl, minimize python3/node
- Use `#!/usr/bin/env bash` and `set -euo pipefail`
- Sourced scripts (e.g., `slack-send.sh`): do NOT add `set -euo pipefail` at top level — it propagates to all callers. If the script is both sourced and executed directly, put strict mode inside the `BASH_SOURCE` guard:
  ```bash
  # Functions here (sourced by test scripts, other scripts)
  my_func() { ... }

  # Main logic (only when executed directly)
  if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
      set -euo pipefail
      # ...
  fi
  ```
- Bash gotcha: `((var++))` returns exit code 1 when var is 0, failing under `set -e`. Use `var=$((var + 1))` instead.
- curl in `set -e` scripts: wrap with `set +e` / `set -e` to capture exit codes:
  ```bash
  set +e
  HTTP_CODE=$(curl -s ... -o "$TMPFILE" -w "%{http_code}")
  CURL_EXIT=$?
  set -e
  ```
- `&&` chains under `set -e`: `[ -f "$f" ] && VAR="$f" && break` exits the script if `[ -f ]` fails (exit code 1). Use if/then blocks instead:
  ```bash
  # BAD: exits under set -e when condition is false
  [ -f "$f" ] && RESULT="$f" && break
  # GOOD: if/then is safe
  if [ -f "$f" ]; then RESULT="$f"; break; fi
  ```
- Empty array iteration under `set -u`: `"${arr[@]}"` on an empty array causes "unbound variable". Guard with `if [[ ${#arr[@]} -gt 0 ]]; then ... fi`.
- Bash regex: in `[[ =~ ]]`, `"?` makes `?` literal (quoted), not a regex quantifier. Use `\"?` for optional literal-quote matching. Bash and zsh have different regex semantics — always debug bash scripts with `bash -c` or `bash -x`, not directly in the Bash tool (which uses zsh).
- When researching Claude Code features (hooks, settings, plugins), verify against the [official docs](https://code.claude.com/docs/en/) via WebFetch.
- When testing scripts, do not manually set up the environment (e.g., `source ~/.zshrc`). Test in a clean environment to reproduce real-world conditions.

## Testing

**Hook scripts** — pipe JSON to stdin:
```bash
echo '{"tool_input":{"file_path":"/path/to/file"}}' | plugins/{name}/hooks/scripts/{script}.sh
```

**Skills** — verify SKILL.md frontmatter, script executability, and run directly to verify behavior.

**Integration** — start a new session with `--plugin-dir`:
```bash
claude --plugin-dir ./plugins/{name} --dangerously-skip-permissions --resume
```

Alternative: add hooks via `/hooks` menu in the current session (goes through review process).

**Apply locally** after modifying an installed plugin:
```bash
/plugin install <plugin-name>@corca-plugins
```

## Pre-Release Validation Gates

Run these checks before public release (or before merging release-bound changes):

```bash
# 1) Verify marketplace entry visibility
bash scripts/check-marketplace-entry.sh --source . --plugin cwf

# 2) Run non-interactive smoke across core CWF skills
bash scripts/noninteractive-skill-smoke.sh \
  --plugin-dir plugins/cwf \
  --workdir <user-repo-path> \
  --timeout 45 \
  --max-failures 0 \
  --max-timeouts 0
```

`check-marketplace-entry.sh` exit codes:
- `0`: FOUND
- `2`: LOOKUP_FAILED (network/path/http)
- `3`: INVALID_MARKETPLACE (invalid JSON shape)
- `4`: MISSING_ENTRY

`noninteractive-skill-smoke.sh` outputs per-case `PASS|FAIL|TIMEOUT` logs and fails gate (exit 1) when configured thresholds are exceeded.

## Repo Git Hooks

Recommended (interactive, single entrypoint):
```text
cwf:setup
```
Full setup asks whether to install git hooks and which gate profile to use.

Explicit mode (non-interactive):
```text
cwf:setup --git-hooks both --gate-profile balanced
```

Manual fallback:
```bash
git config core.hooksPath .githooks
```

- Profiles:
  - `fast`: markdownlint only
  - `balanced` (recommended): markdownlint + local link checks + staged shellcheck + push-time index coverage
  - `strict`: `balanced` + provenance freshness and growth-drift reports on push
- Contract gate:
  - pre-commit/pre-push also run `check-portability-contract.sh --contract auto --context hook`
  - `auto` resolves `authoring` only for CWF authoring repos; all other repos use `portable`
  - contract files live under `plugins/cwf/contracts/` (`portable-contract.json`, `authoring-contract.json`, `claims.json`, `change-impact.json`)
- [pre-commit](../.githooks/pre-commit): staged checks for markdown and shell scripts.
- [pre-push](../.githooks/pre-push): repo-wide markdown/link checks plus index coverage checks.
- [plugins/cwf/skills/setup/scripts/configure-git-hooks.sh](../plugins/cwf/skills/setup/scripts/configure-git-hooks.sh): deterministic hook installer/profile applier used by setup.

## Version Bump Rules

| Change type | Bump | Examples |
|------------|------|---------|
| Bug fix, typo, minor tweak | patch | Fix script error, update wording |
| New feature, new flag, new capability | minor | Add --deep flag, new subcommand |
| Breaking change, renamed skill, changed API | major | Rename /search → /web-search |

## Deploy Workflow

Default executor for plugin changes: [plugin-deploy](../.claude/skills/plugin-deploy/SKILL.md). Use manual steps below only when the skill is unavailable or explicitly skipped.

1. Bump version in `plugin.json` (see version bump rules above)
2. Sync `marketplace.json` entry (version if listed, description, keywords)
3. Update [CHANGELOG.md](../CHANGELOG.md) if the plugin has one (describe what changed)
4. Update [README.md](../README.md) and [README.ko.md](../README.ko.md) (table + detail section)
5. New plugins: check [AI_NATIVE_PRODUCT_TEAM.md](../AI_NATIVE_PRODUCT_TEAM.md) for link opportunities
6. Test locally
7. Commit and push
8. On **main branch**: run `cwf:update` to sync installed behavior with latest plugin changes

Inform users after deploy:
```text
The plugin has been updated. To apply:
1. /plugin marketplace update
2. /plugin install <plugin-name>@corca-plugins
```

## Adding New Plugins

Checklist for new plugins (in addition to the deploy workflow above):

1. Add entry to [.claude-plugin/marketplace.json](../.claude-plugin/marketplace.json) → `plugins[]`
2. Bump marketplace metadata version
3. Update [README.md](../README.md) and [README.ko.md](../README.ko.md) (table + detail section)
4. Check [AI_NATIVE_PRODUCT_TEAM.md](../AI_NATIVE_PRODUCT_TEAM.md) for link opportunities

## Marketplace User Commands

```bash
# Add marketplace
/plugin marketplace add corca-ai/claude-plugins

# Update marketplace catalog
/plugin marketplace update

# Install/update a plugin
/plugin install {name}@corca-plugins
/plugin update {name}@corca-plugins
```

For full marketplace documentation, see the [official Claude Code docs](https://code.claude.com/docs/en/plugin-marketplaces).
