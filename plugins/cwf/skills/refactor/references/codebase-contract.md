# Codebase Contract (Draft Schema)

Repository-local contract used by `cwf:refactor --codebase` to define scope and thresholds for whole-codebase quick scans.

## Purpose

`--codebase` should not hardcode one repository layout. This contract lets each repository declare:

- Which files are in scan scope
- Which checks are enabled
- Thresholds for warnings/errors

## Default Location

`{artifact_root}/codebase-contract.json`

Path resolution follows CWF artifact rules:

1. `.cwf-config.local.yaml`
2. `.cwf-config.yaml`
3. process env (`CWF_ARTIFACT_ROOT`)
4. fallback: `.cwf`

## Bootstrap Behavior

`bootstrap-codebase-contract.sh` creates a draft contract when absent.

- Existing contract is never overwritten unless `--force` is used.
- First run is advisory defaults.
- If bootstrap write fails, codebase scan should continue with fallback defaults and warning metadata.

## Fields

| Field | Type | Description |
|---|---|---|
| `version` | number | Schema version for contract evolution. |
| `generated_at_utc` | string | Draft generation timestamp (UTC). |
| `mode` | string | Contract mode (`advisory` or stricter repository policy mode). |
| `source.git_tracked_only` | bool | Prefer `git ls-files` (tracked files only) when true. |
| `scope.include_globs[]` | list | Repository-relative include globs. |
| `scope.exclude_globs[]` | list | Repository-relative exclude globs. |
| `scope.include_extensions[]` | list | Extension allowlist for scan candidates. |
| `checks.large_file_lines` | object | Large file threshold check (`warn_at`, `error_at`). |
| `checks.long_line_length` | object | Long line check (`warn_at`). |
| `checks.todo_markers` | object | TODO/FIXME marker detection patterns. |
| `checks.shell_strict_mode.enabled` | bool | Shell strict-mode check toggle. |
| `reporting.top_findings_limit` | number | Maximum findings per severity in final output. |

## Fallback Defaults (No Contract)

When no contract can be loaded, `--codebase` should still run with best-effort defaults:

- Source: tracked files when git is available; otherwise filesystem walk
- Scope: include all files, exclude common generated/non-code paths
- Checks: large files, long lines, TODO markers, shell strict mode

## Reporting Contract Metadata

Codebase scan output should include:

- `contract.status`: `loaded` or `fallback`
- `contract.path`: resolved contract path
- `contract.warning` (optional): fallback/parse warning text
