# Planning and Design

## Start with Use Cases

Before writing any code, identify 2–3 concrete use cases your skill should enable.

**Good use case definition:**

```
Use Case: Project Sprint Planning
Trigger: User says "help me plan this sprint" or "create sprint tasks"
Steps:
  1. Fetch current project status from Linear (via MCP)
  2. Analyze team velocity and capacity
  3. Suggest task prioritization
  4. Create tasks in Linear with proper labels and estimates
Result: Fully planned sprint with tasks created
```

Ask yourself:
- What does a user want to accomplish?
- What multi-step workflows does this require?
- Which tools are needed (built-in or MCP)?
- What domain knowledge or best practices should be embedded?

## Common Skill Use Case Categories

### Category 1: Document & Asset Creation

**Used for:** Creating consistent, high-quality output including documents, presentations, apps, designs, code, etc.

**Real example:** frontend-design skill (also see skills for docx, pptx, xlsx, and ppt)

> "Create distinctive, production-grade frontend interfaces with high design quality. Use when building web components, pages, artifacts, posters, or applications."

**Key techniques:**
- Embedded style guides and brand standards
- Template structures for consistent output
- Quality checklists before finalizing
- No external tools required — uses Claude's built-in capabilities

### Category 2: Workflow Automation

**Used for:** Multi-step processes that benefit from consistent methodology, including coordination across multiple MCP servers.

**Real example:** skill-creator skill

> "Interactive guide for creating new skills. Walks the user through use case definition, frontmatter generation, instruction writing, and validation."

**Key techniques:**
- Step-by-step workflow with validation gates
- Templates for common structures
- Built-in review and improvement suggestions
- Iterative refinement loops

### Category 3: MCP Enhancement

**Used for:** Workflow guidance to enhance the tool access an MCP server provides.

**Real example:** sentry-code-review skill (from Sentry)

> "Automatically analyzes and fixes detected bugs in GitHub Pull Requests using Sentry's error monitoring data via their MCP server."

**Key techniques:**
- Coordinates multiple MCP calls in sequence
- Embeds domain expertise
- Provides context users would otherwise need to specify
- Error handling for common MCP issues

## Define Success Criteria

How will you know your skill is working? These are aspirational targets — rough benchmarks rather than precise thresholds.

### Quantitative Metrics

- **Skill triggers on 90% of relevant queries**
  - How to measure: Run 10–20 test queries that should trigger your skill. Track how many times it loads automatically vs. requires explicit invocation.
- **Completes workflow in X tool calls**
  - How to measure: Compare the same task with and without the skill enabled. Count tool calls and total tokens consumed.
- **0 failed API calls per workflow**
  - How to measure: Monitor MCP server logs during test runs. Track retry rates and error codes.

### Qualitative Metrics

- **Users don't need to prompt Claude about next steps**
  - How to assess: During testing, note how often you need to redirect or clarify. Ask beta users for feedback.
- **Workflows complete without user correction**
  - How to assess: Run the same request 3–5 times. Compare outputs for structural consistency and quality.
- **Consistent results across sessions**
  - How to assess: Can a new user accomplish the task on first try with minimal guidance?
