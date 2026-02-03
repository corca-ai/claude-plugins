# Plan: smart-read Hook Plugin

## Goal

Create a `PreToolUse` hook plugin that intercepts `Read` tool calls and enforces intelligent file reading based on file size. Prevents context waste by denying full reads on large files and guiding Claude to use offset/limit or Grep.

## Success Criteria

```gherkin
Given a Read call on a file with ≤500 lines and no offset/limit
When the hook runs
Then the read is allowed silently

Given a Read call on a file with 501-2000 lines and no offset/limit
When the hook runs
Then the read is allowed with additionalContext showing line count

Given a Read call on a file with >2000 lines and no offset/limit
When the hook runs
Then the read is denied with guidance to use offset/limit or Grep

Given a Read call with offset or limit already set
When the hook runs
Then the read is always allowed (regardless of file size)

Given a Read call on a binary file (PDF, image, notebook)
When the hook runs
Then the read is always allowed (Read handles these natively)

Given custom thresholds via env vars CLAUDE_CORCA_SMART_READ_WARN_LINES=1000
When the hook runs
Then the warn threshold is 1000 instead of default 500
```

## Design

### Hook behavior matrix

| Condition | Action | Output |
|-----------|--------|--------|
| offset or limit set | allow | (silent, exit 0) |
| binary file (PDF/image/ipynb) | allow | (silent, exit 0) |
| file not found / unreadable | allow | (let Read handle error) |
| ≤ WARN lines (default 500) | allow | (silent, exit 0) |
| WARN < lines ≤ DENY (500-2000) | allow + context | additionalContext with line count |
| > DENY lines (default 2000) | deny | permissionDecision: deny + guidance |

### Bypass mechanism

Claude can bypass the deny by explicitly setting `limit` (e.g., `limit: 500`). The hook only blocks when BOTH offset AND limit are absent — this teaches Claude to be intentional without being a hard wall.

### Environment variables

| Variable | Default | Description |
|----------|---------|-------------|
| `CLAUDE_CORCA_SMART_READ_WARN_LINES` | 500 | Lines above which additionalContext is added |
| `CLAUDE_CORCA_SMART_READ_DENY_LINES` | 2000 | Lines above which read is denied |

Loaded from `~/.claude/.env` following existing plugin convention.

## File Structure

```
plugins/smart-read/
├── .claude-plugin/
│   └── plugin.json              # v1.0.0
└── hooks/
    ├── hooks.json               # PreToolUse matcher: "Read"
    └── scripts/
        └── smart-read.sh        # Main hook logic
```

## Files to Create

### 1. `plugins/smart-read/.claude-plugin/plugin.json`

Standard metadata: name "smart-read", version "1.0.0", Corca author.

### 2. `plugins/smart-read/hooks/hooks.json`

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Read",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/hooks/scripts/smart-read.sh"
          }
        ]
      }
    ]
  }
}
```

### 3. `plugins/smart-read/hooks/scripts/smart-read.sh`

Script flow:
1. Load env vars from `~/.claude/.env`
2. Read stdin JSON, extract `file_path`, `offset`, `limit` via jq
3. Early exit (allow) if offset or limit already set
4. Early exit if file_path empty or file not found
5. Check MIME type — allow binary files (PDF, image/*, ipynb)
6. Count lines with `wc -l`
7. Apply threshold logic: allow / allow+context / deny

## Files to Modify

### 4. `.claude-plugin/marketplace.json`

Add smart-read entry to plugins array.

### 5. `README.md` + `README.ko.md`

Add smart-read to plugin table and Hooks section.

## Verification

1. Install locally: `/plugin install smart-read@corca-plugins`
2. Test small file: Read a file with <500 lines — should pass silently
3. Test medium file: Read a file with 500-2000 lines — should see additionalContext in system-reminder
4. Test large file: Read a file with >2000 lines without offset/limit — should be denied
5. Test bypass: Read same large file WITH offset/limit — should be allowed
6. Test binary: Read a PDF — should be allowed
7. Test env override: Set `CLAUDE_CORCA_SMART_READ_DENY_LINES=100` in `~/.claude/.env`, verify lower threshold

## Status

- ✅ plugin.json created
- ✅ hooks.json created
- ✅ smart-read.sh created (with WARN≤DENY clamp fix)
- ✅ marketplace.json updated
- ✅ README.md + README.ko.md updated
- ✅ All test scenarios passed

## Deferred Actions

- [ ] None
