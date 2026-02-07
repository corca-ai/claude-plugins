# Project Context

Accumulated context from retrospectives. Each session's retro may add to this document.

## Project

- corca-plugins is a Claude Code plugin marketplace for "AI Native Product Teams"
- Plan & Lessons Protocol creates `prompt-logs/{YYMMDD}-{NN}-{title}/` per session with plan.md, lessons.md, and optionally retro.md. Date via `date +%y%m%d`; NN auto-incremented by scanning existing dirs.

## Design Principles

- SKILL.md tells Claude "what to do", not "how to analyze" — trust Claude's capabilities
- CLAUDE.md is for Claude's behavior, not user instructions
- Progressive disclosure: CLAUDE.md is concise, details live in docs/
- Dogfooding: new tools are tested in the session that creates them

## Process Heuristics

- **Meta-rule check**: When introducing a new rule, verify that the change itself is the first application of that rule (e.g., adding "always bump version" should include bumping the version of the file being changed)
- **Structural fix over instruction fix**: When a behavioral error recurs, prefer removing the structural asymmetry that caused it over adding more instructions. Adding rules has diminishing returns; changing structure is more durable.

## Documentation Intent

- README per-plugin install/update commands are intentionally repeated for copy-paste UX — users jump directly to a plugin section. The `marketplace add` line is omitted (only needed once); each plugin has a one-line install + update.

## Conventions

- Documentation language: English for docs/ and default top-level docs; Korean versions live in README.ko.md and AI_NATIVE_PRODUCT_TEAM.ko.md
- Lessons and retro: written in the user's language
- Plugin structure: `plugins/{name}/.claude-plugin/plugin.json` + `plugins/{name}/skills/{name}/SKILL.md`
- Installed marketplace plugins live at `~/.claude/plugins/marketplaces/`. To find a specific skill file, use Glob (e.g. `**/skill-name**/SKILL.md`), not Explore agent.

## Architecture Patterns

- **Script delegation**: Execution-heavy skills (web-search, gather-context) delegate API calls to wrapper scripts. SKILL.md handles intent analysis and parameter decisions; scripts handle env loading, JSON building, curl, and response formatting. This reduces context cost and improves reliability.
- **Hook-based tool redirect**: Use PreToolUse hooks with `permissionDecision: "deny"` to redirect built-in tools to custom skills (e.g., WebSearch → `/web-search`). Enables loose coupling between plugins.
- **3-tier env loading**: Shell environment → `~/.claude/.env` → grep shell profiles (fallback). All credential-loading scripts must use this pattern.
- **Local vs marketplace**: Repo-specific automation → `.claude/skills/` (e.g., plugin-deploy). Cross-project utility → `plugins/` marketplace.
- **Sub-agent orchestration via SKILL.md**: For multi-phase skills, SKILL.md acts as a thin orchestrator (sequencer + data router) while reference guides in `references/` hold domain knowledge. Each guide follows: role statement → context → methodology → constraints → output format. Established by suggest-tidyings, extended by deep-clarify, matured in refactor (multi-mode routing + parallel sub-agents).
- **Defensive cross-plugin integration**: When plugin A references plugin B's output, A must work normally when B is not installed. Use directory/file existence checks as the gate (e.g., retro checks for `prompt-logs/sessions/` before attempting to link prompt-logger output).

## Hook Configuration

- Project hooks go in `.claude/settings.json` under the `"hooks"` key — NOT `.claude/hooks.json` (which is plugin-only format)
- EnterPlanMode hook is now provided by the `plan-and-lessons` plugin (no longer in `.claude/settings.json`)
- `type: prompt` hooks work with any hook event and are simpler for context injection (no JSON formatting needed)
- Hooks are **snapshots at session start** — no hot-reload. Requires new session or `/hooks` review to pick up changes.
- **Skill loading is cache-based**: Skills (SKILL.md content + allowed-tools) are loaded from `~/.claude/plugins/cache/{marketplace}/{plugin}/{version}/`, not from the source directory. Source modifications require `claude plugin update` or `scripts/update-all.sh` to propagate to the cache. Both hooks and skills are effectively session-start snapshots tied to the cache state.
- **sync vs async rule of thumb**: If a hook only calls external services (Slack, logging) and doesn't need to modify Claude's behavior → use async. Sync hooks with empty stdout can corrupt conversation history on some event types.
- **System tool matching**: Internal tools (`EnterPlanMode`, `ExitPlanMode`, `AskUserQuestion`) can be matched via `PreToolUse`/`PostToolUse` matchers — no dedicated hook events needed.
- **Async race conditions**: Async hooks that check-then-create state files need atomic locking (e.g., `mkdir`). Multiple async instances of the same hook can run concurrently.
- **SessionEnd hook limitation**: Fires after session ends, so the model cannot be involved. Only `type: "command"` (bash) is available. Tasks requiring model intelligence (e.g., naming, classification) must happen in Stop hooks or skills instead.
- Claude Code hook docs: https://code.claude.com/docs/en/hooks.md

## Plugins

- Contains skills (clarify, retro, refactor, gather-context), deprecated skills (deep-clarify, interview, web-search, suggest-tidyings), hooks (attention-hook, plan-and-lessons, smart-read, prompt-logger), and supporting docs
- `clarify` v2: unified requirement clarification — merges clarify v1, deep-clarify, and interview. Default mode: research-first (gather-context integration with fallback) → tier classification → advisory → persistent questioning. `--light` mode: direct Q&A. 4 reference guides (aggregation, advisory, research, questioning) with SKILL.md as thin orchestrator (309 lines). Defensive gather-context detection via system prompt inspection.
- `deep-clarify` (deprecated): first multi-sub-agent skill — 4 sub-agents (codebase researcher, best practice researcher, Advisor α, Advisor β) orchestrated in a 6-phase workflow. Functionality absorbed into clarify v2.
- `retro` v2.0.0: Adaptive retrospective — light by default (Sections 1-4 + 7), `--deep` for full 7 sections. Agent judges session weight to select mode. Section 3 renamed "Prompting Habits" → "Waste Reduction" (broader lens: wasted turns, over-engineering, missed shortcuts, context waste, communication waste). Section 7 now scans installed skills (`Glob` on `~/.claude/plugins/` and `.claude/skills/`) before suggesting external discovery. CDM (Section 4) unconditional; Expert Lens (Section 5) and Learning Resources (Section 6) deep-only.
- `smart-read` hook: PreToolUse → Read, enforces file-size-aware reading (warn >500 lines, deny >2000 lines)
- `gather-context` v2.0.0: Unified information acquisition — absorbs web-search. Three modes: URL auto-detect (Google Docs/Slack/Notion/GitHub/generic), `--search` (Tavily/Exa), `--local` (codebase exploration). Includes PreToolUse hook redirecting WebSearch → `/gather-context --search`. Search scripts (search.sh, code-search.sh, extract.sh) delegated via script delegation pattern.
- `web-search` (deprecated): PreToolUse hook redirected WebSearch → `/web-search`. Functionality absorbed into gather-context v2.
- `prompt-logger` hook: Stop + SessionEnd → incremental transcript-to-markdown logger. Uses `/tmp/` state files (offset, turn_num) with session hash for incremental processing. Atomic `mkdir` lock prevents race between concurrent Stop/SessionEnd hooks. SessionEnd auto-commits the session log file (`--no-verify`, only if no pre-existing staged changes) to avoid untracked leftovers after session close.
  - **Early-exit trap**: When Stop and SessionEnd share a script, Stop runs first and updates offset. SessionEnd finds no new lines → hits early-exit before reaching auto-commit. Fix: duplicate the auto-commit logic in the early-exit branch.
  - **Timezone**: Claude Code transcript timestamps are UTC (ISO 8601 with `Z` suffix). Must convert to local time for display using epoch-based conversion.
- `refactor` v1.0.0: Multi-mode code and skill review — 5 modes routed by args: quick scan (no args, runs quick-scan.sh), `--code` (commit-based tidying via parallel sub-agents with tidying-guide.md), `--skill <name>` (deep review against review-criteria.md), `--skill --holistic` (cross-plugin analysis via holistic-criteria.md), `--docs` (documentation consistency via docs-criteria.md). Absorbs suggest-tidyings' commit analysis workflow. Promotes local refactor-skill to marketplace plugin.
