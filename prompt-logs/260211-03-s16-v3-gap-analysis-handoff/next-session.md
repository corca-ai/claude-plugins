# Next Session: S17 — Exhaustive V3 Coverage and Gap Discovery (Post-42d2cd9)

## Purpose

Produce an omission-resistant analysis of CWF v3 by combining:

1. What was actually implemented
2. What users requested or emphasized during sessions
3. What remained unimplemented, weakly discussed, superseded, or ambiguous

This session is analysis-first and planning-oriented. Do not implement feature
changes in this session unless the user explicitly asks.

## Operating Intent

- Prioritize effectiveness over efficiency.
- Prefer exhaustive evidence collection to short-cut summaries.
- Keep unresolved items visible (`Unknown`) instead of collapsing uncertainty.
- If evidence conflicts, prefer "follow-up reflected in artifacts/code" over
  earlier conversational intent, while still preserving the original intent in
  notes.

## Hard Scope Anchor

Use this exact collection anchor:

- **Range**: `42d2cd9..HEAD`
- **Include**:
  - `prompt-logs/**` (all directories and session logs)
  - `prompt-logs/sessions/*.md`
  - `prompt-logs/sessions-codex/*.md` (same weight as Claude logs)
  - `cwf-state.yaml`
  - `prompt-logs/260208-03-cwf-v3-master-plan/master-plan.md`
  - `docs/v3-migration-decisions.md`
  - `plugins/cwf/**`
- **Do not narrow** to only sessions that have `session.md`.

## Evidence Hierarchy

Use these hierarchies during synthesis:

1. **Implementation truth**
   1. `plugins/cwf/**` (actual behavior)
   2. `cwf-state.yaml` (recorded state/history)
   3. `master-plan.md`, `v3-migration-decisions.md`, session docs
2. **Intent truth**
   1. Session logs (`### User`, `### User Answers`)
   2. `lessons.md`, `retro.md`, `next-session.md`
3. **Conflict rule**
   - Final status follows post-discussion artifact/code reflection.
   - Original conflicting intent remains logged in "Context/History".

## Decision Rationale (Why These Rules Exist)

This section explains why the analysis protocol was designed this way.

| Decision | Why | Risk if omitted |
|---|---|---|
| Scope anchored to `42d2cd9..HEAD` | User intent is "all records after v3 kickoff commit", not only curated session lists | Silent omission of records outside `cwf-state.yaml` sequence |
| Include both Claude and Codex session logs | User explicitly requested equal weight; Codex logs may still capture user-corrective instructions | Missed user-driven corrections and recovery decisions |
| Post-discussion reflection outranks early intent | The objective is current truth for planning, not first-draft intent preservation | Backlog polluted by already-resolved or superseded items |
| Preserve conflicting/early intent in history | Goal includes discovering what was dropped or changed over time | Loss of valuable early ideas and rationale drift traceability |
| Keep `Unknown` as first-class status | Omission resistance requires explicit uncertainty, not forced binary classification | False closure and premature deletion of potentially important gaps |
| Two-pass consistency check (early→late and late→early) | Each direction catches different blind spots (initial intent vs latest state) | One-way discovery bias and missed one-direction-only findings |
| `session.md` is optional pointer, not coverage criterion | Some valid sessions/logs exist without directory-level `session.md` linkage | Systematic under-collection of evidence corpus |

## Required Workflow

### Phase 0: Build Corpus Manifest

Create a manifest file in the session directory:

- `analysis-manifest.md`

Include:

1. File list from `git diff --name-only 42d2cd9..HEAD -- 'prompt-logs/**'`
2. Counts by category:
   - session directories
   - sessions logs
   - sessions-codex logs
3. Any missing or unreadable files (explicit list)

### Phase 1: Implementation Coverage Matrix

Create:

- `coverage-matrix.md`

Map at minimum:

1. Master-plan decisions (#1-#20)
2. Skill/hook inventory targets
3. Workstream milestones (S13.5 A/B/B2/B3/C/D/E, S32, S33, S14, S15)

For each row, classify:

- `Implemented`
- `Partial`
- `Superseded`
- `Not Implemented`
- `Unknown`

Each row must include concrete evidence paths.

### Phase 2: User-Utterance Extraction

Create:

- `user-utterances-index.md`

Extract user statements from:

1. `prompt-logs/sessions/*.md`
2. `prompt-logs/sessions-codex/*.md`

Index format per item:

- `date/session`
- `verbatim user statement (short)`
- `theme tag`
- `linked follow-up artifact (if found)`
- `status (reflected / unreflected / unknown)`

### Phase 3: Gap Candidate Mining

Create:

- `gap-candidates.md`

Mine all records for:

- `deferred`
- `unimplemented`
- `pending`
- `TODO`
- `후속`
- `미구현`
- `논의 필요`
- equivalent unresolved markers

For each candidate include:

1. Source evidence
2. Whether later resolved
3. Resolution evidence if any
4. Final classification:
   - `Resolved`
   - `Unresolved`
   - `Superseded`
   - `Unknown`

### Phase 4: Bidirectional Consistency Pass

Run two independent passes:

1. Early → Late timeline pass
2. Late → Early timeline pass

Create:

- `consistency-check.md`

List items found by only one pass as `one-way findings` and keep them alive for
discussion.

### Phase 5: Discussion Backlog

Create:

- `discussion-backlog.md`

Structure:

1. **A: Likely Missing Implementation**
2. **B: Insufficiently Discussed / Under-specified**
3. **C: Intent drift worth explicit reconfirmation**

Each item needs:

- impact
- confidence (High/Medium/Low)
- required decision question (single sentence)
- minimal next action

## Completion Criteria

The session is complete only if all are true:

1. `analysis-manifest.md` exists with counts and missing-file note.
2. `coverage-matrix.md` has evidence-linked status for all required rows.
3. `user-utterances-index.md` includes both Claude and Codex session logs.
4. `gap-candidates.md` contains explicit `Unknown` bucket if applicable.
5. `consistency-check.md` includes one-way findings.
6. `discussion-backlog.md` is decision-ready.
7. A concise executive summary is written in `summary.md`.

## Do Not Skip

1. Do not discard low-confidence items; classify as `Unknown`.
2. Do not infer resolution without evidence path.
3. Do not treat `session.md` presence as completeness proof.
4. Do not ignore Codex logs because they are shorter.

## Suggested Output Order to User

1. Executive summary (`summary.md`)
2. High-confidence unresolved items
3. Medium/low confidence unknowns
4. Proposed decision order for next implementation planning

## Start Command

```text
@prompt-logs/260211-03-s16-v3-gap-analysis-handoff/next-session.md 시작합니다
```
