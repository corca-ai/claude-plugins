## clarify

### Findings
| Severity | Criterion | Finding | Evidence | Suggestion |
|---|---|---|---|---|
| info | 1 | no material finding (456 lines / ~2 080 words, below the warning/error thresholds) | `plugins/cwf/skills/clarify/SKILL.md:1-456` | n/a |
| info | 2 | no material finding (front matter limited to `name`/`description`; body focuses on the Quick Start plus phased workflow rather than “When to use” prose) | `plugins/cwf/skills/clarify/SKILL.md:1-35,6-83` | n/a |
| info | 3 | no material finding (research/aggregation/questioning procedures reference dedicated docs without copying their content into the SKILL.md body) | `plugins/cwf/skills/clarify/SKILL.md:86-345` | n/a |
| info | 4 | no material finding (each reference listed in `references/` is invoked by the workflow and there are no unused scripts/assets) | `plugins/cwf/skills/clarify/SKILL.md:86-345` | n/a |
| info | 5 | no material finding (imperative instructions such as “Use the live-state helper,” “Decompose into decision points,” and “Launch sub-agents” dominate the entire workflow) | `plugins/cwf/skills/clarify/SKILL.md:40-345` | n/a |
| info | 6 | no material finding (low freedom flows; every phase has exact Task contracts, classification rules, and evidence-gathering steps) | `plugins/cwf/skills/clarify/SKILL.md:86-324` | n/a |
| info | 7 | no material finding (front matter contains only `name`/`description` plus trigger phrases) | `plugins/cwf/skills/clarify/SKILL.md:1-35` | n/a |
| info | 8 | no material finding (concept map marks `clarify` for Expert Advisor, Tier Classification, Agent Orchestration, and Decision Point, and the SKILL implements all those phases with explicit sub-agent contracts, classification tables, and decision-point aggregation) | `plugins/cwf/references/concept-map.md:158-197` + `plugins/cwf/skills/clarify/SKILL.md:66-345` | n/a |
| info | 9 | no material finding (session directory and live-state helper are resolved via `{CWF_PLUGIN_DIR}`/`cwf-live-state.sh`, avoiding hard-coded repo paths) | `plugins/cwf/skills/clarify/SKILL.md:40-64` | n/a |

### Prioritized actions
1. None — all criteria are satisfied.

## gather

### Findings
| Severity | Criterion | Finding | Evidence | Suggestion |
|---|---|---|---|---|
| info | 1 | no material finding (347 lines / ~1 860 words, below the warning thresholds) | `plugins/cwf/skills/gather/SKILL.md:1-347` | n/a |
| info | 2 | no material finding (metadata limited to name/description with triggers; the body concentrates on the workflow and handler dispatch table) | `plugins/cwf/skills/gather/SKILL.md:1-49,53-347` | n/a |
| info | 3 | no material finding (details such as Google/Slack/Notion exports and query intelligence live in reference docs rather than being duplicated) | `plugins/cwf/skills/gather/SKILL.md:53-347` | n/a |
| warning | 4 | `scripts/__pycache__/notion-to-md.cpython-310.pyc` is a compiled artifact that is neither referenced in SKILL.md nor needed in source control, so it bloats the resource directory. | `plugins/cwf/skills/gather/scripts/__pycache__/notion-to-md.cpython-310.pyc` | delete the `.pyc`/`__pycache__` entry (or add it to `.gitignore`) so only tracked source scripts remain. |
| info | 5 | no material finding (imperative language drives each handler: “Parse args,” “Run Task once,” “Validate output,” etc.) | `plugins/cwf/skills/gather/SKILL.md:28-339` | n/a |
| info | 6 | no material finding (highly prescriptive operations, such as the Generic URL routine and Task contracts, keep fragile external integrations under low freedom control) | `plugins/cwf/skills/gather/SKILL.md:53-339` | n/a |
| info | 7 | no material finding (front matter contains only the required fields and the description lists trigger phrases) | `plugins/cwf/skills/gather/SKILL.md:1-4` | n/a |
| info | 8 | no material finding (concept map marks `gather` only for Agent Orchestration, and the SKILL orchestrates multiple handlers, metadata passes, and Task-based local exploration) | `plugins/cwf/references/concept-map.md:158-197` + `plugins/cwf/skills/gather/SKILL.md:28-270` | n/a |
| info | 9 | no material finding (output directory resolution and env var fallbacks ensure the skill adapts to arbitrary repo layouts without hard-coded paths) | `plugins/cwf/skills/gather/SKILL.md:28-49,274-287` | n/a |

### Prioritized actions
1. Remove `plugins/cwf/skills/gather/scripts/__pycache__/notion-to-md.cpython-310.pyc` (or keep it out of version control) to avoid drifting compiled artifacts into the scripts directory; effort: small.

<!-- AGENT_COMPLETE -->
