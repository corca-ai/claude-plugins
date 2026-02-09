# Clarify: Self-Healing Provenance Design (Workstream A)

> Session: S13.5 | Date: 2026-02-09

## Original Requirement

"Self-healing criteria design for CWF plugin — provenance metadata schema, staleness detection logic, threshold design, and adaptive response menu. Generalize to ALL documents agents rely on."

## Clarified Design

### Architecture

```text
Layer 1: .provenance.yaml (metadata sidecar files)     ← S13.5
Layer 2: provenance check (detect + 3-level response)  ← S13.5
Layer 3: DSPy optimization (auto-improvement suggest)   ← future session
```

### Provenance Schema (.provenance.yaml)

Location: Same folder as the target document (sidecar file, NOT inline in the document).

```yaml
# Example: plugins/cwf/skills/refactor/references/holistic-criteria.provenance.yaml
target: holistic-criteria.md
written_session: S11a
last_reviewed: S13
skill_count: 9
hook_count: 14
designed_for:
  - "Cross-plugin analysis across 9 CWF skills with single-mode routing"
  - "14 hook scripts in 7 functional groups"
  - "Pattern propagation, boundary, and connection dimensions"
```

**Fields:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `target` | string | yes | Filename of the document this provenance describes |
| `written_session` | string | yes | Session ID when the document was created |
| `last_reviewed` | string | yes | Session ID when last reviewed for validity |
| `skill_count` | integer | yes | Number of CWF skills at time of last review |
| `hook_count` | integer | yes | Number of hook scripts at time of last review |
| `designed_for` | list[string] | no | Scope declarations — what system state this doc was designed for |

### Target Documents (Category A — system-state-dependent)

1. `plugins/cwf/skills/refactor/references/holistic-criteria.md`
2. `plugins/cwf/skills/refactor/references/review-criteria.md`
3. `plugins/cwf/skills/refactor/references/docs-criteria.md`
4. `plugins/cwf/references/skill-conventions.md`
5. `docs/project-context.md`
6. `CLAUDE.md`

### Staleness Detection

**Deterministic check (count comparison):**
- Read current skill count: `ls plugins/cwf/skills/*/SKILL.md | wc -l`
- Read current hook count: `ls plugins/cwf/hooks/scripts/*.sh | wc -l` (excluding gate)
- Compare against .provenance.yaml values
- ANY change triggers further evaluation

**Non-deterministic check (scope evaluation):**
- When count changes OR `designed_for` exists, agent evaluates:
  "Does this document's scope still cover the current system?"
- Agent reads the target document + current system state and judges

### 3-Level Response

| Level | Trigger | Action |
|-------|---------|--------|
| **inform** | Count unchanged, no scope issues | Log "provenance check passed" — no user interruption |
| **warn** | Count changed OR scope may not cover current system | Agent notifies user: "Document X was reviewed at Y skills, now Z. Consider reviewing." User decides to continue or pause |
| **stop** | Count changed significantly (±50%+) AND scope explicitly violated | Agent halts skill execution: "Criteria document is likely invalid for current system. Review required before proceeding." |

### Index Script

`scripts/provenance-index.sh`:
- Scans all `.provenance.yaml` files
- Outputs JSON summary of all provenance states
- Compares against current system state
- Produces dashboard (text or JSON)
- DSPy-compatible: JSON output can feed optimization pipeline

### Dual Audience

- **Developer**: Full provenance report via index script, all .provenance.yaml visible
- **External user**: Optional summary badge in marketplace or skill description (future)

## Decisions Made

| # | Question | Decision | Decided By |
|---|----------|----------|------------|
| 1 | Schema format | Sidecar `.provenance.yaml` files | Human |
| 2 | Metadata fields | 5 core + structured `designed_for` scope | Human |
| 3 | Check placement | Shared checker (local skill or script) | Agent (T1) |
| 4 | Threshold | Any count change + agent scope evaluation | Human |
| 5 | Response menu | 3-level (inform/warn/stop) | Human |
| 6 | SKILL.md provenance | Not needed (execution spec, not criteria) | Agent (T1) |
| 7 | Hook provenance | Not needed (execution code, no state dependency) | Agent (T1) |
| 8 | Artifact scope | Category A only (6 files) | Agent (T1) |
| 9 | Audience | Dual layered (dev full, user badge optional) | Human |
| 10 | DSPy integration | Layer 1-2 DSPy-compatible, Layer 3 future | Human |
| 11 | Staleness signal | Hybrid: count as proxy + designed_for scope | Human |
| 12 | Location | Sidecar in same folder, not inline in doc | Human |
