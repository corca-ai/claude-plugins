# Retro Section Authoring and Output Templates

Detailed writing guidance for `retro`:
- Section 1-7 authoring expectations
- Section 7 capability/tool gap workflow
- Light/deep output templates

`SKILL.md` keeps execution routing and gate contracts. Use this file for section-level writing details.

## Contents

- [Section Authoring Guide](#section-authoring-guide)
- [Section 1: Context Worth Remembering](#section-1-context-worth-remembering)
- [Section 2: Collaboration Preferences](#section-2-collaboration-preferences)
- [Section 3: Waste Reduction](#section-3-waste-reduction)
- [Section 4: Critical Decision Analysis (CDM)](#section-4-critical-decision-analysis-cdm)
- [Section 5: Expert Lens](#section-5-expert-lens)
- [Section 6: Learning Resources](#section-6-learning-resources)
- [Section 7: Relevant Tools (Capabilities Included)](#section-7-relevant-tools-capabilities-included)
- [Output Templates](#output-templates)
- [Light mode template](#light-mode-template)
- [Deep mode template](#deep-mode-template)

## Section Authoring Guide

Use this guide when drafting `retro.md` sections after execution artifacts are ready.

## Section 1: Context Worth Remembering

Capture user/org/project facts useful for future sessions:
- domain knowledge
- stack/conventions
- team structure and decision patterns

Keep only durable, high-signal items.

## Section 2: Collaboration Preferences

Capture work style and communication observations, then compare against AGENTS/runtime adapter docs.

If warranted, add:
- `### Suggested Agent-Guide Updates`

Right-placement check:
- behavioral collaboration contract -> AGENTS/runtime adapter docs
- architectural pattern/context -> `project-context.md`

## Section 3: Waste Reduction

Identify wasted effort categories:
- wasted turns
- over-engineering
- missed shortcuts
- context waste
- communication waste

Use free-form analysis with concrete session moments (no fixed table required).

Root cause drill-down (5 Whys):

- Distinguish one-off mistakes vs structural causes.
- Push to durable fix level:
  - knowledge gap
  - process gap
  - structural constraint

## Section 4: Critical Decision Analysis (CDM)

- Light mode: draft inline using `{SKILL_DIR}/references/cdm-guide.md`
- Deep mode: integrate Agent A output

Identify 2-4 critical decision moments and apply CDM probes.

## Section 5: Expert Lens

Deep mode only. In light mode, output:
- `"Run \`/retro --deep\` for expert analysis."`

In deep mode:
- integrate Agent C/D outputs
- add `### Agreement and Disagreement Synthesis` with:
  - 2-4 shared conclusions
  - 1-3 explicit disagreements and assumption deltas
  - synthesis decision (adopt now/defer/evidence to resolve)

## Section 6: Learning Resources

Deep mode only. In light mode, output:
- `"Run \`/retro --deep\` for learning resources."`

Deep mode output requirements:
- title + URL
- 2-3 sentence takeaway
- relevance to user workflow

## Section 7: Relevant Tools (Capabilities Included)

### Step 1 — Inventory available capabilities

1. Scan installed agent skills:
   - marketplace: `~/.claude/plugins/*/skills/*/SKILL.md`
   - local: `.claude/skills/*/SKILL.md`
2. Inventory deterministic repo tools/checks already available.
3. Summarize used vs available-but-unused capabilities in this session.

### Step 2 — Tool gap analysis

When a repeated/high-impact gap exists, classify by category:
- missing or underused agent skill
- missing static analysis check/tool
- missing validation/reachability check
- missing indexing/search/dedup utility
- missing workflow automation (hook/CI/script)

Per proposal include:
- session signal
- candidate tool/skill
- integration point
- expected gain + risk/cost
- small reversible pilot scope

### Step 3 — Action path by category

- Skill gap:
  - search existing options with `/find-skills`
  - if unavailable, record evidence (`command -v find-skills`) and fallback rationale
  - if no fit exists, define creation path with `/skill-creator`
- Non-skill tool gap:
  - recommend concrete tools and minimal pilot integration plan
- Prerequisite note:
  - when relevant, recommend installing missing `find-skills` / `skill-creator`

## Output Templates

Use these templates when writing `{output-dir}/retro.md`.

## Light mode template

```markdown
# Retro: {session-title}

- Session date: {YYYY-MM-DD}
- Mode: light

## 1. Context Worth Remembering
## 2. Collaboration Preferences
### Suggested Agent-Guide Updates
## 3. Waste Reduction
## 4. Critical Decision Analysis (CDM)
## 5. Expert Lens
> Run `/retro --deep` for expert analysis.
## 6. Learning Resources
> Run `/retro --deep` for learning resources.
## 7. Relevant Tools (Capabilities Included)
### Installed Capabilities
### Tool Gaps
```

## Deep mode template

```markdown
# Retro: {session-title}

- Session date: {YYYY-MM-DD}
- Mode: deep

## 1. Context Worth Remembering
## 2. Collaboration Preferences
### Suggested Agent-Guide Updates
## 3. Waste Reduction
## 4. Critical Decision Analysis (CDM)
## 5. Expert Lens
## 6. Learning Resources
## 7. Relevant Tools (Capabilities Included)
### Installed Capabilities
### Tool Gaps
```
