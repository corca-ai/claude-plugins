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
- **Agent team review — perspective-based division**: When running parallel agent reviews, divide by perspective (code quality / documentation / tooling research) rather than by module (plugin A / plugin B). Perspective-based division catches systemic cross-cutting issues (e.g., "all scripts missing `set -euo pipefail`") that module-based division would miss.
- **Agent results require spot-checks**: When consolidating agent team findings, verify at least the critical issues against actual source code before incorporating into plans. Agents may report incorrect line numbers or misinterpret code. "Trust but verify" applies to agent collaboration.
- **Tool-first verification for bulk changes**: Before spawning agents for mass file edits, run the relevant lint/validation tool first (e.g., `npx markdownlint-cli2` for MD040). A single tool invocation can confirm whether changes are actually needed, avoiding wasted agent turns. Discovered in S2: plan reported 93 bare fences, but `markdownlint-cli2` showed 0 violations.
- **Full-codebase grep on rename/migration**: When renaming variables, functions, or env vars, always `grep -r OLD_NAME` across the entire codebase — not just the files listed in the plan. README examples, config snippets, and docs may reference the old name outside the core implementation files.

## Documentation Intent

- README per-plugin install/update commands are intentionally repeated for copy-paste UX — users jump directly to a plugin section. The `marketplace add` line is omitted (only needed once); each plugin has a one-line install + update.

## Conventions

- Documentation language: English for docs/ and default top-level docs; Korean versions live in README.ko.md and AI_NATIVE_PRODUCT_TEAM.ko.md
- Lessons and retro: written in the user's language
- Plugin structure: `plugins/{name}/.claude-plugin/plugin.json` + `plugins/{name}/skills/{name}/SKILL.md`
- Installed marketplace plugins live at `~/.claude/plugins/marketplaces/`. To find a specific skill file, use Glob (e.g. `**/skill-name**/SKILL.md`), not Explore agent.

## Architecture Patterns

- **Script delegation**: Execution-heavy skills (gather-context) delegate API calls to wrapper scripts. SKILL.md handles intent analysis and parameter decisions; scripts handle env loading, JSON building, curl, and response formatting. This reduces context cost and improves reliability.
- **Hook-based tool redirect**: Use PreToolUse hooks with `permissionDecision: "deny"` to redirect built-in tools to custom skills (e.g., WebSearch → `/gather-context --search`). Enables loose coupling between plugins.
- **3-tier env loading**: Shell environment → `~/.claude/.env` → grep shell profiles (fallback). All credential-loading scripts must use this pattern.
- **Local vs marketplace**: Repo-specific automation → `.claude/skills/` (e.g., plugin-deploy). Cross-project utility → `plugins/` marketplace.
- **Deprecated plugin policy**: Set `deprecated: true` in plugin.json → remove entry from marketplace.json. Do NOT keep both with a "deprecated" flag in marketplace — the plugin should simply not be listed. check-consistency.sh detects this as a gap.
- **Sub-agent orchestration via SKILL.md**: For multi-phase skills, SKILL.md acts as a thin orchestrator (sequencer + data router) while reference guides in `references/` hold domain knowledge. Each guide follows: role statement → context → methodology → constraints → output format. Matured in refactor (multi-mode routing + parallel sub-agents).
- **Defensive cross-plugin integration**: When plugin A references plugin B's output, A must work normally when B is not installed. Use directory/file existence checks as the gate (e.g., retro checks for `prompt-logs/sessions/` before attempting to link prompt-logger output).
- **Safe extraction patterns**: Scripts must avoid `eval` for parsing shell config. Use grep + parameter expansion instead. See [plugin-dev-cheatsheet.md](plugin-dev-cheatsheet.md) § Environment Variables for the 3-tier loading pattern and § Script Guidelines for `set -euo pipefail`, `curl` wrapping, and `&&` chain safety.
- **Skills are session-level, agents are process-level**: Plugin skills (SKILL.md + allowed-tools) are loaded from cache at session start and only available in the main conversation context. Sub-agents spawned via Task tool do NOT inherit skill definitions. When designing agent teams: (1) skill-dependent work → run in the main session, (2) skill-independent work (file reading, analysis, research) → delegate to agents, (3) to apply skill criteria indirectly, include the skill's reference docs in the agent prompt.

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

- Contains skills (clarify, retro, refactor, gather-context), hooks (attention-hook, plan-and-lessons, smart-read, prompt-logger), and supporting docs. Deprecated plugins (deep-clarify, interview, web-search, suggest-tidyings) were removed in v2.0.0; source available in commit `238f82d`.
- `attention-hook` v2.2.0: Slack notifications with threading when Claude Code is waiting — idle alerts, AskUserQuestion prompts, plan mode approval, and periodic heartbeat status updates. Env vars follow `CLAUDE_CORCA_ATTENTION_*` naming with backward-compat fallback to legacy `CLAUDE_ATTENTION_*` names.
- `clarify` v2.0.1: unified requirement clarification — merges clarify v1, deep-clarify, and interview. Default mode: research-first (gather-context integration with fallback) → tier classification → advisory → persistent questioning. `--light` mode: direct Q&A. 4 reference guides (aggregation, advisory, research, questioning) with SKILL.md as thin orchestrator (309 lines). Defensive gather-context detection via system prompt inspection.
- `retro` v2.0.2: Adaptive retrospective — light by default (Sections 1-4 + 7), `--deep` for full 7 sections. Agent judges session weight to select mode. Section 3 "Waste Reduction" now includes 5 Whys root cause drill-down (classify waste as one-off / knowledge gap / process gap / structural constraint). CDM guide adds "intent-result gaps" as 5th critical decision criterion. Persist step uses JTBD lens ("What recurring situation will this learning prevent?") for right-placement of root causes. Section 7 scans installed skills before suggesting external discovery.
- `smart-read` v1.0.1 hook: PreToolUse → Read, enforces file-size-aware reading (warn >500 lines, deny >2000 lines)
- `gather-context` v2.0.2: Unified information acquisition — absorbs web-search. Three modes: URL auto-detect (Google Docs/Slack/Notion/GitHub/generic), `--search` (Tavily/Exa), `--local` (codebase exploration). Includes PreToolUse hook redirecting WebSearch → `/gather-context --search`. Search scripts (search.sh, code-search.sh, extract.sh) delegated via script delegation pattern.
- `prompt-logger` v1.3.1 hook: Stop + SessionEnd → incremental transcript-to-markdown logger. Uses `/tmp/` state files (offset, turn_num, out_file, team_info) with session hash for incremental processing. Atomic `mkdir` lock prevents race between concurrent Stop/SessionEnd hooks. SessionEnd auto-commits ALL session log `.md` files in the sessions directory (`--no-verify`, only if no pre-existing staged changes), ensuring sub-agent logs from team runs are included.
  - **Filename format**: `{yymmdd}-{hhmm}-{hash}.md` — session start time included for chronological sorting. Time resolved from first transcript timestamp, cached in state.
  - **Team detection**: Teammate identified via transcript JSONL `teamName`/`agentName` fields (first line). Leader identified via config `leadSessionId` match. Team info shown as `Team: {name} ({role})` in session header.
  - **Claude Code agent team internals**: `agentId` (`{name}@{team}`) ≠ `session_id`. Teammate `sessionId` not stored in config. Transcript is the reliable source for teammate identification; config `leadSessionId` for leader.
  - **Early-exit trap**: When Stop and SessionEnd share a script, Stop runs first and updates offset. SessionEnd finds no new lines → hits early-exit before reaching auto-commit. Fix: duplicate the auto-commit logic in the early-exit branch.
  - **Timezone**: Claude Code transcript timestamps are UTC (ISO 8601 with `Z` suffix). Must convert to local time for display using epoch-based conversion.
- `plan-and-lessons` v1.3.1: EnterPlanMode hook that injects the Plan & Lessons Protocol — creates `prompt-logs/` session directories with plan.md and lessons.md.
- `markdown-guard` v1.0.0: PostToolUse hook (Write|Edit matcher) that validates markdown files via `npx markdownlint-cli2`. Blocks on violations with lint output, skips non-.md files and `prompt-logs/` paths. Uses `{"decision": "block", "reason": "..."}` output format (PostToolUse schema differs from PreToolUse).
- `refactor` v1.1.2: Multi-mode code and skill review — 5 modes routed by args: quick scan (no args, runs quick-scan.sh), `--code` (commit-based tidying via parallel sub-agents with tidying-guide.md), `--skill <name>` (deep review against review-criteria.md), `--skill --holistic` (cross-plugin analysis via holistic-criteria.md), `--docs` (documentation consistency via docs-criteria.md, including document design quality checks). Absorbs suggest-tidyings' commit analysis workflow. Promotes local refactor-skill to marketplace plugin.
