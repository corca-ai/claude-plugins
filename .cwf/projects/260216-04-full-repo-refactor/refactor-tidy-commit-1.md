# Tidying Analysis: Commit 226cdd1

> `chore(cwf): enforce script placeholder style via drift gate`

## Commit Summary

This commit adds a new drift-gate check (`check_runtime_placeholder_style`) to
`check-growth-drift.sh` that detects legacy `{SKILL_DIR}/../../scripts/`
placeholders, and removes the now-redundant documentation section from
`skill-conventions.md` (the convention is now enforced at runtime rather than
stated in prose).

**Files changed:**

| File | Change |
|------|--------|
| `plugins/cwf/scripts/check-growth-drift.sh` | +31 lines (new function + call site + header comment) |
| `plugins/cwf/references/skill-conventions.md` | -8 lines (removed prose section) |

**Status at HEAD:** Both files are unchanged since this commit (no subsequent modifications). All line references below reflect the current state.

---

## Tidying Opportunities

### 1. Extract helper: resolve_to_absolute (repeated pattern)

`plugins/cwf/scripts/check-growth-drift.sh:345-348,389-393,405-409,416-420` -- Extract the "resolve relative-or-absolute path" idiom into a small helper function. (reason: the same 4-line if/else block appears four times in `check_live_state_pointers`; a helper eliminates repetition and makes the intent self-documenting)

**Before** (repeated four times with different variable names):

```bash
    if [[ "$state_pointer_raw" == /* ]]; then
      state_pointer_path="$state_pointer_raw"
    else
      state_pointer_path="$REPO_ROOT/$state_pointer_raw"
    fi
```

```bash
    if [[ "$dir_raw" == /* ]]; then
      dir_path="$dir_raw"
    else
      dir_path="$REPO_ROOT/$dir_raw"
    fi
```

```bash
    if [[ "$hitl_state_raw" == /* ]]; then
      dir_path="$hitl_state_raw"
    else
      dir_path="$REPO_ROOT/$hitl_state_raw"
    fi
```

```bash
    if [[ "$hitl_rules_raw" == /* ]]; then
      dir_path="$hitl_rules_raw"
    else
      dir_path="$REPO_ROOT/$hitl_rules_raw"
    fi
```

**After** (define once near the other utility functions around line 88-106):

```bash
resolve_path() {
  local raw="$1"
  if [[ "$raw" == /* ]]; then
    printf '%s' "$raw"
  else
    printf '%s' "$REPO_ROOT/$raw"
  fi
}
```

Each call site becomes a single line, e.g.:

```bash
    state_pointer_path="$(resolve_path "$state_pointer_raw")"
```

```bash
    dir_path="$(resolve_path "$dir_raw")"
```

```bash
    dir_path="$(resolve_path "$hitl_state_raw")"
```

```bash
    dir_path="$(resolve_path "$hitl_rules_raw")"
```

This is purely mechanical -- the logic and runtime behavior are identical.

---

### 2. Explaining variable: rename reused `dir_path` in hitl checks

`plugins/cwf/scripts/check-growth-drift.sh:404-424` -- Rename the reused `dir_path` variable in the hitl validation blocks to `hitl_state_path` and `hitl_rules_path` respectively. (reason: `dir_path` is semantically tied to `live.dir` at line 390; reusing it for `hitl.state_file` and `hitl.rules_file` is misleading and masks intent; renaming is a safe no-op since the variable is local and not read after the final use)

**Before:**

```bash
  if [[ -n "$hitl_state_raw" ]]; then
    if [[ "$hitl_state_raw" == /* ]]; then
      dir_path="$hitl_state_raw"
    else
      dir_path="$REPO_ROOT/$hitl_state_raw"
    fi
    if [[ ! -f "$dir_path" ]]; then
      record_fail "$category" "live.hitl.state_file missing: $hitl_state_raw"
    fi
  fi

  if [[ -n "$hitl_rules_raw" ]]; then
    if [[ "$hitl_rules_raw" == /* ]]; then
      dir_path="$hitl_rules_raw"
    else
      dir_path="$REPO_ROOT/$hitl_rules_raw"
    fi
    if [[ ! -f "$dir_path" ]]; then
      record_fail "$category" "live.hitl.rules_file missing: $hitl_rules_raw"
    fi
  fi
```

**After:**

```bash
  if [[ -n "$hitl_state_raw" ]]; then
    local hitl_state_path
    hitl_state_path="$(resolve_path "$hitl_state_raw")"
    if [[ ! -f "$hitl_state_path" ]]; then
      record_fail "$category" "live.hitl.state_file missing: $hitl_state_raw"
    fi
  fi

  if [[ -n "$hitl_rules_raw" ]]; then
    local hitl_rules_path
    hitl_rules_path="$(resolve_path "$hitl_rules_raw")"
    if [[ ! -f "$hitl_rules_path" ]]; then
      record_fail "$category" "live.hitl.rules_file missing: $hitl_rules_raw"
    fi
  fi
```

(This pairs naturally with opportunity #1. If applied independently, substitute the resolve_path call with the original if/else block using the new variable name.)

Also remove the now-unused `local dir_path=""` and `local p=""` declarations at lines 303 and 312 respectively -- `dir_path` would be replaced by scoped locals, and `p` is already the loop variable at line 373 which creates its own scope.

**Note on `local p=""`:** The variable `p` declared at line 312 is only used as the iterator in the `for p in ...` loop at line 373. In bash, `for` loop variables do not require pre-declaration; removing this line is safe dead-code removal.

---

### 3. Guard clause: early return in `check_runtime_placeholder_style`

`plugins/cwf/scripts/check-growth-drift.sh:476-489` -- Invert the `if [[ -s "$hits_file" ]]` condition to use an early-return guard clause for the happy path, reducing one level of nesting. (reason: the function currently nests the failure loop inside `if -s`; flipping to `if ! -s` for the pass case and returning early follows the guard-clause pattern used by all other check functions in this script, e.g. lines 171-179, 229-240, 314-321)

**Before:**

```bash
  if [[ -s "$hits_file" ]]; then
    while IFS= read -r hit; do
      [[ -n "$hit" ]] || continue
      record_fail "$category" "Forbidden placeholder found: $hit"
      hit_count=$((hit_count + 1))
      if [[ "$hit_count" -ge 5 ]]; then
        record_fail "$category" "More matches omitted after first 5; replace with {CWF_PLUGIN_DIR}/scripts/..."
        break
      fi
    done < "$hits_file"
    return
  fi

  record_pass "$category" "No legacy {SKILL_DIR}/../../scripts placeholders in skills/references"
```

**After:**

```bash
  if [[ ! -s "$hits_file" ]]; then
    record_pass "$category" "No legacy {SKILL_DIR}/../../scripts placeholders in skills/references"
    return
  fi

  while IFS= read -r hit; do
    [[ -n "$hit" ]] || continue
    record_fail "$category" "Forbidden placeholder found: $hit"
    hit_count=$((hit_count + 1))
    if [[ "$hit_count" -ge 5 ]]; then
      record_fail "$category" "More matches omitted after first 5; replace with {CWF_PLUGIN_DIR}/scripts/..."
      break
    fi
  done < "$hits_file"
```

This moves the pass case up front (matching the guard-clause style of other checks) and de-nests the while loop by one level. No behavioral change.

---

## Summary

| # | Technique | File | Lines | Risk |
|---|-----------|------|-------|------|
| 1 | Extract helper | `check-growth-drift.sh` | 345-420 | None -- pure mechanical extraction |
| 2 | Explaining variable + dead code | `check-growth-drift.sh` | 303, 312, 404-424 | None -- local scope rename + unused declaration removal |
| 3 | Guard clause | `check-growth-drift.sh` | 476-489 | None -- control-flow inversion, identical behavior |

All three suggestions are independent and can be applied in any order as separate commits. The markdown file (`skill-conventions.md`) has no tidying opportunities -- the removal was clean and left no orphaned references or formatting issues.

<!-- AGENT_COMPLETE -->
