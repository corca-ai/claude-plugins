# Gather — Refactor Review Prevention Run

## Source
- Input task: `.cwf/projects/260217-01-refactor-review/review-and-prevention.md`

## Incident Summary
- Runtime breakage happened because a deleted script (`csv-to-toon.sh`) still had runtime callers.
- Deterministic safety nets were missing at deletion decision time.
- Manual stage sequencing skipped `review-code`, reducing detection coverage.
- Compaction/restart diluted explicit user workflow directives.

## Proposed Controls in Source Doc
- `A` Deletion safety hook (P0)
- `B` Broken-link triage protocol (P0)
- `C` Recommendation fidelity check in impl (P1)
- `E+G` Hook-based workflow gate enforcement with fail-closed behavior (P0)
- `D/F/H/I` are lower-priority or deferred scope

## Execution Intent
Implement high-priority prevention controls in CWF core while preserving existing runtime compatibility.

## Affected Surfaces
- Hooks runtime: `plugins/cwf/hooks/hooks.json`, `plugins/cwf/hooks/scripts/*`
- Live-state helper: `plugins/cwf/scripts/cwf-live-state.sh`
- Workflow contract: `plugins/cwf/skills/run/SKILL.md`
- Impl contract: `plugins/cwf/skills/impl/SKILL.md`
- Shared protocol docs: `plugins/cwf/references/agent-patterns.md`
- Markdown-link gate messaging: `plugins/cwf/hooks/scripts/check-links-local.sh`
- Hook map docs: `plugins/cwf/hooks/README.md`

## Risks
- Hook output schema mismatch can cause non-blocking behavior.
- YAML list handling bugs in live-state updates can corrupt `live` block.
- New fail-closed behavior can cause false positives; needs explicit override path.
