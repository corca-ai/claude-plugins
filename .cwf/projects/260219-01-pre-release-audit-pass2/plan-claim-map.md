# Claim-to-Implementation Mapping (SoT & Portability)

> Evidence only; no interpretation.

## Claim 1 — README.ko is the user-facing policy single source of truth
- Source documents:
  - `README.md:3-6` (SoT disclaimer pointing to README.ko as the authoritative policy record).
  - `README.ko.md:1-6` (Korean disclaimer describing this file as the SSOT and asking for mismatch reports).
- Implementation evidence:
  1. `plugins/cwf/contracts/claims.json:5-25` — direct: the `readme_ko_sot` claim stores the assertion and links to README/README.ko for verification, plus ties to `check-readme-structure.sh` as its test.
  2. `plugins/cwf/scripts/check-readme-structure.sh:1-160` — direct: the strict heading-parity check referenced by the claim keeps the English/Korean READMEs aligned so the SSOT declaration remains valid.

## Claim 2 — Adaptive Setup Contract keeps runtime portable while allowing repo-specific tooling
- Source documents:
  - `README.md:149-153` (Adaptive Setup Contract described as keeping setup portable with repo-specific tool proposals).
  - `README.ko.md:130-142` (Korean equivalent describing the same adaptive, portable setup contract).
- Implementation evidence:
  1. `plugins/cwf/skills/setup/references/setup-contract.md:7-130` — direct: details bootstrap goals, the core dependency baseline, repo-tool suggestions, `policy.hook_index_coverage_mode`, and the approval prompt flow.
  2. `plugins/cwf/skills/setup/scripts/check-setup-contract-runtime.sh:1-90` — direct: end-to-end runtime check covering creation, idempotence, forced update, fallback, and repo_tool detection (e.g., `yq`).
  3. `plugins/cwf/contracts/portable-contract.json:1-18` — direct: portable gate definition with the `setup_contract_runtime` and `portability_fixtures` checks referenced by the setup contract claim.
  4. `plugins/cwf/contracts/authoring-contract.json:1-60` — direct: authoring gate definition layering claim/test mapping, change impact, hook sync, script deps, growth drift, provenance, and README structure checks on top of the portable baseline.
  5. `plugins/cwf/scripts/check-portability-contract.sh:7-174` — direct: unified gate runner defaulting `auto` → portable, resolving contract paths, filtering by context, and executing each check entry.
  6. `plugins/cwf/scripts/check-portability-fixtures.sh:1-90` — direct: regression fixtures proving host-minimal repos skip index coverage while authoring repos run blocking index coverage, exercising the portable/authoring split.
  7. `plugins/cwf/skills/setup/scripts/configure-git-hooks.sh:4-200` — direct: installs `.githooks`, renders templates per profile, and surfaces the hook installation surface through which the portability policy executes.
  8. `plugins/cwf/skills/setup/assets/githooks/pre-push.template.sh:150-320` — direct: the pre-push hook template reads `hook_index_coverage_mode`, conditionally runs index coverage, invokes the unified portability gate, and enforces authoring-only checks under the `strict` profile.

## Top 10 Claim-Risk Areas Requiring Verification
1. `plugins/cwf/scripts/check-readme-structure.sh:1-160` — confirm the parity safeguard still runs when README/README.ko change so the SSOT assertion does not drift.
2. `plugins/cwf/contracts/claims.json:5-25` — verify the `readme_ko_sot` claim entry stays accurate and that the associated tests cover the right files after documentation edits.
3. `plugins/cwf/skills/setup/scripts/check-setup-contract-runtime.sh:1-90` — rerun to ensure the bootstrap still reports `created`/`existing`/`updated`/`fallback` statuses and detects repo-specific tools in generic host repos.
4. `plugins/cwf/skills/setup/references/setup-contract.md:7-130` — re-review policy fields (core/repo tools, hook coverage mode, install hints) whenever portability needs evolve.
5. `plugins/cwf/contracts/portable-contract.json:1-18` — confirm the portable profile still only lists the fail/warn gates safe for arbitrary host repositories.
6. `plugins/cwf/contracts/authoring-contract.json:1-60` — verify the authoring profile continues to layer claim/test mapping, change-impact, hook sync, and README-structure checks over the portable baseline.
7. `plugins/cwf/scripts/check-portability-contract.sh:7-174` — verify the runner still defaults `auto` to the portable contract and respects `--context` filters so hooks/resources execute the intended gate.
8. `plugins/cwf/scripts/check-portability-fixtures.sh:1-90` — rerun fixtures after changes to ensure host vs authoring behavior (skip vs enforce index coverage) remains reliable.
9. `plugins/cwf/skills/setup/scripts/configure-git-hooks.sh:4-200` — verify the hook profiles (`fast`, `balanced`, `strict`) and template rendering still align with portable/authoring expectations and do not hardcode repo-specific paths.
10. `plugins/cwf/skills/setup/assets/githooks/pre-push.template.sh:150-320` — confirm the pre-push hook still respects `hook_index_coverage_mode`, runs the unified portability gate, and only exercises authoring-only strict checks when appropriate.

<!-- AGENT_COMPLETE -->
