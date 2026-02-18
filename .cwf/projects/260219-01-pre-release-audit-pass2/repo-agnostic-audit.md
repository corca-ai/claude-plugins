# Repository-Agnostic Audit (Pass 2)

## Findings Table
| Severity | File:Line | Impact | Hardening |
| --- | --- | --- | --- |
| High | `plugins/cwf/skills/setup/scripts/bootstrap-setup-contract.sh:385-437` | Any failure to create the artifact root or render/write `setup-contract.yaml` is swallowed (`status=fallback` with exit 0) so `cwf:setup` continues without a repo-local contract, silently dropping repo-specific tooling proposals and hook-index expectations. | Treat `fallback` as a blocking event: surface the warning in `cwf-state.yaml`, halt the run until the filesystem issue is fixed, and/or require an explicit retry so the contract exists for downstream phases. |
| Medium | `plugins/cwf/skills/refactor/scripts/bootstrap-codebase-contract.sh:331-360` | The `codebase-contract` bootstrap mirrors the same fail-open pattern; if it cannot create the contract the quick-scan proceeds with fallback defaults, meaning `cwf:refactor --codebase` can report findings without any tailored scope or strict-mode guidance. | Record the `fallback` status in the session summary and fail the scan early (or at least skip contract-sourced checks) so reviewers know the scan ran without a repo-specific contract rather than assuming the default policy. |
| Medium | `plugins/cwf/hooks/scripts/check-markdown.sh:157-160` | When `markdownlint-cli2` is missing the hook exits cleanly, leaving large Markdown changes unlinted on hosts that do not have the dependency installed. | Log a one-time warning or suggest installing markdownlint during `cwf:setup` so the absence of the dependency does not silently disable Markdown coverage. |

## Contract/Bootstrap Verification
- **Setup**: `cwf:setup` enforces the setup-contract invariant (`rules 2.8-2.10` plus rule 8 in [plugins/cwf/skills/setup/SKILL.md:447-457]). It always runs `scripts/bootstrap-setup-contract.sh --json`, reports the `created|existing|updated|fallback` status, and is meant to drive the repo-specific tool proposal described in `references/setup-contract.md`. The runtime check `scripts/check-setup-contract-runtime.sh` exercises the `created/existing/updated/fallback` paths so the flow is already guarded.
- **Refactor**: `cwf:refactor --codebase` begins by bootstrapping `codebase-contract.json` (`plugins/cwf/skills/refactor/SKILL.md:163-200`) and captures the contract metadata before scanning. The companion `scripts/check-codebase-contract-runtime.sh` verifies the same lifecycle states, so the first-run contract is detectable before any deep review occurs.
- **Update**: The update workflow resolves scope before any mutation (`plugins/cwf/skills/update/SKILL.md:19-37`) and refuses to default to `user` when detection fails; missing scopes or non-installed targets stop the run. This makes the first interaction with a new repo safe because scope selection and confirmations occur before installing or updating Codex artifacts.

## Fail-open vs fail-safe patterns
- **Fail-open**: Both `bootstrap-setup-contract.sh` and `bootstrap-codebase-contract.sh` emit `fallback` metadata and exit 0 whenever directory creation, tempfile allocation, or file writes fail (`setup:385-437`, `refactor:331-360`). These loops are intentionally non-blocking so that the rest of the skill can proceed even when the contract cannot be stored, but that means later stages might operate without the expected contract data.
- **Fail-open (hooks)**: PostToolUse hooks such as `check-markdown` also bail out when dependencies (e.g., `markdownlint-cli2`) are missing (`check-markdown:157-160`), so lint enforcement is invisible on machines lacking the tooling.
- **Fail-safe**: `scripts/check-portability-contract.sh:108-115` treats missing or malformed contracts as fatal (`fail`), ensuring gating commands only run when contracts load successfully; this is the opposite posture, preventing a host from skipping portable checks accidentally.

## Priority remediation
1. **Hard fail on contract bootstrap fallback**: Upgrade `bootstrap-setup-contract.sh` and `bootstrap-codebase-contract.sh` to stop the skill when they cannot emit a contract (or at least surface a forced retry path) so users know the repository remains uncontracted.
2. **Surface missing hooks tooling**: Follow `check-markdown` with a warning state (preferably in `cwf-state.yaml` or `lessons.md`) and include the missing dependency in the setup-contract report so `cwf:setup` can drive installation instead of letting lint gates be silently disabled.
3. **Document fail-open trade-offs**: Call out the fallback behavior in repo-facing docs (e.g., `references/setup-contract.md`) so maintainers understand when `fallback` appears in the logs and how to rerun the bootstrap properly, keeping portability assumptions explicit.

<!-- AGENT_COMPLETE -->
