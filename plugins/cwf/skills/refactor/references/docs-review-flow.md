# Docs Review Procedure Flow

Detailed `--docs` mode procedure for `cwf:refactor`.

This reference preserves the full deterministic tool pass and semantic review sequence. `SKILL.md` keeps only routing/invariant summaries and links here.

## Docs Review Mode (`--docs`)

Review documentation consistency across the repository with portability baseline always enabled.

### 0. Resolve or Bootstrap Docs Contract

Before semantic checks, resolve the repository docs contract.

Default command:

```bash
bash {SKILL_DIR}/scripts/bootstrap-docs-contract.sh --json
```

Behavior:

- If contract is missing: create draft contract at `{artifact_root}/docs-contract.yaml`.
- If contract exists: do not overwrite (unless explicit force is used outside standard flow).
- If bootstrap or contract parsing fails: continue review with fallback defaults and prepend a contract warning.

Capture metadata for final report:

- `CONTRACT_STATUS`: `created`, `existing`, `updated`, or `fallback`
- `CONTRACT_PATH`
- `SKIPPED_CHECKS` (disabled-by-contract or source-missing checks)
- `CONTRACT_WARNING` (optional bootstrap degradation warning)

Contract spec: [docs-contract.md](docs-contract.md)

For implementation/regression checks of docs-contract behavior, run:

```bash
bash {SKILL_DIR}/scripts/check-docs-contract-runtime.sh
```

### 1. Deterministic Tool Pass (Required First)

Before proposing any new documentation rule, run this placement gate:

- `AUTO_EXISTING`: already enforced by lint/hook/script -> remove prose duplication, do not add rule text.
- `AUTO_CANDIDATE`: enforceable via lint/hook/script but missing automation -> propose automation change first, do not add prose rule text.
- `NON_AUTOMATABLE`: judgment-only guidance -> keep as concise principle with rationale.

Only `NON_AUTOMATABLE` items should become or remain documentation rules.

Run deterministic checks before semantic review:

```bash
npx --yes markdownlint-cli2 "**/*.md"
bash {SKILL_DIR}/scripts/check-links.sh --local --json
node {SKILL_DIR}/scripts/doc-graph.mjs --json
```

Dependency note:

- `check-links.sh` requires `lychee`; if unavailable, record a tooling gap and continue semantic review.

Use tool output as the source of truth for lint-level issues.

- If a tool is unavailable, report a tooling gap and continue with best-effort semantic review.
- Do not restate lint-level findings manually unless you add repository-level interpretation or restructuring impact.

### 1.5 Verify docs criteria provenance

Before semantic checks that rely on docs criteria, run:

```bash
bash {CWF_PLUGIN_DIR}/scripts/provenance-check.sh --level inform --json
```

Confirm [docs-criteria.provenance.yaml](docs-criteria.provenance.yaml) is present and fresh against current skill/hook counts. If stale, continue review but include a provenance warning in the final docs report.

### 2. Agent Entry Docs Review (Contract-Driven)

Run only when contract `checks.entry_docs_review` is true.

- Resolve entry docs from contract `entry_docs.required` and `entry_docs.optional`.
- Evaluate each resolved entry doc with `{SKILL_DIR}/references/docs-criteria.md` Section 1.
- If an entry doc path is configured but missing, record it in `SKIPPED_CHECKS` with reason `missing_source`.
- If the check is disabled by contract, add `entry_docs_review: disabled_by_contract` to `SKIPPED_CHECKS`.

### 3. Project Context Review (Conditional)

Run when both conditions are true:

- Contract `checks.project_context_review` is true.
- Contract `inventory.project_context_path` resolves.

When conditions pass, validate plugin/context alignment with `{SKILL_DIR}/references/docs-criteria.md` Section 2.

When either condition fails, add `project_context_review` to `SKIPPED_CHECKS` with reason `disabled_by_contract` or `missing_source`.

### 4. README and Locale Mirror Review (Conditional)

If README.md exists, evaluate README quality using `{SKILL_DIR}/references/docs-criteria.md` Section 3 baseline checks.

Locale mirror checks are conditional and require all conditions:

- Contract `checks.locale_mirror_alignment` is true.
- Contract `locale_mirrors[]` has at least one pair with `enabled: true`.
- Both files in each enabled pair resolve.

When conditions pass, validate mirror structure/content alignment.

When conditions fail, add `locale_mirror_alignment` to `SKIPPED_CHECKS` with reason `disabled_by_contract` or `missing_source`.

### 5. Cross-Document Consistency (Conditional + Always-On)

Always check:

- Entry-doc references -> actual filesystem paths
- Root-relative internal links (leading-slash paths like /path/to/doc.md) -> portability risk (prefer file-relative links)

Inventory consistency checks are conditional and require all conditions:

- Contract `checks.inventory_alignment` is true.
- Contract `inventory.plugin_inventory_path` resolves.
- Contract `inventory.plugin_manifest_glob` resolves to at least one manifest file.

- Plugin inventory source <-> README overview
- Plugin inventory source <-> plugin manifest descriptions
- Project-context plugin listing <-> actual plugin directories

When any inventory condition fails, add `inventory_alignment` to `SKIPPED_CHECKS` with reason `disabled_by_contract`, `missing_source`, or `empty_manifest_set`.

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
- Portability baseline risks (host-repo hardcoding, non-defensive assumptions)

### 7. Structural Optimization

Read `{SKILL_DIR}/references/docs-criteria.md` Section 6 and synthesize:

- Merge candidates (scope-overlapping docs -> identify primary absorber)
- Deletion candidates (unique content fits elsewhere)
- AGENTS/adapter trimming proposals (obvious + automation-redundant + duplicated)
- Target structure: before/after doc set comparison
- Principle compliance: rate each doc against the 7 documentation principles
- Automation promotion candidates (manual findings that should move to lint/hooks/scripts)

Present as a concrete restructuring proposal with rationale, including contract metadata (`CONTRACT_STATUS`, `CONTRACT_PATH`, `SKIPPED_CHECKS`).
