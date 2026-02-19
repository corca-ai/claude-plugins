# Documentation Guide

Principles for writing and organizing documentation in AI-agent-assisted projects. Synthesized from three external sources and this project's experience.

## Sources

1. **Vercel** — [AGENTS.md Outperforms Skills in Our Agent Evals](https://vercel.com/blog/agents-md-outperforms-skills-in-our-agent-evals) (2025). Finding: a compressed index file achieved 100% pass rate vs 79% for skills. 80% size reduction with no performance loss.
2. **g15e** — [Software Project Documentation in AI Era](https://wiki.g15e.com/pages/Software%20project%20documentation%20in%20AI%20era) (2025). Framework: AGENTS.md as entry point → specialized docs (architecture.md, coding.md, testing.md). Agent autonomy principle.
3. **HumanLayer** — [Writing a Good CLAUDE.md](https://www.humanlayer.dev/blog/writing-a-good-claude-md) (2025). Finding: instruction-following quality decreases uniformly as count rises. Frontier models follow ~150-200 instructions; Claude Code's system prompt already uses ~50.

## Principles

### 1. Always-loaded file = compressed index

The primary cross-agent entry point ([AGENTS.md](../AGENTS.md)) should contain pointers and scope descriptions, not full content. Runtime-specific adapter files (for example [CLAUDE.md](../CLAUDE.md)) should remain thin and defer to [AGENTS.md](../AGENTS.md). Agents decide which files to retrieve based on task context.

> "No decision point where agents must choose to look something up,
> consistent availability across all turns." — Vercel

### 2. Each document has one clear scope

If a document serves multiple unrelated purposes, agents cannot make a meaningful read/skip decision. The trigger condition becomes "always" or "never", defeating progressive disclosure.

Bad: `project-context.md` containing architecture patterns, shell troubleshooting, and org facts. Good: separate files where each has a distinct retrieval trigger.

### 3. Agent autonomy for reading, explicit routing for writing

Agents are intelligent enough to judge which documents are relevant to their current task. Prescriptive triggers ("read X when doing Y") are unnecessary when scope descriptions are clear.

> "Readers (agents+humans) are sufficiently intelligent and should judge
> independently whether referenced materials apply to their situation." — g15e

However, writing (persisting findings from retro/lessons) requires explicit routing because the question "where should I write this?" has no task-context signal — it depends on the finding's category, not the current task.

### 4. Less is more

Instruction-following quality degrades uniformly as instruction count rises. Each additional instruction slightly reduces adherence to all other instructions.

- AGENTS.md: aim for < 300 lines, ideally < 100
- Runtime adapters (e.g., CLAUDE.md): keep as thin wrappers, ideally < 80 lines
- Individual docs: focused enough to be skippable when irrelevant
- Prefer pointers to copies — `file:line` references over embedded snippets

> "Never send an LLM to do a linter's job." — HumanLayer

### 5. Documentation-as-Code

Apply software engineering principles to documentation:

- Eliminate redundancy (single source of truth per fact)
- Meaningful names that signal scope
- Link documents, minimize circular references
- Prefer concise semantic link labels over full path-as-label when local context already scopes the target
- Remove unreachable documents
- Don't version auto-generated content

> "Create cohesive document units with meaningful names." — g15e

### 6. Non-obvious decisions only

Document decisions that a capable agent would not independently reach. Skip obvious content ("write clean code") and information already encoded in the codebase structure.

> "Include non-obvious design decisions (e.g., framework rejections,
> tool choices). Provide sufficient information for decision-making." — g15e

### 7. Skills for vertical, docs for horizontal

Skills (SKILL.md) are best for action-specific workflows with defined phases. Documentation is best for horizontal knowledge that applies across many tasks.

> "Skills work better for action-specific workflows like version upgrades,
> not horizontal framework knowledge." — Vercel
