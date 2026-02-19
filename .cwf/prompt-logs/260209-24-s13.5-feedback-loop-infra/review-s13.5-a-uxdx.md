## UX/DX Review

### Concerns (blocking)

- **[C1]** `scripts/provenance-check.sh` line 116: The delta formatting `${skill_delta:+${skill_delta#+}}` is misleading. The `#+` pattern expansion removes a literal leading `+` character, but bash arithmetic never produces a leading `+`. So `${skill_delta#+}` is a no-op for positive numbers (displays `4` not `+4`). The parenthetical in stale output shows `(4)` for a positive delta and `(-2)` for a negative delta. While functionally harmless, the intent was clearly to show a signed delta (the extra `#+` stripping suggests the author expected `+4`). The UX issue: `(4)` is ambiguous -- does it mean "4 more" or "4 fewer"? The arrow notation before it (`5 -> 9`) does disambiguate, but the parenthetical delta should be explicitly signed to be self-documenting. Same issue on line 123 for `hook_delta`.
  Severity: moderate

- **[C2]** `scripts/provenance-check.sh` line 19: `--level` without a value argument crashes with an unbound variable error (`$2: unbound variable`) due to `set -euo pipefail`. The error message is opaque and unhelpful. A user who types `scripts/provenance-check.sh --level` gets no guidance. Should validate that `$2` exists before accessing it, e.g., `[[ $# -ge 2 ]] || { echo "Error: --level requires a value (inform|warn|stop)" >&2; exit 1; }`.
  Severity: moderate

- **[C3]** `scripts/provenance-check.sh`: No `--help` flag is supported. Running `--help` produces `Unknown option: --help` and exits 1. For a script intended to be run by both humans and CI, a `--help` / `-h` flag is a baseline UX expectation. The usage comment at lines 4-11 is excellent documentation but is only visible by reading the source.
  Severity: moderate

### Suggestions (non-blocking)

- **[S1]** `scripts/provenance-check.sh` lines 8-9: The `--level stop` option is documented as "same as warn for scripts" and the code at line 170 treats `stop` identically to `warn`. If `stop` has no behavioral difference from `warn` today, it adds cognitive overhead for users who wonder when to choose one over the other. Consider either (a) removing `stop` until it has distinct behavior, or (b) adding a comment in the usage section explaining the intended future distinction (e.g., `stop` may be used by skills to abort execution vs. `warn` which continues with a warning).

- **[S2]** `scripts/provenance-check.sh` line 136: JSON output is constructed via `printf` string interpolation without escaping the `target`, `written_session`, or `last_reviewed` values. If any provenance YAML file contains characters like `"` or `\` in these fields, the JSON output will be malformed. Current data is safe, but this is fragile. Consider using `jq` if available or at minimum escaping double quotes in the interpolated values.

- **[S3]** `scripts/provenance-check.sh`: The script does not verify that the `target` file referenced by each `.provenance.yaml` sidecar actually exists in the same directory. A dangling provenance file (whose target was renamed or deleted) would silently report FRESH. Adding a "target not found" warning would improve maintainability.

- **[S4]** `plugins/cwf/skills/refactor/references/docs-criteria.provenance.yaml` and `review-criteria.provenance.yaml` both omit the `designed_for` field. The schema in `skill-conventions.md` line 173 marks this field as `# optional`, which is fine. However, 4 out of 6 provenance files include it, and these 2 do not. For consistency and discoverability (a maintainer looking at these files should understand the scope quickly), adding even a one-line `designed_for` entry would be helpful.

- **[S5]** `plugins/cwf/skills/handoff/SKILL.md` Phase 4b: The section title "Phase 4b" breaks the sequential numbering pattern (Phase 1 -> 2 -> 3 -> 4 -> 4b -> 5). While it communicates that this is a sub-phase of Phase 4, a new reader might wonder if there is a "Phase 4a." The numbering convention is slightly confusing. Consider renaming to "Phase 4.2" or integrating into Phase 4 as a subsection.

- **[S6]** `plugins/cwf/skills/handoff/SKILL.md` Phase 4b: The Korean keywords in the source list (line 227: "구현은 별도 세션", "스코프 밖") may be confusing if a non-Korean-speaking contributor encounters them. These are keyword patterns for grep-like matching in `lessons.md`, so they are functional, but a brief inline comment explaining these are Korean equivalents of the English keywords listed alongside would aid comprehension.

- **[S7]** `plugins/cwf/skills/refactor/SKILL.md` line 209: The provenance check step instructs the agent to "Use AskUserQuestion to ask whether to proceed with potentially stale criteria or pause for review." This is good UX (human-in-the-loop gate). However, the handoff skill's Phase 1.3 (line 55-59) extracts unresolved items during artifact reading but has no equivalent provenance check on its own references. If handoff eventually gains provenance-tracked reference documents, the pattern should be extended there too. This is not blocking since handoff currently has no reference criteria files.

- **[S8]** `scripts/provenance-check.sh`: Colors are defined (lines 43-46) but not conditionally disabled when stdout is not a terminal. When piped (e.g., `provenance-check.sh | less` or `provenance-check.sh > log.txt`), ANSI escape codes will appear as raw characters. Consider adding `[[ -t 1 ]] || { RED=''; GREEN=''; YELLOW=''; NC=''; }` to disable colors for non-TTY output.

### Behavioral Criteria Assessment

- [x] **All 6 provenance sidecar files exist and report FRESH with exit code 0** -- Verified. Running `scripts/provenance-check.sh` against the committed state lists all 6 files as FRESH, with exit code 0.

- [x] **Artificially stale provenance (skill_count: 5) reports STALE with correct delta message** -- Verified. Modifying `holistic-criteria.provenance.yaml` to `skill_count: 5` produced the output: `STALE  plugins/cwf/skills/refactor/references/holistic-criteria.provenance.yaml -> holistic-criteria.md (skills: 5 -> 9 (4))` with exit code 1.

- [x] **Refactor holistic mode checks provenance before loading criteria, warns user if different** -- Verified. `plugins/cwf/skills/refactor/SKILL.md` Phase 1b (lines 201-210) inserts a provenance check between inventory gathering (Phase 1) and loading the analysis framework (Phase 2). Rule 9 (line 345) reinforces this as a mandatory rule.

- [x] **skill-conventions.md has formal Provenance Rule (not "Future Consideration")** -- Verified. The section header reads `## Provenance Rule: Self-Healing Criteria`, replacing the former `## Future Consideration: Self-Healing Criteria`.

### Provenance

```text
source: REAL_EXECUTION
tool: claude-task
reviewer: UX/DX
duration_ms: 121395
command: git show 75ef807
```
