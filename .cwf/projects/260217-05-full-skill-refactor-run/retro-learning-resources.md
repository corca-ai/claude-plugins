# Retro Learning Resources

## Target Skill Gaps
- Deterministic gate design: strengthen machine-checkable pass/fail contracts for schema validation, stage provenance, and ship gating.
- Shell safety in automation: reduce Bash footguns in hook scripts, dependency checks, and worktree cleanup flows.
- Documentation contracts: keep policy enforcement in deterministic tools (schemas/lints/link checks), not narrative-only guidance.
- Workflow orchestration: improve resume-safe stage execution, per-stage provenance, and explicit ambiguity/worktree decisions.

## Curated Resources
| Theme | Resource | Why this helps this repository |
|---|---|---|
| Deterministic gates | JSON Schema Validation (Draft 2020-12): https://json-schema.org/draft/2020-12/json-schema-validation | `scripts/check-schemas.sh` already validates with Draft 2020; this is the canonical source for tightening schema rules in `.cwf/cwf-state.yaml` and hook/plugin manifests. |
| Deterministic gates | ajv-cli documentation: https://github.com/ajv-validator/ajv-cli | The repo uses `npx ajv-cli@5`; this gives exact flags/patterns for stricter CI validation, custom formats, and better machine-readable failure output. |
| Shell safety | ShellCheck: https://www.shellcheck.net/ | Directly applicable to `plugins/cwf/hooks/scripts/*.sh` and skill scripts to catch quoting, word-splitting, and portability bugs before they become runtime gate failures. |
| Shell safety | Bash Pitfalls: https://mywiki.wooledge.org/BashPitfalls | Useful for edge cases seen in orchestration scripts (command substitution, globbing, exit handling), especially where cleanup safety and non-destructive behavior matter. |
| Shell safety | GNU Bash Reference Manual: https://www.gnu.org/software/bash/manual/bash.html | Authoritative behavior reference for `set -euo pipefail`, `source`, traps, and conditionals used across deterministic gate scripts. |
| Documentation contracts | Diataxis framework: https://diataxis.fr/ | Helps separate policy/reference/process docs so SKILL contracts stay precise and drift-resistant as workflow surface area grows. |
| Documentation contracts | markdownlint rules and config: https://github.com/DavidAnson/markdownlint | Provides deterministic markdown policy gates that complement existing schema/link checks and reduce review-time style ambiguity. |
| Documentation contracts | lychee link checker: https://github.com/lycheeverse/lychee | Matches current `check-links.sh` dependency; useful for tightening URL health checks and making docs gate failures reproducible. |
| Workflow orchestration | git-worktree manual: https://git-scm.com/docs/git-worktree | Directly supports the `explore-worktrees` mode and safe cleanup requirements in `run` skill orchestration. |
| Workflow orchestration | SLSA Provenance v1 spec: https://slsa.dev/spec/v1.0/provenance | Good model for evolving `run-stage-provenance.md` from basic logs to stronger provenance fields (who/what/when/how inputs/outputs). |

## Application Notes
1. Deterministic gates: add a schema/parser gate for `run-stage-provenance.md` row semantics (stage-skill mapping, timestamp shape, gate outcome enum), not just file existence.
2. Shell safety: introduce a `shellcheck` gate for hook and skill scripts; fail on new high-severity findings, warn on legacy debt until cleaned.
3. Documentation contracts: add markdownlint as a deterministic doc gate alongside existing link/schema checks; keep prose guidance minimal and tool-enforced.
4. Workflow orchestration: extend stage provenance fields and checks to include retry count, reviewer/tool provenance, and ambiguity decision linkage.
5. Review loop quality: treat these resources as implementation references, then codify the decisions in scripts/schemas so future sessions recover from artifacts, not memory.

<!-- AGENT_COMPLETE -->
