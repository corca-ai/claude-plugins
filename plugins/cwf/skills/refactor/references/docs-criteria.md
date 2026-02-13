# Documentation Review Criteria

Checklist for the `--docs` mode. Evaluate documentation consistency across the repository.

## 1. Agent Entry Docs Review

Check the project's root [AGENTS.md](AGENTS.md) and runtime adapter docs (for example [CLAUDE.md](CLAUDE.md)):

| Check | Flag condition |
|-------|---------------|
| AGENTS line count > 200 | Progressive disclosure violation — details should live in docs/ |
| References non-existent files | Dead path reference |
| References deprecated/removed plugins without noting status | Stale reference |
| Duplicates content from docs/ files | Should reference, not repeat |
| Missing protocol references | Protocol docs exist in docs/ but aren't linked from AGENTS/adapters |

## 2. Project Context Review

Check [docs/project-context.md](docs/project-context.md):

| Check | Flag condition |
|-------|---------------|
| Plugin listing doesn't match `plugins/` directory | Missing or extra entries |
| Lists deprecated plugin as active | Status not updated |
| Architecture patterns reference removed plugins | Stale reference |
| Convention entries contradict actual practice | Inconsistency |
| Missing entries for recently added plugins | Incomplete coverage |

## 3. README Review

Check [README.md](README.md) and [README.ko.md](README.ko.md):

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
| [docs/project-context.md](docs/project-context.md) plugins | `plugins/` directory | Matches actual contents |
| [AGENTS.md](AGENTS.md) and adapter file references | Filesystem | All referenced paths exist |
| README deprecated section | `marketplace.json` deprecated flags | Consistent deprecation status |

For each inconsistency found, report:
- **What**: The specific mismatch
- **Where**: Both files and locations involved
- **Suggestion**: Which file should be updated and how

## 5. Document Design Quality

Structural health of the documentation graph. Reference: [Software project documentation in AI era](https://wiki.g15e.com/pages/Software%20project%20documentation%20in%20AI%20era).

| Check | Flag condition |
|-------|---------------|
| Orphaned documents | Doc file unreachable from any entry point (AGENTS.md, runtime adapters, README, docs/ index) |
| Circular references | Two docs reference each other for the same concept, or navigation path > 3 hops from entry |
| Inline overload | A single file embeds substantive content that should live in a dedicated doc (e.g., full protocol text inside AGENTS.md instead of a reference link) |
| Unnecessary hard wraps in prose | Prose paragraphs are split across multiple short lines without semantic boundaries (when MD013 is disabled, this should be style-reviewed explicitly) |
| Auto-generated files in git | Files that can be regenerated (build output, compiled docs) are version-controlled |
| Undocumented non-obvious decisions | Non-obvious technical choices (e.g., "no Tailwind", "no mock objects") lack explicit rationale anywhere in docs |
| Obvious instructions | Docs include self-evident guidance (e.g., "write clean code", "follow best practices") that wastes reader attention |
| Automation-redundant instructions | Docs include behavioral instructions already enforced by deterministic hooks or skill triggers (e.g., AGENTS/adapters say "always do X" when a PostToolUse hook already validates X). Cross-check against installed `hooks.json` entries and skill trigger conditions |
| Scope-overlapping documents | Multiple docs cover the same scope with no clear ownership boundary. Candidate for merge or deletion — one scope, one file |
| Bare code fences | Code blocks missing language specifier (` ```bash `, ` ```text `, etc.) — run `npx markdownlint-cli2` to verify |

## 6. Structural Optimization

Synthesize findings from Sections 1-5 into actionable restructuring proposals.

### Documentation Principles (reference frame)

Apply these principles when evaluating structure:

1. **Always-loaded file = compressed index**: The entry-point ([AGENTS.md](AGENTS.md)) should contain pointers and scope descriptions, not full content. Runtime adapters should stay thin.
2. **Each document has one clear scope**: If a doc serves multiple unrelated purposes, agents can't make a meaningful read/skip decision.
3. **Agent autonomy for reading, explicit routing for writing**: Agents judge which docs are relevant; writing needs explicit routing (persist routing table).
4. **Less is more**: Instruction-following quality degrades as instruction count rises. AGENTS.md < 100 lines ideal; runtime adapters thin; individual docs focused enough to be skippable.
5. **Documentation-as-Code**: Single source of truth per fact. Meaningful names. Link, don't copy. Remove unreachable docs.
6. **Non-obvious decisions only**: Skip guidance a capable agent would independently reach.
7. **Skills for vertical, docs for horizontal**: Skills for action-specific workflows; docs for cross-task knowledge.

### Proposals to produce

| Proposal type | Description |
|---------------|-------------|
| **Merge candidates** | Scope-overlapping docs that should combine into one. Identify the primary file (absorber) and secondary files (to be deleted). |
| **Deletion candidates** | Docs whose unique content fits entirely within another file. |
| **AGENTS/adapter trimming** | Lines that are (a) obvious, (b) automation-redundant (hook/skill enforced), or (c) duplicated in docs/. |
| **Target structure** | Before/after comparison of the doc set with clear scope per file. |
| **Principle compliance** | Rate each remaining doc against principles 1-7 above. Flag violations. |
