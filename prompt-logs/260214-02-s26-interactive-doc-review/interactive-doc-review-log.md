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

- Anchor docs: `AGENTS.md`, `CLAUDE.md`, `README.md`, `README.ko.md`, `repo-index.md`.
- Policy docs: `docs/documentation-guide.md`, `docs/project-context.md`, `docs/interactive-doc-review-protocol.md`.
- References: `plugins/cwf/references/*.md`, `references/**/*.md`.
- Queue size (deterministic build): `31` files.

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

### Chunk Review 02

1. Chunk: `repo-index.md:1-69` (EOF: yes)
2. Excerpt: repository-wide index generated by setup, covering root entry docs, CWF skills/references/hooks/scripts, and project docs/references.
3. Meaning / Intent: provide deterministic "where to read what" routing across repository areas while keeping descriptions file-centric.
4. Review Focus (Line-Anchored):
   - `repo-index.md:3`: same-file self-link (`[repo-index.md](repo-index.md)`) may be low-signal redundancy.
   - `repo-index.md:7-11`: root ordering remains consistent with configured policy (`README`, `AGENTS`, `CLAUDE`, `cwf-state`, `README.ko`).
5. Link Syntax Check: pass (`[]()` usage consistent; no inline literal paths).
6. De-dup / What-Why Check: structure is concise and role-first; expected overlap with AGENTS managed index block remains intentional generation output.
7. Discussion Prompt:
   - Keep line-3 self-link for template uniformity, or remove it from generated index headers for lower noise?
   - Do we want `repo-index.md` to remain a generated artifact, or move completely to AGENTS managed block only (`--target agents`)?

### File Boundary Gate

- Inbound links: `6` (orphan: no)
