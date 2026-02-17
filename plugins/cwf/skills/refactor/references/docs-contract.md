# Docs Contract (Draft Schema)

Repository-local contract used by `cwf:refactor --docs` to decide which repository-specific checks should run.

## Purpose

`--docs` always evaluates portability and structural doc quality, but repository-specific checks (for example plugin inventory alignment or locale mirror checks) should be conditional.

This contract captures those conditions in one repository-local file.

## Default Location

`{artifact_root}/docs-contract.yaml`

Path resolution follows CWF artifact rules:

1. `.cwf-config.local.yaml`
2. `.cwf-config.yaml`
3. process env (`CWF_ARTIFACT_ROOT`)
4. fallback: `.cwf`

## Bootstrap Behavior

`bootstrap-docs-contract.sh` creates a draft contract when absent.

- Existing contract is never overwritten unless `--force` is used.
- First run is `mode: advisory` by default.
- If bootstrap write fails, docs review should continue with fallback defaults and warning metadata.

## Fields

| Field | Type | Description |
|---|---|---|
| `version` | number | Schema version for contract evolution. |
| `generated_at_utc` | string | Draft generation timestamp (UTC). |
| `mode` | string | Contract mode (`advisory` or stricter repository policy mode). |
| `entry_docs.required` | list | Required entry docs to evaluate (for example AGENTS.md, README.md). |
| `entry_docs.optional` | list | Optional entry docs to include when present (for example CLAUDE.md). |
| `inventory.project_context_path` | string | Path to project-context style doc, if used. |
| `inventory.plugin_inventory_path` | string | Path to plugin inventory source, if used. |
| `inventory.plugin_manifest_glob` | string | Glob for plugin manifests used in consistency checks. |
| `locale_mirrors[]` | list | Locale mirror pairs to compare (for example README.md ↔ README.ko.md). |
| `checks.portability_baseline` | bool | Always-on portability baseline toggle (should remain true in normal operation). |
| `checks.entry_docs_review` | bool | Enable/disable entry-doc review step. |
| `checks.project_context_review` | bool | Enable/disable project-context review step. |
| `checks.inventory_alignment` | bool | Enable/disable inventory and manifest alignment checks. |
| `checks.locale_mirror_alignment` | bool | Enable/disable locale mirror alignment checks. |
| `reporting.include_contract_metadata` | bool | Include contract path/status in final report. |
| `reporting.include_skipped_checks` | bool | Include skipped checks with reasons. |

## Fallback Defaults (No Contract)

When no contract can be loaded, `--docs` should still run with best-effort defaults:

- Always-on: portability baseline + deterministic gate + semantic structure checks
- Conditional by file existence:
  - Entry docs: AGENTS.md, README.md, CLAUDE.md, README.ko.md
  - Project context: docs/project-context.md
  - Plugin inventory: .claude-plugin/marketplace.json

## Reporting Contract Metadata

Docs review output should include:

- `CONTRACT_STATUS`: `created`, `existing`, `updated`, `fallback`
- `CONTRACT_PATH`: resolved absolute or repository-relative path
- `SKIPPED_CHECKS`: list of contract-disabled or source-missing checks with reasons
- `CONTRACT_WARNING` (optional): bootstrap warning text when fallback/degradation occurred
