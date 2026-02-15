# S24 No-Go Remediation Plan

Date: 2026-02-11
Session: S24
Source: `prompt-logs/260211-09-s22-pre-release-readiness-audit-plan/next-session.md`

## Decision Lock Reconfirmation

1. No-Go remains fixed until Concern 1-3 blockers are remediated.
2. README work is a minimal framing patch first (`is / is-not / assumptions / decisions+why`) plus inventory sync.
3. Self-containment is treated as a release blocker.
4. Execution order is fixed: Phase A remediation first, Phase B interactive Step 4 second.

## Scope

### Concern 1: Refactor-Led Audit Blockers

- Fix skill/document inventory drift (`11` vs live `12`, missing `run`).
- Resolve skill convention violations:
  - `run`: missing `## References`
  - `ship`: missing `## Rules` and `## References`
  - `refactor`: `References` before `Rules`
  - `retro`: no explicit quick section heading, `References` before `Rules`
- Refresh concept/provenance artifacts from 9-skill/14-hook baseline to current state.

### Concern 2: README Framing Blockers

Apply minimal framing patch to both `README.md` and `README.ko.md`:

1. What CWF Is
2. What CWF Is Not
3. Assumptions
4. Key Decisions and Why

Also synchronize active skill inventory to 12 and include `run` in discoverability tables.

### Concern 3: Discoverability + Self-Containment Blockers

- Remove skill runtime dependency on repo-root `scripts/*` for the blocker set (`setup`, `run`, `impl`, `handoff`, `plan`, `retro`).
- Add plugin-local scripts under `plugins/cwf/scripts/` and update skill script references accordingly.
- Keep agent entry-path documents navigable and inventory-aligned.

## Trade-offs and Rationale

- **Preferred**: Vendor required scripts into `plugins/cwf/scripts` and repoint skills.
  - Pros: marketplace source (`./plugins/cwf`) becomes self-contained.
  - Cons: temporary duplication with root `scripts/`.
- **Rejected for now**: Full script architecture unification/refactor in this session.
  - Reason: exceeds blocker-first scope and would delay release gate remediation.

## Acceptance Gates (Phase A)

A. **Conventions gate**
- All active skills satisfy `Rules before References` and include required sections.

B. **Self-containment gate**
- No blocker-scope skills reference repo-root `scripts/*` paths.
- Required scripts for those skills exist under `plugins/cwf/scripts/`.

C. **Inventory/framing gate**
- README/README.ko reflect 12 active skills and include framing contract sections.
- `.claude-plugin/marketplace.json` and architecture docs no longer claim 11-skill state.

D. **Provenance/concept gate**
- concept map and provenance metadata are updated to current system state.

E. **Session gate**
- `scripts/check-session.sh --impl` passes before Phase A close.

## Commit Strategy

- Commit Unit 1: self-containment + skill convention fixes.
- Commit Unit 2: README/inventory/concept/provenance/docs synchronization.

After Unit 1 completion, run `git status --short`, confirm next boundary, and commit before Unit 2.

## Planned Verification Commands

```bash
# self-containment references in blocker scope
rg -n "scripts/(next-prompt-dir\.sh|check-session\.sh|codex/)" \
  plugins/cwf/skills/{setup,run,impl,handoff,plan,retro}/SKILL.md \
  plugins/cwf/references/plan-protocol.md

# convention/order checks on target skills
rg -n "^## (Quick Start|Quick Reference|Rules|References)" \
  plugins/cwf/skills/{run,ship,refactor,retro}/SKILL.md

# provenance freshness
bash scripts/provenance-check.sh --level warn

# session completeness
bash scripts/check-session.sh --impl
```
