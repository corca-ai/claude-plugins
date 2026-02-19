# Next Session: S17 — Exhaustive V3 Coverage and Gap Discovery (Hardened)

## Purpose

Produce an omission-resistant analysis of CWF v3 by combining:

1. What was actually implemented
2. What users requested or emphasized during sessions
3. What remained unimplemented, weakly discussed, superseded, or ambiguous

This session is analysis-first and planning-oriented. Do not implement feature
changes in this session unless the user explicitly asks.

## Context Files to Read First

- `cwf-state.yaml`
- `prompt-logs/260208-03-cwf-v3-master-plan/master-plan.md`
- `docs/v3-migration-decisions.md`
- `prompt-logs/260211-03-s16-v3-gap-analysis-handoff/next-session.review.integrated.md`

## Operating Intent

- Prioritize effectiveness over efficiency.
- Prefer exhaustive evidence collection to shortcut summaries.
- Keep unresolved items visible (`Unknown`) instead of collapsing uncertainty.
- If evidence conflicts, prefer "follow-up reflected in artifacts/code" over
  earlier conversational intent, while still preserving original intent in
  notes.

## Hard Scope Anchor

Use this exact collection anchor template:

- **START_SHA**: `42d2cd9`
- **END_SHA**: freeze once at session start (see Phase -1)
- **RANGE**: `42d2cd9..$END_SHA`
- **Include buckets**:
  - `prompt-logs/**`
  - `prompt-logs/sessions/*.md`
  - `prompt-logs/sessions-codex/*.md` (same weight as Claude logs)
  - `cwf-state.yaml`
  - `prompt-logs/260208-03-cwf-v3-master-plan/master-plan.md`
  - `docs/v3-migration-decisions.md`
  - `plugins/cwf/**`
- **Do not narrow** to only sessions that have `session.md`.

## Milestone Vocabulary (Canonical)

Use canonical IDs from `cwf-state.yaml` in all artifacts.

| Legacy Label | Canonical ID(s) to use |
|---|---|
| S13.5 A | S13.5-A |
| S13.5 B | S13.5-B |
| S13.5 B2 | S13.5-B2 |
| S13.5 B3 | S13.5-B3 |
| S13.5 C/D/E | post-B3, S29, S32-impl |
| S32 | S32-impl |
| S33 | S33 |
| S14 | S14 |
| S15 | S15 |
| S16 handoff session | S16 |

If a legacy label appears in evidence, preserve it in `history_note` but map it
immediately to canonical ID in the same row.

## Evidence Hierarchy

Use these hierarchies during synthesis:

1. **Implementation truth**
   - `plugins/cwf/**` (actual behavior)
   - `cwf-state.yaml` (recorded state/history)
   - `master-plan.md`, `v3-migration-decisions.md`, session docs
2. **Intent truth**
   - Session logs (`### User`, `### User Answers`)
   - `lessons.md`, `retro.md`, `next-session.md`
3. **Conflict rule**
   - Final status follows post-discussion artifact/code reflection.
   - Original conflicting intent remains logged in `Context/History`.

## Decision Rationale (Why These Rules Exist)

| Decision | Why | Risk if omitted |
|---|---|---|
| Scope anchored to `42d2cd9..$END_SHA` | User intent is "all records after v3 kickoff commit", not only curated session lists | Silent omission of records outside session sequence |
| Freeze `END_SHA` once | Reproducible corpus across phases | Phase-to-phase drift if new commits land mid-analysis |
| Include both Claude and Codex logs | User requested equal weight; Codex logs may capture user-corrective instructions | Missed user-driven corrections and recovery decisions |
| Post-discussion reflection outranks early intent | Objective is current planning truth | Backlog polluted by already-resolved items |
| Preserve conflicting/early intent in history | Goal includes discovering what changed over time | Loss of rationale drift traceability |
| Keep `Unknown` as first-class status | Omission resistance requires explicit uncertainty | False closure and premature deletion |
| Two-pass consistency check (early->late and late->early) | Each direction catches different blind spots | One-way discovery bias |
| `session.md` is optional pointer, not coverage criterion | Valid sessions/logs can exist without directory linkage | Systematic under-collection |

## Required Workflow

### Phase -1: Scope Freeze and Ownership Bootstrap

Create these files in the active session directory before analysis:

- `scope-freeze.md`
- `analysis-manifest.md` (initialized header)

Required commands:

```bash
START_SHA=42d2cd9
END_SHA=$(git rev-parse HEAD)
RANGE="$START_SHA..$END_SHA"
printf "START_SHA=%s\nEND_SHA=%s\nRANGE=%s\n" "$START_SHA" "$END_SHA" "$RANGE"
```

`scope-freeze.md` must include: branch, timestamp, START_SHA, END_SHA, RANGE.
All later git-range commands must use `RANGE` exactly.

### Phase 0: Build Full-Scope Corpus Manifest

Complete `analysis-manifest.md` with bucket-level coverage, not only
`prompt-logs/**`.

Manifest sections (required):

1. `Frozen Range` (`START_SHA`, `END_SHA`, `RANGE`)
2. `Declared Include Buckets` table
3. `Collected Files by Bucket` (explicit path list or referenced appendix)
4. `Counts by Category`:
   - session directories
   - `sessions/*.md`
   - `sessions-codex/*.md`
   - `plugins/cwf/**` touched files
5. `Missing/Unreadable` (explicit list, can be empty)

Minimum intake command (extend as needed, but do not reduce scope):

```bash
git diff --name-only "$RANGE" -- \
  'prompt-logs/**' \
  'cwf-state.yaml' \
  'prompt-logs/260208-03-cwf-v3-master-plan/master-plan.md' \
  'docs/v3-migration-decisions.md' \
  'plugins/cwf/**'
```

### Phase 0.5: Manifest Completeness Gate (Hard Gate)

Do not enter Phase 1 unless all are true:

1. Every declared include bucket has a collection status (`collected` or
   `explicitly empty`).
2. `Missing/Unreadable` is empty OR each entry has a mitigation note.
3. `RANGE` values in manifest match `scope-freeze.md` exactly.

If any condition fails, stop and record a blocking issue in `summary.md`.

### Phase 1: Implementation Coverage Matrix

Create `coverage-matrix.md`.

Required row groups:

1. Master-plan decisions (#1-#20)
2. `docs/v3-migration-decisions.md` decision rows
3. Skill/hook inventory targets
4. Workstream milestones using canonical IDs:
   - `S13.5-A`, `S13.5-B`, `S13.5-B2`, `S13.5-B3`, `post-B3`, `S29`,
     `S32-impl`, `S33`, `S14`, `S15`, `S16`

Required columns:

- `matrix_id`
- `target_type`
- `target_ref`
- `status` (`Implemented` / `Partial` / `Superseded` / `Not Implemented` /
  `Unknown`)
- `evidence_paths` (1+ concrete paths)
- `history_note`

### Phase 2: User-Utterance Extraction (Redaction Required)

Create `user-utterances-index.md`.

Sources:

1. `prompt-logs/sessions/*.md`
2. `prompt-logs/sessions-codex/*.md`
3. Additional in-range session artifacts containing `### User` blocks, if any

Redaction policy (mandatory):

1. Keep verbatim excerpt short (<= 20 words).
2. Mask secrets/tokens (`sk-*`, `ghp_*`, long API-like keys), emails, phone
   numbers, URLs with query secrets.
3. If sensitive details dominate the line, store paraphrase instead of verbatim.
4. Add `redaction_applied` column (`none` / `masked` / `paraphrased`).

Required columns per item:

- `utterance_id` (`UTT-###`)
- `date/session`
- `source_path`
- `quote_or_paraphrase`
- `redaction_applied`
- `theme_tag`
- `linked_follow_up_artifact`
- `status` (`reflected` / `unreflected` / `unknown`)

### Phase 3: Gap Candidate Mining with Stable IDs

Create `gap-candidates.md`.

Mine full-scope records for unresolved markers such as:

- `deferred`, `unimplemented`, `pending`, `TODO`
- `후속`, `미구현`, `논의 필요`
- equivalent unresolved markers

Each candidate must have a stable `gap_id` (`GAP-###`) and required fields:

1. `gap_id`
2. source evidence path(s)
3. candidate statement summary
4. whether later resolved
5. resolution evidence (if any)
6. final classification (`Resolved` / `Unresolved` / `Superseded` / `Unknown`)
7. related utterance IDs (`UTT-*`, if available)

### Phase 4: Bidirectional Consistency Pass

Create `consistency-check.md`.

Run two independent passes:

1. Early -> Late timeline pass
2. Late -> Early timeline pass

For every one-way finding, either:

- map to existing `GAP-###`, or
- create a new `GAP-###` and append back to `gap-candidates.md`

Required fields per one-way finding:

- `finding_id` (`CW-###`)
- `pass_origin` (`early->late` or `late->early`)
- `linked_gap_id`
- `evidence_paths`
- `why_other_pass_missed_it`

### Phase 5: Discussion Backlog (Traceability Contract)

Create `discussion-backlog.md` with sections:

1. **A: Likely Missing Implementation**
2. **B: Insufficiently Discussed / Under-specified**
3. **C: Intent Drift Worth Explicit Reconfirmation**

Each backlog item must include:

- `backlog_id` (`BL-###`)
- linked `gap_id` list (1+)
- impact
- confidence (`High` / `Medium` / `Low`)
- required decision question (single sentence)
- minimal next action

### Phase 6: Semantic Completion Gate

Create `completion-check.md` (pass/fail checklist with evidence).

Required checks:

1. **Scope control**: every artifact references frozen `RANGE` from
   `scope-freeze.md`.
2. **Manifest closure**: all include buckets are covered or explicitly empty.
3. **Gap closure**: every `GAP-*` with status `Unresolved` or `Unknown` appears
   in `discussion-backlog.md`.
4. **One-way closure**: every `CW-*` maps to a `GAP-*`.
5. **Redaction compliance**: no unmasked secret-like strings in
   `user-utterances-index.md`.
6. **Evidence minimums**: required columns exist and are populated in all
   artifacts.

If any check fails, the session is incomplete.

## Completion Criteria

The session is complete only if all are true:

1. Required artifacts exist and are non-empty:
   - `scope-freeze.md`
   - `analysis-manifest.md`
   - `coverage-matrix.md`
   - `user-utterances-index.md`
   - `gap-candidates.md`
   - `consistency-check.md`
   - `discussion-backlog.md`
   - `completion-check.md`
   - `summary.md`
2. `completion-check.md` contains zero unresolved FAIL items.
3. `summary.md` reports:
   - total `GAP-*` count by class
   - unresolved + unknown counts
   - backlog item counts by section (A/B/C)
   - explicit blocking risks, if any

## Do Not Skip

1. Do not discard low-confidence items; classify as `Unknown`.
2. Do not infer resolution without evidence path.
3. Do not treat `session.md` presence as completeness proof.
4. Do not ignore Codex logs because they are shorter.
5. Do not copy raw sensitive strings into derived artifacts.

## Start Command

```text
@prompt-logs/260211-03-s16-v3-gap-analysis-handoff/next-session.md 시작합니다
```
