# Session Bootstrap Snippet

Shared session-directory resolution pattern used across refactor modes.

Use this snippet with the mode-specific bootstrap key:

```bash
session_dir=$(bash {CWF_PLUGIN_DIR}/scripts/cwf-live-state.sh get . dir 2>/dev/null || true)
if [[ -z "$session_dir" ]]; then
  session_dir=$(bash {CWF_PLUGIN_DIR}/scripts/next-prompt-dir.sh --bootstrap {bootstrap_key})
fi
```

## Bootstrap Keys

| Mode | `{bootstrap_key}` |
|------|-------------------|
| Quick Scan | `refactor-quick-scan` |
| Code Tidying | `refactor-tidy` |
| Codebase Quick Scan | `refactor-codebase` |
| Codebase Deep Review | `refactor-codebase-deep` |
| Deep Review (`--skill`) | `refactor-skill` |
| Holistic Analysis | `refactor-holistic` |
