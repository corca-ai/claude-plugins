## Handoff: Next Session (S5b)

### Context

- Read: `.claude/skills/review/SKILL.md` and `references/prompts.md`
- Read: `plugins/cwf/references/agent-patterns.md` (execution patterns, graceful degradation)
- Read: `prompt-logs/260208-09-cwf-review-internal/lessons.md`

### Task

Add external CLI reviewers (Codex + Gemini) to `/review` skill — S5b implementation.

### Scope

1. Add Phase 4 implementation in SKILL.md:
   - Codex via `codex --reasoning xhigh` (code) / `--reasoning high` (plan/clarify)
   - Gemini via `npx @google/gemini-cli`
   - Both as Bash background processes with 300s timeout
2. Add graceful degradation:
   - CLI not found → Task agent fallback with same perspective prompt
   - Timeout → mark FAILED, spawn Task agent fallback
3. Add provenance tracking for external CLIs
4. Update synthesis to handle 4 reviewers (2 internal + 2 external)
5. Create `references/external-review.md` with external CLI prompt templates
6. Test: with CLIs installed, without CLIs (fallback), timeout handling
   - **Gemini**: test error handling first (not logged in) → login → test normal flow

### Don't Touch

- Internal reviewer prompts (already working)
- Verdict algorithm (same rules apply to 4 reviewers)
- Plan/lessons protocol files

### Success Criteria

- All 4 reviewers run in parallel (2 Task + 2 Bash background)
- Graceful fallback when CLI not found (2 Task fallback agents instead)
- Provenance metadata distinguishes REAL_EXECUTION from FALLBACK
- Synthesis handles variable number of reviewer outputs

### Dependencies

- Requires: S5a completed (internal reviewers working)
- Blocks: S6a (infra hooks)

### After Completion

1. Create next session dir: `prompt-logs/{YYMMDD}-{NN}-cwf-review-external/`
2. Write plan.md, lessons.md in that dir
3. Write next-session.md (S6a handoff) in that dir

### Start Command

```text
@prompt-logs/260208-09-cwf-review-internal/next-session.md 시작합니다
```
