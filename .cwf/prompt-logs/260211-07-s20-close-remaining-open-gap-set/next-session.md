# Next Session: S21 — Final Pre-Merge Hygiene and GAP-004 Risk Monitoring

## Context Files to Read
1. `prompt-logs/260211-07-s20-close-remaining-open-gap-set/gap-closure-update.md`
2. `prompt-logs/260211-07-s20-close-remaining-open-gap-set/impl-validation.md`
3. `prompt-logs/260211-05-s18-v3-gap-analysis-execution/gap-decisions.md`
4. `docs/v3-migration-decisions.md`
5. `cwf-state.yaml`

## Task Scope
Prepare final pre-merge hygiene with explicit monitoring strategy for the accepted-policy GAP-004 risk.

### What to Build
- GAP-004 monitoring note and evidence checklist (without adding new hard gate)
- Legacy `sessions-codex` removal readiness criteria
- Optional CI/automation adoption decision for `check-session.sh --semantic-gap`

### Key Design Points
- Respect DEC-004: keep policy-level stance unless explicitly overridden.
- Keep migration cleanup deterministic and reversible.

## Don't Touch
- Already closed GAP-001/002/003/005/006/014 behavior unless regression exists.

## Lessons from Prior Sessions
1. **Unknown gaps close via traceability** (S20): binary verdict requires line-level mapping.
2. **Additive semantic mode is safer** (S20): stronger checks can ship without breaking existing workflows.

## Success Criteria

```gherkin
Given only GAP-004 remains as accepted-policy risk
When S21 finalizes pre-merge hygiene
Then monitoring and migration cleanup criteria are explicit without introducing unapproved hard gates
```

## Dependencies
- Requires: S19 + S20 closure artifacts
- Blocks: final v3 merge confidence review

## Dogfooding
Discover available CWF skills via `plugins/cwf/skills/*/SKILL.md` and apply workflow stages instead of ad-hoc execution.

## Start Command

```text
@prompt-logs/260211-07-s20-close-remaining-open-gap-set/next-session.md 시작합니다
```
