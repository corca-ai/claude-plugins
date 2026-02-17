# Implementation Gates

Shared gate definitions for cwf:impl. Referenced by SKILL.md phases.

## Navigation

- [Branch Gate](#branch-gate)
- [Clarify Completion Gate](#clarify-completion-gate)
- [Commit Gate](#commit-gate)

---

## Branch Gate

Ensure implementation runs on a feature branch, never on a base branch.

> **NEVER proceed with implementation on a base branch.** This is a hard gate, not a warning.

If `--skip-branch` flag is provided, skip this gate entirely and log:

```text
Skipping branch gate (--skip-branch).
```

Otherwise, execute these steps:

### Detect Current Branch

```bash
git branch --show-current
```

### Detect Base Branch Name

```bash
git rev-parse --verify main 2>/dev/null && echo "main" || true
git rev-parse --verify master 2>/dev/null && echo "master" || true
```

Also check `cwf-state.yaml` for a custom primary branch name (e.g., if the repo uses a non-standard base branch listed under `live.branch` when `live.phase` is not `impl`).

### Gate Decision

**If on a base branch** (main, master, or the repo's primary branch):

1. Derive a branch name from the plan title:
   - Format: `feat/{sanitized-plan-title}`
   - Sanitize: lowercase, spaces to hyphens, strip non-alphanumeric (except hyphens), max 50 chars
2. Create the feature branch:

   ```bash
   git checkout -b feat/{sanitized-plan-title}
   ```

3. Report:

   ```text
   Created feature branch: feat/{sanitized-plan-title}
   ```

**If already on a feature branch** (not main/master/primary):

Report and proceed:

```text
On feature branch: {branch-name}
```

**NEVER proceed on a base branch** — the only escape is `cwf:impl --skip-branch` which skips this gate entirely. Do NOT proceed with implementation on a base branch under any circumstances.

---

## Clarify Completion Gate

Verify that `cwf:clarify` has completed before proceeding with implementation.

If `--skip-clarify` flag is provided, skip this gate entirely and log:

```text
Skipping clarify pre-condition check (--skip-clarify).
```

Otherwise, execute these steps:

1. Read `cwf-state.yaml` and check the `live.clarify_completed_at` field
2. **If field exists and is non-empty**: Clarify completed — proceed

   ```text
   Clarify completed at {clarify_completed_at}. Proceeding to plan discovery.
   ```

3. **If field is missing or empty**: Hard-block. Display this message and stop:

   ```text
   Clarify phase has not completed. Run cwf:clarify first,
   or use `cwf:impl --skip-clarify` to bypass.
   ```

   Do NOT proceed to plan discovery. This is a hard gate — implementation cannot begin without a completed clarify phase unless explicitly bypassed.

---

## Commit Gate

Stage and commit completed work using Conventional Commit format.

### Per-File Staging

Stage only the files modified during the work item (specific files, not `git add -A`):

```bash
git add path/to/file1 path/to/file2
```

### Commit Message Construction

- **Type**: Infer from domain — `feat` (new feature), `fix` (bug fix), `docs` (documentation), `refactor` (restructuring), `chore` (maintenance)
- **Scope**: Derive from the plan step's primary target (e.g., `impl`, `clarify`, `review`)
- **Description**: Summarize the work item's deliverable (imperative mood, max 72 chars)
- **Body**: List the step descriptions that were executed
- **Trailer**: `Co-Authored-By: Claude <agent>` (follow the git log convention of the repo)

### Commit Format

```bash
git commit -m "$(cat <<'EOF'
type(scope): description of deliverable

Steps executed:
- Step N: description
- Step M: description

Co-Authored-By: Claude <agent>
EOF
)"
```

### Clean State Verification

After committing, verify the working tree is clean:

```bash
git status --porcelain
```

If output is non-empty, investigate and resolve before proceeding.

### Lesson-Driven Commits

If a lesson is discovered during implementation that leads to a code change:

1. Record it in `lessons.md` immediately
2. Commit the lesson-driven change **separately** from the work item commit:

   ```bash
   git add lessons.md path/to/changed-file
   git commit -m "$(cat <<'EOF'
   fix(scope): brief description of lesson-driven fix

   Driven by lesson: {lesson title}

   The lesson revealed that {brief explanation}, requiring this change.

   Co-Authored-By: Claude <agent>
   EOF
   )"
   ```

   Use type `fix` or `refactor` depending on whether it corrects a bug or restructures code. The commit body MUST reference the lesson with the prefix "Driven by lesson:".

### Cross-Cutting Commit Strategy

When Phase 2.6 identifies cross-cutting changes:

- **Cross-cutting**: Commit boundary = change pattern. Group files by the concept they implement, regardless of which agent modified them.
- **Modular**: Commit boundary = work item (default). Each agent's files form one commit.

When a batch contains multiple work items sharing a `Commit Group`, create one commit per group (not per work item). Stage all files that implement the same concept together.
