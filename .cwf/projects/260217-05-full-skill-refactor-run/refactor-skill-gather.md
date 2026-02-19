# Refactor Review: gather skill

## Executive Summary
- `gather` SKILL.md stays below the size guardrails (1,405 words / 263 lines) and keeps its frontmatter limited to `name`/`description`, so it already meets Criteria 1–2 for progressive disclosure.
- All referenced scripts (`code-search.sh`, `extract.sh`, `search.sh`, `slack-api.mjs`, `slack-to-md.sh`, `notion-to-md.py`, `g-export.sh`, `csv-to-toon.sh`) and reference notes (`google-export.md`, `slack-export.md`, `notion-export.md`, `TOON.md`, `query-intelligence.md`, `search-api-reference.md`, `references/<SKILL_DIR>`) are cited in the body, so resource health checks do not raise unused-files flags (Criterion 4).
- The most actionable risks are: (1) duplicate export prerequisites that bloat the SKILL body (Criterion 3); (2) the Generic URL fallback leaves the actual fetch command intentionally unspecified, which increases degrees of freedom and weakens determinism (Criterion 6); (3) the Agent Orchestration concept (per `plugins/cwf/references/concept-map.md`) is only partially represented by a single `--local` sub-agent and lacks the required state/provenance guidance (Criterion 8).

## Evaluation Metrics
- Word count: `1,405` (Threshold: 3,000 for warning). Criteria 1 passed.
- Line count: `263` (Threshold: 500). Criteria 1 passed.
- Resource files: `google-export.md`, `slack-export.md`, `notion-export.md`, `TOON.md`, `query-intelligence.md`, `search-api-reference.md`, plus all scripts listed above. Each is referenced by name in SKILL.md, so no unused-resource flags (Criterion 4).

## Findings

### Structural / Duplication (Criteria 1–4)
1. **Medium — Duplicate export prerequisites**: The Google/Slack/Notion sections in `plugins/cwf/skills/gather/SKILL.md` restate the same prerequisite bullet lists that already live in their reference documents (e.g., the “Page must be published to the web / Python 3.7+ / known limitations” text repeated from `references/notion-export.md`). That duplication enlarges the SKILL body without adding unique context and violates Criterion 3. Move the heavy prerequisites + limitation lists entirely into the reference files and replace them with short summaries plus explicit “see references/notion-export.md” pointers.

### Quality / Degrees of Freedom & Concept (Criteria 5–8)
1. **Medium — Generic URL fallback is under-specified**: The “Fallback to WebFetch” step in the Generic URL handler (`plugins/cwf/skills/gather/SKILL.md`, “Generic URL” subsection) simply says “Use WebFetch tool” without defining which script/command, how to capture metadata, or what to do when the download produces zero content. With such an open-ended directive, agents can run any tool and produce inconsistent markdown; this mismatches the Degrees of Freedom expectation (Criterion 6) for what should be a low-freedom content-grabbing step. Codify a concrete script (or a documented sequence of `web.run` calls) and capture the exit content/URL in a deterministic artifact so future reviews know exactly which tool was invoked.
2. **Medium — Agent Orchestration concept lacks state/provenance**: Gather’s row in `plugins/cwf/references/concept-map.md` claims Agent Orchestration, yet the SKILL only describes a single Task call in `--local Mode` with no instructions for logging the query, tracking the sub-agent’s identity/output path, or rerunning when the Task fails. The concept requires maintaining work-item decomposition (what query was launched), agent team composition (which Task agent generated the canvas), and provenance for the output so other skills can cite it. Add a short “Task output contract” paragraph describing how to build the prompt, where to persist the resulting markdown, how to detect a failed run, and how to surface that metadata to downstream consumers. That will fulfill Criterion 8’s required state/actions for Agent Orchestration.

## Suggested Actions
1. Replace the long prerequisites/limitations blocks for Google/Slack/Notion exports in SKILL.md with 1‑sentence summaries plus explicit `See references/...` pointers, keeping the reference files as the single source of truth (improves Criterion 3 and keeps the SKILL body lean).
2. Turn the Generic URL fallback into a deterministic routine by naming the fetch command (e.g., a helper script or documented `web.run` call), recording the sanitized filename, and describing how to handle empty results before saving to `{OUTPUT_DIR}` (tightens Criterion 6).
3. Expand the `--local Mode` section into an agent-orchestration checklist: include the query-to-file mapping, how to detect Task failure, how to log the sub-agent’s identity, and where to store the provenance info referenced by later stages (addresses Criterion 8).

## Next Steps
1. Update `plugins/cwf/skills/gather/SKILL.md` along the three suggested actions above so the deep review findings can guide a second pass.
2. Once the SKILL file is updated, rerun `cwf:refactor --skill gather` to verify that no new flags are introduced and that the reference-heavy sections are now purely pointers.

<!-- AGENT_COMPLETE -->
