# Deep Review Batch D

Skills under review: `refactor` (multi-mode drift control) and `retro` (session retrospectives). All nine criteria from `plugins/cwf/skills/refactor/references/review-criteria.md` were applied, with the requested emphasis on internal consistency, concept integrity, and portability.

## refactor

### Highlights
- The **Provenance Sidecars** procedure forces a deterministic metadata check before any criteria document is loaded, so every review run reports the current skill/hook counts, flags stale sidecars, and documents deltas before analysis begins; this mirrors the `Provenance` column in the concept map and keeps different review paths on the same facts (`plugins/cwf/skills/refactor/SKILL.md:43-63`, `plugins/cwf/references/concept-map.md:165-178`).
- Mode routing, sessions, and scan scripts orchestrate every review path through the same agent framework, so the skill behaves like the `Agent Orchestration` row in the concept map: the quick scan resolves the repo root via `{REPO_ROOT}`/`git rev-parse`, writes structured JSON + summaries, and gates the artifacts through `check-run-gate-artifacts.sh` before continuing, while the codebase mode bootstraps `codebase-contract.json`, records contract metadata, and runs `check-codebase-contract-runtime.sh` when available (`plugins/cwf/skills/refactor/SKILL.md:10-200`, `plugins/cwf/references/concept-map.md:165-178`). This keeps the workflow internally consistent and aligned with the requested axes.

### Findings
- None — the skill stays under the size thresholds, keeps “when to use” instructions in the description, pushes implementation details into references (scripts + flows), and documents fallback + gating for each admission point, so all nine criteria are satisfied (`plugins/cwf/skills/refactor/SKILL.md:1-200`).

### Portability
- Session/building scripts resolve every path dynamically (session bootstrap for quick scan, optional `--include-local-skills`, and `git rev-parse` to identify the repo root), so the skill runs regardless of the host repo layout and still writes summary artifacts next to the active session directory (`plugins/cwf/skills/refactor/SKILL.md:66-104`).
- Codebase quick scan bootstraps the repository-local contract and handles missing contracts by continuing with documented fallback defaults (contract metadata status, warnings, and shell-strict-mode overrides), which keeps the skill usable in fresh clones or unfamiliar repos without breaking the run (`plugins/cwf/skills/refactor/SKILL.md:167-200`).

## retro

### Highlights
- The retro workflow updates `cwf-state` (`phase="retro"`), reads the relevant session directory (reuse/new-date logic), syncs Codex logs, and runs the evidence collector before writing anything, so every retrospective takes the same context snapshot and avoids stale artifacts (`plugins/cwf/skills/retro/SKILL.md:24-58`).
- Deep mode enforces the two-batch agent choreography required by the `Expert Advisor` and `Agent Orchestration` concepts in the map: Batch 1 (CDM + learning resources) produces the foundation; Batch 2 (Expert α/β) consumes it, and each output is subject to hard/soft gating, retry bounds, and explicit persistence contracts (`plugins/cwf/skills/retro/SKILL.md:83-150`, `plugins/cwf/references/concept-map.md:165-178`). That choreography keeps expert analysis consistent and portable across sessions.

### Findings
- None — the workflow documents each section’s intent, ties it to session state in `.cwf/projects`, and mandates why/how/when to drop in sub-agent outputs, so the instructions already satisfy every criterion (`plugins/cwf/skills/retro/SKILL.md:6-200`).

### Portability
- Directory selection prompts make it safe to reuse an existing session or bootstrap a new dated directory, then copy `plan.md`/`lessons.md` as needed; these safeguards plus the `cwf-live-state` helper mean the skill can run in any repo without hard-coded session roots (`plugins/cwf/skills/retro/SKILL.md:31-105`).
- External dependencies (Codex sync, retro-collect-evidence, multi-agent flows) live inside the plugin, and the gating scripts explicitly note when fallbacks/warnings are necessary, so the workflow degrades gracefully when a referenced artifact or log is missing (`plugins/cwf/skills/retro/SKILL.md:44-150`).

<!-- AGENT_COMPLETE -->
