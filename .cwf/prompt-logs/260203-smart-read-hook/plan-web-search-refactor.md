# Plan: web-search Skill Refactoring — Script Delegation Pattern

## Background

During the smart-read hook session, the agent invoked `/web-search` but then searched for a `.sh` script file instead of following the loaded SKILL.md instructions. Root cause analysis revealed an architectural asymmetry:

- **Hooks** have executable `.sh` scripts — "find and run" mental model
- **web-search skill** has instruction-only SKILL.md — "read and follow" mental model

This asymmetry causes confusion, especially after context compaction. The gather-context skill already solves this: SKILL.md describes the workflow, but delegates execution to scripts (g-export.sh, slack-api.mjs, etc.).

## Goal

Refactor web-search to use the **script delegation pattern**: SKILL.md handles command parsing and query intelligence (what the agent is good at), wrapper scripts handle API execution (what scripts are good at).

## Success Criteria

```gherkin
Given `/web-search latest AI news`
When the skill executes
Then the agent analyzes intent (topic: news, time_range: week)
And calls search.sh with --topic news --time-range week "latest AI news"
And the script handles env loading, payload building, curl, parsing, formatting
And the output is identical to current behavior

Given `/web-search code React server components`
When the skill executes
Then the agent assesses complexity (tokensNum: 10000)
And calls code-search.sh --tokens 10000 "React server components"

Given `/web-search extract https://example.com "pricing"`
When the skill executes
Then the agent calls extract.sh "https://example.com" --query "pricing"

Given the search.sh script is run standalone
When piped test input
Then it produces correct output (unit-testable independently)
```

## Design

### Separation of Concerns

| Responsibility | Owner | Why |
|----------------|-------|-----|
| Command parsing (subcommand, modifiers) | SKILL.md (agent) | Simple string parsing |
| Query intelligence (temporal, topic, depth) | SKILL.md (agent) | Requires NLU |
| Complexity assessment (tokensNum) | SKILL.md (agent) | Requires judgment |
| Env var loading | Script | Deterministic |
| JSON payload construction | Script | Error-prone if manual |
| curl execution + error handling | Script | Deterministic |
| Response parsing + formatting | Script | Deterministic |

### Script Interface

```bash
# General search
search.sh [--topic news|finance] [--time-range day|week|month|year] [--deep] "<query>"

# Code search
code-search.sh [--tokens NUM] "<query>"

# URL extraction
extract.sh "<url>" [--query "<relevance_query>"]
```

All scripts:
- Load env vars from `~/.claude/.env` (same pattern as hooks)
- Output formatted markdown to stdout
- Exit 0 on success, non-zero on error with message to stderr
- Handle missing API key with guidance message

### File Structure (after refactoring)

```
plugins/web-search/
├── .claude-plugin/
│   └── plugin.json              # bump to v2.0.0
├── hooks/
│   ├── hooks.json
│   └── scripts/
│       └── redirect-websearch.sh
└── skills/
    └── web-search/
        ├── SKILL.md              # Thin: commands + query intelligence + script delegation
        ├── scripts/
        │   ├── search.sh         # Tavily search
        │   ├── code-search.sh    # Exa code context
        │   └── extract.sh        # Tavily extract
        └── references/
            └── api-reference.md  # Keep as-is for human reference (scripts embed the logic)
```

### SKILL.md Size Reduction

| Section | Current | After |
|---------|---------|-------|
| Commands | ~10 lines | ~10 lines (unchanged) |
| Execution Flow | ~30 lines (full curl logic) | ~15 lines (analyze → call script) |
| api-reference.md dependency | Always loaded (~380 lines) | Rarely loaded (scripts embed logic) |
| **Total context cost** | **~420 lines** | **~25 lines** |

### Migration Strategy

1. Extract current curl/parse logic from api-reference.md into scripts
2. Test scripts standalone with known queries
3. Rewrite SKILL.md to delegate to scripts
4. Verify end-to-end behavior matches current output
5. Bump version to 2.0.0 (breaking: different execution model)

## Scope Expansion: Skill Architecture Principle

This refactoring establishes a principle for docs/skills-guide.md:

> **Execution-heavy skills** (API calls, file processing) should delegate to wrapper scripts.
> SKILL.md handles intent analysis and parameter decisions; scripts handle reliable execution.
> This matches the hook pattern (both use scripts) and reduces context cost.

Skill categories:
- **Instruction-only** (plan-and-lessons, retro): SKILL.md alone — no execution needed
- **Execution-heavy** (web-search, gather-context): SKILL.md + scripts/
- **Hybrid** (skill-creator): SKILL.md with occasional Bash

## Deferred Actions

- [ ] Apply same pattern to other execution-heavy skills if they emerge
- [ ] Consider whether api-reference.md should be kept (human docs) or removed (scripts are the source of truth)
