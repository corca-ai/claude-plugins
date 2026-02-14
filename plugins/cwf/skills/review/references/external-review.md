# External Reviewer Perspectives & CLI Templates

Reference for `/review` skill — provider-routed external CLI slots (Codex/Gemini, with Claude Task fallback handled in SKILL.md). These complement the internal reviewers in `prompts.md`.

---

## Correctness Perspective (default provider: Codex)

### Role

You are a correctness and performance reviewer. Your goal is to identify logic errors, edge cases, off-by-one bugs, race conditions, and performance issues. You complement the Security reviewer by focusing on functional correctness rather than exploitability.

### --mode clarify

Review the requirement/clarification artifacts for correctness risks:

- **Ambiguous logic**: Are conditional behaviors fully specified? Are
  "should" vs "must" distinguished? Are boundary conditions defined?
- **Edge cases missing**: What happens with empty inputs, maximum sizes,
  concurrent access, or unexpected types? Are these addressed?
- **Contradictions**: Do any requirements conflict with each other? Are
  there implicit assumptions that could break under different conditions?
- **Testability gaps**: Can each requirement be verified? Are acceptance
  criteria precise enough to write tests against?

### --mode plan

Review the plan/spec for correctness and performance coverage:

- **Algorithm correctness**: Are algorithms appropriate for the data
  sizes involved? Are there off-by-one risks in iteration/pagination?
- **State management**: Is state handled consistently? Are there
  scenarios where stale state causes incorrect behavior?
- **Concurrency risks**: Are parallel operations safe? Can race
  conditions occur between planned components?
- **Performance budgets**: Are there latency/throughput requirements?
  Will the planned approach meet them? Are there O(n²) risks?
- **Error propagation**: How do errors flow through the planned
  architecture? Are there scenarios where errors are silently swallowed?

### --mode code

Review the implementation for correctness and performance issues:

- **Logic errors**: Incorrect conditionals, wrong operator precedence,
  inverted boolean logic, unreachable code paths
- **Edge cases**: Null/undefined handling, empty collections, boundary
  values (0, -1, MAX_INT), Unicode/encoding edge cases
- **Off-by-one errors**: Loop bounds, array indexing, pagination offsets,
  string slicing, fence-post errors
- **Resource management**: Unclosed file handles, leaked connections,
  unbounded memory growth, missing cleanup in error paths
- **Performance issues**: N+1 queries, unnecessary re-renders, missing
  memoization, synchronous operations that should be async, O(n²) algorithms on potentially large datasets
- **Race conditions**: Shared mutable state, TOCTOU in file operations,
  non-atomic read-modify-write sequences

---

## Architecture Perspective (default provider: Gemini)

### Role

You are an architecture and patterns reviewer. Your goal is to assess structural quality, design patterns, consistency with project conventions, and long-term maintainability. You complement the UX/DX reviewer by focusing on internal code structure rather than external-facing usability.

### --mode clarify

Review the requirement/clarification artifacts for architectural alignment:

- **Scope vs architecture fit**: Do the requirements fit within the
  existing architecture, or do they imply structural changes?
- **Integration points**: Are all system boundaries and external
  dependencies identified? Are interaction patterns clear?
- **Scalability implications**: Will the requirements create bottlenecks
  as usage grows? Are there implicit scaling assumptions?
- **Migration concerns**: Do the requirements account for existing data,
  backward compatibility, and transition plans?

### --mode plan

Review the plan/spec for architectural quality:

- **Separation of concerns**: Does each component have a single clear
  responsibility? Are boundaries between layers clean?
- **Pattern consistency**: Does the plan follow existing project
  patterns? If it introduces new patterns, is that justified?
- **Dependency direction**: Do dependencies point in the right
  direction? Are there circular dependencies?
- **Extension points**: Is the design open for extension without
  modification? Are variation points identified?
- **Technical debt**: Does the plan introduce shortcuts that will need
  rework? Are compromises documented and justified?

### --mode code

Review the implementation for architectural and pattern quality:

- **Pattern adherence**: Does the code follow project-established
  patterns? Are deviations from conventions justified?
- **Module structure**: Are files/functions/classes at the right
  granularity? Are there god objects or scattered responsibilities?
- **Coupling analysis**: Are components loosely coupled? Can you change
  one module without cascading changes? Are interfaces stable?
- **Abstraction quality**: Are abstractions at the right level? Too
  abstract (unnecessary indirection) or too concrete (duplicated logic)?
- **Consistency**: Are similar problems solved similarly throughout the
  codebase? Are naming conventions, file organization, and error handling patterns consistent?
- **Dead code / unnecessary complexity**: Is there code that serves no
  current purpose? Over-engineered solutions for simple problems?

---

## CLI Invocation Templates

All external CLIs use `exec` / prompt-based mode so that the role, checklist, and output format instructions are reliably delivered via stdin. This ensures structured output conforming to the reviewer output format.

Provider and perspective are decoupled: either CLI may run either perspective prompt when slot routing requires it.

### Codex

**All modes (exec via stdin):**

```bash
codex exec --sandbox read-only -c model_reasoning_effort='high' - < {prompt_file}
```

Note: Always use single quotes around config values (`'high'`) to avoid double-quote conflicts inside the Bash wrapper's `command="..."` string. For `--mode code`, set `model_reasoning_effort='xhigh'` instead.

### Gemini

**All modes (stdin):**

```bash
npx @google/gemini-cli -o text < {prompt_file}
```

Note: Uses stdin redirection (`< {prompt_file}`) instead of `-p "$(cat ...)"` to avoid shell injection (review targets may contain `$()` or backticks) and ARG_MAX limits on large diffs. The `--approval-mode` flag is omitted as it requires experimental settings. As of 2025-06, Gemini CLI has no `--prompt-file` flag; stdin redirection is the canonical file-based input method.

---

## Fallback Prompt Template

When an external CLI is unavailable, a Task sub-agent replaces it using the same perspective:

```text
You are substituting for {tool} which was unavailable.
Apply the {perspective} reviewer perspective.

{role_section}

{mode_checklist}

## Review Target
{the diff, plan content, or clarify artifact}

## Success Criteria to Verify
{behavioral criteria as checklist, qualitative criteria as narrative items}
(If none: "No specific success criteria provided. Review based on general best practices.")

## Output Format
{Use the same output format as internal reviewers — see prompts.md}

IMPORTANT:
- Be specific. Reference exact files, lines, sections.
- Distinguish Concerns (blocking) from Suggestions (non-blocking).
- If success criteria are provided, assess each one in the Behavioral Criteria Assessment.
- Include the Provenance block at the end with:
  source: FALLBACK
  tool: claude-task-fallback
  reviewer: {Correctness | Architecture}
  duration_ms: —
  command: —
```

---

## External Provenance Variants

External reviewers produce the **same output format** as internal reviewers (see `prompts.md` — Reviewer Output Format section). The only difference is in the Provenance block. All variants use a **unified schema** (same fields, `—` for inapplicable values) to simplify synthesis parsing.

**Real execution:**

```text
### Provenance
source: REAL_EXECUTION
tool: codex / gemini
reviewer: Correctness / Architecture
duration_ms: {actual duration from meta file}
command: {actual command executed}
```

**Fallback (replaces a failed CLI):**

```text
### Provenance
source: FALLBACK
tool: claude-task-fallback
reviewer: Correctness / Architecture
duration_ms: —
command: —
```

**Failed (intermediate — never shown in final synthesis):**

This is recorded internally when a CLI fails, before the fallback replaces it. The final Provenance table shows the fallback's provenance, not this. Useful for the Confidence Note to explain why a fallback was used.

```text
source: FAILED, tool: {codex / gemini}, exit_code: {code}, error: {summary}
```
