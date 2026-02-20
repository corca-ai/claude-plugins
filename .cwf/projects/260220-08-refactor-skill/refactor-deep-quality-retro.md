# Deep retro skill refactor review — Quality & Concept criteria 5-9

Findings:
- [warning] The output-directory resolution narrative (`plugins/cwf/skills/retro/SKILL.md:32-79`) embeds a full decision tree (AskUserQuestion, deterministic fallback, fast-path script sequencing) directly in SKILL. This level of detail makes the prose overly prescriptive, lengthens the doc, and hard-codes what could live in a helper script/reference, reducing the skill’s degrees of freedom for future tweaks.
  Action: Move the step-by-step tree into a dedicated reference or script (e.g., `references/output-dir-policy.md` plus the `next-prompt-dir.sh` helper) and keep SKILL focused on the high-level policy plus pointers; the external artefact can then evolve without bloating this skill guide.
- [warning] Artifact intake assumes `AGENTS.md` and `CLAUDE.md` always exist (`plugins/cwf/skills/retro/SKILL.md:80-91`), so any repo lacking those documents would break this step. That assumption is a portability risk because not every workspace has the same adapter docs.
  Action: Guard these reads with existence checks (or move them behind a helper script that skips missing files and logs their absence) so retros can still run in forks or other repositories without AGENTS/CLAUDE.
- [info] Anthropic compliance is met: the frontmatter is minimal, the skill folder is kebab-case, and the description (lines 1-20) explains what the skill does plus trigger phrases. Continue keeping metadata concise when new sections are added.
  Action: Maintain this compact metadata pattern for any future updates.
- [info] Concept Integrity holds. The skill orchestrates two batches of sub-agents (CDM, learning, experts), collects their outputs, and synthesizes agreement/disagreement tension per the Expert Advisor and Agent Orchestration requirements (`plugins/cwf/skills/retro/SKILL.md:142-209`, Section 5). Keep these gating rituals intact when refactoring.
  Action: Preserve the batch sequencing and expert-synthesis steps whenever this skill evolves, since they satisfy the declared concepts.

Ranked action list for reducing complexity:
1. Publish the full output-directory resolution/fallback decision tree to a reference or script and shrink the SKILL section to a high-level summary plus links.
2. Wrap artifact intake (AGENTS/CLAUDE/project-context reads) in a helper script that can handle missing files, allowing the SKILL to stay focused on intent rather than file plumbing.
3. Document the gating policy for light/deep fast paths in a compact reference, so the SKILL can cite it instead of restating every rule whenever the gate changes.

<!-- AGENT_COMPLETE -->
