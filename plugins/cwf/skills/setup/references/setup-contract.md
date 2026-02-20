# Setup Contract Bootstrap

Detailed procedure reference for setup-contract generation and approval in `cwf:setup`.

`SKILL.md` remains the workflow router and invariant contract. Use this file for concrete command templates, status handling, and prompt text.

## Goal

Generate a repository-local setup contract on first setup so `cwf:setup` can:

- keep a deterministic core dependency baseline for CWF runtime gates,
- propose repository-specific tooling separately (opt-in),
- avoid hidden coupling between portable plugin behavior and host-repo conventions.
- make repository-specific git-hook checks policy-driven via contract fields.

## Hook Policy Field

`setup-contract.yaml` includes `policy.hook_index_coverage_mode` to control pre-push index coverage behavior:

- `authoring-only` (default): run index coverage only for CWF authoring repos
- `always`: run index coverage for all repositories
- `warn`: run index coverage but do not fail push on violations
- `off`: skip index coverage entirely

When the field is missing, runtime defaults to `authoring-only`.

## Hook Extension Field

`setup-contract.yaml` includes `hook_extensions.pre_push` so repositories can add local pre-push logic without editing generated hook code:

```yaml
hook_extensions:
  pre_push:
    path: ""
    required: false
```

- `path`: relative to repo root (or absolute path) for the extension script.
- `required: true`: missing/failing extension blocks push.
- `required: false`: missing/failing extension is reported and skipped (non-blocking).

When `path` is empty or missing, extension execution is skipped.

## Policy Decision: Portable vs Authoring Contracts

Git hook and post-run gates use a contract split so CWF remains repository-agnostic:

- [plugins/cwf/contracts/portable-contract.json](../../../contracts/portable-contract.json): safe baseline checks for arbitrary host repositories.
- [plugins/cwf/contracts/authoring-contract.json](../../../contracts/authoring-contract.json): stricter checks that depend on CWF authoring-repo structure.

`check-portability-contract.sh --contract auto` always selects `portable`.

Authoring checks remain available via explicit selection:

- `bash plugins/cwf/scripts/check-portability-contract.sh --contract authoring --context <manual|hook|post-run>`
- `bash scripts/check-cwf-authoring-contract.sh` (this repository maintainer wrapper)

This keeps runtime dependency direction one-way (`repo -> cwf`, not `cwf -> this repo`) and prevents layout-based auto-detection coupling.

### Audience boundary for policy IDs

Claim IDs and test IDs belong in machine-readable contracts (`claims.json`, `change-impact.json`) instead of user-facing README text or SKILL flow prose. This preserves deterministic traceability without leaking low-signal identifiers into conversational guidance.

## Contract Location and Status

Default command:

```bash
bash {SKILL_DIR}/scripts/bootstrap-setup-contract.sh --json
```

Default path:

- `{artifact_root}/setup-contract.yaml` (typically under the repository `.cwf` artifact root)

Status values:

- `created`: first draft contract generated this run
- `existing`: contract already present; no overwrite
- `updated`: existing contract refreshed via `--force`
- `fallback`: bootstrap failed (for example, path/write failure); stop and fix before continuing

## First-Run Flow (Required)

1. Run bootstrap command and parse `status`, `path`, `warning`.
2. If status is `created` or `updated`, summarize:
   - core tools (always-on baseline)
   - detected `repo_tools` (opt-in suggestions)
3. Ask user whether to apply repo-specific suggestions now.

Prompt text:

```text
Setup contract draft is ready. Apply repository-specific tool suggestions now?
```

Options:

- `Apply suggested repo tools now (recommended for this repo)`
  - install missing suggested tools that are supported by installer
  - re-check and report unresolved items
- `Keep proposal only`
  - keep contract file, no install mutation
- `Skip repo-specific suggestions`
  - continue with core-only baseline

## Install Path

Core baseline install (always valid):

```bash
bash {SKILL_DIR}/scripts/install-tooling-deps.sh --install missing
```

Repo-specific install (example, from contract `repo_tools`):

```bash
bash {SKILL_DIR}/scripts/install-tooling-deps.sh --install yq,rg
```

After install attempt, re-check baseline:

```bash
bash {SKILL_DIR}/scripts/install-tooling-deps.sh --check
```

## Fallback Behavior

If bootstrap returns `fallback`:

- stop setup flow immediately (fail-safe),
- report `warning` text,
- request path/permission fix and rerun bootstrap.

Example report line:

```text
setup-contract: fallback (bootstrap failed); reason: <warning>
```

## Runtime Validation

For regression checks of setup-contract behavior, run:

```bash
bash {SKILL_DIR}/scripts/check-setup-contract-runtime.sh
```
