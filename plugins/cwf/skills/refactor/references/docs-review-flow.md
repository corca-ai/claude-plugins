# Docs Review Procedure Flow

Detailed `--docs` mode procedure for `cwf:refactor`.

This reference preserves the full deterministic tool pass and semantic review sequence. `SKILL.md` keeps only routing/invariant summaries and links here.

## Docs Review Mode (`--docs`)

Review documentation consistency across the repository.

### 1. Deterministic Tool Pass (Required First)

Before proposing any new documentation rule, run this placement gate:

- `AUTO_EXISTING`: already enforced by lint/hook/script → remove prose duplication, do not add rule text.
- `AUTO_CANDIDATE`: enforceable via lint/hook/script but missing automation → propose automation change first, do not add prose rule text.
- `NON_AUTOMATABLE`: judgment-only guidance → keep as concise principle with rationale.

Only `NON_AUTOMATABLE` items should become or remain documentation rules.

Run deterministic checks before semantic review:

```bash
npx --yes markdownlint-cli2 "**/*.md"
bash {SKILL_DIR}/scripts/check-links.sh --local --json
node {SKILL_DIR}/scripts/doc-graph.mjs --json
```

Use tool output as the source of truth for lint-level issues.

- If a tool is unavailable, report a tooling gap and continue with best-effort semantic review.
- Do not restate lint-level findings manually unless you add repository-level interpretation or restructuring impact.

### 1.5 Verify docs criteria provenance

Before semantic checks that rely on docs criteria, run:

```bash
bash {CWF_PLUGIN_DIR}/scripts/provenance-check.sh --level inform --json
```

Confirm [docs-criteria.provenance.yaml](docs-criteria.provenance.yaml) is present and fresh against current skill/hook counts. If stale, continue review but include a provenance warning in the final docs report.

### 2. Agent Entry Docs Review

Read the project's AGENTS.md (and runtime adapter docs like CLAUDE.md) and evaluate with `{SKILL_DIR}/references/docs-criteria.md` Section 1:

- Compressed-index shape
- Less-is-more signal quality (line-level high/medium/low utility scoring across the full file, not intro-only)
- What/why versus how boundary
- Document-role clarity (each linked doc is defined by what it is, not procedural trigger phrasing)
- Routing duplication minimization (avoid repeated listing of the same targets across sections unless purpose differs materially)
- Automation-redundant instructions
- Routing completeness
- Accuracy and staleness

### 3. Project Context Review

Read docs/project-context.md and check:

- Plugin listing matches actual plugins/ directory contents
- Architecture patterns are current (no references to removed/renamed plugins)
- Convention entries match actual practice

### 4. README Review

Read README.md and README.ko.md:

- Plugin overview table matches `marketplace.json` entries
- Each active plugin has install/update commands
- Deprecated plugins are clearly marked
- Korean version mirrors English structure and content

### 5. Cross-Document Consistency

Check alignment between:

- .claude-plugin/marketplace.json plugin list ↔ README overview table
- .claude-plugin/marketplace.json descriptions ↔ plugin manifest descriptions under plugins/
- docs/project-context.md plugin listing ↔ actual plugins/ contents
- Entry-doc references ↔ actual filesystem paths
- Root-relative internal links (leading-slash paths like /path/to/doc.md) ↔ portability check (prefer file-relative links)

Present findings as a prioritized list of inconsistencies with suggested fixes.

### 6. Document Design Quality (Semantic Layer)

Read `{SKILL_DIR}/references/docs-criteria.md` Section 5 and evaluate semantic/structural issues that deterministic tools cannot fully judge:

- Orphan intent and ownership boundary quality (using doc-graph output)
- Circular references or deep navigation paths (>3 hops)
- Inline overload (substantive content that should be a separate doc)
- Unnecessary hard wraps in prose (especially when MD013 is disabled)
- Auto-generated files committed to git
- Non-obvious decisions lacking documented rationale
- Self-evident or automation-redundant instructions
- Scope overlap and ownership ambiguity

### 7. Structural Optimization

Read `{SKILL_DIR}/references/docs-criteria.md` Section 6 and synthesize:

- Merge candidates (scope-overlapping docs → identify primary absorber)
- Deletion candidates (unique content fits elsewhere)
- AGENTS/adapter trimming proposals (obvious + automation-redundant + duplicated)
- Target structure: before/after doc set comparison
- Principle compliance: rate each doc against the 7 documentation principles
- Automation promotion candidates (manual findings that should move to lint/hooks/scripts)

Present as a concrete restructuring proposal with rationale.
