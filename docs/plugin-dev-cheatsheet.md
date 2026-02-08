# Plugin Development Cheat Sheet

Quick reference for adding and modifying plugins. For full details, see [adding-plugin.md](adding-plugin.md), [modifying-plugin.md](modifying-plugin.md), [skills-guide.md](skills-guide.md), [claude-marketplace.md](claude-marketplace.md).

## Directory Patterns

```text
# Skill-only (e.g., clarify, retro)
plugins/{name}/
├── .claude-plugin/plugin.json
└── skills/{name}/
    ├── SKILL.md
    ├── references/          # optional
    └── scripts/             # optional

# Hook-only (e.g., smart-read, plan-and-lessons)
plugins/{name}/
├── .claude-plugin/plugin.json
└── hooks/
    ├── hooks.json
    └── scripts/

# Hybrid (e.g., gather-context)
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

Add to `.claude-plugin/marketplace.json` → `plugins[]`:

```json
{
  "name": "{name}",
  "source": "./plugins/{name}",
  "description": "Same as plugin.json description",
  "keywords": ["keyword1", "keyword2"]
}
```

## SKILL.md Frontmatter

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

## Environment Variables

Naming: `CLAUDE_CORCA_{PLUGIN_NAME}_{SETTING}`

3-tier loading in scripts (needed because Claude Code runs Bash sessions — `~/.zshrc` is not sourced automatically):
```bash
# 1. Shell env (already set)
# 2. ~/.claude/.env
[ -f "$HOME/.claude/.env" ] && { set -a; source "$HOME/.claude/.env"; set +a; }
# 3. Shell profiles (fallback: safe extraction without eval)
if [ -z "${VAR:-}" ]; then
  _line=$(grep -shm1 '^export VAR=' ~/.zshrc ~/.bashrc 2>/dev/null) || true
  if [ -n "${_line:-}" ]; then
    VAR="${_line#*=}"; VAR="${VAR#[\"\']}"; VAR="${VAR%[\"\']}"
    export VAR
  fi
fi
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
- `&&` chains under `set -e`: `[ -f "$f" ] && VAR="$f" && break` exits the script if `[ -f ]` fails (exit code 1). Use `if/then` blocks instead:
  ```bash
  # BAD: exits under set -e when condition is false
  [ -f "$f" ] && RESULT="$f" && break
  # GOOD: if/then is safe
  if [ -f "$f" ]; then RESULT="$f"; break; fi
  ```
- Empty array iteration under `set -u`: `"${arr[@]}"` on an empty array causes "unbound variable". Guard with `if [[ ${#arr[@]} -gt 0 ]]; then ... fi`.

## Testing

**Hook scripts** — pipe JSON to stdin:
```bash
echo '{"tool_input":{"file_path":"/path/to/file"}}' | plugins/{name}/hooks/scripts/{script}.sh
```

**Integration** — hooks are **snapshots at session start** (no hot-reload). Start a new session:
```bash
claude --plugin-dir ./plugins/{name} --dangerously-skip-permissions --resume
```

**Skills** — verify SKILL.md frontmatter and script executability.

## Version Bump Rules

| Change type | Bump | Examples |
|------------|------|---------|
| Bug fix, typo, minor tweak | patch | Fix script error, update wording |
| New feature, new flag, new capability | minor | Add --deep flag, new subcommand |
| Breaking change, renamed skill, changed API | major | Rename /search → /web-search |

## Deploy Workflow

1. Bump version in `plugin.json` (see version bump rules above)
2. Sync `marketplace.json` entry (version if listed, description, keywords)
3. Update `CHANGELOG.md` if the plugin has one (describe what changed)
4. Update `README.md` and `README.ko.md` (table + detail section)
5. New plugins: check `AI_NATIVE_PRODUCT_TEAM.md` for link opportunities
6. Test locally
7. Commit and push
8. Run `bash scripts/update-all.sh`
