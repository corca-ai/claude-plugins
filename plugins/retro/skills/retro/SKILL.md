---
name: retro
description: |
  Perform a comprehensive session retrospective. Use when user says
  "retro", "retrospective", "회고", or at the end of a working session.
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - WebSearch
  - Skill
  - AskUserQuestion
---

# Session Retrospective

Comprehensive end-of-session review. Produces `retro.md` alongside
`plan.md` and `lessons.md` in the session's prompt-logs directory.

## Invocation

```
/retro [path]
```

- `path`: optional override for output directory

## Workflow

### 1. Locate Output Directory

Resolution order:
1. If `[path]` argument provided, use it
2. Scan session for `prompt-logs/` paths already used (plan.md, lessons.md writes)
3. List `prompt-logs/` dirs matching today's date (`{YYMMDD}-*`)
4. If ambiguous, AskUserQuestion with candidates
5. If none exist, create `prompt-logs/{YYMMDD}-{NN}-{title}/` (date via `date +%y%m%d`; NN = next sequence number from existing dirs)

### 2. Read Existing Artifacts

- `plan.md` and `lessons.md` in the target directory (if they exist) — understand session goals, avoid duplicating captured learnings
- `CLAUDE.md` from project root — needed for Section 2
- Project context document (if one exists, e.g. `docs/project-context.md`) — avoid repeating already-persisted context in Section 1

### 3. Draft Retro

Analyze the full conversation to produce five sections. Draft everything internally before writing to file.

#### Section 1: Context Worth Remembering

User, organization, and project facts that future sessions would benefit from:
- Domain knowledge, tech stack, conventions discovered
- Organizational context, team structure, decision-making patterns
- Only include what is genuinely useful for future work

#### Section 2: Collaboration Preferences

- Work style and communication observations; compare against current CLAUDE.md
- If warranted, draft `### Suggested CLAUDE.md Updates` as a bullet list (omit if none)
- **Right-placement check**: Before suggesting a CLAUDE.md change, check if the learning belongs to a document that CLAUDE.md already references (e.g., protocol.md, skills-guide.md). If so, suggest updating that document instead — CLAUDE.md should stay as a concise pointer, not restate referenced content.

#### Section 3: Prompting Habits

Patterns that caused misunderstandings, with specific examples and improved alternatives. Frame constructively.

#### Section 4: Learning Resources

- Search the web to find 2–3 relevant resources
- Calibrate to user's apparent knowledge level
- Focus on topics where the session revealed knowledge gaps or curiosity
- For each resource, fetch the content and provide:
  - Title + URL
  - 2–3 sentence summary of key takeaways relevant to this session
  - Why this matters for the user's work
- Prefer fewer high-quality resources with good summaries over many links

#### Section 5: Relevant Skills

- Assess whether the session reveals a workflow gap or repetitive pattern
- If yes: search the marketplace or web for existing solutions, report relevant results
- If a needed skill does not exist: briefly describe what it would do and suggest creating one
- If no clear gap: state "No skill gaps identified in this session"

### 4. Write retro.md

Write to `{output-dir}/retro.md` using the format below.

### 5. Link Session Log

If `prompt-logs/sessions/` exists (prompt-logger plugin installed):
1. List files in `prompt-logs/sessions/` matching today's date (`{YYMMDD}-*.md`)
2. Filter out files already symlinked from any `prompt-logs/{YYMMDD}-*/session.md`
3. For each remaining candidate, read a sample of the file and verify it matches the current session (user prompts, tool calls, or topics should be recognizable — note: the latest turns may not yet be written due to async logging)
4. If verified and `{output-dir}/session.md` does not exist, create a relative symlink:
   ```bash
   ln -s "../sessions/{filename}" "{output-dir}/session.md"
   ```
5. If no candidates or `prompt-logs/sessions/` does not exist, skip silently

This step is defensive — it does nothing if prompt-logger is not installed.

### 6. Persist Findings

retro.md is session-specific. Findings worth keeping across sessions should be persisted to project-level documents.

**Context (Section 1)**: If new context was identified, offer to append it to the project context document. If no such document exists, offer to create one.

**Collaboration & CLAUDE.md (Section 2)**: If collaboration style observations or explicit CLAUDE.md suggestions were produced:
1. AskUserQuestion: "Apply the suggested CLAUDE.md changes?" — Yes / No
2. If yes: Edit CLAUDE.md with the changes
3. If no: suggestions remain documented in retro.md for future reference

**Actionable improvements (Section 5)**: If the retro identifies concrete, implementable improvements (protocol changes, skill modifications, new automation), offer to implement them now rather than just recording them. Use AskUserQuestion: "Implement now?" — this prevents findings from becoming stale notes that require a separate session to act on.

### 7. Post-Retro Discussion

After writing retro.md and persisting findings, the user will often read the retro and continue the conversation — asking questions, giving corrections, raising new points. This is expected and valuable.

During any post-retro conversation:
- Update `retro.md` — append learnings under `### Post-Retro Findings`
- Update `lessons.md` — add new learnings from the discussion
- **Persistence check** — for each new learning, evaluate where it belongs beyond the session:
  - `CLAUDE.md`: new collaboration pattern or workflow change?
  - Skills/protocol docs: does a skill's instructions or behavior need updating?
  - `project-context.md`: new architecture pattern, convention, or design intent?
- If plugin code was changed (SKILL.md, scripts, hooks, protocol docs), follow normal release procedures: update `plugin.json` version and `CHANGELOG.md`

Do not prompt the user to start this discussion. Simply stay aware that conversation after the retro may produce learnings worth capturing.

## Output Format

```markdown
# Retro: {session-title}

> Session date: {YYYY-MM-DD}

## 1. Context Worth Remembering
## 2. Collaboration Preferences
### Suggested CLAUDE.md Updates
## 3. Prompting Habits
## 4. Learning Resources
## 5. Relevant Skills
```

## Language

Write retro.md in the user's language. Detect from conversation, not from this skill file.

## Rules

1. Never duplicate content already in lessons.md
2. Be specific — cite session moments, not generic advice
3. Keep each section focused — if nothing to say, state that briefly
4. CLAUDE.md changes require explicit user approval
5. If early session context is unavailable due to conversation length, focus on what is visible and note the limitation
