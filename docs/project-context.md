# Project Context

Accumulated context from retrospectives. Each session's retro may add to this document.

## Project

- corca-plugins is a Claude Code plugin marketplace for "AI Native Product Teams"
- Contains skills (clarify, interview, g-export, slack-to-md, notion-to-md, suggest-tidyings, retro, gather-context, web-search), hooks (attention-hook), and supporting docs
- Plan & Lessons Protocol creates `prompt-logs/{YYMMDD}-{title}/` per session with plan.md, lessons.md, and optionally retro.md

## Design Principles

- SKILL.md tells Claude "what to do", not "how to analyze" — trust Claude's capabilities
- CLAUDE.md is for Claude's behavior, not user instructions
- Progressive disclosure: CLAUDE.md is concise, details live in docs/
- Dogfooding: new tools are tested in the session that creates them

## Conventions

- Documentation language: English for docs/, Korean for README.md and AI_NATIVE_PRODUCT_TEAM.md
- Lessons and retro: written in the user's language
- Plugin structure: `plugins/{name}/.claude-plugin/plugin.json` + `plugins/{name}/skills/{name}/SKILL.md`

## Hook Configuration

- Project hooks go in `.claude/settings.json` under the `"hooks"` key — NOT `.claude/hooks.json` (which is plugin-only format)
- `type: prompt` hooks work with any hook event and are simpler for context injection (no JSON formatting needed)
- Claude Code hook docs: https://code.claude.com/docs/en/hooks.md
