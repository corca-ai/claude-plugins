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
  - Glob
  - WebSearch
  - Skill
  - Task
  - AskUserQuestion
---

# Session Retrospective

Adaptive end-of-session review. Light by default, deep on request.
Produces `retro.md` alongside `plan.md` and `lessons.md` in the session's prompt-logs directory.

## Invocation

```text
/retro [path]            # adaptive (light by default)
/retro --deep [path]     # full analysis with expert lens
```

- `path`: optional override for output directory
- `--deep`: force full 7-section analysis (expert lens, learning resources, web search)

## Workflow

### 1. Locate Output Directory

Resolution order:
1. If `[path]` argument provided, use it
2. Reuse `prompt-logs/` path already used in this session (plan.md/lessons.md writes)
3. If multiple candidates exist, AskUserQuestion with candidates
4. Otherwise run `scripts/next-prompt-dir.sh <title>` and create that path

### 2. Read Existing Artifacts

Read `plan.md`, `lessons.md` (if they exist in target dir), `CLAUDE.md` from project root, and project context document (e.g. `docs/project-context.md`) — to understand session goals and avoid duplicating content.

### 3. Select Mode

Parse the `--deep` flag from the invocation arguments.

**If `--deep` is present**: mode = deep (full 7 sections).

**If `--deep` is absent**: assess session weight to decide mode:
- **Light** (Sections 1-4 + 7): Session < 3 turns, OR routine/simple tasks (config changes, small fixes, doc edits)
- **Deep suggestion**: Session has non-trivial architectural decisions, complex debugging, or multi-step implementations → output sections 1-4 + 7 in light mode, but append a note: "This session had significant decisions. Run `/retro --deep` for expert analysis and learning resources."
- **Default bias**: Light. When in doubt, choose light (fast, low cost).

### 4. Draft Retro

Analyze the full conversation to produce the retro sections. Draft everything internally before writing to file.

#### Section 1: Context Worth Remembering

User, org, and project facts useful for future sessions: domain knowledge, tech stack, conventions, team structure, decision-making patterns. Only genuinely useful items.

#### Section 2: Collaboration Preferences

Work style and communication observations; compare against current CLAUDE.md. If warranted, draft `### Suggested CLAUDE.md Updates` as a bullet list (omit if none). **Right-placement check**: if a learning belongs to a doc that CLAUDE.md already references, suggest updating that doc instead.

#### Section 3: Waste Reduction

Identify all forms of wasted effort in the session. Broader than prompting habits — covers the full spectrum of inefficiency:

- **Wasted turns**: Misunderstandings, wrong assumptions, rework
- **Over-engineering**: Unnecessary complexity, premature abstractions
- **Missed shortcuts**: Existing tools/patterns/code that could have been used
- **Context waste**: Large file reads, redundant searches, information not reused
- **Communication waste**: Ambiguous instructions that caused wrong-direction work

Format: free-form analysis citing specific session moments. No table required. Frame constructively with actionable suggestions.

**Root cause drill-down (5 Whys)**: For each significant waste item, don't stop at the symptom. Ask "why did this happen?" repeatedly until you reach a structural or systemic cause. The goal is to distinguish:
- **One-off mistake** (no action needed beyond noting it)
- **Knowledge gap** (persist as context or learning resource)
- **Process gap** (suggest tool, checklist, or protocol change)
- **Structural constraint** (persist to project-context or CLAUDE.md)

Shallow analysis (stopping at "we should have done X") misses persist-worthy structural insights. Always drill to the level where you can recommend a durable fix.

#### Section 4: Critical Decision Analysis (CDM)

Read `{SKILL_DIR}/references/cdm-guide.md` for methodology.

Identify 2-4 critical decision moments from the session. Apply CDM probes to each. This section is unconditional — every retro-worthy session has decisions worth analyzing.

#### Section 5: Expert Lens

**Mode: deep only.** In light mode, output: "Run `/retro --deep` for expert analysis."

Condition: Does the session contain decisions that domain experts would analyze differently? If the session is too lightweight (simple config changes, routine tasks), skip this section with a brief note.

**Expert selection**:
1. Scan the conversation for `/deep-clarify` invocations. If found, extract expert names and use them as preferred starting points.
2. If no deep-clarify experts available, select independently per `{SKILL_DIR}/references/expert-lens-guide.md`.

**Execution**: Launch Expert alpha and Expert beta in parallel via Task tool. Each sub-agent prompt: "Read `{SKILL_DIR}/references/expert-lens-guide.md`. You are Expert {alpha|beta}. Session summary: {Sections 1-4 summary}. Deep-clarify experts: {names or 'not available'}. Analyze through your framework. Use web search to verify expert identity and cite published work." Integrate both results into Section 5.

#### Section 6: Learning Resources

**Mode: deep only.** In light mode, output: "Run `/retro --deep` for learning resources."

Condition: Does the session contain topics where the user showed knowledge gaps or genuine curiosity? If the session is too lightweight (simple config changes, routine tasks), skip this section with a brief note.

Search the web for 2-3 resources calibrated to the user's knowledge level. For each: title + URL, 2-3 sentence summary of key takeaways, and why it matters for the user's work.

#### Section 7: Relevant Skills

**Step 1 — Scan installed skills** (always, both modes):

1. Glob for marketplace skills: `~/.claude/plugins/*/skills/*/SKILL.md`
2. Glob for local skills: `.claude/skills/*/SKILL.md`
3. For each found skill: read the frontmatter (name, description, triggers)
4. Analyze: "Could any of these skills have helped in this session?" and "Should the user try a skill they haven't been using?"
5. Report relevant installed skills with brief explanation of how they apply

**Step 2 — External skill discovery** (if workflow gap identified):

Assess whether the session reveals a workflow gap or repetitive pattern not covered by installed skills. If no clear gap: state "No additional skill gaps identified." Otherwise:

- **Finding existing skills**: Use `/find-skills` to search for existing solutions and report findings.
- **Creating new skills**: If no existing skill fits, use `/skill-creator` to describe and scaffold the needed skill.
- **Prerequisite check**: If `find-skills` (by Vercel) or `skill-creator` (by Anthropic) are not installed, recommend installing them from https://skills.sh/ before proceeding.

### 5. Write retro.md

Write to `{output-dir}/retro.md` using the format below.

### 6. Link Session Log

If `prompt-logs/sessions/` exists (prompt-logger plugin installed):
1. List files matching today's date (`{YYMMDD}-*.md`), filter out already-symlinked ones
2. Read a sample of each candidate to verify it matches the current session
3. If verified and `{output-dir}/session.md` does not exist, create a relative symlink:
   ```bash
   ln -s "../sessions/{filename}" "{output-dir}/session.md"
   ```
4. If no candidates or directory does not exist, skip silently

### 7. Persist Findings

retro.md is session-specific. Persist findings to project-level documents:

- **Context (Section 1)**: Offer to append new context to project-context.md (or create it)
- **CLAUDE.md (Section 2)**: If suggestions exist, AskUserQuestion "Apply?" — edit on approval
- **Root causes (Section 3)**: For each structural root cause identified via 5 Whys, evaluate its future job: "What recurring situation will this learning prevent?" (JTBD lens). If the answer is clear, it belongs in a persistent doc. Use right-placement check: CLAUDE.md for behavioral rules, project-context.md for architectural patterns, protocol/skill docs for process changes.
- **Process improvements (Section 3)**: If waste reduction identifies repeatable process improvements (not one-off observations), suggest updating CLAUDE.md, protocol docs, or project-context.md. Right-placement check applies.
- **Actionable improvements (Section 7)**: If concrete improvements identified, AskUserQuestion "Implement now?" to prevent findings from becoming stale

### 8. Post-Retro Discussion

The user may continue the conversation after the retro. During post-retro discussion:
- Update `retro.md` — append under `### Post-Retro Findings`
- Update `lessons.md` with new learnings
- **Persistence check** — for each new learning, evaluate: CLAUDE.md? Skills/protocol docs? project-context.md?
- If plugin code was changed, follow normal release procedures (version bump, CHANGELOG)

Do not prompt the user to start this discussion.

## Output Format

### Light mode

```markdown
# Retro: {session-title}

> Session date: {YYYY-MM-DD}
> Mode: light

## 1. Context Worth Remembering
## 2. Collaboration Preferences
### Suggested CLAUDE.md Updates
## 3. Waste Reduction
## 4. Critical Decision Analysis (CDM)
## 5. Expert Lens
> Run `/retro --deep` for expert analysis.
## 6. Learning Resources
> Run `/retro --deep` for learning resources.
## 7. Relevant Skills
### Installed Skills
### Skill Gaps
```

### Deep mode

```markdown
# Retro: {session-title}

> Session date: {YYYY-MM-DD}
> Mode: deep

## 1. Context Worth Remembering
## 2. Collaboration Preferences
### Suggested CLAUDE.md Updates
## 3. Waste Reduction
## 4. Critical Decision Analysis (CDM)
## 5. Expert Lens
## 6. Learning Resources
## 7. Relevant Skills
### Installed Skills
### Skill Gaps
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
7. Expert Lens (Section 5) is deep-mode only — in light mode, output a one-line pointer to `--deep`
8. Learning Resources (Section 6) is deep-mode only — in light mode, output a one-line pointer to `--deep`
9. Section 7 always scans installed skills first, before suggesting external skill discovery
10. When writing code fences in retro.md or any markdown output, always include a language specifier (`bash`, `json`, `yaml`, `text`, `markdown`, etc.). Never use bare code fences.
