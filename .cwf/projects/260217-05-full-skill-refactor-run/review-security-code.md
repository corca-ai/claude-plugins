## Security Review
### Concerns (blocking)
- `plugins/cwf/skills/gather/SKILL.md:118` to `plugins/cwf/skills/gather/SKILL.md:140` defines a deterministic generic URL pipeline, but it does not enforce a URL safety gate (scheme allowlist + private/internal target denylist) before `extract.sh` and WebFetch fallback. Because Step 2 falls through on extraction failure and Step 3 fetches `<url>` directly, attacker-controlled input can target localhost/link-local/internal endpoints (SSRF-style data exposure path). Add explicit rejection for non-`http(s)` schemes and private/loopback/link-local destinations before any fetch, with an explicit user-approved override path if needed.
### Suggestions (non-blocking)
- `.cwf/projects/260217-05-full-skill-refactor-run/review-correctness-plan.stderr.log:1` commits a raw CLI stderr transcript (absolute paths, session IDs, prompt payloads). No secret pattern was detected in this range, but this artifact class is high-risk for accidental credential leakage over time. Prefer redacted logs or avoid committing raw stderr outputs.
- Add a deterministic gate/test for gather URL safety (e.g., reject `file://`, `http://127.0.0.1`, `http://169.254.169.254`, RFC1918 hosts) so the SSRF guard cannot regress.
### Behavioral Criteria Assessment
- [x] Post-install re-detection + `cwf-state.yaml` rewrite is now mandatory in setup flow (`plugins/cwf/skills/setup/SKILL.md:232`).
- [x] Review `Fail` now halts `cwf:run` automation and requires explicit user direction before downstream stages (`plugins/cwf/skills/run/SKILL.md:334`).
- [x] Per-stage provenance logging requirements are defined for run-stage execution (`plugins/cwf/skills/run/SKILL.md:293`).
- [ ] Generic URL gathering flow enforces SSRF-safe URL/network restrictions before external fetch (`plugins/cwf/skills/gather/SKILL.md:118`).
### Provenance
source: REAL_EXECUTION
tool: claude-task
reviewer: Security
duration_ms: —
command: —
<!-- AGENT_COMPLETE -->
