# Testing and Iteration

Skills can be tested at varying levels of rigor depending on your needs:

- **Manual testing in Claude.ai** — Run queries directly and observe behavior. Fast iteration, no setup required.
- **Scripted testing in Claude Code** — Automate test cases for repeatable validation across changes.
- **Programmatic testing via skills API** — Build evaluation suites that run systematically against defined test sets.

Choose the approach that matches your quality requirements and the visibility of your skill.

> **Pro Tip: Iterate on a single task before expanding.** The most effective skill creators iterate on a single challenging task until Claude succeeds, then extract the winning approach into a skill. This leverages Claude's in-context learning and provides faster signal than broad testing. Once you have a working foundation, expand to multiple test cases for coverage.

## Recommended Testing Approach

### 1. Triggering Tests

**Goal:** Ensure your skill loads at the right times.

Test cases:
- ✅ Triggers on obvious tasks
- ✅ Triggers on paraphrased requests
- ❌ Doesn't trigger on unrelated topics

Example test suite:

```
Should trigger:
- "Help me set up a new ProjectHub workspace"
- "I need to create a project in ProjectHub"
- "Initialize a ProjectHub project for Q4 planning"

Should NOT trigger:
- "What's the weather in San Francisco?"
- "Help me write Python code"
- "Create a spreadsheet" (unless ProjectHub skill handles sheets)
```

### 2. Functional Tests

**Goal:** Verify the skill produces correct outputs.

Test cases:
- Valid outputs generated
- API calls succeed
- Error handling works
- Edge cases covered

Example:

```
Test: Create project with 5 tasks
Given: Project name "Q4 Planning", 5 task descriptions
When: Skill executes workflow
Then:
  - Project created in ProjectHub
  - 5 tasks created with correct properties
  - All tasks linked to project
  - No API errors
```

### 3. Performance Comparison

**Goal:** Prove the skill improves results vs. baseline.

**Without skill:**
- User provides instructions each time
- 15 back-and-forth messages
- 3 failed API calls requiring retry
- 12,000 tokens consumed

**With skill:**
- Automatic workflow execution
- 2 clarifying questions only
- 0 failed API calls
- 6,000 tokens consumed

## Using the skill-creator Skill

The skill-creator skill — available in Claude.ai via plugin directory or download for Claude Code — can help you build and iterate on skills.

**Creating skills:**
- Generate skills from natural language descriptions
- Produce properly formatted SKILL.md with frontmatter
- Suggest trigger phrases and structure

**Reviewing skills:**
- Flag common issues (vague descriptions, missing triggers, structural problems)
- Identify potential over/under-triggering risks
- Suggest test cases based on the skill's stated purpose

**Iterative improvement:**
- After using your skill and encountering edge cases or failures, bring those examples back to skill-creator
- Example: "Use the issues & solution identified in this chat to improve how the skill handles [specific edge case]"

**To use:**
```
"Use the skill-creator skill to help me build a skill for [your use case]"
```

Note: skill-creator helps you design and refine skills but does not execute automated test suites or produce quantitative evaluation results.

## Iteration Based on Feedback

Skills are living documents. Plan to iterate based on:

### Undertriggering Signals
- Skill doesn't load when it should
- Users manually enabling it
- Support questions about when to use it

**Solution:** Add more detail and nuance to the description — this may include keywords particularly for technical terms.

### Overtriggering Signals
- Skill loads for irrelevant queries
- Users disabling it
- Confusion about purpose

**Solution:** Add negative triggers, be more specific.

### Execution Issues
- Inconsistent results
- API call failures
- User corrections needed

**Solution:** Improve instructions, add error handling.
