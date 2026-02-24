## Security Review

### Concerns (blocking)
- **[C1] Missing explicit authorization boundary for autonomous GitHub triggers (untrusted actors can initiate privileged automation).**
  Reference: `## Scope Summary` (direct automatic handling), `### Step 5 — cwf watch Automatic Handling` (`issues.opened`, `issue_comment.created`), `## Decision Log` #5 (direct automation), and `## Success Criteria -> Behavioral` (watch auto-route criterion).
  Risk: External issue/comment actors may trigger privileged automation (branch/PR/comment operations) and consume runner resources.
  Required fix in plan: define pre-routing authz checks (actor role allowlist, repo permission check, trusted label/slash-command gate, fork-origin policy) before entering implementation flow.
  Severity: security

- **[C2] Prompt-injection and command-injection controls are not specified for issue/comment content used by agents and shell execution.**
  Reference: `### Step 2 — cwf run Core Orchestration` (prompt vs issue URL), `### Step 3 — Six-Stage Loop` (agent execution), `### Step 4 — GitHub Integration in run`, `### Step 5 — cwf watch Automatic Handling`, `## Evidence Gap List` (triage heuristic missing), and `## Deferred Actions` (classification still deferred).
  Risk: Malicious issue/comment text can steer agent behavior toward unsafe commands, data exfiltration, or workflow tampering.
  Required fix in plan: define untrusted-input handling (strict URL allowlist/canonicalization, content delimiting, stdin-based prompt passing, forbidden-command policy, and escalation path for unsafe instructions).
  Severity: security

- **[C3] Secret handling and GitHub token least-privilege policy are absent despite workflow automation scope.**
  Reference: `### Create` (`.github/workflows/cwf-watch.yml`), `### Step 4` (issue/PR automation), `### Step 5` (event automation), and `## Validation Plan` (watch smoke tests only).
  Risk: Over-scoped tokens and secret leakage via logs/comments/artifacts.
  Required fix in plan: add mandatory `permissions:` policy per workflow job, secret source/rotation rules, masking/redaction requirements, and an explicit rule that secrets never appear in issue/PR comments.
  Severity: security

- **[C4] Runner execution sandbox and command boundary are under-specified for agent-driven execution.**
  Reference: `## Scope Summary` (agent mapping to `codex exec` / `claude -p`), `### Step 0 — Runner Contract and Safety Baseline` (contract fields), `### Step 3` (execute/review/refactor loop), and `### Target State` (gate simplification).
  Risk: Agent-produced actions may run with excessive filesystem/network privileges and mutate sensitive state.
  Required fix in plan: extend runner contract with sandbox policy (allowed directories, command allow/deny rules, env allowlist, network policy, resource caps) and enforce it in stage gates.
  Severity: security

- **[C5] Gate-slimming can regress mandatory security checks without a preserved baseline.**
  Reference: `### Step 6 — Remove cwf:run Skill and Slim Gates` (simplify workflow gate logic) and `### Migration Principle` (deterministic scripts authoritative).
  Risk: Security-critical checks can be accidentally removed during simplification.
  Required fix in plan: define a non-removable security gate baseline (authz checks, untrusted-input checks, token-scope checks, branch/worktree integrity checks) before gate slimming.
  Severity: security

### Suggestions (non-blocking)
- **[S1] Add a dedicated `Threat Model & Trust Boundaries` section.**
  Suggested placement: after `## Architecture Direction`.
  Include actors, assets, trust boundaries, and abuse cases for `run` and `watch`.

- **[S2] Add security-specific BDD criteria next to current behavioral criteria.**
  Reference: `## Success Criteria -> Behavioral (BDD)`.
  Add explicit scenarios for unauthorized actor rejection, prompt-injection neutralization, secret-safe logging, and least-privilege workflow permissions.

- **[S3] Extend validation with adversarial security smoke tests.**
  Reference: `## Validation Plan`.
  Add payload replay cases for injection strings, malformed/non-GitHub issue URLs, fork-origin PR comments, and bot-loop spoof attempts.

- **[S4] Add immutable audit provenance fields to bot actions/comments.**
  Reference: `### Step 4` and `### Step 5`.
  Persist actor, event id, classifier output, and gate decisions for incident response.

### Behavioral Criteria Assessment
- [ ] `Given a prepared repository with setup readiness ... Then it creates an initial issue ...` — Functional flow is specified, but security preconditions (authz boundary, token scope, secret-safe outputs) are not specified in `Step 4`.
- [ ] `Given an existing GitHub issue URL ... Then it uses the issue ...` — `Step 2` defines prompt vs URL parsing but does not define trust policy/allowlist for the URL source.
- [x] `Given a stage is running ... Then no more than 3 commits ...` — Deterministic commit cap and non-empty diff policy are explicit in `Step 3` and `Commit Strategy`.
- [x] `Given stage gate checks fail ... Then cwf run stops ...` — Deterministic halt behavior is explicit in BDD and `Step 3`.
- [ ] `Given cwf watch is enabled ... Then the workflow automatically routes ...` — Auto-routing exists, but secure classification/authz controls are not finalized (`Evidence Gap List`, `Deferred Actions`).
- [x] `Given run-skill migration is complete ... Then interactive users invoke other CWF skills ...` — Compatibility criterion is explicit and security-neutral.

### Provenance
source: REAL_EXECUTION
tool: codex-cli
reviewer: Security
duration_ms: —
command: `sed -n '1,260p' .cwf/projects/260224-02-cwf-cli-run-watch-orchestration/plan.md` and `nl -ba .cwf/projects/260224-02-cwf-cli-run-watch-orchestration/plan.md`
<!-- AGENT_COMPLETE -->
