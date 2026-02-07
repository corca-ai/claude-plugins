# Fundamentals

## What is a Skill?

A skill is a set of instructions — packaged as a simple folder — that teaches Claude how to handle specific tasks or workflows. Instead of re-explaining your preferences, processes, and domain expertise in every conversation, skills let you teach Claude once and benefit every time.

A skill is a folder containing:

- **SKILL.md** (required): Instructions in Markdown with YAML frontmatter
- **scripts/** (optional): Executable code (Python, Bash, etc.)
- **references/** (optional): Documentation loaded as needed
- **assets/** (optional): Templates, fonts, icons used in output

## Core Design Principles

### Progressive Disclosure

Skills use a three-level system:

1. **First level (YAML frontmatter):** Always loaded in Claude's system prompt. Provides just enough information for Claude to know when each skill should be used without loading all of it into context.
2. **Second level (SKILL.md body):** Loaded when Claude thinks the skill is relevant to the current task. Contains the full instructions and guidance.
3. **Third level (Linked files):** Additional files bundled within the skill directory that Claude can choose to navigate and discover only as needed.

This progressive disclosure minimizes token usage while maintaining specialized expertise.

### Composability

Claude can load multiple skills simultaneously. Your skill should work well alongside others, not assume it's the only capability available.

### Portability

Skills work identically across Claude.ai, Claude Code, and API. Create a skill once and it works across all surfaces without modification, provided the environment supports any dependencies the skill requires.

## For MCP Builders: Skills + Connectors

If you already have a working MCP server, you've done the hard part. Skills are the knowledge layer on top — capturing the workflows and best practices you already know, so Claude can apply them consistently.

### The Kitchen Analogy

- **MCP** provides the professional kitchen: access to tools, ingredients, and equipment.
- **Skills** provide the recipes: step-by-step instructions on how to create something valuable.

Together, they enable users to accomplish complex tasks without needing to figure out every step themselves.

### How They Work Together

| MCP (Connectivity) | Skills (Knowledge) |
|---|---|
| Connects Claude to your service (Notion, Asana, Linear, etc.) | Teaches Claude how to use your service effectively |
| Provides real-time data access and tool invocation | Captures workflows and best practices |
| What Claude **can** do | How Claude **should** do it |

### Why This Matters for Your MCP Users

**Without skills:**
- Users connect your MCP but don't know what to do next
- Support tickets asking "how do I do X with your integration"
- Each conversation starts from scratch
- Inconsistent results because users prompt differently each time
- Users blame your connector when the real issue is workflow guidance

**With skills:**
- Pre-built workflows activate automatically when needed
- Consistent, reliable tool usage
- Best practices embedded in every interaction
- Lower learning curve for your integration
