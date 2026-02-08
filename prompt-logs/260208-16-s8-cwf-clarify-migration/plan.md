# S8: Migrate clarify → cwf:clarify

## Context

Session S8 of the CWF v3 migration. The `clarify` plugin (v2.0.1) needs to be copied into the CWF plugin as `cwf:clarify`. This follows the same pattern as S7 (gather-context → cwf:gather). The clarify plugin has no scripts — only SKILL.md and 4 reference files — making this a simpler migration than S7.

Key discovery from exploration: `cwf:review --mode clarify` is already fully implemented in `.claude/skills/review/SKILL.md` (S5a/S5b), so integration is already in place.

## Steps

### ✅ 1. Create session directory

- `prompt-logs/260208-16-s8-cwf-clarify-migration/`
- Create `plan.md` (copy of this plan) and `lessons.md`

### ✅ 2. Create skill directory structure

```bash
mkdir -p plugins/cwf/skills/clarify/references/
```

### ✅ 3. Copy reference files (verbatim)

Copy these 4 files from `plugins/clarify/skills/clarify/references/` to `plugins/cwf/skills/clarify/references/`:

- `advisory-guide.md` (58 lines)
- `aggregation-guide.md` (94 lines)
- `questioning-guide.md` (161 lines)
- `research-guide.md` (113 lines)

No modifications needed — all internal references use `{SKILL_DIR}/references/` which resolves correctly in the new location.

### ✅ 4. Adapt and copy SKILL.md

Source: `plugins/clarify/skills/clarify/SKILL.md` (310 lines)
Target: `plugins/cwf/skills/clarify/SKILL.md`

Changes required:

| Location | Old | New |
|----------|-----|-----|
| Frontmatter `name` | `clarify` | `clarify` (keep — `cwf:clarify` comes from `{plugin}:{skill}`) |
| Frontmatter `description` triggers | `"/clarify", "clarify this"` | `"cwf:clarify", "clarify this"` |
| Quick Start examples | `/clarify <requirement>` | `cwf:clarify <requirement>` |
| Phase 2 Path A check | `check if /gather-context appears` | `check if cwf:gather or /gather-context appears` |
| Phase 2 Path A web researcher | `bash {gather-context plugin dir}/...search.sh` | `bash {cwf plugin dir}/skills/gather/scripts/search.sh` |
| Phase 5 end | (none) | Add cwf:review --mode clarify follow-up note |

### ✅ 5. Version bump

- `plugins/cwf/.claude-plugin/plugin.json`: `0.3.0` → `0.4.0`

### ✅ 6. Documentation updates

**CLAUDE.md** (line 50):
- `/clarify` → `cwf:clarify`

### ✅ 7. Update cwf-state.yaml

Add S8 session entry to `sessions[]`.

### ✅ 8. Post-implementation

1. Mark plan.md as done
2. Update lessons.md with implementation learnings
3. Run `/retro`
4. Commit and push
