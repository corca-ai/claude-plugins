Metrics:
- Word count: 3,409 (warning threshold > 3,000 words).
- Line count: 501 (warning threshold > 500 lines).
- Reference files: 3 (`cdm-guide.md`, `expert-lens-guide.md`, `retro-gates-checklist.md`).
- Unreferenced resources: 0 (no `scripts/` or `assets/` in this skill).

1. SKILL.md Size [warning]
- What: The SKILL body spans 3.4k words and 501 lines because it fully enumerates the mode selection, artifact-gate commands, multi-batch orchestration, and Section 4+ instructions. Loading this entire document whenever `retro` is triggered consumes the shared context window more than necessary.
- Where: Lines 50‑270 describe fast path gating commands, live-state resolution, batch sequencing, and persistence policies, and the remainder of the file continues in the same verbose vein.
- Actionable suggestion: Keep the core SKILL body as a concise procedural outline. Move the detailed command sequences, batch policies, and persistence rationale into the references (e.g., `retro-gates-checklist.md` and `agent-patterns`), then replace those paragraphs with short summaries and links. This preserves the deterministic contracts while recovering ~1.5k+ words from the SKILL load.

2. Progressive Disclosure Compliance [warning]
- What: Sections 3‑7 currently embed reference-level detail that should stay behind the meta layer, defeating the progressive disclosure hierarchy. The skill loads long step-by-step instructions for evidence collection, fast-path commands, CDM, sub-agent handling, and expert-resource expectations every time it opens.
- Where: Lines 80‑190 (mode selection, artifact intake, batch orchestration) and lines 239‑270 (CDM/Expert/Learning/Tools requirements) repeat procedures that already live in `references/retro-gates-checklist.md`, `references/cdm-guide.md`, and `references/expert-lens-guide.md`.
- Actionable suggestion: Reduce the SKILL body to high-level checkpoints (e.g., “Collect artifacts, resolve live state, launch Batch 1 agents, etc.”) and rely on the reference files for the full algorithms and verbatim scripts. This keeps the skill lightweight while still linking to the deterministic scripts and rules that must run every time.

3. Duplication Check [warning]
- Candidate 1: SKILL lines 239‑244 (“Identify 2‑4 critical decision moments…”) restates the CDM methodology already detailed in `references/cdm-guide.md` lines 36‑49 (including the probe list and lesson format).
- Candidate 2: SKILL lines 248‑267 (“Mode: deep only… Expert selection… Execution…”) mirrors the expert-lens guidance in `references/expert-lens-guide.md` lines 9‑51, providing the same conditions, selection priority, and analysis requirements.
- Actionable suggestion: Replace these verbose paragraphs with single-sentence pointers (e.g., “Follow `references/cdm-guide.md` for the CDM probe list” or “Follow `references/expert-lens-guide.md` for expert selection and synthesis”). Keeping only the deterministically required statements in SKILL eliminates the redundancy, shrinks the file, and avoids out-of-sync edits between the body and references.

4. Resource Health [info]
- What: All three reference files are modest in size (<100 lines each), and each is explicitly mentioned in SKILL; there are no unused `scripts/` or `assets/` resources to manage.
- Where: Verified by listing `plugins/cwf/skills/retro/references/` and checking that each filename appears in SKILL (section references or the References list).
- Actionable suggestion: None beyond continuing to keep the references in sync—resource health is solid.

<!-- AGENT_COMPLETE -->
