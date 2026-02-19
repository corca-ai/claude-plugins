**Summary**
setup SKILL still attempts to cover every setup phase in a single ~4,000-word, 957-line document, so the body takes far more context than the refactor criteria intend, it never re-writes the SSOT after new tooling gets installed, and the bottom “Rules” block simply restates earlier procedural steps (making the file heavier to scan).

**Findings**
Medium – `plugins/cwf/skills/setup/SKILL.md` is 4,063 words and 957 lines, exceeding the warning thresholds in `plugins/cwf/skills/refactor/references/review-criteria.md:5-16`. Every fresh trigger therefore loads a very large chunk of text and the later phases (2.4‑4.4, Phase 5, Rules) all become harder to parse; split the heavier command sequences into dedicated references or summarize them with linking bullets so the core SKILL can stay under the 3k/500 constraints and keep the on‑trigger payload light.
Medium – Phase 2.2 updates `cwf-state.yaml`’s `tools:` section before Phase 2.3 even offers to install missing commands, and nothing in `Phase 2.3.2` (lines 225‑233) or the surrounding text instructs agents to re-run the detection or rewrite `cwf-state` after those installs. The SSOT therefore can stay stuck listing a tool as “unavailable” even after `install-tooling-deps.sh` succeeded, violating the Rule 2 invariant about keeping `cwf-state` authoritative. Add an explicit post‑install re-check and `cwf-state` rewrite or otherwise reapply Phase 2.1/2.2 with the finalized availability table so the recorded state matches reality before continuing (see `plugins/cwf/skills/setup/SKILL.md:158-166` and `:193-233`).
Low – The `Rules` block at the bottom (`plugins/cwf/skills/setup/SKILL.md:918-940`) recaps many command references already spelled out in the earlier phases (for example coverage validation in `:882-893` and dependency install prompts in `:193-233`). That duplication both adds to the file’s length and creates two sources of truth for the same behavior, increasing the risk of drift when a phase description changes. Keep only the fundamental invariants here (or move them into a short reference) and link the detailed sequences back to the phase where they belong.

**Quick wins**
- Extract chunked command sequences (codex sync, git gate sizing, index coverage checks, repository index editing) into per-phase reference files and replace the inline text with summaries plus `see also` links to those references.
- After an install attempt, immediately re-run the detection block from Phase 2.1 and re-write `cwf-state.yaml` so the `tools:` section reflects the final availability before reporting “Tool Detection Results”.
- Trim the “Rules” list to only the invariant statements that are not otherwise described in the body; point to the relevant phase for the procedural details instead of duplicating them.

**Deferred refactors**
- Consider reorganizing the SKILL so the optional Codex, Git hook, env, and repository index phases live in small companion `references/` docs that can be loaded on demand while the SKILL stays focused on orchestration decisions and gating.
- Introduce a helper script (or a shared reference snippet) that updates `stage_checkpoints` + `tools` in `cwf-state.yaml` consistently across skills, then call that helper from Phase 5.2 so future skills do not forget the SSOT rewrite.

**Risk if unchanged**
New reviewers keep pulling a massive document around (slowing comprehension), `cwf-state.yaml` drifts from reality after tooling installs, and duplicate “Rules” promote inconsistent updates between the workflow steps and the invariants section.

<!-- AGENT_COMPLETE -->
