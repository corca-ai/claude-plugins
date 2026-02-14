# Architecture Patterns

Code-level patterns, hook configuration, and plugin integration conventions
accumulated from retrospectives and implementation sessions.

## Code Patterns

- **Script delegation**: Execution-heavy skills (gather-context) delegate API calls to wrapper scripts. SKILL.md handles intent analysis and parameter decisions; scripts handle env loading, JSON building, curl, and response formatting. This reduces context cost and improves reliability.
- **Hook-based tool redirect**: Use PreToolUse hooks with `permissionDecision: "deny"` to redirect built-in tools to custom skills (e.g., WebSearch → `/gather-context --search`). Enables loose coupling between plugins.
- **3-tier env loading**: See `plugin-dev-cheatsheet.md` § Environment Variables for the pattern and implementation.
- **Safe extraction**: Scripts must avoid `eval` for parsing shell config. Use grep + parameter expansion instead.
- **Local vs marketplace**: Repo-specific automation → `.claude/skills/` (e.g., plugin-deploy). Cross-project utility → `plugins/` marketplace.
- **Deprecated plugin policy**: Set `deprecated: true` in plugin.json → remove entry from marketplace.json. Do NOT keep both with a "deprecated" flag in marketplace — the plugin should simply not be listed. check-consistency.sh detects this as a gap.
- **Sub-agent orchestration via SKILL.md**: For multi-phase skills, SKILL.md acts as a thin orchestrator (sequencer + data router) while reference guides in `references/` hold domain knowledge. Each guide follows: role statement → context → methodology → constraints → output format. When data is already in orchestrator context, inline analysis may outperform sub-agents (avoids summarization loss).
- **Shared skill conventions**: [plugins/cwf/references/skill-conventions.md](../plugins/cwf/references/skill-conventions.md) defines the structural template for all CWF skills (frontmatter → Language → Phases → Rules → References). When 3+ skills repeat the same pattern, extract to shared reference.
- **Skills are session-level, agents are process-level**: Plugin skills (SKILL.md + allowed-tools) are loaded from cache at session start and only available in the main conversation context. Sub-agents spawned via Task tool do NOT inherit skill definitions. Design accordingly: (1) skill-dependent work → main session, (2) skill-independent work → delegate to agents, (3) to apply skill criteria indirectly, include reference docs in the agent prompt.
- **Mention-only handoff execution contract**: `next-session.md` includes an explicit execution contract so path-only mention can be treated as "execute". The contract must define base-branch escape (feature branch creation before implementation edits) and meaningful commit-unit policy.
- **Validation hooks must be fail-visible**: Hooks that validate preconditions must always emit observable output (never silent `exit 0`), respond with allow/warn/deny based on conditions. Silent exit makes hook firing indistinguishable from hook not firing. When a hook chain includes a behavioral step, add an independent deterministic validation step that blocks if it was not done. (Reason: independent defense layers; Dekker: ambiguous protective structures accelerate drift.)

## Hook Configuration

- Project hooks go in `.claude/settings.json` under the `"hooks"` key — NOT `.claude/hooks.json` (which is plugin-only format)
- **Compact recovery**: `SessionStart(compact)` hook reads `cwf-state.yaml` `live` section and injects context after auto-compact. CWF skills update `live` at phase transitions; `check-session.sh --live` validates required fields.
- `type: prompt` hooks work with any hook event and are simpler for context injection (no JSON formatting needed)
- **Hooks and skills are session-start snapshots**: See `plugin-dev-cheatsheet.md` § hooks.json and § Testing for details on cache-based loading and propagation.
- **sync vs async rule of thumb**: If a hook only calls external services (Slack, logging) and doesn't need to modify Claude's behavior → use async. Sync hooks with empty stdout can corrupt conversation history on some event types.
- **System tool matching**: Internal tools (`EnterPlanMode`, `ExitPlanMode`, `AskUserQuestion`) can be matched via `PreToolUse`/`PostToolUse` matchers — no dedicated hook events needed.
- **Async race conditions**: Async hooks that check-then-create state files need atomic locking (e.g., `mkdir`). Multiple async instances of the same hook can run concurrently.
- **SessionEnd hook limitation**: Fires after session ends, so the model cannot be involved. Only `type: "command"` (bash) is available. Tasks requiring model intelligence must happen in Stop hooks or skills instead.
- **Hook output schemas differ by event**: PreToolUse uses `permissionDecision`; PostToolUse uses `{"decision": "block/allow", "reason": "..."}`. Check hook type before writing output format.
- Claude Code hook docs: <https://code.claude.com/docs/en/hooks.md>

## Plugin System

- CWF plugin (`plugins/cwf/`) consolidates all workflow skills (12 skills: setup, update, gather, clarify, plan, impl, retro, refactor, handoff, ship, review, run) and infrastructure hooks (7 groups).
- **Env var backward-compat**: `attention-hook` supports legacy `CLAUDE_ATTENTION_*` alongside `CLAUDE_CORCA_ATTENTION_*`. New plugins should not add backward-compat — use `CLAUDE_CORCA_{PLUGIN}_{SETTING}` only.
