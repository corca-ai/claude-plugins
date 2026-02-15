# Review: `next-session.md` (Codex)

## Target

- `prompt-logs/260211-03-s16-v3-gap-analysis-handoff/next-session.md`
- Reference: `prompt-logs/260211-03-s16-v3-gap-analysis-handoff/plan.md`

## Verdict

**Revise**

## Findings (ordered by severity)

### 1) [critical] Scope anchor vs corpus intake mismatch

The hard scope declares `42d2cd9..HEAD` and includes non-`prompt-logs` sources (`cwf-state.yaml`, migration docs, `plugins/cwf/**`), but Phase 0 manifest collection only requires `prompt-logs/**`. This allows silent omission while still passing completion checks.

- Evidence:
  - `prompt-logs/260211-03-s16-v3-gap-analysis-handoff/next-session.md:27`
  - `prompt-logs/260211-03-s16-v3-gap-analysis-handoff/next-session.md:32`
  - `prompt-logs/260211-03-s16-v3-gap-analysis-handoff/next-session.md:35`
  - `prompt-logs/260211-03-s16-v3-gap-analysis-handoff/next-session.md:77`
  - `prompt-logs/260211-03-s16-v3-gap-analysis-handoff/next-session.md:190`

### 2) [security] Verbatim user-utterance extraction without redaction rules

The workflow asks for verbatim user statements but does not require masking/minimization, which can replicate secrets or sensitive data from logs into new artifacts.

- Evidence:
  - `prompt-logs/260211-03-s16-v3-gap-analysis-handoff/next-session.md:112`
  - `prompt-logs/260211-03-s16-v3-gap-analysis-handoff/next-session.md:120`

### 3) [moderate] User-intent mining scope is narrower than declared hard scope

User-utterance extraction is restricted to `sessions/*.md` and `sessions-codex/*.md`, while hard scope declares broader `prompt-logs/**` coverage.

- Evidence:
  - `prompt-logs/260211-03-s16-v3-gap-analysis-handoff/next-session.md:29`
  - `prompt-logs/260211-03-s16-v3-gap-analysis-handoff/next-session.md:114`
  - `prompt-logs/260211-03-s16-v3-gap-analysis-handoff/next-session.md:115`

### 4) [moderate] Reproducibility risk from mutable `HEAD`

The range anchor uses `42d2cd9..HEAD` with no explicit scope freeze step; `HEAD` can move during execution.

- Evidence:
  - `prompt-logs/260211-03-s16-v3-gap-analysis-handoff/next-session.md:27`

### 5) [moderate] Weak cross-artifact traceability

No mandatory stable key/backlink requirement ensures `gap-candidates` and `one-way findings` are fully represented in `discussion-backlog`.

- Evidence:
  - `prompt-logs/260211-03-s16-v3-gap-analysis-handoff/next-session.md:164`
  - `prompt-logs/260211-03-s16-v3-gap-analysis-handoff/next-session.md:171`
  - `prompt-logs/260211-03-s16-v3-gap-analysis-handoff/next-session.md:195`

### 6) [moderate] Ambiguity in autonomous execution ownership

The document references creating files in “the session directory” and requires `summary.md` at completion, but ownership/bootstrap responsibility is not explicitly bound to a phase.

- Evidence:
  - `prompt-logs/260211-03-s16-v3-gap-analysis-handoff/next-session.md:71`
  - `prompt-logs/260211-03-s16-v3-gap-analysis-handoff/next-session.md:196`

## Behavioral Criteria Assessment

- [ ] Self-contained enough for autonomous execution in a new session
- [ ] Omission-resistant scope anchored to `42d2cd9..HEAD`
- [ ] Full coverage of implementation mapping, history mining, gap discovery, discussion backlog
- [x] Concrete required artifacts and completion criteria are present
- [x] Analysis-first constraint is clearly specified

## Suggested Fix Directions

1. Add a full-scope manifest requirement covering all declared include buckets, not only `prompt-logs/**`.
2. Add mandatory redaction/minimization policy for user-utterance extraction.
3. Add a scope-freeze pre-step (`END_SHA`) for reproducible range queries.
4. Add stable IDs/backlinks across `coverage-matrix.md`, `gap-candidates.md`, `consistency-check.md`, and `discussion-backlog.md`.
5. Explicitly define bootstrap and `summary.md` ownership phase.

## Reviewer Provenance

| Reviewer | Source | Tool | Notes |
|---|---|---|---|
| Security | REAL_EXECUTION | claude-task | Security + data exposure risks |
| UX/DX | REAL_EXECUTION | claude-task | Clarity and execution ergonomics |
| Correctness | FALLBACK | claude-task-fallback | Correctness/performance perspective |
| Architecture | FALLBACK | claude-task-fallback | Architecture/pattern perspective |
| Expert α (Donella Meadows) | REAL_EXECUTION | claude-task | Systems thinking lens |
| Expert β (David Parnas) | REAL_EXECUTION | claude-task | Modularity/information-hiding lens |
