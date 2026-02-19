# Deep Review Batch F

Skills under review: `setup` (initial CWF configuration) and `update` (marketplace version reconciliation). All nine criteria from `plugins/cwf/skills/refactor/references/review-criteria.md` were applied with an emphasis on portability.

## setup

### Findings
| Severity | Criterion | Finding | Evidence | Suggestion |
|---|---|---|---|---|
| info | 1 | ~2,514 words across 459 lines keeps the skill under the >3 000/500 thresholds. | `plugins/cwf/skills/setup/SKILL.md:459` | n/a |
| info | 2 | Metadata is limited to name/description/triggers and the Quick Start plus mode-routing table deliver the “when to use” guidance before the body continues with phase references. | `plugins/cwf/skills/setup/SKILL.md:1`; `plugins/cwf/skills/setup/SKILL.md:10` | n/a |
| info | 3 | Phase 2 (and later phases) point directly to reference docs for detailed checks (tool detection, Codex, etc.), so no duplication of the reference material appears in the SKILL body. | `plugins/cwf/skills/setup/SKILL.md:147` | n/a |
| warning | 4 | `scripts/check-configure-git-hooks-runtime.sh` is documented in the directory README but missing from SKILL.md’s references, so its regression check sits outside the skill’s narrative and looks unused. | `plugins/cwf/skills/setup/SKILL.md:461`; `plugins/cwf/skills/setup/README.md:15` | Mention the runtime regression script in SKILL.md (Phase 2.7 or the References section) or retire it so the workflow’s resource list matches reality. |
| info | 5 | Phase descriptions use imperative language (“read cwf-state,” “Use AskUserQuestion,” “run the sync script”), keeping the writing style consistent with expectations. | `plugins/cwf/skills/setup/SKILL.md:67` | n/a |
| info | 6 | Each phase enumerates precise scripts, prompts, and gate requirements (e.g., the entire tool-detection flow in Phase 2), so the freedom level matches the low-freedom operations being performed. | `plugins/cwf/skills/setup/SKILL.md:143` | n/a |
| info | 7 | Front matter contains only the required `name`/`description` pair plus trigger phrases, so the metadata aligns with the Anthropic schema. | `plugins/cwf/skills/setup/SKILL.md:1` | n/a |
| info | 8 | Concept map labels `setup` as infrastructure-only (the sparse row), so no additional generic concept checks are needed. | `plugins/cwf/references/concept-map.md:178` | n/a |
| info | 9 | Phase 2.4.1 resolves the active plugin scope via `detect-plugin-scope.sh` and only falls back to the git top-level (for project/local root discovery) after explicit confirmation, preventing hard-coded repo paths. | `plugins/cwf/skills/setup/SKILL.md:189`; `plugins/cwf/skills/setup/SKILL.md:193` | n/a |

### Portability
Phase 2.4.1 and its safety guards resolve the active plugin scope before touching Codex links, and project/local scopes delegate to the repository’s git top-level when no explicit root exists, so this skill adapts to different repo layouts without relying on fixed paths. `plugins/cwf/skills/setup/SKILL.md:189`; `plugins/cwf/skills/setup/SKILL.md:193`

## update

### Findings
| Severity | Criterion | Finding | Evidence | Suggestion |
|---|---|---|---|---|
| info | 1 | The SKILL spans ~269 lines (line 269 begins the rules) and ~1.2 k words, keeping it below both the 3 000-word and 500-line thresholds. | `plugins/cwf/skills/update/SKILL.md:269` | n/a |
| info | 2 | Metadata is minimal (line 1) and the Quick Start block lists only `cwf:update`/`cwf:update --check`, so the body can focus on the workflow without duplicating “when to use” prose. | `plugins/cwf/skills/update/SKILL.md:1`; `plugins/cwf/skills/update/SKILL.md:10` | n/a |
| info | 3 | Phase 0 defers all scope-resolution detail to `references/scope-reconcile.md`, avoiding duplication. | `plugins/cwf/skills/update/SKILL.md:23` | n/a |
| info | 4 | The only reference in the skill directory is `scope-reconcile.md`, and it is invoked where needed, so there are no unused scripts/items. | `plugins/cwf/skills/update/SKILL.md:23` | n/a |
| info | 5 | Phase 1 lists imperative shell checks and command sequences (list plugin JSON, copy snapshots), so the writing style stays directive. | `plugins/cwf/skills/update/SKILL.md:42` | n/a |
| info | 6 | Phase 2 walks through the confirm/apply flows with exact commands (including the install fallback), so the operation is constrained to low freedom. | `plugins/cwf/skills/update/SKILL.md:123` | n/a |
| info | 7 | Front matter is limited to the required fields plus trigger phrases, satisfying the schema. | `plugins/cwf/skills/update/SKILL.md:1` | n/a |
| info | 8 | Concept map also flags `update` as a sparse infrastructural row, so no extra concept-verification is needed. | `plugins/cwf/references/concept-map.md:178` | n/a |
| warning | 9 | The version check only searches `${CLAUDE_HOME:-$HOME/.claude}/plugins/cache` and `$HOME/.claude/plugins/cache`, so installs with nonstandard cache roots immediately hit the error path that tells the user to set `CLAUDE_HOME` instead of continuing automatically—this makes updates brittle on alternative layouts. | `plugins/cwf/skills/update/SKILL.md:83`; `plugins/cwf/skills/update/SKILL.md:97` | Allow adding extra cache paths (e.g., `--cache-root`) or search the standard XDG cache cascade before failing so nonstandard installs can still detect the latest metadata. |

### Portability
Scope detection prints the active scope/install path before any mutation (Phase 0.1), but the latest-version check only looks at the two hard-coded cache roots above and exits if nothing is found; adding either additional default scan locations (e.g., `/usr/local/share/claude/plugins/cache`, `$XDG_CACHE_HOME/claude/plugins/cache`) or a flag for extra cache roots would keep the skill portable across alternative runtimes. `plugins/cwf/skills/update/SKILL.md:23`; `plugins/cwf/skills/update/SKILL.md:83`; `plugins/cwf/skills/update/SKILL.md:97`

<!-- AGENT_COMPLETE -->
