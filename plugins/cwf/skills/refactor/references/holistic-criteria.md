# Holistic Analysis Framework

<!-- Provenance: written at 5 skills, 7 hooks (S11a). Updated at 9 skills, 14 hooks (S13). -->

Three dimensions for cross-plugin analysis. Apply each to the full plugin inventory.

## 1. Pattern Propagation

Identify good patterns in one skill that others should adopt, and repeated patterns that should be extracted into shared references.

**What to look for:**

### 1a. Convention compliance

Read `{PLUGIN_ROOT}/references/skill-conventions.md` and verify each skill against its checklists. Flag deviations with specific file:line references.

### 1b. Pattern gaps

- Language adaptation: does every user-facing skill specify how to match the user's language?
- Sub-agent usage: when skills use Task tool, do they follow the mature pattern (reference guide in references/, parallel execution, structured output)?
- Usage message: do skills with subcommands show help when invoked with no args?
- Configuration: are env vars named consistently (CLAUDE_CORCA_{PLUGIN}_{SETTING})?
- Output persistence: do skills that produce artifacts offer to save them?
- Progressive Disclosure: do all skills follow the three-level hierarchy (metadata → body → references)?

### 1c. Pattern extraction opportunities

When 3+ skills repeat the same structural pattern, prose block, or rule text:
- Identify the repeated content
- Propose extracting it to a shared reference file under `{PLUGIN_ROOT}/references/`
- If the shared reference already exists (e.g., `skill-conventions.md`), verify skills comply with it; if not, propose fixes

**How to report:**
For each pattern gap, name the source skill (where the pattern is done well) and the target skills (where it's missing). Be specific about what to add — not "add language adaptation" but "add `**Language**: Match the user's language.` after the title."

For extraction opportunities: cite the repeated text, list all skills that contain it, and propose the shared reference location.

## 2. Boundary Issues

Find overlapping roles, ambiguous triggers, or unclear when-to-use guidance.

**What to look for:**
- Multiple skills that could trigger on the same user intent
- Descriptions that don't clearly differentiate from similar skills
- Skills that partially duplicate each other's functionality
- Hook conflicts (multiple hooks on the same matcher)

**How to report:**
For each boundary issue, list the conflicting skills, describe the ambiguous user intent, and propose a resolution (clearer descriptions, merge, explicit routing guidance in README).

## 3. Missing Connections

Find natural handoffs between skills that are currently broken.

**What to look for:**
- Skill A produces output that Skill B could consume, but no link exists
- A workflow that requires manual invocation of multiple skills in sequence
- Skills that do internal research when another skill already provides that capability
- Hook infrastructure that could bridge two skills but doesn't

**How to report:**
For each missing connection, describe the flow (A → B), what's currently broken, and propose a concrete fix. Include defensive check requirements — the connection must work when either skill is not installed.

**Important constraints on connections:**
- Cross-plugin dependencies must be defensive (gate on existence)
- Prefer lightweight suggestions ("Consider running /X") over hard dependencies
- Don't create circular dependencies
