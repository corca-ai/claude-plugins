# Interactive Documentation Review Log — S26

## Session

- Session ID: S26
- Started at: 2026-02-14
- Previous cursor: `CLAUDE.md:1`
- Protocol: `docs/interactive-doc-review-protocol.md`

## Track 1 — Pre-Review Retro Fixes

### Fix 1: Deterministic date-rollover fixture tests

- Motivation: eliminate ambiguity around `YYMMDD-NN` sequencing and cross-day rollover behavior.
- Classification: `AUTO_CANDIDATE` -> implement as executable fixture test.
- Scope: `scripts/next-prompt-dir.sh`, `plugins/cwf/scripts/next-prompt-dir.sh`, `scripts/tests/next-prompt-dir-fixtures.sh`.
- Result: implemented and validated (`PASS=5`, rollover + boundary cases).

### Fix 2: Commit-boundary split rule in review workflow

- Motivation: reduce mixed-commit regressions by separating structural tidy changes from behavior/policy changes.
- Classification: `NON_AUTOMATABLE` workflow guidance in review synthesis contract.
- Scope: `plugins/cwf/skills/review/SKILL.md`.
- Result: implemented (new synthesis section + explicit rule + BDD check).

### Fix 3: Deterministic markdownlint noise reduction + setup link false-positive cleanup

- Motivation: baseline lint output was dominated by vendored markdown under `scripts/node_modules/**`; doc-graph showed 3 setup broken refs from placeholder example text.
- Classification: `AUTO_CANDIDATE` -> gate scope hardening + `AUTO_EXISTING` broken-ref cleanup.
- Scope: `.markdownlint-cli2.jsonc`, `plugins/cwf/skills/setup/SKILL.md`.
- Result: implemented (ignore patterns expanded, placeholder pseudo-link removed).

### Fix 4: AGENTS-first entrypoint policy alignment

- Motivation: repository policy shifted to AGENTS-only default entrypoint; legacy `cwf-index.md` should not be part of default navigation.
- Classification: `NON_AUTOMATABLE` policy decision + `AUTO_EXISTING` reference cleanup.
- Scope: `CLAUDE.md`, `README.md`, `README.ko.md`, `docs/v3-migration-decisions.md`, `docs/interactive-doc-review-protocol.md`, `plugins/cwf/skills/setup/SKILL.md`, `plugins/cwf/skills/refactor/scripts/doc-graph.mjs`, `scripts/markdownlint-rules/no-inline-md-path-literals.cjs`, `plugins/cwf/hooks/markdownlint/rules/no-inline-md-path-literals.cjs`.
- Result: implemented (`cwf-index.md` removed; `--cap-index` remains explicit-only path).

### Fix 5: Remove repository index file artifact (`repo-index.md`)

- Motivation: apply the same AGENTS-first policy to repository-level index output in this repository.
- Classification: `NON_AUTOMATABLE` policy decision + `AUTO_EXISTING` reference cleanup.
- Scope: `README.md`, `README.ko.md`, `AGENTS.md`, `docs/v3-migration-decisions.md`, `docs/interactive-doc-review-protocol.md`, `plugins/cwf/skills/setup/SKILL.md`, `plugins/cwf/skills/setup/scripts/configure-git-hooks.sh`, `plugins/cwf/skills/setup/scripts/check-index-coverage.sh`, `scripts/markdownlint-rules/no-inline-md-path-literals.cjs`, `plugins/cwf/hooks/markdownlint/rules/no-inline-md-path-literals.cjs`.
- Result: implemented (`repo-index.md` removed; repository index output is AGENTS-managed by default).

## Track 2 — Interactive Review

### Deterministic Baseline (Pre-Chunk)

- `markdownlint-cli2 "**/*.md"`: fail (`1955`), dominated by vendored files under `scripts/node_modules/**` (scope noise, not actionable project-doc signal).
- `bash plugins/cwf/skills/refactor/scripts/check-links.sh --local --json`: pass (`errors=0`).
- `node scripts/doc-graph.mjs --json > docs/doc-graph.snapshot.json || true`: stats = `total_docs=69`, `total_links=438`, `orphan_count=0`, `broken_ref_count=3`.
- Current broken refs (all same source): `plugins/cwf/skills/setup/SKILL.md` -> synthetic target `path`.

### Deterministic Baseline Refresh (After Fix 3)

- `markdownlint-cli2 "**/*.md"`: pass (`0`), vendored markdown noise excluded.
- `node scripts/doc-graph.mjs --json > docs/doc-graph.snapshot.json || true`: stats = `total_docs=69`, `total_links=435`, `orphan_count=0`, `broken_ref_count=0`.

### Relationship Map

- Anchor docs: `AGENTS.md`, `CLAUDE.md`, `README.md`, `README.ko.md`.
- Policy docs: `docs/documentation-guide.md`, `docs/project-context.md`, `docs/interactive-doc-review-protocol.md`.
- References: `plugins/cwf/references/*.md`, `references/**/*.md`.
- Queue size (deterministic build): `30` files.

### Chunk Review 01

1. Chunk: `CLAUDE.md:1-14` (EOF: yes)
2. Excerpt: compact runtime-adapter file that defers shared rules to `AGENTS.md`, then lists Claude-only runtime specifics.
3. Meaning / Intent: keep always-loaded adapter minimal; route policy ownership to `AGENTS.md`; preserve only Claude runtime deltas.
4. Review Focus (Line-Anchored):
   - `CLAUDE.md:3` and `CLAUDE.md:7-8`: check potential redundancy between the sentence-level pointer and the explicit "Read first" list.
   - `CLAUDE.md:12-14`: verify runtime-only statements remain implementation-factual and do not duplicate procedural policy already in other docs.
5. Link Syntax Check: pass (`[]()` markdown links used for all file references).
6. De-dup / What-Why Check: mostly clean; minor duplication risk around repeated AGENTS routing cue, but still within concise adapter scope.
7. Discussion Prompt:
   - Should line-level routing be reduced to a single form (either sentence pointer or numbered list) for tighter signal?
   - Keep explicit env fallback (`~/.claude/.env`) in this adapter, or move it to a dedicated runtime troubleshooting doc and leave only pointer text here?

### File Boundary Gate

- Inbound links: `6` (orphan: no)

### Policy Resolution

- Resolved by user decision: default discoverability is AGENTS-first; `cwf-index.md` removed from repository.
- `cwf:setup --cap-index` remains available for explicit, on-demand capability-map generation.
- Re-baseline after removal: `total_docs=68`, `total_links=399`, `orphan_count=0`, `broken_ref_count=0`.

### Policy Resolution 2

- Resolved by user decision: remove `repo-index.md` in this repository.
- Repository index output remains available through AGENTS managed block generation (`cwf:setup --repo-index --target agents`).
- Re-baseline after removal: `total_docs=67`, `total_links=351`, `orphan_count=0`, `broken_ref_count=0`.

### Chunk Review 02

1. Chunk: `README.md:1-117` (EOF: no)
2. Excerpt: framing contract, rationale, core concepts, workflow table, and installation/update/legacy migration guidance.
3. Meaning / Intent: present CWF positioning and behavioral model before tactical skill-by-skill reference sections.
4. Review Focus (Line-Anchored):
   - `README.md:24-25`: AGENTS-first routing statement now aligns with current repository policy; check that no alternate default entrypoint is implied in nearby sections.
   - `README.md:70-83`: workflow table scope and ordering remain coherent with actual skill inventory and trigger model.
5. Link Syntax Check: pass (`[]()` syntax consistent; no broken local references in this chunk).
6. De-dup / What-Why Check: framing is high-signal; minor potential verbosity in concept narrative blocks, but still mostly what/why-oriented.
7. Discussion Prompt:
   - Should the framing section keep both "What CWF Is" and "Why CWF?" as separate top-level narratives, or can they be merged to reduce initial read length?
   - In this README, do you want to keep the full 12-skill workflow table in the top half, or move detailed capability enumeration deeper for faster onboarding?

### File Boundary Gate

- Inbound links: `5` (orphan: no)

### Follow-up Edit (From Discussion)

- User feedback: plan/impl skill descriptions should state review gates more explicitly.
- Applied: added explicit sequence/guard text in `README.md` and `README.ko.md`:
  - plan -> `cwf:review --mode plan` before `cwf:impl`
  - impl flow includes post-impl `cwf:review --mode code`

### Chunk Review 03

1. Chunk: `README.md:118-201` (EOF: no)
2. Excerpt: skills reference block for `gather`, `clarify`, `plan`, `impl`, `retro`, and `refactor`; each section provides command synopsis, concise behavior notes, and a pointer to skill-local `SKILL.md`.
3. Meaning / Intent: maximize command discoverability in README while keeping implementation/policy detail delegated to per-skill source docs.
4. Review Focus (Line-Anchored):
   - `README.md:175` vs `README.md:178`: default-mode wording conflicts (`light by default` in section intro vs `deep by default` in command annotation); canonical default should be unified.
   - `README.md:156` and `README.md:169`: plan/impl review-gate sequencing is now explicit; verify this sequencing language remains consistent with orchestration docs and run pipeline wording.
5. Link Syntax Check: pass (`[]()` syntax used consistently for all skill reference links in this chunk).
6. De-dup / What-Why Check: structure is mostly high-signal and scan-friendly; repeated "Full reference" lines are intentionally uniform and acceptable for quick navigation.
7. Discussion Prompt:
   - For `retro` default mode, should README follow the skill contract (`light by default`) and update line-level command annotation accordingly?
   - In skills reference, do you want to keep behavior summaries at current density or tighten to one sentence per skill to reduce vertical length?

### Follow-up Decision (From Discussion)

- User decision: canonical `retro` default is `deep`.
- Applied normalization:
  - `README.md` retro intro wording aligned to deep-default.
  - `README.ko.md` retro intro wording aligned to deep-default.
  - `plugins/cwf/skills/retro/SKILL.md` description, opening summary, and quick-start comment aligned to deep-default with explicit `--light`/tiny-session light fallback note.

### Chunk Review 04

1. Chunk: `README.md:203-259` (EOF: no)
2. Excerpt: skills reference block for `handoff`, `ship`, `review`, and `run`; each section provides command synopsis, concise behavior notes, and a pointer to skill-local `SKILL.md`.
3. Meaning / Intent: document downstream workflow-control skills (handoff/ship/review/run) in a quick-scan format so operators can chain the lifecycle without opening each skill doc first.
4. Review Focus (Line-Anchored):
   - `README.md:238-240`: review command examples cover default code mode plus `clarify`/`plan`; consider whether explicit `--mode code` example should be shown for symmetry with other mode lines.
   - `README.md:257`: run summary says "automatic chaining after implementation by default"; ensure this phrasing remains consistent with stage-level human confirmation at `ship` in run skill behavior.
5. Link Syntax Check: pass (`[]()` syntax used consistently for all skill reference links in this chunk).
6. De-dup / What-Why Check: concise and consistent with prior skill blocks; no major overlap risk beyond intentional command-template repetition.
7. Discussion Prompt:
   - Do you want `cwf:review --mode code` listed explicitly in README command examples for mode symmetry?
   - Keep current `run` one-line summary, or add a brief note that `ship` still includes a human confirmation gate?

### Follow-up Decision (From Discussion 2)

- User decision: apply both edits.
- Applied:
  - Added explicit `cwf:review --mode code` example in `README.md` and `README.ko.md`.
  - Updated `run` summary in `README.md` and `README.ko.md` to explicitly mention user confirmation gate at `ship`.

### Chunk Review 05

1. Chunk: `README.md:262-318` (EOF: no)
2. Excerpt: setup command matrix (`--hooks`, `--tools`, `--codex`, `--codex-wrapper`, `--cap-index`, `--repo-index --target agents`), AGENTS-first entry file guidance, and Codex wrapper integration/verification notes.
3. Meaning / Intent: concentrate operator-facing setup discoverability (bootstrap + indexing + codex integration) while preserving AGENTS-managed repository navigation policy.
4. Review Focus (Line-Anchored):
   - `README.md:267-274`: setup command list is comprehensive; check whether keeping both `--repo-index` and `--repo-index --target agents` lines remains the right balance between generic capability and this repo's AGENTS-managed convention.
   - `README.md:305-318`: codex wrapper verification and shell-refresh instructions are explicit; verify wording stays aligned with current wrapper install behavior and avoids implying mandatory wrapper usage.
5. Link Syntax Check: pass (`[]()` syntax is valid for all local references in this chunk).
6. De-dup / What-Why Check: section density is high but purposeful; repetition around AGENTS/indices appears intentional for operator safety and policy recall.
7. Discussion Prompt:
   - In this repository README, do you want to keep the bare `cwf:setup --repo-index` example, or show only `--repo-index --target agents` to reinforce single-policy discoverability?

### Follow-up Decision (From Discussion 3)

- User direction: README should prioritize plugin users over repository-internal operation notes.
- Applied README restructuring (`README.md`, `README.ko.md`):
  - Moved installation and update guidance to the top so first-time users see install/run/update paths first.
  - Consolidated update guidance into the top installation section and removed the duplicated `### update` subsection in skills reference.
  - Removed the repository-internal `Agent Entry Files` block (including interactive review playbook link) from user-facing README flow.
  - Kept both `cwf:setup --repo-index` and `cwf:setup --repo-index --target agents` in quick start, but changed wording to neutral plugin-usage framing (`for AGENTS-based repositories`).
