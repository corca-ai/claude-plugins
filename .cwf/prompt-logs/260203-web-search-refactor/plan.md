# Plan: web-search Skill Refactoring — Script Delegation Pattern

Based on: `prompt-logs/260203-smart-read-hook/plan-web-search-refactor.md`

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

## Implementation Steps

- [x] Create prompt-logs with plan.md and lessons.md
- [x] Create `search.sh` — Tavily search wrapper
- [x] Create `code-search.sh` — Exa code context wrapper
- [x] Create `extract.sh` — Tavily extract wrapper
- [x] Rewrite `SKILL.md` — thin delegation layer
- [x] Bump `plugin.json` to v2.0.0
- [x] Update `docs/skills-guide.md` — add execution-heavy skill principle
- [x] Update `README.md` — adjust web-search section
- [x] Test scripts standalone
- [x] Run /retro, commit, push

## Deferred Actions

- [ ] Apply same pattern to other execution-heavy skills if they emerge
- [ ] Consider whether api-reference.md should be kept or removed
- [x] Apply 3-tier env loading pattern to gather-context scripts (slack-api.mjs — only file with credential loading)
