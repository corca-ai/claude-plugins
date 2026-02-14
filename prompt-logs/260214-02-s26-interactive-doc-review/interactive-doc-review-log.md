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
