# Plan: S20 Remaining Gap Closures (DEC-003/006/007)

## Context
S19 resolved top blockers (BL-001/002/003). Remaining open set is centered on closure confidence and semantic reliability: GAP-003 (classification uncertainty), GAP-006 (sub-agent persistence gate strength), GAP-014 (artifact-only session checks).

## Goal
Close or concretely re-scope GAP-003/006/014 by implementing DEC-003/006/007 contracts with explicit evidence.

## Scope
In scope:
- GAP-003 dedicated closure trace and final class update
- GAP-006 stage-tier persistence gate policy encoding in orchestrator skills
- GAP-014 minimal semantic extension in `scripts/check-session.sh`
- S20 session artifacts and state registration

Out of scope:
- New broad protocol redesign
- Full semantic overhaul beyond first-wave checks
- Reopening already-resolved S19 items

## Commit Strategy
- **Per change pattern**:
1. Semantic checker extension (`check-session.sh`)
2. Stage-tier persistence gate policy docs (`context-recovery` + plan/review/retro)
3. GAP-003 trace + S20 closure artifacts/state

## Steps
1. Add `--semantic-gap` mode to `scripts/check-session.sh` with explicit failures for
   - Open GAPs (Unresolved/Unknown) missing from backlog linkage
   - CW rows with missing/invalid GAP mapping
   - Optional RANGE mismatch across analysis artifacts
2. Add stage-tier persistence policy to `plugins/cwf/references/context-recovery-protocol.md` and align orchestrator skills:
   - `plugins/cwf/skills/plan/SKILL.md`
   - `plugins/cwf/skills/review/SKILL.md`
   - `plugins/cwf/skills/retro/SKILL.md`
3. Execute dedicated GAP-003 trace from S13.5-B2 integration points to current refactor references; write `gap-003-trace.md` with line-level evidence and binary verdict.
4. Produce closure update artifact for GAP-003/006/014 and record implementation evidence.
5. Run validation (`check-session --impl`, `--live`, and new `--semantic-gap`) and finalize S20 artifacts/state.

## Success Criteria

### Behavioral (BDD)

```gherkin
Given a gap-analysis session with gap-candidates/discussion-backlog/consistency-check artifacts
When scripts/check-session.sh --semantic-gap is run
Then it fails explicitly if any Unresolved/Unknown GAP is missing from backlog linkage

Given a consistency-check artifact with CW rows
When scripts/check-session.sh --semantic-gap is run
Then it fails explicitly if any CW row lacks a valid GAP mapping

Given orchestrator skills using context recovery
When required critical outputs remain invalid after bounded retry
Then plan/review/retro contracts specify deterministic hard-fail behavior

Given optional/advisory outputs fail persistence validation
When bounded retry is exhausted
Then contracts specify warning + continue behavior with explicit note

Given S13.5-B2 integration points for refactor concept integration
When dedicated trace is executed against current refactor references
Then GAP-003 receives a binary final class with line-level evidence
```

### Qualitative
- Semantic checks are minimal, understandable, and backward-compatible.
- Stage-tier rules are explicit enough to prevent silent data-loss interpretation.
- GAP-003 closure rationale is auditable without hidden assumptions.

## Files to Create/Modify

| File | Action | Purpose |
|------|--------|---------|
| `scripts/check-session.sh` | Edit | Add minimal semantic closure checks (`--semantic-gap`) |
| `plugins/cwf/references/context-recovery-protocol.md` | Edit | Define stage-tier persistence gate policy |
| `plugins/cwf/skills/plan/SKILL.md` | Edit | Encode hard gate for critical persistence outputs |
| `plugins/cwf/skills/review/SKILL.md` | Edit | Encode hard gate for critical reviewer persistence outputs |
| `plugins/cwf/skills/retro/SKILL.md` | Edit | Encode hybrid hard/soft persistence policy by output tier |
| `prompt-logs/260211-07-s20-close-remaining-open-gap-set/gap-003-trace.md` | Create | DEC-003 dedicated trace report |
| `prompt-logs/260211-07-s20-close-remaining-open-gap-set/gap-closure-update.md` | Create | GAP-003/006/014 closure status updates |
| `prompt-logs/260211-07-s20-close-remaining-open-gap-set/*` | Create/Edit | Session artifacts |
| `cwf-state.yaml` | Edit | Register S20 and update live state |

## Don't Touch
- S19 implementation behavior for BL-001/002/003 unless regression evidence appears
- Broad refactor skill architecture outside DEC-003 trace scope

## Deferred Actions
- [ ] Evaluate second-wave semantic checks after first-wave false-positive/false-negative signal review
