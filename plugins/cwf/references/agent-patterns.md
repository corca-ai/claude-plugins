# Agent Patterns Reference

Shared reference for all cwf skills that orchestrate sub-agents or agent teams.

## Decision Criteria

When to use single agent vs team:

| Pattern | When | Example |
|---------|------|---------|
| **Single** | Interactive, sequential, low complexity | `cwf:setup`, `cwf:update`, `cwf:handoff` |
| **Adaptive** | Complexity varies — detect and scale | `cwf:gather` (broad = parallel, specific = single) |
| **Agent team** | Multi-perspective work, parallelizable | `cwf:plan`, `cwf:impl` |
| **4 parallel** | Review/validation requiring diverse perspectives | `cwf:review`, `cwf:retro`, `cwf:refactor` |

## Adaptive Sizing

Task complexity detection drives team composition:

1. **Assess scope** — count files, estimate cross-cutting concerns
2. **Choose pattern** — single for focused tasks, team for broad ones
3. **Scale team** — add agents only when each has distinct work

Avoid spawning agents that will idle. A 2-agent team doing real work beats a 5-agent team where 3 wait.

## Execution Patterns

Two mechanisms for parallel execution:

### External CLI (Bash background)

```text
Bash: nohup codex ... &
Bash: nohup npx @google/gemini-cli ... &
```

- Use for external AI CLIs (Codex, Gemini)
- Set timeout (default 300s)
- Capture PID for monitoring
- Output to temp files, collect after completion

### Internal (Task tool)

```text
Task(subagent_type="general-purpose", prompt="...")
```

- Use for Claude-native sub-agents
- Security reviewer, UX/DX reviewer, research agents
- Has access to full tool suite
- No timeout needed (managed by Claude Code)

## Multi-Agent Review Pattern

4 parallel reviewers with mode-specific focus:

```text
4 parallel reviewers:
+-- External (Bash background, timeout 300s)
|   +-- Codex: reasoning=xhigh (code) / high (spec)
|   +-- Gemini: npx @google/gemini-cli
+-- Internal (Task tool)
    +-- Security: vulnerabilities, auth, data exposure
    +-- UX/DX: API design, error messages, developer experience
```

### Review Modes

| Mode | Trigger | Focus |
|------|---------|-------|
| `--mode clarify` | After requirement gathering | Intent alignment, completeness, ambiguity detection |
| `--mode plan` | After spec/plan creation | Feasibility, edge cases, best practices |
| `--mode code` | After implementation | Correctness, simplicity, security, performance |

## Graceful Degradation

When an external CLI is unavailable:

1. **Detect**: `command -v codex` or `which npx` check
2. **Fallback**: Spawn Task agent with the same perspective prompt
3. **Never**: Run the review inline in the main agent (blocks other work)
4. **Track**: Mark output with `Source: FALLBACK` (see Provenance Tracking)

Timeout handling:

1. Wait for configured timeout (default 300s)
2. If exceeded, mark output as `Source: FAILED`
3. Spawn Task agent fallback with same prompt
4. All 4 reviews always run regardless of individual failures

## Provenance Tracking

Every agent/review output must include provenance metadata:

```yaml
source: REAL_EXECUTION | FALLBACK | FAILED
tool: codex | gemini | claude-task | claude-task-fallback
timestamp: "2025-02-08T12:00:00Z"
duration_ms: 45000
command: "codex --reasoning xhigh ..."  # for external CLIs
```

This enables:

- **Audit trail** — which tool actually produced each review
- **Quality signals** — fallback reviews may have different characteristics
- **Optimization** — track which CLIs are reliably available per environment

## Perspective-Based Division

When splitting work across agents, divide by **perspective** not by module:

| Perspective | Focus |
|------------|-------|
| Content integrity | Does the output match requirements? Are there gaps? |
| Missed opportunities | What could be improved? Alternative approaches? |
| Structural analysis | Architecture, patterns, consistency, maintainability |
| Security/risk | Vulnerabilities, data exposure, auth issues |

This prevents blind spots that occur when agents only review "their" files.

## Review Synthesis Format

`cwf:review` outputs structured narrative — not numerical scores. Numerical scoring creates false precision and invites mechanical thresholds ("77% so it passes"). Narrative preserves context and trusts intelligent agents.

### Verdict Levels

| Verdict | Meaning |
|---------|---------|
| **Pass** | No concerns. Safe to proceed. |
| **Conditional Pass** | Minor concerns that should be addressed, but not blocking. |
| **Revise** | Significant concerns. Must address before proceeding. |

### Output Template

```text
## Review Synthesis

### Verdict: [Pass | Conditional Pass | Revise]
[1-2 sentence summary of overall assessment]

### Concerns (must address)
- [Reviewer name: specific concern with context]

### Suggestions (optional)
- [Reviewer name: improvement idea]

### Confidence Note
[Note any disagreements between reviewers, or areas where confidence is low]
```

### Verification Input

When `--mode plan` or `--mode code` is used, `cwf:review` receives the plan's success criteria as verification input:

- **Behavioral criteria** (BDD-style Given/When/Then): checked as a pass/fail list
- **Qualitative criteria** (narrative): addressed in the verdict prose

## Web Research Protocol

All sub-agents that use WebSearch/WebFetch must follow these rules to avoid wasting turns on invalid URLs:

1. **Discover before fetching**: Use WebSearch to find valid URLs first. NEVER construct URLs from memory or training data — they may be outdated or nonexistent.
2. **Skip failed domains**: If a WebFetch returns 404 or 429, skip that domain entirely. Move to the next source.
3. **Stop when sufficient**: Find 3-5 authoritative sources. Stop when sufficient evidence is collected — do NOT exhaustively search.
4. **Prefer official sources**: Official documentation and primary sources over blog posts.
5. **Budget turns**: Reserve at least 2-3 turns for writing output. If `max_turns` is 12, stop researching by turn 9-10.

Include this protocol (or reference this section) in every sub-agent prompt that involves web research. Failure to include it causes agents to exhaust `max_turns` on 404 retries without producing output.

## Design Principles

### Deliberate Naivete

From StrongDM's SW Factory: challenge internalized cost assumptions. Never reduce review depth, agent count, or verification thoroughness because "it costs too many tokens." If the design calls for 4 reviewers, run 4 reviewers. The question is "does this improve quality?" not "is this expensive?"

### Shift Work

Separate interactive work (human refining intent) from autonomous work (agent executing on fixed spec). `cwf-state.yaml` encodes this via `auto: true/false` per stage:

- **Interactive** (auto: false): gather, clarify, plan — human in the loop
- **Autonomous** (auto: true): impl → review → retro → commit — agent chains automatically
