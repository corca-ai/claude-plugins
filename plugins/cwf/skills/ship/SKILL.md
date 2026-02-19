---
name: ship
description: "Automate GitHub workflow so validated session artifacts become ship-ready issue/PR/merge actions with explicit human control points. Triggers: \"/ship\""
---

# Ship (/ship)

Convert validated CWF session artifacts into issue → PR → merge execution with explicit human merge control.

## Quick Start

```text
/ship                                  Show usage
/ship issue [--base B] [--no-branch]   Create issue + feature branch
/ship pr [--base B] [--issue N] [--draft]  Create PR linked to issue
/ship merge [--squash|--merge|--rebase]    Check & merge if ready
/ship status                           Show open issues, PRs, checks
```

No args or `help` → print the usage block above and stop.

## Defaults

- **Base branch**: auto-detect remote default branch → `main` → `master` (override with `--base`)
- **Merge strategy**: `--squash` (override with `--merge` or `--rebase`)

## Prerequisites

Before any subcommand, verify:

```bash
command -v gh >/dev/null 2>&1 || { echo "gh CLI not found"; exit 1; }
gh auth status 2>&1 | grep -q "Logged in" || { echo "Not authenticated — run: gh auth login"; exit 1; }
```

If either fails, do not stop with a passive failure only. Ask the user:
- `Install/configure now (recommended)`:
  - if `gh` is missing, run `bash {SKILL_DIR}/../setup/scripts/install-tooling-deps.sh --install gh`
  - if auth is missing, run `gh auth login`
  - then retry prerequisite checks once
- `Show commands only`:
  - print exact install/auth commands and stop
- `Skip ship for now`:
  - stop without executing ship actions

## Output Persistence (Mandatory)

For every `/ship` invocation (`issue`, `pr`, `merge`, `status`, and `help` or no-args):

1. Resolve session directory from live state (`live.dir`).
2. Persist a structured execution summary to `{session_dir}/ship.md` with these required sections:
   - `## Execution Status`
   - `## Ambiguity Resolution`
   - `## Next Step`
3. In `## Ambiguity Resolution`, always write these scalar lines:
   - `mode: strict|defer-blocking|defer-reversible|explore-worktrees`
   - `blocking_open_count: <integer>`
   - `blocking_issue_refs: <comma-separated refs or none>`
   - `merge_allowed: yes|no`
   - Resolve `mode` from live state (`live.ambiguity_mode`) and derive counts from `{session_dir}/run-ambiguity-decisions.md` if it exists.
   - For `defer-blocking`, `merge_allowed` must be `no` when `blocking_open_count > 0`.
4. Synchronize live ambiguity debt state before gate closure:

```bash
bash {CWF_PLUGIN_DIR}/scripts/sync-ambiguity-debt.sh \
  --base-dir . \
  --session-dir "{session_dir}"
```

1. When running under `cwf:run`, enforce the stage gate:

```bash
bash {CWF_PLUGIN_DIR}/scripts/check-run-gate-artifacts.sh \
  --session-dir "{session_dir}" \
  --stage ship \
  --strict \
  --record-lessons
```

---

## /ship issue

Create a GitHub issue for the current session and optionally a feature branch.

### Workflow

1. **Detect session context**:
   - Find the current session directory in `.cwf/projects/` (most recent `YYMMDD-NN-*`)
   - Read `plan.md` if it exists for purpose, scope, success criteria
   - Read master-plan (search for `master-plan.md` or similar) for session number
   - Resolve `{base}`:
     - if `--base` is provided, use it
     - otherwise detect with `git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||'`
     - if unresolved, fallback to `main`, then `master`; if none exists, ask the user for base branch explicitly

2. **Compose issue body**:
   - Read `{SKILL_DIR}/references/issue-template.md`
   - Substitute variables from session context:
     - `{BACKGROUND}` — why this work is needed; extract from plan.md context/motivation section, or summarize from session history
     - `{PROBLEM}` — specific problem being solved; from plan.md or ask the user
     - `{GOAL}` — desired outcome; from plan.md objectives or ask the user
     - `{SCOPE}` — files/areas from plan.md or summarize
     - `{BRANCH}` — the feature branch name to be created
     - `{BASE}` — the base branch
     - `{PLAN_LINK}` — relative path to plan.md
   - If plan.md is missing or incomplete, ask the user for the missing fields

3. **Create issue**:

   ```bash
   gh issue create \
     --title "S{N}: {title}" \
     --body "$(cat <<'EOF'
   {composed_body}
   EOF
   )" \
     --label "cwf-v3"
   ```

   - If `cwf-v3` label doesn't exist, create it first:
     `gh label create cwf-v3 --color 0E8A16 --description "CWF v3 migration"`

4. **Create feature branch** (unless `--no-branch`):

   ```bash
   git checkout {base} && git pull origin {base}
   git checkout -b feat/{short-name}
   ```

5. **Report**: Print issue URL and branch name.

---

## /ship pr

Create a pull request from the current feature branch.

### Workflow

1. **Pre-flight checks** (stop with message if any fail):
   - Resolve `{base}` using the same rule as `/ship issue`
   - Not on the resolved base branch
   - Has commits ahead of base: `git log {base}..HEAD --oneline` is non-empty
   - No uncommitted changes: `git status --porcelain` is empty
     - If dirty, ask user whether to commit first or abort

2. **Auto-detect linked issue**:
   - If `--issue N` provided, use that
   - Otherwise: `gh issue list --label cwf-v3 --search "S{N}" --json number,title`
   - Match by session number from the current session artifact directory name
   - If no match found, proceed without issue link (warn the user)

3. **Build PR body** from `{SKILL_DIR}/references/pr-template.md`:
   - `{ISSUE_LINK}` — `Closes #{N}` if issue found, otherwise omit
   - `{PURPOSE}` — synthesize from `git log {base}..HEAD --oneline` and plan.md;
     describe **why** this change exists, not what files changed
   - `{DECISIONS}` — extract key decisions from:
     - `.cwf/projects/{session}/lessons.md` takeaways
     - `.cwf/projects/{session}/retro.md` CDM section
     - `.cwf/projects/{session}/plan.md` decision points
     - Format as markdown table: `| Decision | Rationale | Alternatives |` (in user's language)
     - If no decisions found, write a brief "no significant decisions" note (in user's language)
   - `{VERIFICATION}` — concrete, reproducible verification steps:
     - Include exact commands to run (e.g., `claude --plugin-dir ... -p "..."`)
     - Describe expected output/behavior
     - Cover both happy path and edge cases if relevant
   - `{HUMAN_JUDGMENT}` — agent self-assessment of items needing human review:
     - Architecture changes, UX decisions, security implications, breaking changes
     - Read `live.ambiguity_mode` and `{session_dir}/run-ambiguity-decisions.md` when present
     - If mode is `defer-blocking` and `blocking_open_count > 0`, list all open blocking decision debts here (never write `None`)
     - If none, write `None` (this enables autonomous merge — see `/ship merge`)
   - `{SYSTEM_IMPACT}` — behavioral changes visible to end users or dependent systems
   - `{FUTURE_IMPACT}` — impact on future development (new patterns, constraints, tech debt)
   - `{GIT_DIFF_STAT}` — output of `git diff {base}...HEAD --stat`
     wrapped in a `` ```text `` code fence
   - `{LESSONS}` — extract from `.cwf/projects/{session}/lessons.md` if exists,
     otherwise write `_No lessons recorded for this session._`
   - `{CDM}` — extract from `.cwf/projects/{session}/retro.md` CDM section if exists,
     otherwise write `_No CDM recorded yet._`
   - `{CONDITIONAL_ITEMS}` — add checklist items based on changed file types:
     - `*.sh` changed → `- [ ] Scripts are executable and pass shellcheck`
     - `SKILL.md` changed → `- [ ] SKILL.md under 500 lines`
     - `plugin.json` changed → `- [ ] Version bumped appropriately`
     - `hooks.json` changed → `- [ ] Hook matchers are correct`
     - `*.md` changed → `- [ ] Markdown lint passes`

4. **Push and create PR**:

   ```bash
   git push -u origin $(git branch --show-current)
   ```

   ```bash
   gh pr create \
     --title "S{N}: {title}" \
     --body "$(cat <<'EOF'
   {composed_body}
   EOF
   )" \
     --base {base}
   ```

   - Add `--draft` if the user specified it

5. **Report**: Print PR URL.

---

## /ship merge

Check PR status and merge if ready.

### Workflow

1. **Find current PR**:

   ```bash
   gh pr view --json number,state,reviewDecision,statusCheckRollup,mergeable,headRefName
   ```

   - If no PR found for current branch, report and stop

2. **Assess readiness**:

   **Core checks** (always required):
   - `state` = `OPEN`
   - All status checks passed (parse `statusCheckRollup`)
   - `mergeable` = `MERGEABLE`

   **Review requirement** (conditional):
   - Parse the PR body for `## Human Judgment Required` section
   - Check branch protection: `gh api repos/{owner}/{repo}/branches/{base}/protection 2>&1`
   - Parse `{session_dir}/run-ambiguity-decisions.md` and/or `ship.md` ambiguity block:
     - if `mode: defer-blocking` and `blocking_open_count > 0`, merge is blocked

   Decision matrix:

   | Human judgment | Branch protected | Review required |
   |---|---|---|
   | `defer-blocking` with open blocking debt | Any | **Stop** — do not merge |
   | `None` or empty | No | **Skip** — autonomous merge |
   | `None` or empty | Yes | `reviewDecision` = `APPROVED` required |
   | Items listed | Any | Report items, **stop** — do not merge |

   If not ready, report which conditions are blocking and stop. Do not attempt to merge.

3. **Merge**:

   ```bash
   gh pr merge {N} --squash --delete-branch
   ```

   - Use `--merge` or `--rebase` if the user specified an override
   - Default is `--squash`

4. **Post-merge cleanup**:

   ```bash
   git checkout {base} && git pull origin {base}
   ```

5. **Report**: Merge confirmation, deleted branch name.

---

## /ship status

Read-only overview of current GitHub state.

### Workflow

1. **Open issues**:

   ```bash
   gh issue list --label cwf-v3 --state open --json number,title,assignees
   ```

2. **Open PRs**:

   ```bash
   gh pr list --json number,title,state,headRefName,reviewDecision,statusCheckRollup
   ```

3. **Current branch PR** (if exists):

   ```bash
   gh pr view --json number,title,state,reviewDecision,mergeable,statusCheckRollup
   ```

   - If no PR for current branch, note that

4. **Session progress** (optional):
   - If `master-plan.md` exists, parse the session roadmap
   - Show completed vs remaining sessions

5. **Report**: Format as a readable summary table.

---

## Error Handling

| Situation | Action |
|-----------|--------|
| `gh` not installed | Ask whether to install now via setup installer script; if declined/fails, print manual commands and stop |
| Not authenticated | Report, suggest `gh auth login`, stop |
| No commits ahead of base | Report "nothing to PR", stop |
| Issue already exists for session | Show existing issue, ask user before creating duplicate |
| PR already exists for branch | Show existing PR URL, stop |
| Merge conflicts | Report, suggest `git rebase {base}` instructions, stop |
| Missing `lessons.md` or `retro.md` | Use placeholder text, do not fail |
| Label `cwf-v3` missing | Create it automatically |
| Dirty working tree on PR | Ask user: commit or abort |

## Usage Message

When invoked with no args or `help`, print:

```text
Ship — GitHub workflow automation for cwf sessions

Usage:
  /ship                                  Show this message
  /ship issue [--base B] [--no-branch]   Create issue + feature branch
  /ship pr [--base B] [--issue N] [--draft]  Create PR
  /ship merge [--squash|--merge|--rebase]    Merge approved PR
  /ship status                           Show issues, PRs, checks

Defaults: base=auto-detected (origin/HEAD -> main -> master), merge=squash
```

## Rules

1. Use `gh` as the primary interface; do not craft raw GitHub API payloads when `gh` already supports the operation.
2. Stop immediately on failed prerequisites (`gh` missing, unauthenticated, or invalid branch state).
3. Keep PR purpose and decision sections evidence-backed from session artifacts when available (`plan.md`, `lessons.md`, `retro.md`).
4. Never auto-merge when human-judgment items are present in the PR body.
5. Preserve user-created files and branches; do not perform destructive cleanup beyond explicit merge cleanup.
6. All code fences must have language specifiers.
7. Missing prerequisites must trigger an install/configure choice prompt, not a passive "missing tool" report only.
8. `/ship` must always persist `{session_dir}/ship.md` before returning.
9. In `defer-blocking` mode, unresolved ambiguity debt is merge-blocking until tracked follow-up references are recorded and `blocking_open_count` is zero.
10. **Language override**: issue/PR narrative sections are written in the user's language; code blocks, file paths, commit hashes, and CLI output remain verbatim.

## References

- [issue-template.md](references/issue-template.md) — Issue body template
- [pr-template.md](references/pr-template.md) — PR body template
- [agent-patterns.md](../../references/agent-patterns.md) — Shared workflow pattern reference
