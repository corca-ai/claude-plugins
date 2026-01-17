---
name: interview
description: Conducts structured interviews to extract requirements, constraints, and design decisions. Use when the user invokes /interview or needs to discover requirements through conversation.
---

# Requirements Interview

Conduct one-on-one interviews to extract requirements, constraints, and decisions from the user through conversational discovery.

## Invocation

```
/interview <topic> [--ref <path>] [--workspace <dir>]
```

- `<topic>`: Short kebab-case name for the interview (e.g., `auth-system`, `api-design`)
- `--ref <path>`: Optional reference file to anchor discussion
- `--workspace <dir>`: Override the workspace directory for this interview

## Configuration

Default settings are in [config.yaml](config.yaml):

```yaml
workspace_dir: workspace/interviews  # where interview folders are created
```

The `--workspace` flag overrides `workspace_dir` for a single invocation.

## Setup

1. Read [config.yaml](config.yaml) to get the workspace directory (use `--workspace` override if provided)

2. Generate timestamp and create workspace:

```bash
TIMESTAMP=$(date +"%y%m%d-%H%M%S")
mkdir -p ${WORKSPACE_DIR}/${TIMESTAMP}-<topic>
```

3. Create SCRATCHPAD.md from [SCRATCHPAD.template.md](SCRATCHPAD.template.md)

4. If reference provided, read it first to anchor discussion

## Interview Methodology

**Format**: Conversational, one question per turn

**Goal**: Extract requirements, constraints, decisions, and rationale

### Interviewer Approach

- **One focused question per exchange** — never bundle questions
- Listen for implicit requirements and constraints
- Dig into "why" 2-3 times when you sense deeper reasoning
- Follow unexpected threads — often the best insights emerge tangentially
- Reference specific context from prior answers to show you're tracking
- Watch for tensions between stated goals (speed vs quality, flexibility vs simplicity)

### Question Flow

Draw from these categories based on conversation flow:

**Opening**
- What problem are we solving?
- What does success look like?
- Who are the users/stakeholders?

**Constraints**
- What's non-negotiable?
- What resources/timeline exist?
- What can we defer?

**Technical**
- What's the current state?
- What patterns should we follow/avoid?
- What integrations matter?

**Decisions**
- What have you already decided?
- What are you uncertain about?
- What trade-offs are you willing to make?

**Priorities**
- What's the MVP?
- What's nice-to-have?
- What's explicitly out of scope?

## Scratchpad Protocol

Update SCRATCHPAD.md after **every exchange**:

- Add emerging themes as patterns surface
- Capture decisions and requirements verbatim
- Note tensions and trade-offs
- Track areas needing deeper exploration
- Record key quotes worth preserving

The scratchpad is your working memory across the conversation.

## Closing the Interview

When 5-7 meaningful threads have been explored:

1. Summarize key themes back to the user
2. Confirm any ambiguous points
3. Offer to synthesize findings

## Output

Create these files in the interview workspace:

1. **SCRATCHPAD.md** — Live notes (updated throughout)
2. **SYNTHESIS.md** — Polished summary (created at end). Use [SYNTHESIS.template.md](SYNTHESIS.template.md)
3. **JUST_IN_CASE.md** — Context that might help future agents (optional). Use [JUST_IN_CASE.template.md](JUST_IN_CASE.template.md)

## Language Adaptation

Detect the user's language from their first response and conduct the interview in that language throughout.

- If the user responds in Korean, ask all questions in Korean
- If the user responds in English, continue in English
- Match the user's formality level (e.g., 존댓말 vs 반말 in Korean)
- Use natural, conversational phrasing in the detected language
- Write scratchpad and synthesis documents in the same language as the interview

## Key Behaviors

- Never ask multiple questions at once
- Update scratchpad after every exchange
- Dig into tensions and trade-offs
- Capture quotes verbatim when they're insightful
- Stay curious — follow the user's energy
