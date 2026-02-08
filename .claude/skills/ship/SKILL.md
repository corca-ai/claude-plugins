---
name: ship
description: |
  Automate GitHub workflow: issue creation, PR with lessons/CDM/checklist,
  and merge management. Triggers: "/ship"
allowed-tools:
  - Bash
  - Read
  - Glob
  - Grep
---

# Ship (/ship)

Automate the GitHub issue → PR → merge cycle for cwf sessions.

**Language**: Match the user's language.

## Commands

```text
/ship                                  Show usage
/ship issue [--base B] [--no-branch]   Create issue + feature branch
/ship pr [--base B] [--issue N] [--draft]  Create PR linked to issue
/ship merge [--squash|--merge|--rebase]    Check & merge if ready
/ship status                           Show open issues, PRs, checks
```

No args or `help` → print the usage block above and stop.

## Defaults

- **Base branch**: `marketplace-v3` (override with `--base`)
- **Merge strategy**: `--squash` (override with `--merge` or `--rebase`)

## Prerequisites

Before any subcommand, verify:

```bash
command -v gh >/dev/null 2>&1 || { echo "gh CLI not found"; exit 1; }
gh auth status 2>&1 | grep -q "Logged in" || { echo "Not authenticated — run: gh auth login"; exit 1; }
```

If either fails, report the issue and stop. Do not proceed.

---

## /ship issue

Create a GitHub issue for the current session and optionally a feature branch.

### Workflow

1. **Detect session context**:
   - Find the current session directory in `prompt-logs/` (most recent `YYMMDD-NN-*`)
   - Read `plan.md` if it exists for purpose, scope, success criteria
   - Read master-plan (search for `master-plan.md` or similar) for session number

2. **Compose issue body**:
   - Read `{SKILL_DIR}/references/issue-template.md`
   - Substitute variables from session context:
     - `{PURPOSE}` — from plan.md or ask the user
     - `{SUCCESS_CRITERIA}` — from plan.md or ask the user
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
   - Not on `main` or the base branch
   - Has commits ahead of base: `git log {base}..HEAD --oneline` is non-empty
   - No uncommitted changes: `git status --porcelain` is empty
     - If dirty, ask user whether to commit first or abort

2. **Auto-detect linked issue**:
   - If `--issue N` provided, use that
   - Otherwise: `gh issue list --label cwf-v3 --search "S{N}" --json number,title`
   - Match by session number from current prompt-logs directory name
   - If no match found, proceed without issue link (warn the user)

3. **Build PR body** from `{SKILL_DIR}/references/pr-template.md`:
   - `{SUMMARY}` — `git log {base}..HEAD --oneline` formatted as bullet list
   - `{ISSUE_LINK}` — `Closes #{N}` if issue found, otherwise omit
   - `{GIT_DIFF_STAT}` — output of `git diff {base}...HEAD --stat`
     wrapped in a `` ```text `` code fence
   - `{LESSONS}` — extract from `prompt-logs/{session}/lessons.md` if exists,
     otherwise write `_No lessons recorded for this session._`
   - `{CDM}` — extract from `prompt-logs/{session}/retro.md` CDM section if exists,
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

2. **Assess readiness** — all must be true:
   - `state` = `OPEN`
   - `reviewDecision` = `APPROVED`
   - All status checks passed (parse `statusCheckRollup`)
   - `mergeable` = `MERGEABLE`

   If not ready, report which conditions are blocking and stop.
   Do not attempt to merge.

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
| `gh` not installed | Report, suggest `brew install gh` or `apt install gh`, stop |
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

Defaults: base=marketplace-v3, merge=squash
```
