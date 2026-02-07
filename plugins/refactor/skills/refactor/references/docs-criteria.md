# Documentation Review Criteria

Checklist for the `--docs` mode. Evaluate documentation consistency across the repository.

## 1. CLAUDE.md Review

Check the project's root `CLAUDE.md`:

| Check | Flag condition |
|-------|---------------|
| Line count > 200 | Progressive disclosure violation — details should live in docs/ |
| References non-existent files | Dead path reference |
| References deprecated/removed plugins without noting status | Stale reference |
| Duplicates content from docs/ files | Should reference, not repeat |
| Missing protocol references | Protocol docs exist in docs/ but aren't linked from CLAUDE.md |

## 2. Project Context Review

Check `docs/project-context.md`:

| Check | Flag condition |
|-------|---------------|
| Plugin listing doesn't match `plugins/` directory | Missing or extra entries |
| Lists deprecated plugin as active | Status not updated |
| Architecture patterns reference removed plugins | Stale reference |
| Convention entries contradict actual practice | Inconsistency |
| Missing entries for recently added plugins | Incomplete coverage |

## 3. README Review

Check `README.md` and `README.ko.md`:

| Check | Flag condition |
|-------|---------------|
| Overview table doesn't match `marketplace.json` | Missing, extra, or mismatched entries |
| Active plugin missing install/update commands | Incomplete section |
| Deprecated plugin not clearly marked | Missing deprecation notice |
| Korean version structure differs from English | Structural mismatch |
| Korean version content is stale | Content mismatch with English version |
| Dead links (internal file references) | Broken link |

## 4. Cross-Document Consistency

Check alignment between documents:

| Source A | Source B | Check |
|----------|----------|-------|
| `marketplace.json` plugins | README overview table | Same set of plugins, same descriptions |
| `marketplace.json` descriptions | `plugin.json` descriptions | Consistent messaging |
| `docs/project-context.md` plugins | `plugins/` directory | Matches actual contents |
| `CLAUDE.md` file references | Filesystem | All referenced paths exist |
| README deprecated section | `marketplace.json` deprecated flags | Consistent deprecation status |

For each inconsistency found, report:
- **What**: The specific mismatch
- **Where**: Both files and locations involved
- **Suggestion**: Which file should be updated and how
