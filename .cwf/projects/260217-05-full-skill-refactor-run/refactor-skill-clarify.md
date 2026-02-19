**Summary**
clarify.md covers the workflow thoroughly, but the review flagged three maintainability gaps: the session directory is never defined before it is referenced, the Phase 2 prompts duplicate material already stored in `references/research-guide.md`, and the longer reference files lack navigation aids.

**Findings**
Medium – `Phase 2` starts generating `{session_dir}/clarify-*.md` artifacts (see `plugins/cwf/skills/clarify/SKILL.md:72-133`) before the skill tells the agent how to resolve `session_dir`. Other skills explicitly run `cwf-live-state.sh resolve` to read `live.dir`. Right now, a new reviewer could miss that step and mis-locate the files; add a short “Resolve session directory” step immediately after Phase 0 (or inline in Phase 2) so the placeholder becomes actionable.
Medium – The codebase/web research Task prompts (also in `plugins/cwf/skills/clarify/SKILL.md:72-131`) repeat the same heuristics already documented in `plugins/cwf/skills/clarify/references/research-guide.md`. That duplication bloats the SKILL body and invites drift between the prompt text and the reference guide; keep the prompt focused on the output paths and link to the reference for the step-by-step methodology.
Low – Both `plugins/cwf/skills/clarify/references/research-guide.md` (103 lines) and `references/questioning-guide.md` (147 lines) are longer than the 100-line threshold mentioned in `plugins/cwf/skills/refactor/references/review-criteria.md:45-52`, yet neither file has a table of contents. Adding a short TOC at each top-level file would align with the resource-health rule and make the heuristics easier to navigate.

**Quick wins**
- Insert an explicit `session_dir` resolution snippet (e.g., run `cwf-live-state.sh resolve` and describe how to extract `live.dir`) before the first `{session_dir}` placeholder.
- Prepend concise tables of contents to `research-guide.md` and `questioning-guide.md` so readers can jump to sections directly.

**Deferred refactors**
- Refactor the default-mode research prompts so they import their methodology from `references/research-guide.md` (or a dedicated prompt template) instead of rephrasing it inline; this keeps the step-by-step guidance in one place while keeping the SKILL focused on orchestration.

**Risk if unchanged**
New reviewers may still write research outputs to the wrong location, the latest methodology updates can drift between the SKILL and the research guide, and the long reference files remain harder to scan, making future maintenance slower.

<!-- AGENT_COMPLETE -->
