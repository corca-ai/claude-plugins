# Retro: Plan Mode Removal + Live State + Compact Recovery

> Session date: 2026-02-09
> Mode: light

## 1. Context Worth Remembering

- Plan mode has been consistently problematic across multiple sessions — the user's CWF workflow (clarify → plan → impl → retro → handoff) already provides better structured planning than Claude Code's built-in plan mode.
- `PreCompact` hook has NO decision control output (can't inject `additionalContext` or `custom_instructions`). Only `SessionStart` with `compact` matcher can inject context after auto-compact.
- `cwf-state.yaml` `live` section is the bridge between pre-compact and post-compact context. Skills update it at phase transitions; CLAUDE.md rules serve as backup.
- CWF plugin is not yet in marketplace.json (still on `marketplace-v3` branch), so `scripts/install.sh` and `scripts/update-all.sh` don't work for it. Bootstrapping hooks requires direct `.claude/settings.json` edits.
- Session touched 25+ files across code, docs, and skills — the widest cross-cutting change in the CWF v3 migration so far.

## 2. Collaboration Preferences

- The user's "save as plan.md then go" + "Before start impl, turn on auto compact and impl session start hook first" instruction demonstrated a bootstrapping-first mindset: get the safety net active before the long implementation. This is a good pattern to follow for infrastructure sessions.
- The user expects commit granularity to match logical units (infra / removal / docs), not mechanical units (file-by-file).
- Session log commit timing: the user expects prompt-logs artifacts to be committed as part of the session workflow, not deferred indefinitely.

### Suggested CLAUDE.md Updates

- None. Current CLAUDE.md already reflects the updated Session State section from this session.

## 3. Waste Reduction

**Bootstrapping detour with install.sh**: Attempted `scripts/update-all.sh` + `scripts/install.sh` to propagate the hook, which failed because CWF isn't in marketplace.json yet. The fallback (direct `.claude/settings.json` edit) was the correct path from the start.

- Why did this happen? → Followed the standard plugin deployment workflow.
- Why was that wrong? → CWF is still a development-branch plugin, not yet published.
- Root cause: No explicit "CWF is not installable yet" note in the plan or session context. The `marketplace-v3` branch status was known but not connected to the install path decision.
- Fix: When working on unpublished plugins, skip marketplace install paths. This is already implicitly understood but could be noted in `project-context.md` under Current Project Phase if it recurs.

**Context compaction mid-session**: The session hit auto-compact during the retro phase, which is ironic given that the session implemented compact recovery. The compact recovery hook successfully fired and injected context — a live dogfooding validation.

- This is not waste per se, but notable: the session was long enough (25+ file changes across 6 phases) that compaction was inevitable. Future sessions of similar scope should consider splitting into 2 sessions.

## 4. Critical Decision Analysis (CDM)

### CDM 1: SessionStart(compact) over PreCompact for context injection

| Probe | Analysis |
|-------|----------|
| **Cues** | User wanted auto-compact hook for context recovery. Initial assumption was PreCompact could handle it. |
| **Knowledge** | Deep-dive into Claude Code hook docs revealed PreCompact has no `hookSpecificOutput` schema — it can only run commands, not inject context. |
| **Goals** | Inject session state into post-compact context vs. keep implementation simple (single hook). |
| **Options** | (A) PreCompact only — prepare files on disk, hope Claude reads them. (B) SessionStart(compact) — inject `additionalContext` directly. (C) 2-hook chain: PreCompact prepares, SessionStart injects. |
| **Basis** | Option B chosen because `cwf-state.yaml` is already maintained by skills, so PreCompact preparation is unnecessary. SessionStart(compact) can read the file and inject directly. Simplest viable solution. |
| **Hypothesis** | Option A would have been unreliable — no guarantee Claude reads the prepared file post-compact. Option C adds complexity for no gain since `live` section is always current. |
| **Aiding** | The official hook docs (verified via WebFetch) were the deciding factor. Without doc verification, we might have attempted PreCompact injection and wasted turns debugging silent failures. |

**Key lesson**: Always verify hook output schemas against official docs before designing hook-based features. Hook events have asymmetric capabilities that aren't obvious from naming alone.

### CDM 2: Option C (hybrid) for live section update mechanism

| Probe | Analysis |
|-------|----------|
| **Cues** | User asked how the `live` section stays current. Three options proposed: A (skills only), B (CLAUDE.md rules only), C (hybrid). |
| **Goals** | Reliability (live section always current when compact fires) vs. implementation cost (touching every skill) vs. resilience (behavioral rules degrade). |
| **Options** | A: Skills-only — deterministic but misses freeform work. B: CLAUDE.md rules — covers freeform but behavioral instructions degrade over time. C: Hybrid — skills at transitions + CLAUDE.md as backup + check-session.sh as gate. |
| **Basis** | User chose C. Aligns with project-context.md principle: "Deterministic validation over behavioral instruction." Skills provide the deterministic layer; CLAUDE.md is the fallback; check-session.sh is the gate. |
| **Experience** | A less experienced approach would pick A or B exclusively. The hybrid recognizes that neither pure automation nor pure instruction is sufficient — defense in depth. |
| **Analogues** | Same pattern as `check-session.sh --impl`: deterministic gate that catches what behavioral rules miss. |

**Key lesson**: For state that must be current at unpredictable times (like auto-compact), use layered update mechanisms: automated primary + behavioral backup + deterministic validation gate.

### CDM 3: Bootstrapping order — hook first, then implementation

| Probe | Analysis |
|-------|----------|
| **Cues** | User explicitly said: "Before start impl, turn on auto compact and impl session start hook first." |
| **Goals** | Protect the implementation session itself from context loss vs. follow the plan's phase order sequentially. |
| **Options** | (A) Follow plan phases 1→2→3→4→5→6 sequentially. (B) Implement the compact recovery hook first (Phase 2), activate it, then proceed with the rest. |
| **Basis** | User recognized the bootstrapping paradox: the session implementing compact recovery is itself vulnerable to compact. Solving the meta-problem first is strictly better. |
| **Time Pressure** | The session was expected to be long (25+ files), making auto-compact likely. The user's instinct was correct — compact did fire during retro. |
| **Situation Assessment** | Correctly assessed that hook activation requires `.claude/settings.json` edit (not plugin install), and that activation happens on next SessionStart event — meaning the hook was live for any mid-session compact. |

**Key lesson**: When implementing a safety mechanism, activate it before the work it's meant to protect. The bootstrapping order matters more than the logical phase order.

## 5. Expert Lens

> Run `/retro --deep` for expert analysis.

## 6. Learning Resources

> Run `/retro --deep` for learning resources.

## 7. Relevant Skills

### Installed Skills

- **plugin-deploy** (`.claude/skills/`): Not applicable this session — CWF is not yet in marketplace, so deploy workflow doesn't apply until `marketplace-v3` merges to main.
- **ship** (`.claude/skills/`): Could have been used for the commit workflow, but the user requested manual commit granularity control ("적절한 단위로 커밋"), which is more nuanced than ship's default behavior.
- **review** (`.claude/skills/`): Could have been valuable for the 25+ file cross-cutting change — parallel reviewers might have caught stale references. Worth considering for sessions of this scope.

### Skill Gaps

No additional skill gaps identified. The session's workflow (clarify → plan → impl → retro) was well-served by existing CWF skills. The compact recovery hook fills the primary gap (context loss on auto-compact) that motivated this session.
