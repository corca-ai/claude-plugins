# Documentation Review Criteria

Checklist for the `--docs` mode. Evaluate documentation consistency across the repository with portability baseline always enabled.

## 0. Deterministic Gate (Run First)

Run deterministic checks before semantic review:

- Markdown lint (`markdownlint-cli2 "**/*.md"`)
- Link validation (`bash {SKILL_DIR}/scripts/check-links.sh --local --json`)
- Graph/orphan analysis (`node {SKILL_DIR}/scripts/doc-graph.mjs --json`)
- Repository-local deterministic rules configured in current lint/hooks/scripts

Rules:

- Treat tool output as source of truth for lint-level findings.
- Do not duplicate linter findings as manual review items unless you are interpreting repository-level impact.
- If a required tool is missing, report a tooling gap.
- For each proposed new documentation rule, classify first: `AUTO_EXISTING`, `AUTO_CANDIDATE`, or `NON_AUTOMATABLE`.
- Only `NON_AUTOMATABLE` items belong in prose rules; `AUTO_EXISTING` and `AUTO_CANDIDATE` belong in deterministic gates.

## 0.5 Contract-Aware Scope Resolution

Resolve repository docs contract before semantic checks.

Contract reference: [docs-contract.md](docs-contract.md)

### Always-on baseline (independent of contract)

- Entry-doc path validity for discovered entry docs
- Root-relative internal link portability checks
- Structural/semantic doc quality checks (Sections 5-6)
- Portability risk checks (host-repo hardcoding, non-defensive assumptions)

### Contract-driven checks (run only when enabled and source-resolved)

- Project context alignment
- Plugin inventory and manifest alignment
- Locale mirror alignment (for example README language pairs)
- Semantic/path exclusions declared by contract `scope.semantic_exclude_globs`
- Root-relative-link exclusion declared by contract `scope.root_relative_link_exclude_globs`

If a contract-driven source is missing, report in `SKIPPED_CHECKS` with reason.

## 1. Agent Entry Docs Review

Check root entry docs resolved from contract (`entry_docs.required` + `entry_docs.optional`). Typical examples include AGENTS.md, README.md, and CLAUDE.md.

| Check | Flag condition |
|-------|---------------|
| Entry doc line count > 200 | Progressive disclosure violation - details should live in docs/ |
| Low-signal boilerplate | Intro/meta lines do not change routing, invariants, or safety outcomes |
| Partial-only SNR trimming | Review trims only opening lines; no full-file line/bullet utility pass was performed |
| Entry docs are not index-shaped | Entry docs include long phase-by-phase procedures instead of routing + invariants |
| What/why vs how boundary violation | Entry docs prescribe low-level execution sequences that belong in specialized docs, scripts, or hooks |
| Document-role ambiguity | Linked docs are listed without clear role definition (what this doc is) |
| Directive-style routing overload | Entry docs rely on procedural read/write directives instead of concise role mapping |
| Path-heavy link labels in scoped lists | Link labels repeat long filesystem paths even when section context already disambiguates targets |
| Mixed ordering policy in a single index | Similar lists mix alphabetical and semantic order without explicit policy |
| Routing list duplication | Same target docs repeated across sections without materially different purpose |
| Behavioral rules duplicated by deterministic checks | Docs state behavior already enforced by hooks/scripts |
| Missing core routing links | Entry docs omit links to core docs needed for progressive disclosure |
| References non-existent files | Dead path reference |
| References deprecated/removed components without status | Stale reference |
| Duplicates content from downstream docs | Should reference, not repeat |

## 2. Project Context Review (Conditional)

Run when contract enables project context review and path resolves.

| Check | Flag condition |
|-------|---------------|
| Component listing does not match repository structure | Missing or extra entries |
| Lists deprecated component as active | Status not updated |
| Architecture patterns reference removed/renamed components | Stale reference |
| Convention entries contradict actual practice | Inconsistency |
| Missing entries for recently added components | Incomplete coverage |

## 3. README Review (Baseline + Conditional Mirrors)

Baseline checks for primary README (typically README.md):

| Check | Flag condition |
|-------|---------------|
| Active component missing install/update commands | Incomplete section |
| Deprecated component not clearly marked | Missing deprecation notice |
| Dead internal file links | Broken link |

Conditional checks (when contract enables these sources):

| Check | Flag condition |
|-------|---------------|
| Inventory source does not match README overview table | Missing, extra, or mismatched entries |
| Locale mirror structure mismatch | Primary and mirror README have divergent structure |
| Locale mirror intent drift | Primary README diverges from mirror policy decisions |

## 4. Cross-Document Consistency

Always-on checks:

| Source A | Source B | Check |
|----------|----------|-------|
| Entry docs and adapter file references | Filesystem | All referenced paths exist |
| Internal links | Portability baseline | Root-relative links are minimized; file-relative links preferred |

Contract-driven checks (run only when sources resolve):

| Source A | Source B | Check |
|----------|----------|-------|
| Plugin inventory source | README overview table | Same component set and messaging intent |
| Plugin inventory source descriptions | Plugin manifests | Consistent messaging |
| Project-context component listing | Actual repository directories | Matches current contents |
| Deprecated section in README | Inventory deprecated flags/status | Consistent deprecation status |

For each inconsistency found, report:

- **What**: specific mismatch
- **Where**: both files/locations involved
- **Suggestion**: which file should be updated and how

## 5. Document Design Quality

Structural health of the documentation graph. Reference: [Software project documentation in AI era](https://wiki.g15e.com/pages/Software%20project%20documentation%20in%20AI%20era).

| Check | Flag condition |
|-------|---------------|
| Orphaned documents | Doc file unreachable from any entry point (entry docs, README, docs index) |
| Circular references | Two docs reference each other for same concept, or navigation path > 3 hops |
| Inline overload | A single file embeds substantive content that should be a dedicated doc |
| Unnecessary hard wraps in prose | Prose split across short lines without semantic boundaries |
| Auto-generated files in git | Regenerable files are version-controlled without reason |
| Undocumented non-obvious decisions | Technical choices lack explicit rationale in docs |
| Obvious instructions | Self-evident advice that wastes reader attention |
| Automation-redundant instructions | Behavioral instructions already enforced by deterministic gates |
| Root-relative internal links | Leading-slash targets reduce renderer/tooling portability |
| Scope-overlapping documents | Multiple docs cover same scope without ownership boundary |
| Manual-review/linter overlap | Narrative repeats deterministic findings without semantic interpretation |
| Host-repo hardcoding in docs | Instructions assume one repository layout without detection/fallback |
| Non-defensive dependency assumptions | Docs require external files/tools without existence guards |

## 6. Structural Optimization

Synthesize findings from Sections 1-5 into actionable restructuring proposals.

### Documentation Principles (reference frame)

Apply these principles when evaluating structure:

1. **Always-loaded file = compressed index**: entry docs should contain pointers and scope descriptions, not full content.
2. **Each document has one clear scope**: if a doc serves multiple unrelated purposes, read/skip decisions degrade.
3. **Agent autonomy for reading, explicit routing for writing**: agents judge relevance; writing needs explicit routing.
4. **Less is more**: instruction-following quality degrades as instruction count rises.
5. **Documentation-as-Code**: single source of truth per fact; link, do not copy.
6. **Non-obvious decisions only**: skip guidance a capable agent would independently infer.
7. **Skills for vertical, docs for horizontal**: skills for action workflows; docs for cross-task knowledge.

### Proposals to produce

| Proposal type | Description |
|---------------|-------------|
| **Merge candidates** | Scope-overlapping docs that should combine into one. Identify primary absorber and secondary files. |
| **Deletion candidates** | Docs whose unique content fits fully elsewhere. |
| **Entry-doc trimming** | Lines that are obvious, automation-redundant, or duplicated downstream. |
| **Signal-to-noise scoring** | For entry docs, assign High/Medium/Low utility per line or bullet. |
| **Target structure** | Before/after comparison of the doc set with clear ownership per file. |
| **Principle compliance** | Rate each remaining doc against principles 1-7 above. |
| **Automation promotion candidates** | Manual findings that should become lint rules, hooks, or scripts. |
| **Portability hardening candidates** | Repository-coupled assumptions that should move to contract or defensive detection logic. |
