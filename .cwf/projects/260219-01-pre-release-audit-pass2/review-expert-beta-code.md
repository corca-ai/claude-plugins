### Expert Reviewer β: W. Edwards Deming
**Framework Context**: Quality is built into the process by closing the PDCA loop early—prevent recurring gate violations with deterministic contracts (Out of the Crisis, 1986).
#### Concerns (blocking)
- [blocker] Hard-fail refactor gate is still tripped because `refactor-summary.md` either does not exist or lacks the required `## Refactor Summary` heading, so `check-run-gate-artifacts.sh` reports a `HARD_FAIL` every time the stage runs and stops the pipeline from progressing; the recorded violation in `lessons.md:27-31` proves the process is stuck in the “check” stage and can’t move to “act” until the artifact is present. `plugins/cwf/scripts/check-run-gate-artifacts.sh:111-138` enforces the heading contract, so produce the summary file with the heading before any release gating can pass.
#### Suggestions (non-blocking)
- Keep the `plugins/cwf/skills/gather/scripts/__pycache__/notion-to-md.cpython-310.pyc` artifact out of version control (or add it to `.gitignore`) so codebase deep reviews and future runs stop warning about non-source noise and we can trust the statistical signal from clean scans (`plugins/cwf/skills/gather/scripts/__pycache__/notion-to-md.cpython-310.pyc`).
- Before invoking the external CLIs, assert that they are authenticated (e.g., `codex auth status`, `npx @google/gemini-cli auth status`) so the review pipeline fails fast when auth is missing instead of timing out over and over; see the current detection stanza in `plugins/cwf/skills/review/SKILL.md:265-281` for where this guard belongs.
- Either adjust the concept-map claim or the doc text so that `cwf:run` is described as a sequential pipeline, matching the stage loop in `plugins/cwf/skills/run/SKILL.md:116-134`; otherwise we risk repeating the special-cause failure of misunderstanding orchestration expectations every time the skill is used (and the “Agent Orchestration” framing cannot be trusted for continuous improvement).
#### Provenance
- source: REAL_EXECUTION
- tool: claude-task
- expert: W. Edwards Deming
- framework: Systems Quality / PDCA
- grounding: Out of the Crisis (1986)

<!-- AGENT_COMPLETE -->
