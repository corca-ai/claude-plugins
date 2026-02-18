# Plan — run-portability-contract-hardening

## Goal
Implement six portability guardrails so CWF can run in external repositories without implicit dependency on this authoring repository.

## Scope
1. Split gate contracts into portable vs authoring profiles and keep them plugin-local.
2. Add deterministic claim-test mapping contract and validator.
3. Add deterministic change-impact contract and validator.
4. Add generated-hook synchronization validator based on source SHA marker.
5. Add portability fixture regression for host-minimal and authoring-like repos.
6. Integrate unified contract gate into git hooks and Codex post-run checks.

## Success Criteria
- `check-portability-contract.sh --contract auto` selects `authoring` in this repo and `portable` elsewhere.
- Hook and post-run paths execute unified gate with context filtering (`hook` / `post-run`).
- Portable profile is safe in non-authoring repos (no authoring-specific hard dependency).
- Authoring profile retains strict quality gates and deterministic policy checks.
- Setup/reference docs explain policy decisions and contract boundaries.
- Run session produces doc-only ship output (`ship.md`) instead of GitHub actions.

## Verification Plan
- Run shell syntax checks for all modified gate/setup scripts.
- Run direct gate checks (`claim-test`, `change-impact`, `hook-sync`, `portability-fixtures`).
- Run unified gate for `portable`, `auto`, and contexts `manual|hook|post-run`.
- Validate ship-stage artifact gate for run session.
