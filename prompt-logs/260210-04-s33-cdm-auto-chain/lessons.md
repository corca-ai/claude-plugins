# Lessons — S33 CDM Improvements + Auto-Chaining

### Gate extraction is a high-ROI refactor

- **Expected**: Extracting gates from impl/SKILL.md would be a simple cut-and-paste
- **Actual**: The extraction forced a clean separation of "what" (SKILL.md pointer) from "how" (reference file), which made subsequent CDM 2 and CDM 3 additions to impl/SKILL.md cleaner — they touched the simplified file, not the bloated original
- **Takeaway**: When a SKILL.md exceeds ~300 lines, consider extracting procedural blocks to references before adding more features. The extraction itself improves the edit surface for future changes.

### Gemini CLI has no retry/timeout control flags

- **Expected**: Gemini CLI would support `--max-retries 0` or `--timeout` flags to control retry behavior
- **Actual**: `npx @google/gemini-cli --help` shows no such flags. Internal exponential backoff cannot be disabled.
- **Takeaway**: For external CLIs without retry control, the only defense is (1) shorter outer timeout and (2) stderr parsing for fail-fast classification. We reduced timeout from 280s to 120s and added error-type classification.

### Decision journal is a minimal-overhead mechanism

- **Expected**: Decision journal would require significant changes to impl/SKILL.md workflow
- **Actual**: The mechanism is just "append a string to a YAML list" during impl phases. The compact recovery hook reads it with the same line-by-line parser already in place. Total impl/SKILL.md addition: ~20 lines.
- **Takeaway**: When adding persistent state to a workflow, prefer append-only lists over complex structures. YAML lists are easy to parse in bash and easy to write from any context.

### cwf:run leverages Skill tool for clean chaining

- **Expected**: Auto-chaining would require complex inter-skill communication
- **Actual**: The Skill tool provides exactly the right abstraction — invoke a skill, wait for completion, check result, decide next step. cwf:run is essentially a state machine that calls `Skill(skill="cwf:X")` in a loop.
- **Takeaway**: When designing orchestration skills, prefer sequential Skill invocations over spawning Task agents. The Skill tool preserves the conversation context, which is critical for user gates.

### Convention-level lessons recur; structure-level lessons stick

- **Expected**: Recording a lesson in lessons.md would prevent recurrence
- **Actual**: S32's commit strategy lesson (CDM 2) recurred in S33 — user had to intervene with "Do commit in proper units." SKILL.md structural changes (cross-cutting gate, fail-fast classification) did not recur.
- **Takeaway**: Lessons that only exist as conventions ("remember to do X") are fragile. To prevent recurrence, escalate to structure: required template sections, workflow phases, or automated gates. Applied: plan template now requires Commit Strategy section.

### Rules in docs get ignored; rules in workflow get followed

- **Expected**: CLAUDE.md rule "run check-session.sh --impl" would be followed
- **Actual**: BDD 5/5 pass created a "completion illusion" and check-session.sh was never run. The rule existed in CLAUDE.md (a document) but not in impl SKILL.md (a workflow).
- **Takeaway**: A rule's location determines its execution likelihood. Move compliance checks from docs to workflow phases or forced-function gates. Applied: check-session.sh added as impl Phase 4.5 and cwf:run Phase 3.
