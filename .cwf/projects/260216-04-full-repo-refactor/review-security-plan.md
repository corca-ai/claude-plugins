# Security Review: review-and-prevention.md (260217-01)

**Target**: `/home/hwidong/codes/claude-plugins/.cwf/projects/260217-01-refactor-review/review-and-prevention.md`
**Scope**: Prevention proposals A through G for post-incident CWF workflow enforcement
**Reviewer**: Security Reviewer (Claude Opus 4.6)

---

## Security Review

### Concerns (blocking)

- **[C1]** Proposal D (`check-script-deps.sh`, Section 6, lines 222-235) specifies a shell script that will parse other scripts to extract call targets (`$SCRIPT_DIR/...`, `bash ...`, `source ...`) and verify target existence. The proposal does not specify any input sanitization for extracted path values. Shell scripts that dynamically construct paths from parsed content (e.g., extracting `$SCRIPT_DIR/../some-path` from source code and then testing `-f` on it) are susceptible to path traversal if the parsed content contains adversarial filenames with `../` sequences or symlink targets outside the repository boundary. The script should enforce that all resolved paths remain within the repository root (e.g., `realpath --relative-to=REPO_ROOT`).
  Severity: moderate

- **[C2]** Proposal E (Hook-based workflow enforcement gate, Section 6, lines 237-275) stores `user_directive` as a free-text field in `cwf-state.yaml` (line 266: `user_directive: "cwf:run ..."`) which is then injected into hook output and surfaced to the agent on every turn. The existing `cwf-live-state.sh` (`/home/hwidong/codes/claude-plugins/plugins/cwf/scripts/cwf-live-state.sh`, lines 198-242, function `cwf_live_upsert_live_scalar`) uses awk string interpolation with `-v value="$escaped_value"` where `cwf_live_escape_dq` (line 191-196) only escapes backslashes and double quotes. If `user_directive` contains YAML special characters (colons, newlines, brackets) or awk-significant patterns (backslash sequences beyond `\\` and `\"`), this can corrupt the state file or produce malformed YAML. The `set` command's validation (`cwf_live_validate_scalar_key`, lines 244-254) blocks certain key names but does not validate or sanitize **values**. Since `user_directive` is a new field proposed to contain arbitrary user-supplied text, value sanitization is needed before writing to YAML via the awk-based upsert.
  Severity: security

- **[C3]** Proposal E (lines 261-268) specifies that the `workflow-gate.sh` hook reads `cwf-state.yaml` and injects content into the agent prompt on every turn via `UserPromptSubmit` or `Notification` hook output. The hook output format shown (lines 258-260) includes `remaining_gates` and `user_directive` values that originate from the YAML state file. If the state file is corrupted (see C2) or tampered with (it is git-tracked per `cwf-state.yaml` line 2), the injected hook output becomes an injection vector for prompt manipulation. A compromised or maliciously crafted `cwf-state.yaml` could inject arbitrary instructions into every agent turn. The proposal should specify that hook output from `workflow-gate.sh` must escape or quote state values, and ideally validate `remaining_gates` against a known enumeration of valid gate names (e.g., `review-code`, `refactor`, `retro`, `ship`) rather than passing through raw YAML content.
  Severity: security

### Suggestions (non-blocking)

- **[S1]** Proposal A (Deletion safety gate, Section 6, lines 163-179) recommends a `grep -r "filename"` search as the caller check. The grep pattern shown uses bare filename matching (`--include="*.sh" --include="*.md" --include="*.mjs"`), which will miss callers in `.py`, `.yaml`, `.json`, `Makefile`, or other file types. The proposal should either use a broader include list or default to searching all text files. Additionally, the grep should match the filename as a word boundary (e.g., `grep -rw`) to avoid false positives from partial filename matches.

- **[S2]** Proposal A's caller check (line 173) runs entirely within the implementation agent's context as a prose rule in `SKILL.md`. Since this is a "trust the agent to follow the rule" mechanism, it has the same compaction-vulnerability that Proposal E identifies for workflow gates. Consider implementing Proposal A as a deterministic `PreToolUse(Bash)` hook that intercepts `git rm` or `rm` commands and runs the caller check automatically, rather than relying on agent compliance with prose rules. This would make deletion safety compaction-immune, consistent with the design philosophy articulated for Proposal E.

- **[S3]** Proposal E+G (lines 293-307) stores `remaining_gates` as a comma-separated string in `cwf-state.yaml` (e.g., `remaining_gates="review-code,refactor,retro,ship"`). The existing `cwf_live_validate_scalar_key` function (lines 244-254 of `cwf-live-state.sh`) blocks list-type keys like `key_files`, `decisions`, `decision_journal` from being set via the scalar `set` command. `remaining_gates` is semantically a list but is being encoded as a comma-separated scalar to work around this restriction. This is a data integrity concern: the scalar encoding loses YAML type safety and makes it possible to inject commas or additional gate names into the value. Consider either adding `remaining_gates` as a proper list field with dedicated accessors, or adding value validation that restricts content to a known set of gate names.

- **[S4]** Proposal B (Broken-link triage protocol, Section 6, lines 183-205) is specified as an agent behavioral protocol in `AGENTS.md` or `agent-patterns.md`. Like Proposal A, this is a prose-level control. The existing `check-links-local.sh` PostToolUse hook (`/home/hwidong/codes/claude-plugins/plugins/cwf/hooks/hooks.json`, lines 98-101) already runs on every Write/Edit operation. Consider extending this hook to perform the "was the target recently deleted?" check (step 1 of the decision matrix) automatically and surface the triage decision matrix in its output, rather than relying on agent memory of the protocol.

- **[S5]** Proposal F (Session log review mode, Section 6, lines 277-291) cross-references session logs from `.cwf/projects/{session}/session-logs/` against task plans and user instructions. Session logs may contain sensitive content (user messages with credentials, API keys mentioned in conversation, internal URLs). The proposal should specify that session log review mode must not persist extracted user instructions or conversation content into review output files that could be committed to git. A redaction policy for review output (similar to the one mentioned in session S18's artifacts) should be explicitly required.

- **[S6]** The `cwf-hook-gate.sh` (`/home/hwidong/codes/claude-plugins/plugins/cwf/hooks/scripts/cwf-hook-gate.sh`, lines 14-18) sources `~/.claude/cwf-hooks-enabled.sh` without validating its contents. Since Proposal E adds a security-critical hook (`workflow-gate.sh`) that enforces workflow compliance, an attacker who can write to `~/.claude/cwf-hooks-enabled.sh` could disable the workflow gate by adding `export HOOK_WORKFLOW_GATE_ENABLED="false"`. This is an existing risk amplified by Proposal E's security-critical nature. The document should note that the hook toggle file is a trust boundary and should have appropriate file permissions (0600).

- **[S7]** Proposal G (lines 293-307) extends `cwf-live-state.sh set` to write `workflow` and `remaining_gates` fields. The `cwf-live-state.sh` script uses `mktemp` and `mv` for atomic writes (lines 155-188, 206-242), which is good practice. However, the script does not set restrictive permissions on temp files. On multi-user systems, the default `mktemp` umask could allow other users to read state contents during the write window. Since the proposal adds `user_directive` (potentially containing sensitive user instructions), temp files should be created with `mktemp` under a directory with restricted permissions, or the script should explicitly `chmod 600` temp files before writing content.

### Provenance

```yaml
source: REAL_EXECUTION
tool: claude-task
reviewer: Security
duration_ms: ---
command: ---
```

<!-- AGENT_COMPLETE -->
