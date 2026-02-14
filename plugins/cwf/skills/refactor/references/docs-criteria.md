# Documentation Review Criteria

Checklist for the `--docs` mode. Evaluate documentation consistency across the repository.

## 0. Deterministic Gate (Run First)

Run deterministic checks before semantic review:

- Markdown lint (`npx --yes markdownlint-cli2`)
- Link validation (`bash scripts/check-links.sh --local --json`)
- Graph/orphan analysis (`node scripts/doc-graph.mjs --json`)

Rules:

- Treat tool output as source of truth for lint-level findings.
- Do not duplicate linter findings as manual review items unless you are interpreting repository-level impact.
- If a required tool is missing, report a tooling gap.

## 1. Agent Entry Docs Review

Check the project's root [AGENTS.md][repo-agents] and runtime adapter docs (for example [CLAUDE.md][repo-claude]):

| Check | Flag condition |
|-------|---------------|
| AGENTS line count > 200 | Progressive disclosure violation — details should live in docs/ |
| Low-signal boilerplate | Intro/meta lines do not change routing, invariants, or safety outcomes |
| AGENTS/adapters are not index-shaped | Entry docs include long phase-by-phase procedures instead of routing + invariants |
| What/why vs how boundary violation | Entry docs prescribe low-level execution sequences that belong in specialized docs, scripts, or hooks |
| Behavioral rules duplicated by deterministic checks | Entry docs say "always do X" for behavior already enforced by hooks/scripts |
| Missing core routing links | Entry docs omit links to the core docs needed for progressive disclosure |
| References non-existent files | Dead path reference |
| References deprecated/removed plugins without noting status | Stale reference |
| Duplicates content from docs/ files | Should reference, not repeat |
| Missing protocol references | Protocol docs exist in docs/ but aren't linked from AGENTS/adapters |

## 2. Project Context Review

Check [docs/project-context.md][repo-project-context]:

| Check | Flag condition |
|-------|---------------|
| Plugin listing doesn't match `plugins/` directory | Missing or extra entries |
| Lists deprecated plugin as active | Status not updated |
| Architecture patterns reference removed plugins | Stale reference |
| Convention entries contradict actual practice | Inconsistency |
| Missing entries for recently added plugins | Incomplete coverage |

## 3. README Review

Check [README.md][repo-readme] and [README.ko.md][repo-readme-ko]:

| Check | Flag condition |
|-------|---------------|
| Overview table doesn't match `marketplace.json` | Missing, extra, or mismatched entries |
| Active plugin missing install/update commands | Incomplete section |
| Deprecated plugin not clearly marked | Missing deprecation notice |
| Korean version structure differs from English | Structural mismatch |
| Korean version content is stale | Content mismatch with English version |
| Dead links (internal file references) | Broken link |

## 4. Cross-Document Consistency

Check alignment between documents:

| Source A | Source B | Check |
|----------|----------|-------|
| `marketplace.json` plugins | README overview table | Same set of plugins, same descriptions |
| `marketplace.json` descriptions | `plugin.json` descriptions | Consistent messaging |
| [docs/project-context.md][repo-project-context] plugins | `plugins/` directory | Matches actual contents |
| [AGENTS.md][repo-agents] and adapter file references | Filesystem | All referenced paths exist |
| README deprecated section | `marketplace.json` deprecated flags | Consistent deprecation status |

For each inconsistency found, report:
- **What**: The specific mismatch
- **Where**: Both files and locations involved
- **Suggestion**: Which file should be updated and how

## 5. Document Design Quality

Structural health of the documentation graph. Reference: [Software project documentation in AI era](https://wiki.g15e.com/pages/Software%20project%20documentation%20in%20AI%20era).

| Check | Flag condition |
|-------|---------------|
| Orphaned documents | Doc file unreachable from any entry point ([AGENTS.md](../../../../../AGENTS.md), runtime adapters, README, docs/ index) |
| Circular references | Two docs reference each other for the same concept, or navigation path > 3 hops from entry |
| Inline overload | A single file embeds substantive content that should live in a dedicated doc (e.g., full protocol text inside [AGENTS.md](../../../../../AGENTS.md) instead of a reference link) |
| Unnecessary hard wraps in prose | Prose paragraphs are split across multiple short lines without semantic boundaries (when MD013 is disabled, this should be style-reviewed explicitly) |
| Auto-generated files in git | Files that can be regenerated (build output, compiled docs) are version-controlled |
| Undocumented non-obvious decisions | Non-obvious technical choices (e.g., "no Tailwind", "no mock objects") lack explicit rationale anywhere in docs |
| Obvious instructions | Docs include self-evident guidance (e.g., "write clean code", "follow best practices") that wastes reader attention |
| Automation-redundant instructions | Docs include behavioral instructions already enforced by deterministic hooks or skill triggers (e.g., AGENTS/adapters say "always do X" when a PostToolUse hook already validates X). Cross-check against installed `hooks.json` entries and skill trigger conditions |
| Root-relative internal links | Links with leading-slash targets (for example, /docs/x.md) are renderer/tooling dependent; prefer file-relative links |
| Scope-overlapping documents | Multiple docs cover the same scope with no clear ownership boundary. Candidate for merge or deletion — one scope, one file |
| Manual-review/linter overlap | Review narrative repeats deterministic tool findings without adding semantic interpretation or structural action |

## 6. Structural Optimization

Synthesize findings from Sections 1-5 into actionable restructuring proposals.

### Documentation Principles (reference frame)

Apply these principles when evaluating structure:

1. **Always-loaded file = compressed index**: The entry-point ([AGENTS.md][repo-agents]) should contain pointers and scope descriptions, not full content. Runtime adapters should stay thin.
2. **Each document has one clear scope**: If a doc serves multiple unrelated purposes, agents can't make a meaningful read/skip decision.
3. **Agent autonomy for reading, explicit routing for writing**: Agents judge which docs are relevant; writing needs explicit routing (persist routing table).
4. **Less is more**: Instruction-following quality degrades as instruction count rises. [AGENTS.md][repo-agents] < 100 lines ideal; runtime adapters thin; individual docs focused enough to be skippable.
5. **Documentation-as-Code**: Single source of truth per fact. Meaningful names. Link, don't copy. Remove unreachable docs.
6. **Non-obvious decisions only**: Skip guidance a capable agent would independently reach.
7. **Skills for vertical, docs for horizontal**: Skills for action-specific workflows; docs for cross-task knowledge.

### Proposals to produce

| Proposal type | Description |
|---------------|-------------|
| **Merge candidates** | Scope-overlapping docs that should combine into one. Identify the primary file (absorber) and secondary files (to be deleted). |
| **Deletion candidates** | Docs whose unique content fits entirely within another file. |
| **AGENTS/adapter trimming** | Lines that are (a) obvious, (b) automation-redundant (hook/skill enforced), or (c) duplicated in docs/. |
| **Signal-to-noise scoring** | For AGENTS/adapters, assign High/Medium/Low utility per line or bullet. Remove or merge Low items. |
| **Target structure** | Before/after comparison of the doc set with clear scope per file. |
| **Principle compliance** | Rate each remaining doc against principles 1-7 above. Flag violations. |
| **Automation promotion candidates** | Repeated manual findings that should become deterministic checks (lint rule, hook, or script). Include proposed owner file. |

[repo-agents]: ../../../../../AGENTS.md
[repo-claude]: ../../../../../CLAUDE.md
[repo-project-context]: ../../../../../docs/project-context.md
[repo-readme]: ../../../../../README.md
[repo-readme-ko]: ../../../../../README.ko.md
