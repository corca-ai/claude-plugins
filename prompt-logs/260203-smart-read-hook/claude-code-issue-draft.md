# GitHub Issue Draft: Smart File Reading for Read Tool

> Target: https://github.com/anthropics/claude-code/issues
> Template: Feature Request

---

## Title

`[FEATURE] Pre-flight file size check for Read tool with adaptive reading strategy`

## Preflight Checklist

- [x] I have searched existing requests and this feature hasn't been requested yet
- [x] This is a single feature request (not multiple features)

Note: Related issues exist (#14888 dynamic token limits, #22506 /tokens command, #6780 session corruption from large files, #12349 context flood protection — closed/autoclose), but none propose automatic pre-read size checking with adaptive strategy at the Read tool level.

## Problem Statement

The Read tool has no pre-flight intelligence about file size. It attempts to read any file regardless of how many lines/tokens it contains relative to the remaining context window. This causes several problems:

**1. Silent context flooding**: A single `Read` call on a large file (e.g., 5000+ lines) can consume a significant portion of the context window. The agent discovers the file is too large only *after* the tokens are already spent. Even when truncated at 2000 lines, the content often fills context with information the agent didn't actually need.

**2. No size-aware strategy selection**: The agent has no mechanism to choose the right reading approach *before* executing. For a 300-line file, full read is fine. For a 3000-line file, `offset`/`limit` or `Grep` would be far more efficient. Currently, this decision can only happen after context is already consumed.

**3. System prompt workarounds are fragile**: Users add rules to CLAUDE.md like "always check file size before reading" — but this costs an extra turn (the agent runs `wc -l` first), and system prompt rules can be ignored under context pressure.

**4. Cascading session problems**: As documented in #6780, large file reads can corrupt sessions. As noted in #16390, there's no proactive feedback before context is consumed.

## Proposed Solution

Add a pre-flight size check to the Read tool that adapts behavior based on file size:

### Behavior Matrix

| File Size | Read Behavior |
|-----------|---------------|
| ≤ small threshold (e.g., 500 lines) | Read normally, no intervention |
| Small → large threshold (e.g., 500-2000 lines) | Read normally, but inject a system note: "This file has N lines. Consider using offset/limit for future reads of this file." |
| > large threshold (e.g., 2000 lines) | Block the read. Return guidance: "File has N lines. Use Read with offset/limit, or use Grep to find relevant sections first." |

### Key Design Principles

1. **Pre-flight, not post-hoc**: Check size *before* reading, not after tokens are consumed.
2. **Intentional bypass**: If the agent explicitly sets `offset` or `limit` parameters, allow the read regardless of file size. This signals intentional, targeted reading.
3. **Binary-aware**: Skip the check for PDFs, images, and notebooks (which the Read tool handles natively as visual content).
4. **Configurable**: Thresholds should be adjustable (environment variables or settings).

### User Experience

```
# Small file — no change
> Read /src/utils.ts
(reads normally)

# Medium file — reads with advisory note
> Read /src/large-module.ts
[system note: File has 1,200 lines. Consider using offset/limit for targeted reading.]
(reads normally)

# Large file — blocked with guidance
> Read /data/huge-log.txt
[blocked: File has 8,500 lines. To read: (1) Use Read with offset/limit, (2) Use Grep to find relevant sections, (3) Use Task/Explore agent for broad understanding.]

# Explicit offset/limit — always allowed
> Read /data/huge-log.txt offset=100 limit=200
(reads lines 100-300, regardless of total file size)
```

## Alternative Solutions

### Current workarounds

1. **CLAUDE.md rules** ("check file size before reading"): Works but costs an extra turn per read and is not enforced — the agent can ignore it.
2. **PreToolUse hooks** (what we built): Works well as a plugin ([smart-read hook](https://github.com/corca-ai/claude-plugins)) but requires users to discover and install a third-party plugin. This should be a built-in behavior.
3. **`MAX_MCP_OUTPUT_TOKENS` env var**: Limits output size but is a blunt instrument — doesn't provide guidance on *how* to read the file differently.

### Why this should be built-in

The PreToolUse hook system is powerful and we've built a working implementation. However:
- Most users don't know hooks exist
- Context waste from large file reads is a universal problem (evidenced by multiple related issues: #6780, #12349, #14888, #16390, #22506)
- The Read tool already has a 2000-line default limit — adding size-aware behavior before that limit is hit is a natural extension

## Priority

High - Significant impact on productivity

## Feature Category

File operations

## Use Case Example

1. Agent is tasked with fixing a bug in a large codebase
2. Agent identifies a relevant file `/src/services/database.ts` (3,500 lines)
3. **Current**: Agent calls `Read /src/services/database.ts` → 2,000 lines loaded into context (truncated). Agent realizes it needs lines 2800-2900. Calls Read again with offset. Total: ~2,100 lines of context consumed for ~100 lines of useful content.
4. **Proposed**: Agent calls `Read /src/services/database.ts` → Blocked with "3,500 lines. Use offset/limit or Grep." Agent calls `Grep "connectionPool" /src/services/database.ts` → finds relevant section at line 2850. Agent calls `Read /src/services/database.ts offset=2830 limit=40` → reads exactly what's needed. Total: ~50 lines of context consumed.

## Additional Context

### Working proof-of-concept

We've implemented this as a [PreToolUse hook plugin](https://github.com/corca-ai/claude-plugins) (`smart-read`) that demonstrates the approach works in practice:
- Shell script that intercepts Read calls via stdin JSON
- Checks `wc -l` before allowing the read
- Thresholds configurable via `CLAUDE_CORCA_SMART_READ_WARN_LINES` and `CLAUDE_CORCA_SMART_READ_DENY_LINES` environment variables
- Allows bypass when `offset` or `limit` is explicitly set
- Skips binary files (PDF, images, notebooks)

This validates the UX: the agent quickly learns to use offset/limit or Grep when denied, and context usage drops significantly.

### Relationship to existing issues

| Issue | Relationship |
|-------|-------------|
| #14888 (dynamic token limits) | Complementary — that raises the ceiling, this adds pre-flight intelligence |
| #22506 (/tokens command) | Complementary — that's manual, this is automatic |
| #6780 (session corruption) | This prevents the root cause (oversized reads) |
| #16390 (attachment warnings) | Same philosophy, different vector (`@` vs `Read` tool) |
| #12349 (context flood protection) | Same problem statement, but that was closed for lack of specifics — this provides a concrete mechanism and working PoC |
