# Skills Guide

## Skill Structure

```text
.claude/skills/{skill-name}/
├── SKILL.md              # Required. Core instructions only (<500 lines)
├── references/           # Optional. Detailed docs
│   └── *.md
└── scripts/              # Optional. Executable utilities
    └── *.sh
```

In this marketplace, skills are located within `plugins/{name}/skills/{name}/`.

## Skill Content Rules

1. **Modify skill files in the plugin directory only**
2. **Keep SKILL.md concise** - Move details to `references/`
3. **No duplication** - Don't repeat content between SKILL.md and references
4. **Progressive Disclosure** - Load SKILL.md on trigger, load references as needed
5. **English only** - All skill files (SKILL.md, references) must be written in English

## Design Principles

- **Concise is Key**: Context window is shared resource. Don't explain what Claude already knows
- **Set Appropriate Degrees of Freedom**:
  - High freedom (text instructions) - Multiple valid approaches
  - Medium freedom (pseudocode) - Preferred pattern with allowed variations
  - Low freedom (specific scripts) - Exact sequence required

## Skill Categories

- **Instruction-only** (plan-and-lessons, retro): SKILL.md alone — no execution needed
- **Execution-heavy** (gather-context): SKILL.md + `scripts/`
- **Hybrid** (clarify): SKILL.md with occasional Bash

**Execution-heavy skills** (API calls, file processing) should delegate to wrapper scripts. SKILL.md handles intent analysis and parameter decisions; scripts handle reliable execution. This matches the hook pattern (both use scripts) and reduces context cost.

## Adding Environment Variables

### Naming Convention

For skills distributed via [corca-ai/claude-plugins](https://github.com/corca-ai/claude-plugins):

```text
CLAUDE_CORCA_<SKILL_NAME>_<SETTING>
```

- `CLAUDE_` — Claude Code ecosystem prefix
- `CORCA_` — Marketplace (corca-ai) namespace, avoids collision with other Claude plugins
- `<SKILL_NAME>` — Skill identifier (e.g., `NOTION_TO_MD`)
- `<SETTING>` — Specific config (e.g., `OUTPUT_DIR`)

Example: `CLAUDE_CORCA_NOTION_TO_MD_OUTPUT_DIR`

### Why Environment Variables

Plugin/skill directories are replaced on update (version-specific cache). User config **must** live outside the skill directory. Environment variables in shell profile (`~/.zshrc`) survive any plugin update.

### Priority Chain

CLI argument > Environment variable > Hardcoded default

### Documentation

Add environment variable section to `references/` or SKILL.md:

```markdown
## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `CLAUDE_CORCA_<SKILL>_<SETTING>` | `default` | Description |
```
