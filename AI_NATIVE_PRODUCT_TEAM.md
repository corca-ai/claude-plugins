# AI-Native Product Team

[한국어](AI_NATIVE_PRODUCT_TEAM.ko.md)

As of January 2026, this document describes Corca's vision of an ideal **AI-native product team**—a team where strong agentic engineering processes and practices are well established. Corca's internal team is rapidly moving in this direction, and Corca's [AX coaching/consulting](https://spilist.notion.site/x-AX-25a9c2b2727580f785aade9a88da5add) primarily aims to "plant seeds" so our customers' product teams can evolve toward this model.

---

## 1. How we collaborate with AI

### Prompt reviews and pair prompting

Less time is spent on traditional, human-only code reviews. Instead, more time is invested in reviewing spec prompts and doing pair prompting. We think together: "Where might the agent make mistakes if we ask with this prompt?"

Pair prompting is used in many situations:
- **Spec writing**: while organizing complex requirements, two people refine the prompt together and find missing parts
- **Problem solving**: when the agent doesn't behave as expected, we analyze the cause together and improve the prompt
- **Onboarding**: a new teammate learns tools and workflows by prompting together with an existing teammate
- **Learning**: we observe each other's prompting style and learn new techniques

### Turning team knowledge into assets

The prompts each person uses become assets in the codebase. A culture of experimenting with and sharing new tools and methodologies takes root. Every week, tools/processes/workflows tried that week are shared on Slack and accumulated over time.

The scope of "assetization" goes beyond prompts:
- **Prompts and skills**: frequently used prompts are packaged as skills so the whole team can reuse them
- **Retrospective records**: trial-and-error with agents and the improvement process are recorded in GitHub issues, PR descriptions, and commit logs
- **Decision context**: the "why" is recorded, so it can be referenced when the same problem appears again

### AI's limitations and the role of humans

We distinguish between what AI does well and where humans must be involved. Final business decisions, ethical judgment, and emotional communication with customers and stakeholders are (for now) human responsibilities. The team shares criteria for when to step in—e.g., when an agent repeatedly fails on the same problem or heads in an unexpected direction.

### The Spec–Implement–Retro cycle

A cycle of **research → spec writing → spec refinement → spec review → implementation instruction → retrospective → code review** becomes established.

1. **Research**: information needed to write a spec is already prepared in an LLM-friendly form, or tools exist to collect it (MCP, scripts, custom prompts, etc.). For example, with [gather](./plugins/cwf/skills/gather/SKILL.md) you can provide a URL and it auto-detects the service and gathers Google Docs/Slack/Notion content via built-in scripts; with `gather-context --search` you can gather external information via web search and code/technical search. We provide these base materials to a research agent and receive a report.

2. **Spec writing**: we process the report into a spec and write it in Jira tickets/GitHub issues (ideally as pair work).

3. **Spec refinement**: tools that refine the spec (e.g., [clarify](./plugins/cwf/skills/clarify/SKILL.md)) are available. We run them locally or automate them via GitHub Actions, and (ideally with teammates) iterate with the tool to sharpen the spec.

4. **Spec review**: we review the refined spec and produce a final version. If we lack the ability to review it ourselves, we proactively learn. With AI and with teammates, we deepen our understanding of domain knowledge, the codebase, and the rationale behind decisions.

5. **Implementation instruction**: we hand the final spec to a coding agent to implement. We trust that with a good plan document and test cases, we can get the desired feature in a single turn—and we work to make that true.

6. **Retrospective**: if we don't get the desired result in one shot, we run a retrospective (e.g., [retro](./plugins/cwf/skills/retro/SKILL.md)). We ask the agent: "It didn't work out for these reasons—what should we have done up front to get the desired result?" Then we experiment by implementing again following that answer. This becomes part of the team's knowledge assets.

7. **Code review**: after implementation, we use a code-review agent (e.g., CodeRabbit, or a GitHub Action + Claude Code setup) for a pre-review to minimize the amount of human review needed. We retro on both wrong changes (false positives) and missing changes (false negatives), and learn "what should we have done up front to avoid this mistake?"

---

## 2. Organizational culture shifts

### Role boundaries blur

PMs and designers write code to show working prototypes, or even author PRs directly. Engineers get involved across frontend, backend, DB, and infra—and go further into planning and marketing across the full product development lifecycle. Cross-discipline learning and conversation happen very frequently.

### Everything can be automated

We believe anything a person does manually on a computer can be replaced by code or LLMs. We actively work to replace even a portion of routine work. Full automation can be hard initially due to permissions or security constraints, but we move forward while recognizing that, with humans acting as "glue" (uploading files, copying content, etc.), far more can be automated than expected.

### One person from start to finish

For new projects with low legacy dependencies, one person should, as much as possible, take main ownership and drive end-to-end from start to finish. However, individual ownership and pair work are not mutually exclusive:

- **Individual ownership**: one person holds final responsibility for decisions, maintains a holistic view of progress, and manages the schedule
- **When to pair**: we proactively ask for pair work in stages requiring specialized expertise (research, design, marketing, legal review, etc.) or when refining complex specs

In other words, it's not "one person does everything", but "one person orchestrates, collaborating when needed."

### Don't fear failure

It's okay if experiments with new tools, prompts, and workflows fail. Failure cases are shared as actively as success cases, and we analyze "why it didn't work" together. It's natural for an agent to not behave as expected, and the team learns through that process.

### Onboarding new teammates

New teammates who are unfamiliar with AI-native ways of working learn via pair prompting, use prompts and skills that have been turned into assets, and gradually become fluent. They start with small scopes and expand responsibility step by step.

---

## 3. Technical practices

### Invest in code quality

Everyone actively invests in the main product's code quality. We understand that higher-quality codebases make coding agents work better. Code quality metrics are managed on dashboards and establish a steadily improving practice (e.g., using the [refactor](./plugins/cwf/skills/refactor/SKILL.md) skill daily). With strong E2E tests, large refactors are not scary.

### Fix papercuts

Many "papercut" tasks—work that would have increased team efficiency if built, but was deprioritized—actually get implemented, including tools that improve code quality. Examples include backoffice admin, various linter rules, test code, static analysis scripts, and end-of-work notifications for agents (e.g., the [attention](./plugins/cwf/hooks/README.md) hook).

### Evaluation sets come first

If automated verification is possible, agents can iterate as much as needed to improve results. So we focus first on securing an evaluation set—an environment where an agent can work for longer and produce trustworthy output. When implementing new features, we first ask: "How can we verify this automatically?"

### Wasting tokens beats saving them

In an AI-native team, "efficiency" means optimizing **human time**. We believe token costs will become as cheap as electricity. Rather than spending time and effort to save tokens through human intervention, we think about how to let agents work longer and more. It's hard to intentionally spend tokens anyway. We provide sufficient information and run generous verify-and-retry loops.

## 4. Improve the process itself

The process described here is just a snapshot at a point in time. We regularly review the current workflow and discuss whether there are better approaches. When new AI tools or capabilities appear, we experiment with how to integrate them into the existing process. Anyone can propose process improvements, and we decide whether to adopt them based on experimental results.
