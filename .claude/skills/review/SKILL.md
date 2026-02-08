---
name: review
description: |
  Universal review with narrative verdicts. Parallel internal reviewers
  (Security, UX/DX) via Task tool. Modes: --mode clarify/plan/code.
  Triggers: "/review"
allowed-tools:
  - Task
  - Read
  - Write
  - Glob
  - Grep
  - Bash
  - AskUserQuestion
---

# Review (/review)

Universal review with narrative verdicts via parallel internal reviewers.

**Language**: Match the user's language for synthesis. Reviewer prompts in English.

## Quick Reference

```text
/review                 Code review (default)
/review --mode plan     Plan/spec review
/review --mode clarify  Requirement review
```

## Mode Routing

| Input | Mode |
|-------|------|
| No args or `--mode code` | Code review |
| `--mode plan` | Plan review |
| `--mode clarify` | Clarify review |

Default: `--mode code`.

---

## Phase 1: Gather Review Target

### 1. Parse mode flag

Extract `--mode` from user input. Default to `code` if not specified.

### 2. Detect review target

Automatically detect what to review based on mode:

**--mode code:**

Try in order (first non-empty wins):

1. Detect base branch: check `main`, then `master`, then the default remote branch
   via `git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||'`
2. Branch diff vs base: `git diff $(git merge-base HEAD {base_branch})..HEAD`
   - Only if current branch differs from the detected base branch
3. Staged changes: `git diff --cached`
4. Last commit: `git show HEAD`

If all empty, ask user with AskUserQuestion.

**--mode plan:**

1. Search for the most recent plan file:
   ```bash
   ls -td prompt-logs/*/plan.md 2>/dev/null | head -1
   ```
2. If not found, check `prompt-logs/*/master-plan.md`
3. If not found, ask user with AskUserQuestion

**--mode clarify:**

1. Search for recent clarification artifacts:
   ```bash
   ls -td prompt-logs/*/clarify-result.md 2>/dev/null | head -1
   ```
2. If not found, ask user with AskUserQuestion

### 3. Extract behavioral/qualitative criteria

Search the associated plan.md for success criteria to use as verification input:

1. Find the most recent `prompt-logs/*/plan.md` by modification time
2. Extract **behavioral criteria** — look for Given/When/Then patterns or
   checkbox-style success criteria. These become a pass/fail checklist.
3. Extract **qualitative criteria** — narrative criteria like "should be
   intuitive" or "maintain backward compatibility". These are addressed
   in the narrative verdict.
4. If no plan.md or no criteria found: proceed without criteria.
   Note in synthesis: "No success criteria found — review based on
   general best practices only."

---

## Phase 2: Launch Internal Reviewers

Launch **two** parallel Task agents. Both in a **single message** (parallel execution).

### Prompt construction

For each reviewer:

1. Read `{SKILL_DIR}/references/prompts.md`
2. Extract the reviewer's Role section + mode-specific checklist
3. Build prompt:

```text
You are conducting a {mode} review as the {reviewer_name}.

## Your Role
{role section from prompts.md}

## Review Focus ({mode})
{mode-specific checklist from prompts.md}

## Review Target
{the diff, plan content, or clarify artifact}

## Success Criteria to Verify
{behavioral criteria as checklist, qualitative criteria as narrative items}
(If none: "No specific success criteria provided. Review based on general best practices.")

## Output Format
{output format section from prompts.md}

IMPORTANT:
- Be specific. Reference exact files, lines, sections.
- Distinguish Concerns (blocking) from Suggestions (non-blocking).
- If success criteria are provided, assess each one in the Behavioral Criteria Assessment.
- Include the Provenance block at the end.
```

### Launch

```text
Task(subagent_type="general-purpose", name="security-reviewer", prompt="{security_prompt}")
Task(subagent_type="general-purpose", name="uxdx-reviewer", prompt="{uxdx_prompt}")
```

Both in the same message for parallel execution.

---

## Phase 3: Collect & Synthesize

### 1. Collect reviewer outputs

Read both reviewer responses. If a response is malformed (missing sections),
extract what you can by pattern matching and note in the Confidence Note.

### 2. Determine verdict

Apply these rules in order:

| Condition | Verdict |
|-----------|---------|
| Any unchecked behavioral criterion | **Revise** |
| Any Concern with severity `critical` or `security` | **Revise** |
| Any Concern with severity `moderate` | **Conditional Pass** |
| Only Suggestions or no issues found | **Pass** |

Conservative default: when reviewers disagree, the stricter assessment wins.

### 3. Render Review Synthesis

Output to the conversation (do NOT write to a file unless the user asks):

```markdown
## Review Synthesis

### Verdict: {Pass | Conditional Pass | Revise}
{1-2 sentence summary of overall assessment}

### Behavioral Criteria Verification
(Only if criteria were extracted from plan)
- [x] {criterion} — {reviewer}: {evidence}
- [ ] {criterion} — {reviewer}: {reason for failure}

### Concerns (must address)
- **{reviewer}** [{severity}]: {concern description}
  {specific reference: file, line, section}

(If none: "No blocking concerns.")

### Suggestions (optional improvements)
- **{reviewer}**: {suggestion description}

(If none: "No suggestions.")

### Confidence Note
{Note any of the following:}
- Disagreements between reviewers and which side was chosen
- Areas where reviewer confidence was low
- Malformed reviewer outputs that required interpretation
- Missing success criteria (if no plan was found)

### Reviewer Provenance
| Reviewer | Source | Tool |
|----------|--------|------|
| Security | REAL_EXECUTION | claude-task |
| UX/DX | REAL_EXECUTION | claude-task |
```

---

## Phase 4: External Reviewers (placeholder)

Reserved for S5b. Will add Codex + Gemini as parallel external reviewers
via Bash background processes. See `plugins/cwf/references/agent-patterns.md`
for the execution pattern.

---

## Error Handling

| Situation | Action |
|-----------|--------|
| No review target found | AskUserQuestion: "What should I review?" |
| Reviewer output malformed | Extract by pattern matching, note in Confidence Note |
| `--scenarios <path>` flag used | Holdout scenario validation (planned). Print "Not yet implemented. Proceeding without holdout scenarios." |
| No git changes found (code mode) | AskUserQuestion: ask user to specify target |
| No plan.md found (plan mode) | AskUserQuestion: ask user to specify target |
| Both reviewers report no issues | Verdict = Pass. Note "clean review" in synthesis |

---

## Rules

1. **Always run BOTH reviewers** — deliberate naivete. Never skip a reviewer
   because the change "looks simple." Each perspective catches different issues.
2. **Narrative only** — no numerical scores, no percentages, no letter grades.
   Verdicts are Pass / Conditional Pass / Revise.
3. **Never inline review** — always use Task sub-agents. The main agent
   synthesizes but does not review directly.
4. **Conservative default** — stricter reviewer determines the verdict when
   reviewers disagree.
5. **Output to conversation** — review results are communication, not state.
   Do not write files unless the user explicitly asks.
6. **Criteria from plan** — review verifies plan criteria, it does not
   invent its own. If no criteria exist, review on general best practices
   and note the absence.

---

## References

- Reviewer perspective prompts: [references/prompts.md](references/prompts.md)
- Agent patterns (provenance, synthesis, execution): `plugins/cwf/references/agent-patterns.md`
