I now have a comprehensive understanding of the full diff. Let me produce the architecture review.

## Architecture Review

### Concerns (blocking)

- **[A1]** **Retro skill's extracted gate checklist may silently lose enforceability.** The refactoring in `retro/SKILL.md` replaces 19 inline rules with 6 summary rules (Rule 5 now says "Use the deterministic gate checklist in `retro-gates-checklist.md`"), but the new reference file (`retro-gates-checklist.md`) is a passive document that no script or gate validates. The original inline rules were at least co-located with agent execution context and could not be missed. By moving them to a reference that the agent "should read," enforcement degrades to a reading-compliance obligation with no tooling backstop. If a future refactor removes or renames the reference path, the SKILL becomes silently under-specified. Consider adding a deterministic pre-check (or extending `check-run-gate-artifacts.sh`) that validates retro artifacts against the checklist's criteria, or at minimum add a mandatory `Read` step in the SKILL that fails the workflow when the reference is missing.
  Severity: moderate

- **[A2]** **Provenance verification in `refactor/SKILL.md` is inform-only with no workflow consequence.** The new provenance sidecar section (lines 35-49 and repeated at Steps 3, 2, 1.5 in the three modes) instructs agents to run `provenance-check.sh --level inform` and "continue but prepend a Provenance Warning." This warn-and-continue pattern means stale criteria can silently shape review outcomes without any gate blocking the output. The concept-map Section 1.6 (Provenance) says "significant changes are flagged before proceeding," but the SKILL never defines "significant" or offers a threshold. The result is that the Provenance concept is claimed but functionally toothless — agents will always continue regardless of delta magnitude. Define a concrete staleness threshold (e.g., skill-count delta > N) where the workflow must stop or escalate, or the concept claim is unfulfilled.
  Severity: moderate

### Suggestions (non-blocking)

- **[S1]** **Run-stage provenance table format is fragile for Markdown parsing.** The `run-stage-provenance.md` uses a pipe-delimited Markdown table that is easy to corrupt with unescaped pipes in artifact paths or args. Consider using YAML or a structured format (`run-stage-provenance.yaml`) that scripts can parse reliably, especially given the provenance row is appended via `printf` in a bash heredoc context where quoting is error-prone.

- **[S2]** **Handoff's missing-entry branch creates a new interactive gate that may not compose well with `cwf:run` auto-mode.** Phase 4.1 of `handoff/SKILL.md` now requires AskUserQuestion when no session entry exists. If handoff is invoked as part of a `cwf:run` automated pipeline (which runs stages sequentially without user presence), this gate will block indefinitely. Consider adding an `--auto` / `--create-if-missing` flag or documenting that the `run` orchestrator must pre-create the session entry before invoking handoff.

- **[S3]** **The `explore-worktrees` flow in `run/SKILL.md` uses `git branch -D` and `git worktree remove --force` without user confirmation.** This contradicts the AGENTS.md invariant "Never delete user-created files without explicit confirmation. Prefer `mv` over `rm`." While worktrees are pipeline-created, the branches may contain work-in-progress from sub-agents. The cleanup should either ask the user or at minimum check `git stash` / `git status --porcelain` before force-removing, which the diff partially does but only as a pre-check without actually halting on dirty state.

- **[S4]** **Plan discovery ranking in `impl/SKILL.md` introduces four priority tiers but no deterministic script to execute them.** The ranking (live-state pin → metadata timestamp → filesystem mtime → directory name) is described in prose, which means each agent invocation may implement the ranking differently. Extracting this into a helper script (e.g., `resolve-plan.sh`) would make the selection auditable, testable, and consistent across sessions.

- **[S5]** **Concept-map update is incomplete for the new hitl row.** The `hitl` row marks Decision Point and Handoff, but the refactored HITL skill now also explicitly composes Provenance-like behavior (intent-resync gate tracking with timestamped lifecycle state). If this is intentional non-inclusion, document it in the map's reading notes; otherwise, evaluate whether `hitl` should also claim Provenance.

- **[S6]** **Gather's Task output contract asks the sub-agent to self-write output AND end with `<!-- AGENT_COMPLETE -->`.** This is a good sentinel pattern but the gather SKILL specifies `subagent_type: general-purpose` while giving the agent a `Write` instruction. Since the Task tool's general-purpose type has Write access, this works, but it creates an implicit dependency on the agent type having Write. Document this requirement explicitly in the contract or validate the sentinel from the orchestrator side as well.

### Behavioral Criteria Assessment

- [x] **Concept-map alignment**: All changed skills have their concept obligations addressed or improved (hitl added to map, provenance enforcement added to refactor, Expert Advisor synthesis added to retro, Decision Point metadata expanded in plan, Agent Orchestration provenance added to run).
- [x] **Progressive disclosure direction**: Handoff, plan, retro, hitl, and setup all reduce SKILL.md body weight by extracting content to references — net reduction of ~349 lines from skill bodies with corresponding reference file growth.
- [x] **Single source of truth discipline**: Plan, handoff, and retro changes consistently route duplicated content to `plan-protocol.md` or dedicated references rather than maintaining parallel copies.
- [x] **Cross-skill consistency of clarify/gather deterministic patterns**: Both skills adopt the same `session_dir` resolution pattern, slug-sanitization conventions, and metadata sidecar structure (`*.meta.yaml`).
- [ ] **Provenance concept enforcement completeness**: The refactor skill adds provenance checks but they are inform-only with no threshold or blocking gate, leaving the concept partially unimplemented (see A2).
- [ ] **Automated pipeline composability**: The new interactive gates in handoff (missing-entry branch) and run (explore-worktrees cleanup) are untested for `cwf:run` auto-mode, risking pipeline stalls in unattended execution.
- [x] **Reference file navigability**: TOCs added to 6 reference files (questioning-guide, research-guide, agent-prompts, impl-gates, prompts, external-review) that exceeded the 100-line threshold.
- [x] **Run-stage provenance closes the Agent Orchestration gap**: The new `run-stage-provenance.md` + per-stage checklist + `Fail` verdict handling directly addresses the three medium findings from the refactor review for the `run` skill.

### Provenance
source: REAL_EXECUTION
tool: claude-cli
reviewer: Architecture
duration_ms: —
command: claude -p

<!-- AGENT_COMPLETE -->
