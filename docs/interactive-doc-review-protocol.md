# Interactive Documentation Review Protocol

Repeatable, resumable workflow for user-facing documentation outside [prompt-logs](../prompt-logs/).

## Goal

- Review repository docs from a user perspective.
- Start each session with a relationship map and graph baseline.
- Continue file-by-file in small, meaningful chunks.
- For each chunk, explain intent and propose concrete review points.
- Resume in the same style when only this file path is mentioned.

## Working Principles (Captured from Recent AGENTS Review Cycles)

- Less is more: remove low-signal repetition and label clutter.
- Prefer what/why over procedural how in stable guidance documents.
- Keep `Review Focus` non-empty and line-anchored (minimum two concrete checks).
- Treat orphan triage as mandatory, not optional.
- Use Markdown links (`[]()`) for file/path mentions in review outputs.
- Avoid unnecessary hard-wrapped prose in authored docs.

## Review Scope

### Include

- Root docs: [AGENTS.md](../AGENTS.md), [README.md](../README.md), [README.ko.md](../README.ko.md), [CLAUDE.md](../CLAUDE.md), [AI_NATIVE_PRODUCT_TEAM.md](../AI_NATIVE_PRODUCT_TEAM.md), [AI_NATIVE_PRODUCT_TEAM.ko.md](../AI_NATIVE_PRODUCT_TEAM.ko.md), [cwf-index.md](../cwf-index.md), [repo-index.md](../repo-index.md), [CHANGELOG.md](../CHANGELOG.md)
- Project docs: [docs/*.md](.)
- Plugin shared references: [plugins/cwf/references/*.md](../plugins/cwf/references/)
- Plugin internal reference docs: [plugins/cwf/skills/*/references/*.md](../plugins/cwf/skills/)
- External references: [references/**/*.md](../references/)

### Exclude

- Session artifacts: [prompt-logs/**](../prompt-logs/)
- Skill definition files: [**/SKILL.md](../plugins/cwf/skills/)
- Local runtime helper docs outside project-facing scope: [.claude/**](../.claude/)

## Execution Contract (Mention-Only Safe)

If user input only mentions this file path (with or without "start"), treat it as an instruction to start or resume this workflow.

Run in fixed order:

1. Regenerate graph baseline.
2. Present relationship map.
3. Continue chunked review from cursor.
4. Pause after every chunk and continue only with explicit user acknowledgement.
5. Update `Review State` in this file.

## Queue Construction (Deterministic)

Queue groups:

1. Anchor files (fixed order)
2. [docs/*.md](.)
3. [plugins/cwf/references/*.md](../plugins/cwf/references/)
4. [plugins/cwf/skills/*/references/*.md](../plugins/cwf/skills/)
5. [references/**/*.md](../references/)

Reference command:

```bash
{
  printf '%s\n' \
    AGENTS.md \
    CLAUDE.md \
    cwf-index.md \
    repo-index.md \
    README.md \
    README.ko.md \
    AI_NATIVE_PRODUCT_TEAM.md \
    AI_NATIVE_PRODUCT_TEAM.ko.md \
    CHANGELOG.md

  rg --files docs -g '*.md' | sort
  rg --files plugins/cwf/references -g '*.md' | sort
  rg --files plugins/cwf/skills -g '*/references/*.md' | sort
  rg --files references -g '*.md' | sort
} | awk '!seen[$0]++'
```

## Step 1: Relationship Map and Graph Baseline

Before the first chunk in each session, run:

```bash
node scripts/doc-graph.mjs --json > docs/doc-graph.snapshot.json || true
jq '.stats' docs/doc-graph.snapshot.json
```

Then present:

- Documentation map (anchor docs -> policy docs -> references).
- Baseline metrics: `total_docs`, `total_links`, `orphan_count`, `broken_ref_count`.
- One-line interpretation of current graph density and orphan risk.

[scripts/doc-graph.mjs](../scripts/doc-graph.mjs) respects [`.doc-graph-ignore`](../.doc-graph-ignore). Files listed there are excluded from graph checks by design.

If structure or links were edited during the session, regenerate [docs/doc-graph.snapshot.json](doc-graph.snapshot.json) before the next file group.

## Orphan Gates (Mandatory)

### Gate A: Session Baseline

Record baseline stats from [docs/doc-graph.snapshot.json](doc-graph.snapshot.json).

### Gate B: Group Boundary Recheck

After each queue group, rerun graph stats and report deltas (orphans, broken refs, new orphan candidates).

### Gate C: Per-File Inbound Check

At each file boundary, report:

```text
Inbound links: <N> (orphan: yes/no)
```

### Gate D: Final Orphan Triage

Classify each orphan as:

1. `Intentional orphan`
2. `Needs link fix`
3. `Deferred (decision pending)`

For each `Needs link fix`, propose source file, target section, and rationale.

## Step 2: Chunked File Review

### Chunking Rules

- Use meaningful chunks (usually 60-120 lines).
- Do not split a heading block, table, or fenced code block.
- Review each file sequentially to EOF.
- Ask confirmation at each file boundary.

### Output Contract Per Chunk

For each chunk, provide exactly:

1. `Chunk`: `{file}:{start_line}-{end_line}` and EOF 여부
2. `Excerpt`
3. `Meaning / Intent`
4. `Review Focus (Line-Anchored)` with at least 2 concrete points
5. `Link Syntax Check` for Markdown-link compliance (`[]()`)
6. `De-dup / What-Why Check` (overlap, low-signal labels, procedural overload)
7. `Discussion Prompt` with 1-2 concrete questions

Then pause.

## Resume Rules

On resume:

1. Rebuild queue with the deterministic rule.
2. Read `Review State.cursor`.
3. Resume at `cursor.file` from `cursor.next_line`.
4. If lines drift, anchor by nearest previous heading.
5. Keep the same chunk -> intent -> focus -> pause cadence.

## Review State (Update In Place)

```yaml
review_state:
  version: 2
  status: in_progress
  queue_policy: anchors_then_docs_then_plugin_refs_then_skill_refs_then_references
  map_presented_in_current_session: true
  graph_baseline:
    total_docs: 69
    total_links: 435
    orphan_count: 0
    broken_ref_count: 0
  group_progress:
    anchors_done: false
    docs_done: false
    plugin_refs_done: false
    skill_refs_done: false
    references_done: false
  cursor:
    file: repo-index.md
    next_line: 1
  completed_files: [AGENTS.md, CLAUDE.md, cwf-index.md]
  current_file_eof: true
  last_chunk_range: "cwf-index.md:1-43"
  last_inbound_count: 9
  orphan_triage:
    intentional: []
    needs_link_fix: []
    deferred: []
  unresolved_discussion_points:
    - "CLAUDE.md routing duplication: keep both sentence pointer and numbered read-first list?"
    - "CLAUDE.md env fallback note: keep in adapter or move to troubleshooting doc?"
    - "cwf-index.md line-3 self-link: keep for template consistency or remove as low-signal?"
  last_updated: "2026-02-14"
```

## Start Command

```text
@docs/interactive-doc-review-protocol.md 시작
```
