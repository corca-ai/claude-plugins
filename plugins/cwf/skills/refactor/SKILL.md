---
name: refactor
description: "Multi-mode code and skill review for controlling drift as capability surface grows. Quick scan all plugins, commit-based tidying, contract-driven codebase quick scan, deep-review a single skill, holistic cross-plugin analysis, or docs consistency check. Triggers: \"cwf:refactor\", \"/refactor\", \"tidy\", \"review skill\", \"cleanup code\", \"check docs consistency\""
---

# Refactor (cwf:refactor)

Control drift across code, skills, and docs as teams install and author more capabilities.

**Language**: Write review reports in English. Communicate with the user in their prompt language.

## Quick Reference

```text
cwf:refactor                        Quick scan all marketplace skills
cwf:refactor --include-local-skills Quick scan marketplace + local skills
cwf:refactor --tidy [branch]        Commit-based tidying (parallel sub-agents)
cwf:refactor --codebase             Contract-driven whole-codebase quick scan
cwf:refactor --codebase --deep      Codebase deep review with 4 expert sub-agents
cwf:refactor --skill <name>         Deep review of a single skill (parallel sub-agents)
cwf:refactor --skill --holistic     Cross-plugin analysis (parallel sub-agents)
cwf:refactor --docs                 Documentation consistency review
```

Philosophy:
- `cwf:refactor` (no args) is a maintenance heartbeat for ecosystem-level drift detection.
- `cwf:refactor --skill <name>` is for focused diagnosis when one authored/installed skill needs targeted correction without paying the cost of full holistic analysis.
- Portability is a default review axis across deep, holistic, and docs modes (no extra flag).

## Mode Routing

Parse the user's input:

| Input | Mode |
|-------|------|
| No args | Quick Scan |
| `--tidy` or `--tidy <branch>` | Code Tidying |
| `--codebase` | Codebase Quick Scan |
| `--codebase --deep` | Codebase Deep Review |
| `--include-local-skills` (no other mode flags) | Quick Scan + local skills |
| `--skill <name>` | Deep Review |
| `--skill --holistic` or `--holistic` | Holistic Analysis |
| `--docs` | Docs Review |

## Provenance Sidecars (Required)

Before using any criteria document, verify its provenance sidecar against the current live repository state (current skill/hook counts).

| Criteria | Provenance sidecar |
|----------|--------------------|
| [review-criteria.md](references/review-criteria.md) | [review-criteria.provenance.yaml](references/review-criteria.provenance.yaml) |
| [holistic-criteria.md](references/holistic-criteria.md) | [holistic-criteria.provenance.yaml](references/holistic-criteria.provenance.yaml) |
| [docs-criteria.md](references/docs-criteria.md) | [docs-criteria.provenance.yaml](references/docs-criteria.provenance.yaml) |

Verification command:

```bash
bash {CWF_PLUGIN_DIR}/scripts/provenance-check.sh --level inform --json
```

Provenance verification rules:
- Confirm the mode-relevant sidecar entry exists in the checker output.
- Compare sidecar `skill_count`/`hook_count` with checker `current.skills`/`current.hooks`.
- If the sidecar is missing or stale, continue review but prepend a **Provenance Warning** and include the delta in the report.

---

## Quick Scan Mode (no args)

Resolve session directory (for deterministic artifact persistence) using [references/session-bootstrap.md](references/session-bootstrap.md) with bootstrap key `refactor-quick-scan`.

Run the structural scan script and persist raw output:

```bash
bash {SKILL_DIR}/scripts/quick-scan.sh {REPO_ROOT} > {session_dir}/refactor-quick-scan.json
```

`{REPO_ROOT}` is the git repository root (5 levels up from SKILL.md in marketplace path, or use `git rev-parse --show-toplevel`).

Optional local-skill scope (portability hardening):

```bash
bash {SKILL_DIR}/scripts/quick-scan.sh \
  {REPO_ROOT} \
  --include-local-skills \
  --local-skill-glob ".claude/skills/*/SKILL.md" > {session_dir}/refactor-quick-scan.json
```

Parse the JSON output and present a summary table. Also persist a concise summary to `{session_dir}/refactor-summary.md`:

| Plugin | Skill | Words | Lines | Flags |
|--------|-------|-------|-------|-------|

- For each flagged skill (flag_count > 0), list the specific flags.
- Suggest: "Run `cwf:refactor --skill <name>` for a deep review."
- Include `Mode: cwf:refactor (Quick Scan)` and the scan command in the summary file.

After writing summary artifacts, run deterministic gate:

```bash
bash {CWF_PLUGIN_DIR}/scripts/check-run-gate-artifacts.sh \
  --session-dir "{session_dir}" \
  --stage refactor \
  --strict \
  --record-lessons
```

---

## Code Tidying Mode (`--tidy [branch]`)

Analyze recent commits for safe tidying opportunities — guard clauses, dead code removal, explaining variables. Based on Kent Beck's "Tidy First?" philosophy.

### 1. Get Target Commits

Run the script to get recent non-tidying commits:

```bash
bash {SKILL_DIR}/scripts/tidy-target-commits.sh 5 [branch]
```

- If branch argument provided (e.g., `cwf:refactor --tidy develop`), pass it to the script.
- If no branch specified, defaults to HEAD.

### 2. Parallel Analysis with Sub-agents

**Resolve session directory** using [references/session-bootstrap.md](references/session-bootstrap.md) with bootstrap key `refactor-tidy`.

Apply the [context recovery protocol](../../references/context-recovery-protocol.md) — for each commit N (1-indexed), check `{session_dir}/refactor-tidy-commit-{N}.md`.

For each commit hash that needs analysis, launch a **parallel sub-agent** using Task tool:
- Shared output persistence contract: [agent-patterns.md § Sub-agent Output Persistence Contract](../../references/agent-patterns.md#sub-agent-output-persistence-contract).

```yaml
Task tool:
  subagent_type: general-purpose
  max_turns: 12
```

Each sub-agent prompt:

1. Read `{SKILL_DIR}/references/tidying-guide.md` for techniques, constraints, and output format
2. Analyze commit diff: `git show {commit_hash}`
3. Check if changes still exist: `git diff {commit_hash}..HEAD -- {file}` (skip modified regions)
4. Return suggestions or "No tidying opportunities"
5. **Output Persistence**: Write your complete analysis to: `{session_dir}/refactor-tidy-commit-{N}.md`. At the very end of the file, append this sentinel marker on its own line: `<!-- AGENT_COMPLETE -->`

### 3. Aggregate Results

Read all result files from the session directory (`{session_dir}/refactor-tidy-commit-{N}.md` for each commit) and present:

```markdown
# Tidying Analysis Results

## Commit: {hash} - {message}
- suggestion 1
- suggestion 2

## Commit: {hash} - {message}
- No tidying opportunities
```

---

## Codebase Quick Scan Mode (`--codebase`)

Run a contract-driven quick scan across the repository codebase.

### 0. Resolve or Bootstrap Codebase Contract

Before scanning, resolve the repository-local codebase contract:

```bash
bash {SKILL_DIR}/scripts/bootstrap-codebase-contract.sh --json
```

Behavior:

- Default location: `{artifact_root}/codebase-contract.json`
- If contract is missing: create a draft contract
- If contract exists: do not overwrite unless explicit force is used
- If bootstrap/contract load fails: continue with fallback defaults and prepend a contract warning

Capture metadata for final summary:

- `CONTRACT_STATUS`: `created`, `existing`, `updated`, or `fallback`
- `CONTRACT_PATH`
- `CONTRACT_WARNING` (optional)

Contract spec: [references/codebase-contract.md](references/codebase-contract.md)

For shell strict-mode exceptions, use contract + file pragma dual control:

- contract allowlist: `checks.shell_strict_mode.file_overrides`
- file pragma: `# cwf: shell-strict-mode relax reason="..." ticket="..." expires="YYYY-MM-DD"`

For implementation/regression checks of codebase-contract behavior, run:

```bash
bash {SKILL_DIR}/scripts/check-codebase-contract-runtime.sh
```

### 1. Resolve Session Directory

Use [references/session-bootstrap.md](references/session-bootstrap.md) with bootstrap key `refactor-codebase`.

### 2. Run Contract-Driven Scan and Persist Raw Output

```bash
bash {SKILL_DIR}/scripts/codebase-quick-scan.sh \
  {REPO_ROOT} \
  --contract "{CONTRACT_PATH}" > {session_dir}/refactor-codebase-scan.json
```

`{REPO_ROOT}` is the git repository root (`git rev-parse --show-toplevel`).

[scripts/codebase-quick-scan.sh](scripts/codebase-quick-scan.sh) delegates contract evaluation and findings aggregation to [scripts/codebase-quick-scan.py](scripts/codebase-quick-scan.py) as the backend implementation.

### 3. Summarize Findings

Read `{session_dir}/refactor-codebase-scan.json` and write `{session_dir}/refactor-summary.md` with:

- `Mode: cwf:refactor --codebase`
- Contract metadata (`CONTRACT_STATUS`, `CONTRACT_PATH`, optional `CONTRACT_WARNING`)
- Scope summary (candidate/scanned/excluded files)
- Top findings table: severity, check, file, detail
- If no findings: explicit "No significant codebase tidy risks detected"

After writing summary artifacts, run deterministic gate:

```bash
bash {CWF_PLUGIN_DIR}/scripts/check-run-gate-artifacts.sh \
  --session-dir "{session_dir}" \
  --stage refactor \
  --strict \
  --record-lessons
```

---

## Codebase Deep Review Mode (`--codebase --deep`)

Run codebase quick scan first, then add expert-lens deep review using 4 parallel expert sub-agents.

Full procedure: [references/codebase-deep-review-flow.md](references/codebase-deep-review-flow.md)

Execution contract:
1. Resolve/bootstrap codebase contract (`bootstrap-codebase-contract.sh --json`)
2. Resolve session directory with [references/session-bootstrap.md](references/session-bootstrap.md) (`refactor-codebase-deep`)
3. Run codebase scan to `{session_dir}/refactor-codebase-scan.json`
4. Select experts to `{session_dir}/refactor-codebase-experts.json`
5. Launch 4 parallel experts (Fowler, Beck, Context 1, Context 2) and persist outputs with `<!-- AGENT_COMPLETE -->`
6. Merge scan + expert outputs into `{session_dir}/refactor-summary.md`, then run gate

---

## Deep Review Mode (`--skill <name>`)

Full procedure: [references/deep-review-flow.md](references/deep-review-flow.md)

Execution contract:
1. Locate the target skill, read `SKILL.md` + `references/` + `scripts/` + `assets/`
2. Verify deep-review provenance (`review-criteria.provenance.yaml`)
3. Resolve session directory with [references/session-bootstrap.md](references/session-bootstrap.md) (`refactor-skill`)
4. Launch 2 parallel sub-agents (Structural 1-4, Quality+Concept 5-9) with output persistence sentinel
5. Merge outputs into unified deep report and offer to apply changes

---

## Holistic Mode (`--skill --holistic` or `--holistic`)

Cross-plugin analysis for global optimization. Read ALL skills and hooks, then analyze inter-plugin relationships.

Full procedure: [references/holistic-review-flow.md](references/holistic-review-flow.md)

Execution contract:
1. Build inventory from marketplace skills, hooks, and local skills
2. Verify holistic criteria provenance (`holistic-criteria.provenance.yaml`)
3. Resolve session directory with [references/session-bootstrap.md](references/session-bootstrap.md) (`refactor-holistic`)
4. Launch 3 parallel sub-agents (Convention, Concept, Workflow) with output persistence sentinel
5. Merge to holistic report and discuss prioritization with the user

---

## Docs Review Mode (`--docs`)

Review documentation consistency with this fixed flow:
1. Resolve/bootstrap docs contract (`bootstrap-docs-contract.sh`)
2. Deterministic tool pass (`markdownlint`, local link check, doc-graph)
3. Docs criteria provenance verification
4. Contract-aware entry docs, project context, README, and cross-document consistency review
5. Semantic quality and structural optimization synthesis (portability baseline always on)

Deterministic tool pass uses [scripts/check-links.sh](scripts/check-links.sh) and [scripts/doc-graph.mjs](scripts/doc-graph.mjs) with markdownlint; for docs-contract runtime regression checks, run [scripts/check-docs-contract-runtime.sh](scripts/check-docs-contract-runtime.sh).

Use `{SKILL_DIR}/references/docs-criteria.md` for evaluation criteria, [references/docs-contract.md](references/docs-contract.md) for contract schema, and [references/docs-review-flow.md](references/docs-review-flow.md) for full `--docs` procedure (commands, sequence, and reporting scope).

---

## Rules

1. Write review reports in English, communicate with user in their prompt language
2. Deep Review and Holistic use perspective-based parallel sub-agents (not module-based)
3. Deep Review: 2 agents (structural 1-4 + quality/concept/portability 5-9), single batch
4. Holistic: 3 agents (Convention Compliance, Concept Integrity, Workflow Coherence), single batch after inline inventory
5. Code Tidying: 1 agent per commit, all in one message
6. Codebase Quick Scan: contract-driven deterministic scan, no sub-agents
7. Codebase Deep Review: 4 expert sub-agents (fixed 2 + context 2) after codebase scan
8. Docs Review: inline, no sub-agents (single-context synthesis over whole-repo graph and deterministic outputs)
9. Docs Review must run the deterministic tool pass before semantic analysis
10. In Docs Review, do not report lint/hook-detectable issues as standalone manual findings when tool output already covers them
11. Sub-agents analyze and report; orchestrator merges. Sub-agents do not modify files
12. All code fences must have a language specifier

## References

- Review criteria for deep review: [references/review-criteria.md](references/review-criteria.md)
- Holistic analysis framework: [references/holistic-criteria.md](references/holistic-criteria.md)
- Detailed codebase deep procedure: [references/codebase-deep-review-flow.md](references/codebase-deep-review-flow.md)
- Detailed deep-review procedure: [references/deep-review-flow.md](references/deep-review-flow.md)
- Detailed holistic procedure: [references/holistic-review-flow.md](references/holistic-review-flow.md)
- Concept synchronization map: [concept-map.md](../../references/concept-map.md)
- Tidying techniques for --tidy mode: [references/tidying-guide.md](references/tidying-guide.md)
- Codebase scan contract schema: [references/codebase-contract.md](references/codebase-contract.md)
- Shared session bootstrap snippet: [references/session-bootstrap.md](references/session-bootstrap.md)
- Codebase expert selector script: [scripts/select-codebase-experts.sh](scripts/select-codebase-experts.sh)
- Docs review criteria: [references/docs-criteria.md](references/docs-criteria.md)
- Docs review contract schema: [references/docs-contract.md](references/docs-contract.md)
- Docs review procedure flow: [references/docs-review-flow.md](references/docs-review-flow.md)
- Provenance sidecar (deep criteria): [references/review-criteria.provenance.yaml](references/review-criteria.provenance.yaml)
- Provenance sidecar (holistic criteria): [references/holistic-criteria.provenance.yaml](references/holistic-criteria.provenance.yaml)
- Provenance sidecar (docs criteria): [references/docs-criteria.provenance.yaml](references/docs-criteria.provenance.yaml)
- Shared agent patterns: [agent-patterns.md](../../references/agent-patterns.md)
- Skill conventions checklist: [skill-conventions.md](../../references/skill-conventions.md)
