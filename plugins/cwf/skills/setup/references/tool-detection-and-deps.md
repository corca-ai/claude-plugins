# Tool Detection and Dependency Handling Details

Detailed procedure reference for setup Phase 2 (tool detection, dependency prompts, and post-install re-detection).

`SKILL.md` remains the routing and invariant contract. Use this file for concrete checks, AskUserQuestion text, and command templates.

## Phase 2: External Tool Detection

Detect availability of external AI/search tools and local runtime dependencies used by CWF checks/skills.

### 2.1 Check Tools

Run the following checks via Bash:

```bash
command -v codex >/dev/null 2>&1     # Codex CLI
command -v gemini >/dev/null 2>&1 || npx @google/gemini-cli --version 2>/dev/null  # Gemini CLI
command -v shellcheck >/dev/null 2>&1 # Shell lint gate
command -v jq >/dev/null 2>&1         # JSON parsing for scripts
command -v gh >/dev/null 2>&1         # GitHub CLI for ship
command -v node >/dev/null 2>&1       # Node runtime for gather/review helpers
command -v python3 >/dev/null 2>&1    # Python runtime for gather helpers
command -v lychee >/dev/null 2>&1     # Deterministic link checks for docs/refactor
command -v markdownlint-cli2 >/dev/null 2>&1 # Deterministic markdown lint checks
```

Check environment variables:

```bash
[ -n "${TAVILY_API_KEY:-}" ]         # Tavily search API
[ -n "${EXA_API_KEY:-}" ]            # Exa search API
```

### 2.2 Update cwf-state.yaml

Edit `cwf-state.yaml` `tools:` section with AI/search results:

```yaml
tools:
  codex: available      # or "unavailable"
  gemini: available     # or "unavailable"
  tavily: available     # or "unavailable"
  exa: unavailable      # or "available"
```

### 2.3 Report Results

Display two result groups:

1) AI/search tools + API keys:

```text
Tool Detection Results:
  codex   : available
  gemini  : available
  tavily  : unavailable (TAVILY_API_KEY not set)
  exa     : unavailable (EXA_API_KEY not set)
```

1) Local runtime dependencies:

```text
Local Dependency Results:
  shellcheck : available|unavailable
  jq         : available|unavailable
  gh         : available|unavailable
  node       : available|unavailable
  python3    : available|unavailable
  lychee     : available|unavailable
  markdownlint-cli2: available|unavailable
```

### 2.3.1 Missing Dependency Install Prompt (Required)

If any local runtime dependency is missing, use AskUserQuestion (single choice):

```text
Some CWF runtime dependencies are missing. Install missing tools now?
```

Options:
- `Install missing now (recommended)`:
  - run installer script for missing tools
  - re-check and report unresolved items with exact commands
- `Show commands only`:
  - do not install
  - print exact install commands per missing tool
- `Skip for now`:
  - continue setup without installation

If user selects `Install missing now (recommended)`, run:

```bash
bash {SKILL_DIR}/scripts/install-tooling-deps.sh --install missing
```

If user selects `Show commands only`, run:

```bash
bash {SKILL_DIR}/scripts/install-tooling-deps.sh --check
```

Then print manual install commands for each missing tool from script output.

### 2.3.2 Retry Check (After Install Attempt)

After `Install missing now` path, re-run:

```bash
bash {SKILL_DIR}/scripts/install-tooling-deps.sh --check
```

If still missing, explicitly list unresolved tools and ask whether to continue setup or stop for manual installation.

### 2.3.3 Post-Install Re-Detection + `cwf-state.yaml` Rewrite (Required)

When `Install missing now` was selected, run a full re-detection pass so `cwf-state.yaml` remains the SSOT for tool status:

1. Re-run **all checks in Phase 2.1** (AI/search tools + local runtime dependencies + API key presence).
2. Re-run **Phase 2.2** and rewrite `cwf-state.yaml` `tools:` from the re-detected results.
3. Re-run **Phase 2.3** output reporting and label the second report as post-install results.

This step is mandatory even when some dependencies remain unresolved.

### 2.3.4 Setup Contract Bootstrap and Repo-Tool Proposal (Required for full/tools setup)

After baseline dependency detection, bootstrap setup contract:

```bash
bash {SKILL_DIR}/scripts/bootstrap-setup-contract.sh --json
```

Handle by `status`:

- `created` or `updated`:
  - report generated contract path
  - summarize `repo_tools` proposals from contract
  - ask whether to apply repo-specific suggestions now
- `existing`:
  - report contract path and continue with current contract
- `fallback`:
  - report warning and continue with core defaults

Prompt text:

```text
Setup contract draft is ready. Apply repository-specific tool suggestions now?
```

If approved, install selected suggestions via:

```bash
bash {SKILL_DIR}/scripts/install-tooling-deps.sh --install <tool1,tool2,...>
```

Contract details and status semantics: [setup-contract.md](setup-contract.md)
