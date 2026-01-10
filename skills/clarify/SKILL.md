---
name: clarify
description: Transform vague or ambiguous requirements into precise, actionable specifications through structured questioning. Use when user says "clarify", "refine requirements", or when requirements are unclear, incomplete, or open to multiple interpretations. Always use before implementing any ambiguous feature request.
allowed-tools:
  - AskUserQuestion
  - Write
  - Read
---

# Clarify

## Quick Start

1. **Capture**: Record the original requirement verbatim
2. **Clarify**: Use `AskUserQuestion` to resolve ambiguities iteratively
3. **Compare**: Present Before/After comparison
4. **Save** (optional): Offer to save clarified spec to file

## Protocol

### Phase 1: Capture Original Requirement

Record the original requirement exactly as stated:

```markdown
## Original Requirement
"{user's original request verbatim}"
```

Identify ambiguities using the categories below (see **Ambiguity Categories**).

### Phase 2: Iterative Clarification

Use `AskUserQuestion` tool to resolve each ambiguity. Continue until ALL aspects are clear.

**Question Design Principles:**
- **Specific over general**: Ask about concrete details, not abstract preferences
- **Options over open-ended**: Provide 2-4 choices (recognition > recall)
- **One concern at a time**: Avoid bundling multiple questions
- **Neutral framing**: Present options without bias

**Loop Structure:**
```python
while ambiguities_remain:
    identify_most_critical_ambiguity()
    ask_clarifying_question()  # Use AskUserQuestion tool
    update_requirement_understanding()
    check_for_new_ambiguities()
```

### Phase 3: Before/After Comparison

After clarification is complete, present the transformation:

```markdown
## Requirement Clarification Summary

### Before (Original)
"{original request verbatim}"

### After (Clarified)
**Goal**: [precise description of what user wants]
**Reason**: [the ultimate purpose or jobs to be done]
**Scope**: [what's included and excluded]
**Constraints**: [limitations, requirements, preferences]
**Success Criteria**: [how to know when done]

**Decisions Made**:
| Question | Decision |
|----------|----------|
| [ambiguity 1] | [chosen option] |
| [ambiguity 2] | [chosen option] |
```

### Phase 4: Save Option

Use `AskUserQuestion` to ask if the user wants to save the clarified requirement:
- Question: "Save this requirement specification to a file?"
- Options: "Yes, save to file" (Save to requirements/ directory) / "No, proceed" (Continue without saving)

If saving:
- Default location: `requirements/` or project-appropriate directory
- Filename: descriptive, based on requirement topic (e.g., `auth-feature-requirements.md`)
- Format: Markdown with Before/After structure

## Ambiguity Categories

Common types to probe:

| Category | Example Questions |
|----------|------------------|
| **Scope** | What's included? What's explicitly out? |
| **Behavior** | Edge cases? Error scenarios? |
| **Interface** | Who/what interacts? How? |
| **Data** | Inputs? Outputs? Format? |
| **Constraints** | Performance? Compatibility? |
| **Priority** | Must-have vs nice-to-have? |
| **Reason** | Why are you doing this? What are jobs to be done? |
| **Success** | How to verify we're taking the right steps? |

## Examples

### Example 1: Vague Feature Request

**Original**: "Add a login feature"

**Clarifying questions (via AskUserQuestion)**:
1. Authentication method? → Username/Password
2. Registration included? → Yes, self-signup
3. Session duration? → 24 hours
4. Password requirements? → Min 8 chars, mixed case

**Clarified**:
- Goal: Add username/password login with self-registration
- Reason: Restrict access to authorized users only
- Scope: Login, logout, registration, password reset
- Constraints: 24h session, bcrypt, rate limit 5 attempts
- Success Criteria: User can register, login, logout, reset password

### Example 2: Bug Report

**Original**: "The export is broken"

**Clarifying questions**:
1. Which export? → CSV
2. What happens? → Empty file
3. When did it start? → After v2.1 update
4. Steps to reproduce? → Export any report

**Clarified**:
- Goal: Fix CSV export producing empty files
- Reason: Users need to export data for external reporting
- Scope: CSV only, other formats work
- Constraints: Regression from v2.1, must not break other exports
- Success Criteria: CSV contains correct data matching UI

## Rules

1. **No assumptions**: Ask, don't assume
2. **Preserve intent**: Refine, don't redirect
3. **Minimal questions**: Only what's needed
4. **Respect answers**: Accept user decisions
5. **Track changes**: Always show before/after