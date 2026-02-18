# Setup Contract Bootstrap

Detailed procedure reference for setup-contract generation and approval in `cwf:setup`.

`SKILL.md` remains the workflow router and invariant contract. Use this file for concrete command templates, status handling, and prompt text.

## Goal

Generate a repository-local setup contract on first setup so `cwf:setup` can:

- keep a deterministic core dependency baseline for CWF runtime gates,
- propose repository-specific tooling separately (opt-in),
- avoid hidden coupling between portable plugin behavior and host-repo conventions.

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
- `fallback`: bootstrap degraded (for example, path/write failure); continue setup with core defaults

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

- continue setup using core dependency defaults,
- report `warning` text,
- suggest manual rerun after environment/path issues are resolved.

Example report line:

```text
setup-contract: fallback (using core defaults); reason: <warning>
```

## Runtime Validation

For regression checks of setup-contract behavior, run:

```bash
bash {SKILL_DIR}/scripts/check-setup-contract-runtime.sh
```
