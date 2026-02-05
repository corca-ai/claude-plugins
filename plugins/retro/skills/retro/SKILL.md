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
  - Task
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

Read `plan.md`, `lessons.md` (if they exist in target dir), `CLAUDE.md` from project root, and project context document (e.g. `docs/project-context.md`) — to understand session goals and avoid duplicating content.

### 3. Draft Retro

Analyze the full conversation to produce seven sections. Draft everything internally before writing to file.

#### Section 1: Context Worth Remembering

User, org, and project facts useful for future sessions: domain knowledge, tech stack, conventions, team structure, decision-making patterns. Only genuinely useful items.

#### Section 2: Collaboration Preferences

Work style and communication observations; compare against current CLAUDE.md. If warranted, draft `### Suggested CLAUDE.md Updates` as a bullet list (omit if none). **Right-placement check**: if a learning belongs to a doc that CLAUDE.md already references, suggest updating that doc instead.

#### Section 3: Prompting Habits

Patterns that caused misunderstandings, with specific examples and improved alternatives. Frame constructively.

#### Section 4: Critical Decision Analysis (CDM)

Read `{SKILL_DIR}/references/cdm-guide.md` for methodology.

Identify 2-4 critical decision moments from the session. Apply CDM probes to each. This section is unconditional — every retro-worthy session has decisions worth analyzing.

#### Section 5: Expert Lens (conditional)

Condition: Does the session contain decisions that domain experts would analyze differently? If the session is too lightweight (simple config changes, routine tasks), skip this section with a brief note.

**Expert selection**:
1. Scan the conversation for `/deep-clarify` invocations. If found, extract expert names and use them as preferred starting points.
2. If no deep-clarify experts available, select independently per `{SKILL_DIR}/references/expert-lens-guide.md`.

**Execution**: Launch Expert alpha and Expert beta in parallel via Task tool. Each sub-agent prompt: "Read `{SKILL_DIR}/references/expert-lens-guide.md`. You are Expert {alpha|beta}. Session summary: {Sections 1-4 summary}. Deep-clarify experts: {names or 'not available'}. Analyze through your framework. Use web search to verify expert identity and cite published work." Integrate both results into Section 5.

#### Section 6: Learning Resources (conditional)

Condition: Does the session contain topics where the user showed knowledge gaps or genuine curiosity? If the session is too lightweight (simple config changes, routine tasks), skip this section with a brief note.

Search the web for 2-3 resources calibrated to the user's knowledge level. For each: title + URL, 2-3 sentence summary of key takeaways, and why it matters for the user's work.

#### Section 7: Relevant Skills

Assess whether the session reveals a workflow gap or repetitive pattern. If no clear gap: state "No skill gaps identified." Otherwise:

- **Finding existing skills**: Use `/find-skills` to search for existing solutions and report findings.
- **Creating new skills**: If no existing skill fits, use `/skill-creator` to describe and scaffold the needed skill.
- **Prerequisite check**: If `find-skills` (by Vercel) or `skill-creator` (by Anthropic) are not installed, recommend installing them from https://skills.sh/ before proceeding.

### 4. Write retro.md

Write to `{output-dir}/retro.md` using the format below.

### 5. Link Session Log

If `prompt-logs/sessions/` exists (prompt-logger plugin installed):
1. List files matching today's date (`{YYMMDD}-*.md`), filter out already-symlinked ones
2. Read a sample of each candidate to verify it matches the current session
3. If verified and `{output-dir}/session.md` does not exist, create a relative symlink:
   ```bash
   ln -s "../sessions/{filename}" "{output-dir}/session.md"
   ```
4. If no candidates or directory does not exist, skip silently

### 6. Persist Findings

retro.md is session-specific. Persist findings to project-level documents:

- **Context (Section 1)**: Offer to append new context to project-context.md (or create it)
- **CLAUDE.md (Section 2)**: If suggestions exist, AskUserQuestion "Apply?" — edit on approval
- **Actionable improvements (Section 7)**: If concrete improvements identified, AskUserQuestion "Implement now?" to prevent findings from becoming stale

### 7. Post-Retro Discussion

The user may continue the conversation after the retro. During post-retro discussion:
- Update `retro.md` — append under `### Post-Retro Findings`
- Update `lessons.md` with new learnings
- **Persistence check** — for each new learning, evaluate: CLAUDE.md? Skills/protocol docs? project-context.md?
- If plugin code was changed, follow normal release procedures (version bump, CHANGELOG)

Do not prompt the user to start this discussion.

## Output Format

```markdown
# Retro: {session-title}

> Session date: {YYYY-MM-DD}

## 1. Context Worth Remembering
## 2. Collaboration Preferences
### Suggested CLAUDE.md Updates
## 3. Prompting Habits
## 4. Critical Decision Analysis (CDM)
## 5. Expert Lens
## 6. Learning Resources
## 7. Relevant Skills
```

## References

- `{SKILL_DIR}/references/cdm-guide.md` — CDM probe methodology and output format
- `{SKILL_DIR}/references/expert-lens-guide.md` — Expert identity, grounding, and analysis format

## Language

Write retro.md in the user's language. Detect from conversation, not from this skill file.

## Rules

1. Never duplicate content already in lessons.md
2. Be specific — cite session moments, not generic advice
3. Keep each section focused — if nothing to say, state that briefly
4. CLAUDE.md changes require explicit user approval
5. If early session context is unavailable due to conversation length, focus on what is visible and note the limitation
6. CDM analysis (Section 4) is unconditional — every session has decisions to analyze
7. Expert Lens (Section 5) is conditional — skip for lightweight sessions with no non-trivial decisions
8. Learning Resources (Section 6) is conditional — skip for lightweight sessions with no knowledge gaps or curiosity signals
