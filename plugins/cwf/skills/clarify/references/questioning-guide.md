# Questioning Guide

Methodology for persistent, structured questioning of humans during
requirement clarification. Used in Phase 4 (default mode, T3 items)
and Phase 2 (--light mode, all ambiguities).

---

## Core Principles

1. **One question at a time** — never bundle multiple questions
2. **Options over open-ended** — provide 2-4 concrete choices (recognition > recall)
3. **Neutral framing** — present options without bias
4. **Specific over general** — ask about concrete details, not abstract preferences
5. **Persistent** — do not accept surface-level answers; dig deeper

---

## Why-Digging

When a user gives a surface-level answer, dig 2-3 levels deeper to uncover
the real requirement. Adapted from Toyota's "5 Whys" — scaled to 2-3 for
requirement context where full root-cause depth is rarely needed.

### When to Why-Dig

- Answer is vague: "I want it to be fast" → How fast? What's the baseline?
- Answer is a solution, not a need: "Use Redis" → What problem does caching solve?
- Answer contradicts earlier statements
- Answer feels like a default rather than a deliberate choice

### How to Why-Dig

1. Acknowledge the answer: "You mentioned wanting Redis for caching."
2. Ask the deeper question: "What latency target are you aiming for?"
3. If still surface-level, dig once more: "What user experience breaks at higher latency?"
4. Stop at 2-3 levels — beyond that, you're overthinking for requirements

### Phrasing Examples

- "You mentioned X — what's driving that choice?"
- "When you say Y, what specific scenario are you picturing?"
- "If we didn't do Z, what would break?"
- "What's the worst case if we chose the other option?"

---

## Tension Detection

Watch for contradictions between stated requirements. Tensions are signals,
not problems — they reveal where the user hasn't fully thought through
trade-offs.

### Common Tension Patterns

| Tension | Example |
|---------|---------|
| Speed vs Quality | "Ship fast" + "Full test coverage" |
| Flexibility vs Simplicity | "Support all formats" + "Keep it simple" |
| Security vs UX | "Strong auth" + "Frictionless onboarding" |
| Scope vs Timeline | "All features" + "Next sprint" |
| Consistency vs Innovation | "Follow existing patterns" + "Modern approach" |

### How to Surface Tensions

1. Note the tension without judgment
2. Present both stated positions back to the user
3. Ask which takes priority in this specific context
4. Record the resolution as a constraint

**Example**:
> "You mentioned wanting both rapid iteration and comprehensive testing.
> These can sometimes pull in different directions — for this feature,
> which takes priority if they conflict?"

---

## Ambiguity Categories

Common types of ambiguity to probe. Use as a checklist, not a script —
only ask about categories relevant to the specific requirement.

| Category | Probe Questions |
|----------|----------------|
| **Scope** | What's included? What's explicitly out? |
| **Behavior** | Edge cases? Error handling? Failure modes? |
| **Interface** | Who/what interacts? How? API shape? |
| **Data** | Inputs? Outputs? Format? Volume? |
| **Constraints** | Performance? Compatibility? Dependencies? |
| **Priority** | Must-have vs nice-to-have? |
| **Reason** | Why this? What's the jobs-to-be-done? |
| **Success** | How do we verify correctness? |

---

## Question Design for AskUserQuestion

When using the `AskUserQuestion` tool:

### Structure

- **question**: Clear, specific, ending with `?`
- **header**: Short label (max 12 chars) — e.g., "Auth method", "Scope"
- **options**: 2-4 concrete choices, each with:
  - **label**: 1-5 words describing the choice
  - **description**: What this option means and its implications

### Good vs Bad Questions

**Good**: "Which authentication method should we use?"
- Option 1: "JWT tokens" — Stateless, scalable, standard for SPAs
- Option 2: "Session cookies" — Server-side state, simpler for SSR apps
- Option 3: "OAuth only" — Delegate to external providers, no password management

**Bad**: "What do you think about authentication?"
(Open-ended, no concrete options, unclear what decision is needed)

### When Advisory Context Is Available (Default Mode)

In Phase 4 of the default workflow, include advisory context before the question:

1. Summarize what the codebase shows
2. Summarize what best practice research found
3. Present Advisor α's position briefly
4. Present Advisor β's position briefly
5. Then ask the question with options derived from the advisory

---

## New Ambiguity Detection

After each answer, check whether the response reveals NEW ambiguities
that weren't in the original decomposition. This is common — clarifying
one aspect often exposes previously hidden questions.

### Process

1. After each AskUserQuestion response, review the answer
2. Ask: "Does this answer create new questions?"
3. If yes: classify the new ambiguity (in default mode: T1/T2/T3;
   in light mode: add to queue)
4. Continue until no new ambiguities emerge

### Example

User says: "Use JWT tokens for auth"
→ New ambiguities: Token expiry policy? Refresh token strategy? Storage location?
→ These may be T1 (codebase already has JWT patterns) or T3 (policy decision)

---

## Loop Termination

Stop questioning when:
- All identified ambiguities are resolved
- No new ambiguities emerge from recent answers
- Remaining items are implementation details (not requirement decisions)

Do NOT over-question. If the user gives clear, deliberate answers,
accept them and move on.
