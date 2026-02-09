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
- Deterministic validation over behavioral instruction: When preventing recurring mistakes, prefer scripts/checks that always run and produce pass/fail over adding more rules to CLAUDE.md. Behavioral instructions degrade (unread, misinterpreted, diminishing returns as rules accumulate); deterministic checks scale. Example: `check-session.sh` + `session_defaults` catches missing artifacts reliably, whereas "remember to create next-session.md" failed across S8→S10.

## Process Heuristics

- **Meta-rule check**: When introducing a new rule, verify that the change itself is the first application of that rule (e.g., adding "always bump version" should include bumping the version of the file being changed)
- **Structural fix over instruction fix**: When a behavioral error recurs, prefer removing the structural asymmetry that caused it over adding more instructions. Adding rules has diminishing returns; changing structure is more durable.
- **Agent team review — perspective-based division**: When running parallel agent reviews, divide by perspective (code quality / documentation / tooling research) rather than by module (plugin A / plugin B). Perspective-based division catches systemic cross-cutting issues (e.g., "all scripts missing `set -euo pipefail`") that module-based division would miss.
- **Agent results require spot-checks**: When consolidating agent team findings, verify at least the critical issues against actual source code before incorporating into plans. Agents may report incorrect line numbers or misinterpret code. "Trust but verify" applies to agent collaboration.
- **Tool-first verification for bulk changes**: Before spawning agents for mass file edits, run the relevant lint/validation tool first (e.g., `npx markdownlint-cli2` for MD040). A single tool invocation can confirm whether changes are actually needed, avoiding wasted agent turns. Discovered in S2: plan reported 93 bare fences, but `markdownlint-cli2` showed 0 violations.
- **Full-codebase grep on rename/migration**: When renaming variables, functions, or env vars, always `grep -r OLD_NAME` across the entire codebase — not just the files listed in the plan. README examples, config snippets, and docs may reference the old name outside the core implementation files.
- **Canonical template over recent example**: When producing templated artifacts (handoffs, plans, session docs), always read the canonical template definition first — not the most recent instance. After a convention change, previous instances become stale. Recent examples are references, not templates.
- **Feedback loop existence over case count**: When a structural failure is discovered and no feedback loop exists to detect future occurrences, install the loop immediately — don't wait for more cases. "Rule of three" applies to statistical sampling, not to feedback loop absence. Without a loop, you can't even detect cases 2 and 3. (Meadows: "Drift to Low Performance" archetype; Woods: graceful extensibility doesn't wait for recurring known failures.)
- **Reporting: minimize reader's external knowledge dependency**: When reporting quantitative results, always provide enough context (denominator, ratio, trend) for the reader to assess significance without looking up additional information. "7 rules disabled" → "7/55 rules disabled (13%)". See `skill-conventions.md` Reporting Principle.
- **Separation of concerns: WHAT vs HOW**: plan.md carries WHAT (specs, steps, files), phase handoff carries HOW (protocols, rules, must-read references, "don't do" lists). When adding new information transfer needs, find the tool whose concern already matches, rather than appending sections to the nearest existing document.
- **Reference guide separation by consumer count**: When a reference guide has 1 consumer (specialized), keep it specialized. When N consumers need the same pattern, create a new shared guide rather than force-generalizing the specialized one. "Separate now, unify when stable" is safer than "unify now, separate on failure."
- **Count-agnostic logic design**: When designing synthesis/verdict logic that may need to support more inputs in the future, use count-independent conditions (any/all/none) and annotate the design intent (e.g., "reviewer-count-agnostic"). This eliminates modification when expanding.

## Directory Classification Criteria

Document placement uses **lifecycle as primary axis**, consumer count as secondary:

| Directory | Lifecycle | Change Trigger | Examples |
|-----------|-----------|----------------|----------|
| `docs/` | Project-scope (permanent) | Project conventions change | plugin-dev-cheatsheet.md, project-context.md |
| `references/` | Project-scope (permanent) | External framework updates | essence-of-software/distillation.md (source texts) |
| `prompt-logs/{session}/` | Session-scope (ephemeral) | Session ends; absorbed into deliverables | plan.md, retro.md, concept-distillation.md |

Key distinction: `references/` holds **external framework source texts**, not analysis outputs that apply those frameworks. An analysis output (e.g., concept distillation) is a session artifact in `prompt-logs/` — its lifecycle ends when its deliverable (e.g., README) absorbs it. Discovery of session artifacts is via `cwf-state.yaml` session history.

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
- **Sub-agent orchestration via SKILL.md**: For multi-phase skills, SKILL.md acts as a thin orchestrator (sequencer + data router) while reference guides in `references/` hold domain knowledge. Each guide follows: role statement → context → methodology → constraints → output format. Matured in refactor (multi-mode routing + parallel sub-agents). When data is already in orchestrator context, inline analysis may outperform sub-agents (avoids summarization loss).
- **Shared skill conventions**: `references/skill-conventions.md` defines the structural template for all CWF skills (frontmatter → Language → Phases → Rules → References). When 3+ skills repeat the same pattern, extract to shared reference. `holistic-criteria.md` Section 1c automates detection of extraction opportunities.
- **Defensive cross-plugin integration**: When plugin A references plugin B's output, A must work normally when B is not installed. Use directory/file existence checks as the gate (e.g., retro checks for `prompt-logs/sessions/` before attempting to link prompt-logger output).
- **Safe extraction patterns**: Scripts must avoid `eval` for parsing shell config. Use grep + parameter expansion instead. See [plugin-dev-cheatsheet.md](plugin-dev-cheatsheet.md) § Environment Variables for the 3-tier loading pattern and § Script Guidelines for `set -euo pipefail`, `curl` wrapping, and `&&` chain safety.
- **Hand-rolled YAML parsers need section boundary guards**: When parsing cwf-state.yaml or similar multi-section YAML with `while read` loops, always add a break condition for top-level keys (`^[a-z#]`). Without this, the last entry in a section is vulnerable to field overwrite by identically-named keys in subsequent sections (e.g., `sessions[last].dir` overwritten by `live.dir: ""`). Also: in bash `[[ =~ ]]`, `"?` makes `?` literal (quoted), not a regex quantifier — use `\"?` for optional literal-quote matching.
- **Skills are session-level, agents are process-level**: Plugin skills (SKILL.md + allowed-tools) are loaded from cache at session start and only available in the main conversation context. Sub-agents spawned via Task tool do NOT inherit skill definitions. When designing agent teams: (1) skill-dependent work → run in the main session, (2) skill-independent work (file reading, analysis, research) → delegate to agents, (3) to apply skill criteria indirectly, include the skill's reference docs in the agent prompt.
- **Agent autonomy requires boundary awareness**: When delegating more work to agents autonomously, the agent's tools (criteria, checklists, guides) must be self-aware of their own validity. A stale checklist followed blindly is worse than no checklist. Provenance metadata (system state at creation time) enables tools to detect when they may be operating outside their design envelope. (Woods: graceful extensibility; Meadows: leverage point #6 — information flow.)
- **Validation hooks must be fail-visible**: Hooks that validate preconditions (gate/verification role) must follow the `smart-read.sh` 3-tier pattern: always emit observable output (never silent `exit 0`), respond with allow/warn/deny based on conditions. Silent exit makes hook firing indistinguishable from hook not firing, destroying debuggability. When a hook chain includes a behavioral step (agent must do X), add an independent deterministic validation step that blocks if X was not done. (Reason: independent defense layers; Dekker: ambiguous protective structures accelerate drift.)

## Hook Configuration

- Project hooks go in `.claude/settings.json` under the `"hooks"` key — NOT `.claude/hooks.json` (which is plugin-only format)
- **Compact recovery**: `SessionStart(compact)` hook reads `cwf-state.yaml` `live` section and injects context after auto-compact. CWF skills update `live` at phase transitions; `check-session.sh --live` validates required fields.
- `type: prompt` hooks work with any hook event and are simpler for context injection (no JSON formatting needed)
- Hooks are **snapshots at session start** — no hot-reload. Requires new session or `/hooks` review to pick up changes.
- **Skill loading is cache-based**: Skills (SKILL.md content + allowed-tools) are loaded from `~/.claude/plugins/cache/{marketplace}/{plugin}/{version}/`, not from the source directory. Source modifications require `claude plugin update` or `scripts/update-all.sh` to propagate to the cache. Both hooks and skills are effectively session-start snapshots tied to the cache state.
- **sync vs async rule of thumb**: If a hook only calls external services (Slack, logging) and doesn't need to modify Claude's behavior → use async. Sync hooks with empty stdout can corrupt conversation history on some event types.
- **System tool matching**: Internal tools (`EnterPlanMode`, `ExitPlanMode`, `AskUserQuestion`) can be matched via `PreToolUse`/`PostToolUse` matchers — no dedicated hook events needed.
- **Async race conditions**: Async hooks that check-then-create state files need atomic locking (e.g., `mkdir`). Multiple async instances of the same hook can run concurrently.
- **SessionEnd hook limitation**: Fires after session ends, so the model cannot be involved. Only `type: "command"` (bash) is available. Tasks requiring model intelligence (e.g., naming, classification) must happen in Stop hooks or skills instead.
- Claude Code hook docs: https://code.claude.com/docs/en/hooks.md

## Plugins

- CWF plugin (`plugins/cwf/`) consolidates all workflow skills (9 skills: setup, update, gather, clarify, plan, impl, retro, refactor, handoff) and infrastructure hooks (7 groups). 10th skill (review) pending migration from `plugins/review/`.
- Legacy marketplace plugins (clarify, retro, refactor, gather-context, attention-hook, plan-and-lessons, smart-read, prompt-logger, markdown-guard) still exist but are deprecated in favor of cwf. Previous deprecated plugins (deep-clarify, interview, web-search, suggest-tidyings) removed in v2.0.0; source in commit `238f82d`.
- **Hook output schemas differ by event**: PreToolUse uses `permissionDecision`; PostToolUse uses `{"decision": "block/allow", "reason": "..."}`. Check hook type before writing output format.
- **Env var backward-compat**: `attention-hook` supports legacy `CLAUDE_ATTENTION_*` alongside `CLAUDE_CORCA_ATTENTION_*`. New plugins should not add backward-compat — use `CLAUDE_CORCA_{PLUGIN}_{SETTING}` only.
- **prompt-logger internals**: `/tmp/` state files with session hash for incremental processing. Atomic `mkdir` lock prevents Stop/SessionEnd race. When shared scripts short-circuit on no-new-lines, auto-commit logic must be duplicated in early-exit branch. Transcript timestamps are UTC — convert to local via epoch.
- **Retro persist criterion**: JTBD lens ("What recurring situation will this learning prevent?") determines where a finding belongs (CLAUDE.md / project-context.md / cwf-state.yaml / lessons only).
- **Plan document ≠ current state**: master-plan.md and other plan documents are plans, not execution records. Always check cwf-state.yaml sessions list for actual completion status. Plan documents may have stale status markers.

## Current Project Phase

CWF v3 migration (S0-S14) on `marketplace-v3` branch. This section is temporal — update or remove when the migration completes.

- `cwf-state.yaml` is the SSOT for project state (sessions, workflow stage, tools, hooks)
- After completing any session tracked in cwf-state.yaml, update the session entry
- When starting a new session, read cwf-state.yaml to determine current state
- For plugin changes: use `/plugin-deploy` for version checks, marketplace sync, README updates
- After committing plugin changes on **main branch**: run `bash scripts/update-all.sh`
- Skip `update-all.sh` on feature branches (pulls from default branch only)
- When a custom skill overlaps with a built-in tool, prefer the custom skill. The CWF plugin enforces this via PreToolUse hook (blocks WebSearch, redirects to `cwf:gather --search`). For other overlaps (e.g., `cwf:gather` vs WebFetch), prefer the custom skill manually.
- When creating new skills or automation tools, first evaluate: marketplace plugin (`plugins/`, general-purpose) vs local skill (`.claude/skills/`, repo-specific). Prefer local skill unless the tool has clear cross-project utility.
- After large multi-file changes, consider running parallel sub-agent reviews before committing — give each agent a different review perspective (content integrity, missed opportunities, structural analysis) along with session lessons/retro as context.
