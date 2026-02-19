# Plan — minimal-smoke-plan

## Task
"Create a minimal smoke plan for CWF skill smoke tests in the repo-smoke sandbox."

## Scope Summary
- **Goal**: Define a focused, fast-running smoke test suite that validates each CWF skill loads and produces non-error output in `--print` mode, without sub-agent spawns or user-interaction that cause timeouts.
- **Key Decisions**: Which skills form the minimal set; per-case timeout; pass/fail thresholds.
- **Known Constraints**: Uses existing `noninteractive-skill-smoke.sh` harness; sandbox is `iter2/sandbox/repo-smoke` (bare git repo); prior runs show 9/14 and 2/6 TIMEOUT at 60s.

## Inputs and Evidence
- Prior smoke run 1: `iter2/artifacts/skill-smoke-260219-143747/summary.tsv` — 4 PASS, 1 FAIL, 9 TIMEOUT
- Prior smoke run 2 (postfix): `iter2/artifacts/skill-smoke-260219-145730-postfix/summary.tsv` — 3 PASS, 2 TIMEOUT (partial)
- Smoke harness: `scripts/noninteractive-skill-smoke.sh`
- Test fixtures: `scripts/tests/noninteractive-skill-smoke-fixtures.sh`

## Analysis of Prior Failures

| Skill | Run 1 | Run 2 | Root Cause |
|-------|-------|-------|------------|
| setup-env | TIMEOUT | PASS | Borderline — sub-agent spawns, barely fits 60s |
| setup-git-hooks | PASS | TIMEOUT | Borderline — depends on interactive hook selection |
| gather | PASS | PASS | Fast (16s) — reliable |
| clarify | TIMEOUT | PASS | `--light` helps but spawns research agents; 59s in run 2 |
| plan | TIMEOUT | TIMEOUT | Spawns 2 parallel research sub-agents; inherently heavy |
| review | TIMEOUT | — | 6 parallel reviewer agents; inherently heavy |
| impl | TIMEOUT | — | Spawns implementation agents; inherently heavy |
| refactor | TIMEOUT | — | `--mode quick` still reads many files; borderline |
| retro | PASS | — | `--light` works (32s) — reliable |
| handoff | TIMEOUT | — | Reads session state + generates handoff doc; borderline |
| ship | PASS | — | `--help` mode is trivial (6s) — reliable |
| update | TIMEOUT | — | Fetches remote updates; network-dependent |
| run | FAIL(WAIT_INPUT) | — | Asks user for task description — expected for bare invocation |
| hitl | TIMEOUT | — | Requires interactive review state; inherently interactive |

## Minimal Smoke Case Set

Criteria for inclusion:
1. Must complete in `--print` mode without user interaction
2. Must be achievable within 45s timeout
3. Must validate skill loading (prompt parsed, skill body executed, no crash)

### Tier 1 — Core (must-pass, fast)

| # | Case ID | Prompt | Expected | Rationale |
|---|---------|--------|----------|-----------|
| 1 | gather | `cwf:gather docs/plugin-dev-cheatsheet.md` | PASS <20s | File-local skill, no agents, fast |
| 2 | ship-help | `/ship --help` | PASS <10s | Help mode, trivial |
| 3 | retro-light | `cwf:retro --light` | PASS <40s | Lightweight retro, proven reliable |

### Tier 2 — Extended (allow timeout, informational)

| # | Case ID | Prompt | Expected | Rationale |
|---|---------|--------|----------|-----------|
| 4 | setup-env | `cwf:setup --env` | PASS or TIMEOUT | Borderline at 60s; validates setup path |
| 5 | clarify-light | `cwf:clarify --light smoke test only` | PASS or TIMEOUT | Borderline at 60s; validates clarify path |
| 6 | refactor-quick | `cwf:refactor --mode quick` | PASS or TIMEOUT | Validates refactor loads |

### Excluded (by design)

| Case ID | Reason |
|---------|--------|
| plan | Spawns 2 parallel sub-agents; inherently >60s |
| review | Spawns 6 parallel reviewers; inherently >60s |
| impl | Spawns implementation agents; inherently heavy |
| handoff | Requires prior session state; borderline |
| update | Network-dependent, unreliable in sandbox |
| run | Requires user input by design |
| hitl | Interactive by design |
| setup-git-hooks | Intermittent; depends on hook selection prompts |

## Files to Create/Modify

| File | Action | Description |
|------|--------|-------------|
| `iter2/sandbox/repo-smoke/minimal-smoke-cases.txt` | Create | Case definition file for `--cases-file` |

## Execution Steps

### Step 1: Create minimal smoke case file

Create `minimal-smoke-cases.txt` in the repo-smoke sandbox with the Tier 1 + Tier 2 cases in `id|prompt` format, compatible with `noninteractive-skill-smoke.sh --cases-file`.

### Step 2: Run minimal smoke

Execute:
```bash
bash scripts/noninteractive-skill-smoke.sh \
  --plugin-dir plugins/cwf \
  --workdir .cwf/projects/260219-01-pre-release-audit-pass2/iter2/sandbox/repo-smoke \
  --cases-file .cwf/projects/260219-01-pre-release-audit-pass2/iter2/sandbox/repo-smoke/minimal-smoke-cases.txt \
  --timeout 45 \
  --max-failures 0 \
  --max-timeouts 3 \
  --output-dir .cwf/projects/260219-01-pre-release-audit-pass2/iter2/artifacts/skill-smoke-minimal
```

### Step 3: Evaluate results

- Tier 1 cases must all PASS (0 failures allowed)
- Tier 2 cases may TIMEOUT (up to 3 timeouts allowed)
- If any Tier 1 case fails: investigate log, fix skill, re-run

## Commit Strategy
- **Per step** — one commit for case file creation, one for results (if any fixes needed)

## Decision Log

| # | Decision Point | Evidence / Source | Alternatives Considered | Resolution | Status | Resolved By | Resolved At (UTC) |
|---|----------------|-------------------|-------------------------|------------|--------|-------------|-------------------|
| 1 | Which skills to include | Prior run summaries (high confidence) | Include all 14 (too slow), include only PASS-history (too narrow) | 3 core + 3 extended with lenient timeout threshold | resolved | assistant | 2026-02-19T15:00:00Z |
| 2 | Timeout per case | Prior run durations (high) | 30s (too tight for clarify), 60s (same as before), 90s (defeats "minimal") | 45s — proven sufficient for Tier 1, reasonable for Tier 2 | resolved | assistant | 2026-02-19T15:00:00Z |
| 3 | Gate threshold | Prior TIMEOUT rate 9/14 (high) | max-timeouts=0 (too strict), unlimited (no signal) | max-failures=0, max-timeouts=3 — Tier 1 must pass, Tier 2 can timeout | resolved | assistant | 2026-02-19T15:00:00Z |

## Success Criteria

```gherkin
Given a minimal-smoke-cases.txt file with 6 cases (3 core, 3 extended)
When noninteractive-skill-smoke.sh runs with --timeout 45 --max-failures 0 --max-timeouts 3
Then the gate exits 0 (PASS)

Given the 3 Tier 1 cases (gather, ship-help, retro-light)
When each completes within the 45s timeout
Then each reports result=PASS reason=OK in summary.tsv

Given the 3 Tier 2 cases (setup-env, clarify-light, refactor-quick)
When any times out
Then the overall gate still passes (timeout count <= 3)
```

## Qualitative Criteria
- The smoke suite completes in under 5 minutes total (6 cases x 45s max = 4.5m worst case)
- Results are reproducible across repeated runs for Tier 1 cases
- The case file is portable and works from the repo root with relative paths

## Deferred Actions
- [ ] If Tier 2 cases consistently pass, promote them to Tier 1 in a future iteration
- [ ] Consider adding `--parallel` support to the smoke harness for faster execution
