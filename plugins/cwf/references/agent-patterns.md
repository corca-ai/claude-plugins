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

## Broken Link Triage Protocol

When a broken link is detected (e.g., by `check-links-local.sh`), the agent should **NOT** default to "remove the reference." Instead, follow this triage:

### 1. Check git log

Was the target recently deleted?

```bash
git log --diff-filter=D --name-only -- <path>
```

If yes, investigate **why** the file was deleted before deciding how to handle the broken link.

### 2. Classify callers by type

For each file that references the missing target, classify the reference:

| Caller Type | Examples |
|-------------|----------|
| **Runtime** | Script `source`/`.` includes, `bash <path>`, `exec` calls, import statements |
| **Build/Test** | CI configs, test fixtures, Makefile targets, package.json scripts |
| **Documentation** | READMEs, comments, inline doc references, SKILL.md references |
| **Stale** | No recent usage, dead code, orphaned references |

### 3. Decision matrix

| Caller Type | Action |
|-------------|--------|
| Runtime caller exists | **STOP. Restore the deleted file.** |
| Build/test dependency | Restore file or update build config |
| Documentation reference | Update docs to reflect removal |
| No callers / stale ref | Remove the broken reference |

Rule: never treat "broken link" as "remove reference" by default. Determine why the file is missing before editing references.

### 4. Record the triage decision

Persist the triage decision in the current session's artifacts — either `lessons.md` or `live.decision_journal` in the resolved live-state file.

### Integration with check-links-local.sh hook

The `check-links-local.sh` PostToolUse hook automatically checks for broken links when markdown files are edited. When the hook blocks an edit due to broken links, its error message includes a reference to this protocol.

This means agents encountering a hook block should:

1. Read the broken link details from the hook output
2. Follow the triage protocol above (git log → classify callers → decision matrix)
3. Take the appropriate action from the decision matrix — **not** simply remove the reference to make the hook pass
4. Record the triage decision before re-attempting the edit

## Web Research Protocol

All sub-agents that use WebSearch/WebFetch must follow these rules. Include this protocol (or reference this section) in every sub-agent prompt that involves web research.

### Phase 1: Discover URLs

Use WebSearch to find valid URLs first. NEVER construct URLs from memory or training data — they may be outdated or nonexistent. Find 3-5 authoritative sources. Stop when sufficient evidence is collected. Prefer official documentation over blog posts.

### Phase 2: Fetch Content (two-tier)

**Tier A — WebFetch** (try first, fast and lightweight):

Use WebFetch for the discovered URL. If it returns substantive content (>50 chars of body text), use it and move on.

**Tier B — agent-browser** (fallback for JS-rendered sites):

If WebFetch returns empty or minimal content, the page likely requires JavaScript rendering. Check availability and use agent-browser:

```bash
command -v agent-browser  # check if installed
agent-browser open <url>
agent-browser snapshot -c  # compact accessibility tree
agent-browser close
```

agent-browser renders JavaScript via headless Chromium. It handles SPAs, client-side rendering, and redirect chains that WebFetch cannot.

If agent-browser is not installed, skip the URL and move to the next source. Do not retry the same URL with WebFetch.

**Fetch decision flow**:

```text
URL discovered via WebSearch
  → WebFetch(url)
    → got content? → use it ✓
    → empty/minimal?
      → agent-browser available?
        → yes → agent-browser open+snapshot → use it ✓
        → no  → skip URL, next source
```

### Common Rules

1. **Skip failed domains**: If any fetch returns 404, 429, or 403, skip
   that domain entirely. Move to the next source.
2. **Budget turns**: Reserve at least 2-3 turns for writing output. If
   `max_turns` is 12, stop researching by turn 9-10.
3. **No retry loops**: Each URL gets at most 2 attempts (WebFetch +
   agent-browser). Never retry the same URL with the same tool.

## Design Principles

### Deliberate Naivete

From StrongDM's SW Factory: challenge internalized cost assumptions. Never reduce review depth, agent count, or verification thoroughness because "it costs too many tokens." If the design calls for 4 reviewers, run 4 reviewers. The question is "does this improve quality?" not "is this expensive?"

### Shift Work

Separate interactive work (human refining intent) from autonomous work (agent executing on fixed spec). `cwf-state.yaml` encodes this via `auto: true/false` per stage:

- **Interactive** (auto: false): gather, clarify, plan — human in the loop
- **Autonomous** (auto: true): impl → review → retro → commit — agent chains automatically
