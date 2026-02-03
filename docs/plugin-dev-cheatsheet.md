# Plugin Development Cheat Sheet

Quick reference for adding and modifying plugins. For full details, see [adding-plugin.md](adding-plugin.md), [modifying-plugin.md](modifying-plugin.md), [skills-guide.md](skills-guide.md), [claude-marketplace.md](claude-marketplace.md).

## Directory Patterns

```
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

# Hybrid (e.g., web-search, gather-context)
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

## Environment Variables

Naming: `CLAUDE_CORCA_{PLUGIN_NAME}_{SETTING}`

3-tier loading in scripts:
```bash
# 1. Shell env (already set)
# 2. ~/.claude/.env
[ -f "$HOME/.claude/.env" ] && { set -a; source "$HOME/.claude/.env"; set +a; }
# 3. Shell profiles
[ -z "${VAR:-}" ] && eval "$(grep -sh '^export VAR=' ~/.zshrc ~/.bashrc)"
```

## Script Guidelines

- Cross-platform (macOS + Linux): avoid `sed -i ''` (macOS-only)
- Minimal deps: prefer bash + curl, minimize python3/node
- Use `#!/usr/bin/env bash` and `set -euo pipefail`

## Testing

**Hook scripts** — pipe JSON to stdin:
```bash
echo '{"tool_input":{"file_path":"/path/to/file"}}' | plugins/{name}/hooks/scripts/{script}.sh
```

**Integration** — start new session with plugin loaded:
```bash
claude --plugin-dir ./plugins/{name} --dangerously-skip-permissions --resume
```

**Skills** — verify SKILL.md frontmatter and script executability.

## Deploy Workflow

1. Bump version in `plugin.json`
2. Sync `marketplace.json` entry (version if listed, description, keywords)
3. Update `README.md` and `README.ko.md` (table + detail section)
4. New plugins: check `AI_NATIVE_PRODUCT_TEAM.md` for link opportunities
5. Test locally
6. Commit and push
7. Run `bash scripts/update-all.sh`
