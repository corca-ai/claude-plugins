# GitHub Issue Draft: Smart File Reading for Read Tool

> Target: https://github.com/anthropics/claude-code/issues
> Template: Feature Request

---

## Title

`[FEATURE] Size-aware file reading — pre-flight checks for Read tool and smart @ attachment handling`

## Preflight Checklist

- [x] I have searched existing requests and this feature hasn't been requested yet
- [x] This is a single feature request (not multiple features)

Note: Related issues exist (#14888 dynamic token limits, #22506 /tokens command, #6780 session corruption from large files, #12349 context flood protection — closed/autoclose, #16390 attachment size warnings), but none propose a unified size-aware reading strategy covering both the Read tool and `@` file attachments.

## Problem Statement

There are two entry points for loading file content into context — the Read tool and `@` file attachments — and neither has pre-flight intelligence about file size. This causes several problems:

### Read tool

**1. Silent context flooding**: A single `Read` call on a large file (e.g., 5000+ lines) can consume a significant portion of the context window. The agent discovers the file is too large only *after* the tokens are already spent. Even when truncated at 2000 lines, the content often fills context with information the agent didn't actually need.

**2. No size-aware strategy selection**: The agent has no mechanism to choose the right reading approach *before* executing. For a 300-line file, full read is fine. For a 3000-line file, `offset`/`limit` or `Grep` would be far more efficient. Currently, this decision can only happen after context is already consumed.

### @ file attachment

**3. Silent failure on large files**: When a user attaches a large file via `@`, it either silently fails to load or loads the entire content into context with no warning. There is no feedback at attachment time about whether the file size is problematic. The user discovers the issue only when they submit their prompt and get a "Prompt is too long" error (as also described in #16390), or worse, the session becomes degraded.

**4. No graceful degradation**: When `@` encounters a file too large to inline, the ideal behavior would be to fall back to a smarter strategy — e.g., pass the file path to the agent so it can use Read with offset/limit, or Grep to find relevant sections. Instead, the current behavior is binary: either full inline or failure.

### Shared problems

**5. System prompt workarounds are fragile**: Users add rules to CLAUDE.md like "always check file size before reading" — but this costs an extra turn (the agent runs `wc -l` first), and system prompt rules can be ignored under context pressure.

**6. Cascading session problems**: As documented in #6780, large file reads can corrupt sessions irreversibly. There is no proactive defense at any level.

## Proposed Solution

Add size-aware intelligence to both file loading paths:

### A. Read Tool — Pre-flight Size Check

| File Size | Read Behavior |
|-----------|---------------|
| ≤ small threshold (e.g., 500 lines) | Read normally, no intervention |
| Small → large threshold (e.g., 500-2000 lines) | Read normally, but inject a system note: "This file has N lines. Consider using offset/limit for future reads of this file." |
| > large threshold (e.g., 2000 lines) | Block the read. Return guidance: "File has N lines. Use Read with offset/limit, or use Grep to find relevant sections first." |

### B. @ Attachment — Smart Fallback

| File Size | @ Behavior |
|-----------|------------|
| ≤ inline threshold | Inline as today (no change) |
| > inline threshold | Do NOT inline. Instead: (1) Show a visible warning: "File X is too large to inline (N tokens). Passing as a path reference instead." (2) Pass the file path to the agent, so it can use Read/Grep/Task tools to access the content intelligently. |

The key insight: `@` on a large file should **degrade gracefully to a path reference**, not fail silently. The agent already has the tools to handle large files well (Read with offset/limit, Grep, Task/Explore) — it just needs the path instead of a context-flooding inline.

### Key Design Principles

1. **Pre-flight, not post-hoc**: Check size *before* reading/inlining, not after tokens are consumed.
2. **Intentional bypass**: For Read, if the agent explicitly sets `offset` or `limit` parameters, allow regardless of file size. This signals intentional, targeted reading.
3. **Graceful degradation**: For `@`, large files become path references rather than silent failures.
4. **Binary-aware**: Skip the check for PDFs, images, and notebooks (which the Read tool handles natively as visual content).
5. **Configurable**: Thresholds should be adjustable (environment variables or settings).

### User Experience

**Read tool:**
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

**@ attachment:**
```
# Small file — no change
> @src/utils.ts explain this
(file content inlined, agent sees it immediately)

# Large file — graceful degradation
> @data/huge-log.txt find the error
[warning: data/huge-log.txt is ~45,000 tokens — too large to inline.
 Passing as path reference. The agent will read relevant sections.]
(agent receives the path, uses Grep/Read with offset to find the error)
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

**Scenario 1 — Read tool:**
1. Agent is tasked with fixing a bug in a large codebase
2. Agent identifies a relevant file `/src/services/database.ts` (3,500 lines)
3. **Current**: Agent calls `Read /src/services/database.ts` → 2,000 lines loaded into context (truncated). Agent realizes it needs lines 2800-2900. Calls Read again with offset. Total: ~2,100 lines of context consumed for ~100 lines of useful content.
4. **Proposed**: Agent calls `Read /src/services/database.ts` → Blocked with "3,500 lines. Use offset/limit or Grep." Agent calls `Grep "connectionPool" /src/services/database.ts` → finds relevant section at line 2850. Agent calls `Read /src/services/database.ts offset=2830 limit=40` → reads exactly what's needed. Total: ~50 lines of context consumed.

**Scenario 2 — @ attachment:**
1. User starts a new session and types: `@large-report.pdf summarize this`
2. **Current**: The PDF (~180k tokens) is inlined. User hits Enter → "Prompt is too long" error. Session is effectively dead. User must start over without `@`.
3. **Proposed**: `@` detects the PDF is too large → shows warning "large-report.pdf is ~180k tokens, passing as path reference." Agent receives the path, uses Read to process the PDF page by page, produces a summary without flooding context.

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
| #16390 (attachment warnings) | This subsumes that request — we propose graceful degradation (path fallback) beyond just a warning |
| #12349 (context flood protection) | Same problem statement, but that was closed for lack of specifics — this provides a concrete mechanism and working PoC |
| #15426 (binary file reads after compaction) | The binary-aware check in our PoC addresses this class of problems |
