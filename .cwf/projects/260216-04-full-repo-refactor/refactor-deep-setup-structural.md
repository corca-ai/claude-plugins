# Structural Review: setup Skill (Criteria 1-4)

Skill path: `plugins/cwf/skills/setup/SKILL.md`

---

## 1. SKILL.md Size

| Metric | Value | Threshold | Severity |
|--------|-------|-----------|----------|
| Word count | 3,685 | > 3,000 warning / > 5,000 error | **warning** |
| Line count | 850 | > 500 warning | **warning** |

**Assessment**: Both metrics exceed the warning threshold. At 3,685 words the file is 23% over the 3,000-word warning line, and at 850 lines it exceeds the 500-line threshold by 70%. Not yet at error level (5,000 words), but a clear candidate for extraction.

### Root cause

The skill covers 10+ distinct phases (1, 2, 2.3.1, 2.3.2, 2.4, 2.5, 2.6, 2.7, 2.8, 2.9, 3, 4, 5), each with its own multi-step procedure, AskUserQuestion prompts, and code fences. The file contains 54 code fence pairs -- an unusually high count indicating that procedural detail is inlined rather than delegated.

### Specific reduction opportunities

| Section | Lines | Words (approx) | Extraction candidate |
|---------|-------|-----------------|---------------------|
| Phase 2.4-2.6 (Codex integration) | ~160 lines (228-384) | ~600 | Move to `references/codex-integration.md`; SKILL.md retains a summary + pointer |
| Phase 3 (CWF cap index) | ~60 lines (638-693) | ~350 | Move to `references/cap-index-generation.md` |
| Phase 4 (Repo index) | ~95 lines (695-788) | ~600 | Move to `references/repo-index-generation.md` |
| Phase 2.7 (Git hook gates) | ~70 lines (387-455) | ~350 | Move to `references/git-hook-gates.md` |

Extracting these four sections to reference files would reduce SKILL.md by roughly 1,900 words (to ~1,800), well under the 3,000-word warning line.

---

## 2. Progressive Disclosure Compliance

### Metadata (frontmatter)

- **Fields**: `name`, `description` only. Compliant.
- **Description length**: 418 characters. Under the 1,024-character limit. Compliant.
- **Description content**: Includes what the skill does AND trigger phrases. Compliant.

### Body -- red flag checks

| Check | Status | Detail |
|-------|--------|--------|
| "When to Use" section in body | **Pass** | Not present; trigger info is in description |
| Long code examples that belong in references | **Warning** | 54 code fence pairs inline. Most are 1-4 line command invocations (appropriate), but the embedded git hook script bodies in Phase 2.7.3 (via `configure-git-hooks.sh`) and the detailed Codex wrapper explanations in Phases 2.4-2.6 are procedural reference material, not core workflow steps |
| API docs / schemas / lookup tables in body | **Pass** | The Mode Routing table is a legitimate dispatch table. No API schemas found |

### Three-level hierarchy usage

| Level | Status |
|-------|--------|
| Metadata (frontmatter) | Properly minimal |
| Body (core workflow) | Overloaded -- body tries to be both routing dispatcher AND full procedure for every sub-phase |
| Bundled resources | Under-used -- no `references/` directory exists; all detail lives in SKILL.md body |

**Key finding**: The skill has zero reference files. All procedural detail for 10+ phases is packed into the body, violating the progressive disclosure principle. The `scripts/` directory is well-used (6 scripts), but the reference layer is empty.

---

## 3. Duplication Check

### SKILL.md vs. scripts/ (semantic duplication)

| Topic | SKILL.md location | Script equivalent | Overlap type |
|-------|-------------------|-------------------|-------------|
| Env var migration mappings | Phase 2.8.1 lists scanned files (`~/.zshrc`, `~/.bashrc`, `~/.claude/.env`) and required keys (`SLACK_BOT_TOKEN`, etc.) | `migrate-env-vars.sh` lines 83-133 define the same scan files and required keys list | **Low** -- SKILL.md describes what to expect, script implements it; descriptions match but are not verbatim |
| Tool list for dependency check | Phase 2.1 lists `codex`, `gemini`, `shellcheck`, `jq`, `gh`, `node`, `python3` | `install-tooling-deps.sh` manages `shellcheck`, `jq`, `gh`, `node`, `python3` | **Low** -- partial overlap, SKILL.md has broader scope (includes AI tools not in script) |
| Git hook profile descriptions | Phase 2.7.2 describes `fast`/`balanced`/`strict` | `configure-git-hooks.sh` usage text lines 18-21 describes the same profiles | **Medium** -- both places describe what each profile includes; the script's `usage()` and SKILL.md Phase 2.7.2 are near-duplicates |
| Agent Teams config options | Phase 2.9 describes `--enable`/`--disable`/`--status` | `configure-agent-teams.sh` usage text describes the same | **Low** -- minimal overlap |

### SKILL.md vs. README.md (skill-local)

The skill's `README.md` is a file map (13 lines). It lists all scripts with one-line descriptions. SKILL.md's "References" section (lines 837-850) also lists all scripts with one-line descriptions. The two lists are semantically equivalent with different wording.

**Finding**: The References section at the bottom of SKILL.md and the README.md file map contain overlapping script inventories. This is a minor duplication -- the README serves as a standalone file map while the SKILL.md references section serves as in-context navigation. Acceptable but worth noting.

### SKILL.md internal duplication

Phase 2.4 (Codex Integration on Full Setup) and Phase 2.5 (Codex Skill Sync) share nearly identical content regarding `sync-skills.sh --cleanup-legacy`. The command appears in:
- Phase 2.4.2 (line 255)
- Phase 2.5.1 (line 299)

Phase 2.4.3 and Phase 2.6.3 both provide Codex wrapper status/rollback instructions with similar structure and wording. The overlapping reporting pattern could be consolidated into a single "Codex post-install verification" sub-procedure.

---

## 4. Resource Health

### File inventory

| Resource | Lines | Words | Referenced in SKILL.md |
|----------|-------|-------|----------------------|
| `scripts/check-index-coverage.sh` | 201 | 618 | Yes (lines 686, 782, 823, 848) |
| `scripts/migrate-env-vars.sh` | 350 | 937 | Yes (lines 470, 501, 507, 844) |
| `scripts/configure-agent-teams.sh` | 194 | 458 | Yes (lines 607, 613, 619, 627, 846) |
| `scripts/install-tooling-deps.sh` | 355 | 898 | Yes (lines 204, 210, 220, 833, 847) |
| `scripts/bootstrap-project-config.sh` | 164 | 441 | Yes (lines 551, 557, 845) |
| `scripts/configure-git-hooks.sh` | 246 | 720 | Yes (lines 438, 843) |
| `README.md` | 13 | ~100 | **No** (not referenced by filename in SKILL.md) |

### File quality checks

| Check | File | Status |
|-------|------|--------|
| File > 10k words (needs grep patterns) | None | N/A -- all scripts are under 1,000 words |
| File > 100 lines (needs ToC) | `install-tooling-deps.sh` (355 lines) | **Flag** -- no table of contents or section markers |
| File > 100 lines (needs ToC) | `migrate-env-vars.sh` (350 lines) | **Flag** -- no table of contents or section markers |
| File > 100 lines (needs ToC) | `configure-git-hooks.sh` (246 lines) | **Flag** -- no table of contents; function boundaries serve as implicit sections |
| File > 100 lines (needs ToC) | `check-index-coverage.sh` (201 lines) | **Flag** -- no table of contents |
| File > 100 lines (needs ToC) | `configure-agent-teams.sh` (194 lines) | **Flag** -- no table of contents |
| File > 100 lines (needs ToC) | `bootstrap-project-config.sh` (164 lines) | **Flag** -- no table of contents |
| Deeply nested references | None | N/A -- no references directory exists |

**Note on script ToC**: The >100 line ToC criterion from the review criteria is written for `references/*.md` files. Applying it strictly to shell scripts is debatable -- shell scripts typically use function names as implicit section markers. However, the three largest scripts (355, 350, 246 lines) would benefit from section comment headers for navigability.

### Unused resources

| File | Referenced in SKILL.md | Status |
|------|----------------------|--------|
| `README.md` | No | **Flag** -- The skill's own `README.md` filename does not appear as a reference in SKILL.md. SKILL.md references various external `README.md` files (hooks, scripts), but never its own skill-local README. |

### Missing resources

The `references/` directory does not exist for this skill. Given the SKILL.md size (3,685 words, 850 lines), this is the primary structural concern: all reference-weight content lives in the body with no offloading.

---

## Summary of Findings

| # | Criterion | Severity | Finding |
|---|-----------|----------|---------|
| 1.1 | Word count 3,685 > 3,000 | **warning** | Exceeds warning threshold by 23% |
| 1.2 | Line count 850 > 500 | **warning** | Exceeds warning threshold by 70% |
| 2.1 | No references/ directory | **warning** | All procedural detail is inlined; progressive disclosure reference layer is unused |
| 2.2 | 54 code fence pairs | **info** | High inline code density; most are appropriate short commands but Codex/index/git-hook phases contain extractable procedure blocks |
| 3.1 | Codex phases 2.4/2.5 share `sync-skills.sh` invocation | **info** | Minor internal duplication of the same command in two phases |
| 3.2 | Codex phases 2.4.3/2.6.3 share post-install verification pattern | **info** | Similar reporting structure could be consolidated |
| 3.3 | SKILL.md References vs README.md | **info** | Script inventory appears in both places with different wording |
| 3.4 | Git hook profile descriptions duplicated | **info** | Phase 2.7.2 and `configure-git-hooks.sh` usage text describe the same profiles |
| 4.1 | 6 scripts over 100 lines lack ToC headers | **info** | Shell scripts use function names as implicit sections; adding comment headers would improve navigability for the 3 largest |
| 4.2 | Skill-local `README.md` not referenced in SKILL.md | **flag** | File exists but is not referenced from the primary skill document |

### Recommended extraction plan (priority order)

1. Create `references/codex-integration.md` -- move Phases 2.4, 2.5, 2.6 (~160 lines, ~600 words). Consolidate the duplicated verification/reporting patterns.
2. Create `references/repo-index-generation.md` -- move Phase 4 (~95 lines, ~600 words).
3. Create `references/cap-index-generation.md` -- move Phase 3 (~60 lines, ~350 words).
4. Create `references/git-hook-gates.md` -- move Phase 2.7 (~70 lines, ~350 words).

This would reduce SKILL.md to approximately 1,800 words and ~465 lines, bringing both metrics comfortably under their respective thresholds.

<!-- AGENT_COMPLETE -->
