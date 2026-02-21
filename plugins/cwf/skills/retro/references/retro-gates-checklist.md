# Retro Gates Checklist

Deterministic checks for `cwf:retro` execution. Use this checklist before finalizing `retro.md`.

## Core Quality Gates

1. Never duplicate content already captured in `lessons.md`.
2. Cite concrete session moments; avoid generic advice.
3. Keep each section scoped; if there is no meaningful signal, state that briefly.
4. If early context is unavailable due to truncation/window limits, state the limitation explicitly.
5. Always include language specifiers for fenced code blocks (`bash`, `yaml`, `markdown`, `text`, etc.).
6. Read `cwf-state.yaml` (when present) during artifact intake for lifecycle/stage context.
7. Use `retro-collect-evidence.sh` as the default evidence path and include `retro-evidence.md` when present.
8. In deep mode, generate coverage-contract artifacts (`retro-coverage-contract.sh`) before causal narrative and cite coverage counts in `retro.md`.

## Section Scope Gates

1. Section 4 (CDM) is unconditional for retro-worthy sessions.
2. Section 5 (Expert Lens) is deep-mode only. In light mode, include a one-line pointer to `/retro --deep`.
3. Section 6 (Learning Resources) is deep-mode only. In light mode, include a one-line pointer to `/retro --deep`.
4. Section 7 must inventory installed capabilities first (skills + deterministic repo tools) before proposing new external tools.
5. If Section 7 enters a skill-gap branch, run `/find-skills` first and record command/result (or explicit tool-unavailable evidence).

## Deep Mode Artifact Gates

1. Run analysis sections as two-batch sub-agents (Batch 1: CDM + Learning, Batch 2: Expert alpha + Expert beta). Do not run these inline.
2. Apply stage-tier persistence gates:
   - `retro-cdm-analysis.md`: hard fail if invalid after bounded retry.
   - `retro-learning-resources.md`, `retro-expert-alpha.md`, `retro-expert-beta.md`: soft continue with warning + explicit omission notes.
3. Deep mode contract must be mode-accurate:
   - If `retro.md` says `Mode: deep`, all four deep artifacts must exist and end with `<!-- AGENT_COMPLETE -->`.
   - Otherwise downgrade to light mode with explicit reason.
4. In deep mode, Section 6 must include external web resources (URLs) discovered in the current run; internal docs can be supplemental only.
5. In deep mode, include a `Coverage Matrix` subsection and keep `coverage/` artifacts non-empty.

## Persistence and Reporting Gates

1. Run an ownership gate before tiering: classify each finding as `owner=repo` or `owner=plugin`, with `apply_layer=local|upstream` and concrete evidence.
2. Route `owner=plugin` findings to upstream backlog targets; do not use local AGENTS/docs as the primary fix path.
3. After ownership routing, persist findings using `eval > state > doc` ordering. Do not suggest new prose rules when deterministic checks can enforce behavior.
4. AGENTS/runtime-adapter edits require explicit user approval.
5. For direct invocation (`cwf:retro`, `/retro`), assistant response must include both:
   - `Retro Brief`
   - `Persist Proposals`
6. Each direct-invocation persist proposal must include `owner`, `apply_layer`, `promotion_target`, `due_release`, and `evidence`.
