# Skill Review Criteria

Checklist distilled from skill-creator's Progressive Disclosure philosophy. Use this to evaluate a skill's SKILL.md and bundled resources.

## 1. SKILL.md Size

| Metric | Threshold | Severity |
|--------|-----------|----------|
| Word count | > 3,000 words | warning |
| Word count | > 5,000 words | error |
| Line count | > 500 lines | warning |

**Why**: The context window is a shared resource. SKILL.md body loads on trigger — keep it lean.

## 2. Progressive Disclosure Compliance

Check the three-level loading hierarchy:

- **Metadata (frontmatter)**: `name` + `description` only (~100 words). No extra fields.
  - `description` must include both what the skill does AND when to trigger it.
  - "When to use" info belongs in description, NOT in the body.
- **SKILL.md body**: Core workflow, procedural knowledge (<5k words).
  - Move detailed reference material, schemas, and examples to `references/`.
- **Bundled resources**: Loaded on demand by the agent.
  - Large references (>10k words) should have grep patterns in SKILL.md.

### Red flags

- Body contains "When to Use This Skill" section (should be in description)
- Body contains long code examples that could be in `references/` or `scripts/`
- Body contains API docs, schemas, or lookup tables (move to `references/`)

## 3. Duplication Check

Information should live in ONE place — either SKILL.md or references, not both.

- Compare SKILL.md content with each `references/*.md` file.
- Flag paragraphs or sections that appear in both.
- Preference: detailed info in `references/`, summary/pointer in SKILL.md.

## 4. Resource Health

Unified check for reference file quality and resource usage.

### File quality

| Check | Flag condition |
|-------|---------------|
| Reference file > 10k words | Needs grep patterns in SKILL.md |
| Reference file > 100 lines | Needs table of contents at top |
| Deeply nested references (ref → ref) | Keep one level deep from SKILL.md |

### Unused resources

Scan for files in `scripts/`, `references/`, and `assets/` not referenced in SKILL.md:

- A file is "referenced" if its filename (without path) appears in SKILL.md.
- Unused files waste disk and confuse readers — flag for removal or add a reference.

## 5. Writing Style

- Use imperative/infinitive form ("Run the script", not "You should run the script").
- Avoid extraneous documentation (README.md, INSTALLATION_GUIDE.md, etc.).
- Prefer concise examples over verbose explanations.
- Only include information the agent doesn't already know.

## 6. Degrees of Freedom

Evaluate whether instructions match the task's fragility:

- **High freedom** (text guidance): Multiple valid approaches, context-dependent decisions.
- **Medium freedom** (pseudocode/parameterized scripts): Preferred pattern exists, some variation OK.
- **Low freedom** (specific scripts): Fragile operations, consistency critical.

Flag mismatches: e.g., a fragile deployment script described only in prose (needs low freedom).

## 7. Anthropic Compliance

Check alignment with Claude Code plugin best practices:

### Folder naming

- Plugin folder must use kebab-case (e.g., `gather-context`, not `gatherContext` or `gather_context`)
- Skill folder under `skills/` must also use kebab-case

### SKILL.md metadata

- Frontmatter must contain only `name`, `description`, and optionally `allowed-tools`
- No XML tags in frontmatter values
- `name` must match the skill folder name

### Description quality

- Description must be ≤ 1024 characters
- Should follow the pattern: [What it does] + [When to use it] + [Key capabilities]
- Must include trigger phrases (e.g., "Use when user says...")
- Should differentiate from similar skills

### Composability

- Skills should not duplicate functionality available in other installed skills
- Cross-skill references should use defensive checks (gate on file/directory existence)
- Output format should be consumable by other skills when applicable
- Avoid hard dependencies on other plugins — prefer suggestions ("Consider running /X")

> **Note**: For rigorous cross-skill duplication and composition analysis, see holistic Axis 2 (Concept Integrity). This per-skill check catches obvious cases; holistic mode performs systematic comparison.

## 8. Concept Integrity

Verify that the skill correctly composes its claimed generic concepts.

**Input**: `{PLUGIN_ROOT}/references/concept-map.md`

### Verification steps

1. Look up the skill's **row** in the synchronization map (concept-map.md Section 2)
1. For each concept the skill claims to compose (`x` in the map):

| Check | What to verify | Flag condition |
|-------|---------------|----------------|
| Required behavior | Does the SKILL.md implement the concept's operational principle? | Concept claimed but behavior missing or contradicted |
| Required state | Does the skill maintain the concept's state elements? | State element referenced in concept but absent from skill |
| Required actions | Does the skill perform the concept's actions? | Action listed in concept but not present in skill workflow |

1. Check for **unclaimed concepts**: does the skill exhibit behavior matching a concept it doesn't claim? (potential missing synchronization)

### Example

Reviewing `gather`:

- Map shows: Agent Orchestration only
- Verify: adaptive sizing (Single/Adaptive) ✓, parallel batch for broad queries ✓, output synthesis ✓
- Check unclaimed: does gather route decisions by evidence? No → no missing sync
