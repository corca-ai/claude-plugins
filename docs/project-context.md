# Project Context

Project and organizational facts accumulated from retrospectives.

## Project

- corca-plugins is a Claude Code plugin marketplace for "AI Native Product Teams"
- Plan & Lessons Protocol creates `prompt-logs/{YYMMDD}-{NN}-{title}/` per session with plan.md, lessons.md, and optionally retro.md. Sequence is allocated by `scripts/next-prompt-dir.sh` (date-scoped `YYMMDD-NN-*`), so numbering resets to `01` each day.

## Design Principles

- SKILL.md tells Claude "what to do", not "how to analyze" — trust Claude's capabilities
- CLAUDE.md is for Claude's behavior, not user instructions
- Progressive disclosure: CLAUDE.md is a concise index, details live in specialized docs/
- Dogfooding: new tools are tested in the session that creates them
- Deterministic validation over behavioral instruction: When preventing recurring mistakes, prefer scripts/checks that always run and produce pass/fail over adding more rules to CLAUDE.md. Behavioral instructions degrade; deterministic checks scale. Example: `check-session.sh` + `session_defaults` catches missing artifacts reliably.

## Process Heuristics

- **Meta-rule check**: When introducing a new rule, verify that the change itself is the first application of that rule (e.g., adding "always bump version" should include bumping the version of the file being changed)
- **Structural fix over instruction fix**: When a behavioral error recurs, prefer removing the structural asymmetry that caused it over adding more instructions. Adding rules has diminishing returns; changing structure is more durable.
- **Agent team review — perspective-based division**: When running parallel agent reviews, divide by perspective (code quality / documentation / tooling research) rather than by module. Perspective-based division catches systemic cross-cutting issues that module-based division would miss.
- **Agent results require spot-checks**: When consolidating agent team findings, verify at least the critical issues against actual source code before incorporating into plans. Agents may report incorrect line numbers or misinterpret code.
- **Tool-first verification for bulk changes**: Before spawning agents for mass file edits, run the relevant lint/validation tool first. A single tool invocation can confirm whether changes are actually needed.
- **Full-codebase grep on rename/migration**: When renaming variables, functions, or env vars, always `grep -r OLD_NAME` across the entire codebase — not just the files listed in the plan.
- **Canonical template over recent example**: When producing templated artifacts, always read the canonical template definition first — not the most recent instance. After a convention change, previous instances become stale.
- **Feedback loop existence over case count**: When a structural failure is discovered and no feedback loop exists to detect future occurrences, install the loop immediately — don't wait for more cases. (Meadows: "Drift to Low Performance"; Woods: graceful extensibility.)
- **Reporting: minimize reader's external knowledge dependency**: When reporting quantitative results, provide enough context (denominator, ratio, trend) for the reader to assess significance. "7 rules disabled" → "7/55 rules disabled (13%)".
- **Reference guide separation by consumer count**: When a reference guide has 1 consumer, keep it specialized. When N consumers need the same pattern, create a new shared guide. "Separate now, unify when stable."
- **Plan document ≠ current state**: master-plan.md and other plan documents are plans, not execution records. Always check cwf-state.yaml sessions list for actual completion status.
- **Parallel sub-agent review after large changes**: After large multi-file changes, consider running parallel sub-agent reviews before committing — give each agent a different review perspective (content integrity, missed opportunities, structural analysis).
- **Delegation criterion: exploration cost**: When a task requires understanding existing code structure before modifying it, delegate to a sub-agent or codex exec. When creating new files or making small edits with known context, execute directly. Decide before starting exploration — switching mid-exploration wastes the exploration context.

## Directory Classification Criteria

Document placement uses **lifecycle as primary axis**, consumer count as secondary:

| Directory | Lifecycle | Change Trigger | Examples |
|-----------|-----------|----------------|----------|
| `docs/` | Project-scope (permanent) | Project conventions change | plugin-dev-cheatsheet.md, architecture-patterns.md |
| `references/` | Project-scope (permanent) | External framework updates | essence-of-software/distillation.md (source texts) |
| `prompt-logs/{session}/` | Session-scope (ephemeral) | Session ends; absorbed into deliverables | plan.md, retro.md, concept-distillation.md |

Key distinction: `references/` holds **external framework source texts**, not analysis outputs. Discovery of session artifacts is via `cwf-state.yaml` session history.

## Conventions

- Installed marketplace plugins live at `~/.claude/plugins/marketplaces/`. To find a specific skill file, use Glob (e.g. `**/skill-name**/SKILL.md`), not Explore agent.
