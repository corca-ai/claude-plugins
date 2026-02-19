# Lessons — S26

### AGENTS-first default and optional cap-index can coexist without policy drift

- **Expected**: Removing `cwf-index.md` entirely would conflict with users who still want an explicit capability map.
- **Actual**: Setting AGENTS as the single default entrypoint while keeping `cwf:setup --cap-index` as an explicit opt-in preserved both goals.
- **Takeaway**: For discoverability artifacts, make defaults singular and explicit alternatives opt-in; avoid dual-default navigation surfaces.

### AGENTS-managed repo index avoids duplicate generated surfaces

- **Expected**: Keeping both `repo-index.md` file and AGENTS managed block would continue creating synchronization overhead.
- **Actual**: Removing `repo-index.md` and documenting `--target agents` as the repository default simplified routing and reduced duplication.
- **Takeaway**: Generated index artifacts should have one canonical persistence target per repository.
