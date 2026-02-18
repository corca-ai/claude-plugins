# Codebase Deep Review Flow (`--codebase --deep`)

Run codebase quick scan first, then add expert-lens deep review using 4 parallel expert sub-agents.

## 0. Resolve or Bootstrap Codebase Contract

Use the same contract bootstrap flow as `--codebase`.

```bash
bash {SKILL_DIR}/scripts/bootstrap-codebase-contract.sh --json
```

Contract deep-review policy fields are defined in [codebase-contract.md](codebase-contract.md):

- `deep_review.fixed_experts[]` (mandatory experts)
- `deep_review.context_experts[]` (context expert roster in contract JSON)
- `deep_review.context_expert_count` (additional context experts)

## 1. Resolve Session Directory and Run Codebase Scan

Resolve session directory using [session-bootstrap.md](session-bootstrap.md) with bootstrap key `refactor-codebase-deep`.

```bash
bash {SKILL_DIR}/scripts/codebase-quick-scan.sh \
  {REPO_ROOT} \
  --contract "{CONTRACT_PATH}" > {session_dir}/refactor-codebase-scan.json
```

The wrapper delegates to [../scripts/codebase-quick-scan.py](../scripts/codebase-quick-scan.py); keep both files aligned when changing scan behavior.

## 2. Select Experts (Contract-Driven)

Select experts using deterministic script:

```bash
bash {SKILL_DIR}/scripts/select-codebase-experts.sh \
  --scan "{session_dir}/refactor-codebase-scan.json" \
  --contract "{CONTRACT_PATH}" > "{session_dir}/refactor-codebase-experts.json"
```

Selection policy:

- Always include fixed experts from contract defaults:
  - Martin Fowler
  - Kent Beck
- Add `deep_review.context_expert_count` context-matched experts from `deep_review.context_experts[]`
- If context matches are insufficient, fill from contract roster order

## 3. Parallel Expert Deep Review (4 Sub-agents)

Read `{session_dir}/refactor-codebase-experts.json` and launch one sub-agent per selected expert (single message, parallel).

Output files:

| Expert slot | Output file |
|-------------|-------------|
| Martin Fowler | `{session_dir}/refactor-codebase-deep-fowler.md` |
| Kent Beck | `{session_dir}/refactor-codebase-deep-beck.md` |
| Context Expert 1 | `{session_dir}/refactor-codebase-deep-context-1.md` |
| Context Expert 2 | `{session_dir}/refactor-codebase-deep-context-2.md` |

Each expert sub-agent prompt:

1. Read `{CWF_PLUGIN_DIR}/references/expert-advisor-guide.md` (review mode format)
2. Read `{session_dir}/refactor-codebase-scan.json`
3. Read `{session_dir}/refactor-codebase-experts.json` and adopt assigned expert identity
4. Produce:
   - Top 3 concerns (blocking risks)
   - Top 3 suggestions (high leverage)
   - 1 prioritized first action
5. **Output Persistence**: write to assigned file and append `<!-- AGENT_COMPLETE -->`

## 4. Synthesize Deep Report

Merge scan + four expert outputs into `{session_dir}/refactor-summary.md`:

- `Mode: cwf:refactor --codebase --deep`
- Contract metadata (`CONTRACT_STATUS`, `CONTRACT_PATH`, optional `CONTRACT_WARNING`)
- Scan metrics summary (errors/warnings/check counts)
- Expert roster used (fixed + contextual, with selection reasons)
- Convergent findings (agreements across 2+ experts)
- Divergent findings (framework tensions)
- Prioritized action list (P0/P1/P2)

After writing summary artifacts, run deterministic gate:

```bash
bash {CWF_PLUGIN_DIR}/scripts/check-run-gate-artifacts.sh \
  --session-dir "{session_dir}" \
  --stage refactor \
  --strict \
  --record-lessons
```
