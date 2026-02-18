#!/usr/bin/env bash
set -euo pipefail

# codebase-quick-scan.sh: Contract-driven structural scan for repository code files.
#
# Usage:
#   codebase-quick-scan.sh [repo-root] [--contract <path>]
#
# Output:
#   JSON report to stdout

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT_DEFAULT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
RESOLVER_SCRIPT="$SCRIPT_DIR/../../../scripts/cwf-artifact-paths.sh"

REPO_ROOT="$REPO_ROOT_DEFAULT"
CONTRACT_PATH=""
REPO_ROOT_ARG_SET="false"

usage() {
  cat <<'USAGE'
codebase-quick-scan.sh — contract-driven codebase scan

Usage:
  codebase-quick-scan.sh [repo-root] [--contract <path>]

Options:
  --contract <path>  Contract path (default: {artifact_root}/codebase-contract.json)
  -h, --help         Show help
USAGE
}

path_to_abs() {
  local base="$1"
  local path_value="$2"
  if [[ "$path_value" == /* ]]; then
    printf '%s\n' "$path_value"
  else
    printf '%s\n' "$base/$path_value"
  fi
}

resolve_artifact_root() {
  local resolved=""
  if [[ ! -f "$RESOLVER_SCRIPT" ]]; then
    return 1
  fi

  if resolved="$(
    bash -c 'source "$1" && resolve_cwf_artifact_root "$2"' _ "$RESOLVER_SCRIPT" "$REPO_ROOT" 2>/dev/null
  )"; then
    if [[ -n "$resolved" ]]; then
      printf '%s\n' "$resolved"
      return 0
    fi
  fi

  return 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --contract)
      CONTRACT_PATH="${2-}"
      if [[ -z "$CONTRACT_PATH" ]]; then
        echo "Error: --contract requires a path value" >&2
        exit 1
      fi
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -*)
      echo "Error: unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
    *)
      if [[ "$REPO_ROOT_ARG_SET" == "true" ]]; then
        echo "Error: repo-root provided more than once" >&2
        usage >&2
        exit 1
      fi
      REPO_ROOT="$(path_to_abs "$PWD" "$1")"
      REPO_ROOT_ARG_SET="true"
      shift
      ;;
  esac
done

if [[ ! -d "$REPO_ROOT" ]]; then
  echo "Error: repo-root not found: $REPO_ROOT" >&2
  exit 1
fi

if [[ -z "$CONTRACT_PATH" ]]; then
  artifact_root="$(resolve_artifact_root 2>/dev/null || true)"
  if [[ -z "$artifact_root" ]]; then
    artifact_root="$REPO_ROOT/.cwf"
  fi
  CONTRACT_PATH="$artifact_root/codebase-contract.json"
else
  CONTRACT_PATH="$(path_to_abs "$PWD" "$CONTRACT_PATH")"
fi

tmp_candidates="$(mktemp "${TMPDIR:-/tmp}/cwf-codebase-scan-candidates.XXXXXX")"
cleanup() {
  rm -f "$tmp_candidates"
}
trap cleanup EXIT

source_mode="find"
if git -C "$REPO_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  if git -C "$REPO_ROOT" ls-files -z > "$tmp_candidates" 2>/dev/null; then
    source_mode="git_ls_files"
  fi
fi

if [[ "$source_mode" == "find" ]]; then
  find "$REPO_ROOT" -type f -print0 > "$tmp_candidates"
fi

python3 - "$REPO_ROOT" "$CONTRACT_PATH" "$source_mode" "$tmp_candidates" <<'PY'
import fnmatch
import json
import os
import re
import sys
from copy import deepcopy

repo_root = os.path.abspath(sys.argv[1])
contract_path = os.path.abspath(sys.argv[2])
source_mode = sys.argv[3]
candidate_path = os.path.abspath(sys.argv[4])
with open(candidate_path, "rb") as f:
    raw_candidates = f.read().split(b"\0")
raw_candidates = [item for item in raw_candidates if item]

defaults = {
    "version": 1,
    "mode": "fallback",
    "source": {"git_tracked_only": True},
    "scope": {
        "include_globs": ["**/*"],
        "exclude_globs": [
            ".git/**",
            ".cwf/**",
            "node_modules/**",
            "dist/**",
            "build/**",
            "coverage/**",
            ".venv/**",
            "venv/**",
            "**/*.md",
            "**/*.mdx",
            "**/*.png",
            "**/*.jpg",
            "**/*.jpeg",
            "**/*.gif",
            "**/*.svg",
            "**/*.pdf",
            "**/*.lock",
            "**/*.snap",
            "**/*.min.js",
            "**/*.min.css",
        ],
        "include_extensions": [
            ".sh",
            ".bash",
            ".zsh",
            ".py",
            ".js",
            ".jsx",
            ".ts",
            ".tsx",
            ".mjs",
            ".cjs",
            ".java",
            ".go",
            ".rs",
            ".rb",
            ".php",
            ".cs",
            ".kt",
            ".swift",
            ".scala",
            ".lua",
            ".sql",
            ".yaml",
            ".yml",
            ".json",
            ".toml",
            ".ini",
            ".cfg",
            ".conf",
            ".xml",
        ],
    },
    "checks": {
        "large_file_lines": {"enabled": True, "warn_at": 400, "error_at": 800},
        "long_line_length": {"enabled": True, "warn_at": 140},
        "todo_markers": {"enabled": True, "patterns": ["TODO", "FIXME", "HACK", "XXX"]},
        "shell_strict_mode": {"enabled": True},
    },
    "reporting": {"top_findings_limit": 30, "include_clean_summary": True},
}


def deep_merge(base, override):
    for key, value in override.items():
        if isinstance(value, dict) and isinstance(base.get(key), dict):
            deep_merge(base[key], value)
        else:
            base[key] = value
    return base


contract = deepcopy(defaults)
contract_status = "fallback"
contract_warning = []

if os.path.isfile(contract_path):
    try:
        with open(contract_path, encoding="utf-8") as f:
            loaded = json.load(f)
        if not isinstance(loaded, dict):
            raise ValueError("contract root must be an object")
        contract = deep_merge(contract, loaded)
        contract_status = "loaded"
    except Exception as exc:
        contract_warning.append(f"invalid contract JSON; fallback defaults used ({exc})")
else:
    contract_warning.append("contract file missing; fallback defaults used")


def as_posix(path_value):
    return path_value.replace("\\", "/")


def rel_from_candidate(raw_item):
    decoded = raw_item.decode("utf-8", errors="replace")
    if source_mode == "git_ls_files":
        rel_path = decoded
    else:
        rel_path = os.path.relpath(os.path.abspath(decoded), repo_root)
    rel_path = as_posix(rel_path).lstrip("./")
    return rel_path


include_globs = [as_posix(p) for p in contract.get("scope", {}).get("include_globs", ["**/*"]) if p]
exclude_globs = [as_posix(p) for p in contract.get("scope", {}).get("exclude_globs", []) if p]
include_extensions = contract.get("scope", {}).get("include_extensions", [])
include_extensions = [ext if ext.startswith(".") else f".{ext}" for ext in include_extensions if isinstance(ext, str) and ext]
include_extension_set = set(include_extensions)

checks = contract.get("checks", {})
large_file_cfg = checks.get("large_file_lines", {})
long_line_cfg = checks.get("long_line_length", {})
todo_cfg = checks.get("todo_markers", {})
shell_cfg = checks.get("shell_strict_mode", {})

todo_patterns = [p for p in todo_cfg.get("patterns", []) if isinstance(p, str) and p]
todo_regex = None
if todo_patterns:
    todo_regex = re.compile(r"(?<!\\w)(?:%s)(?!\\w)" % "|".join(re.escape(p) for p in todo_patterns))

top_limit = int(contract.get("reporting", {}).get("top_findings_limit", 30))
if top_limit <= 0:
    top_limit = 30

errors = []
warnings = []

check_summary = {
    "large_file_lines": {"warnings": 0, "errors": 0},
    "long_line_length": {"warnings": 0},
    "todo_markers": {"warnings": 0},
    "shell_strict_mode": {"warnings": 0},
}

scanned_files = 0
total_lines = 0
excluded_scope = 0
excluded_extension = 0
excluded_binary = 0


def in_scope(rel_path):
    include_hit = any(fnmatch.fnmatch(rel_path, pattern) for pattern in include_globs)
    exclude_hit = any(fnmatch.fnmatch(rel_path, pattern) for pattern in exclude_globs)
    return include_hit and not exclude_hit


def is_shell_candidate(rel_path, first_line):
    if rel_path.endswith((".sh", ".bash", ".zsh")):
        return True
    if first_line.startswith("#!") and ("sh" in first_line or "bash" in first_line or "zsh" in first_line):
        return True
    return False


def has_shell_strict_mode(text):
    has_errexit = re.search(r"^\\s*set\\s+(-[^\\n#]*e\\b|.*-o\\s+errexit\\b)", text, flags=re.MULTILINE) is not None
    has_nounset = re.search(r"^\\s*set\\s+(-[^\\n#]*u\\b|.*-o\\s+nounset\\b)", text, flags=re.MULTILINE) is not None
    has_pipefail = re.search(r"^\\s*set\\s+(-[^\\n#]*o\\s+pipefail\\b|.*-o\\s+pipefail\\b)", text, flags=re.MULTILINE) is not None
    return has_errexit and has_nounset and has_pipefail


for raw_item in raw_candidates:
    rel_path = rel_from_candidate(raw_item)
    if rel_path.startswith("../") or rel_path == "..":
        continue

    if not in_scope(rel_path):
        excluded_scope += 1
        continue

    abs_path = os.path.join(repo_root, rel_path)
    if not os.path.isfile(abs_path):
        continue

    try:
        with open(abs_path, "rb") as bf:
            head = bf.read(4096)
        if b"\0" in head:
            excluded_binary += 1
            continue
        first_line = head.splitlines()[0].decode("utf-8", errors="ignore") if head else ""
    except Exception:
        warnings.append(
            {
                "severity": "warning",
                "check": "file_read",
                "path": rel_path,
                "detail": "unable to read file header; skipped",
            }
        )
        continue

    extension_allowed = any(rel_path.endswith(ext) for ext in include_extension_set)
    shell_candidate = is_shell_candidate(rel_path, first_line)
    if include_extension_set and not extension_allowed and not shell_candidate:
        excluded_extension += 1
        continue

    try:
        with open(abs_path, encoding="utf-8", errors="replace") as f:
            text = f.read()
    except Exception:
        warnings.append(
            {
                "severity": "warning",
                "check": "file_read",
                "path": rel_path,
                "detail": "unable to read file text; skipped",
            }
        )
        continue

    lines = text.splitlines()
    line_count = len(lines)
    total_lines += line_count
    scanned_files += 1

    if large_file_cfg.get("enabled", True):
        warn_at = int(large_file_cfg.get("warn_at", 400))
        error_at = int(large_file_cfg.get("error_at", 800))
        if line_count > error_at:
            errors.append(
                {
                    "severity": "error",
                    "check": "large_file_lines",
                    "path": rel_path,
                    "detail": f"{line_count} lines (error threshold: {error_at})",
                }
            )
            check_summary["large_file_lines"]["errors"] += 1
        elif line_count > warn_at:
            warnings.append(
                {
                    "severity": "warning",
                    "check": "large_file_lines",
                    "path": rel_path,
                    "detail": f"{line_count} lines (warning threshold: {warn_at})",
                }
            )
            check_summary["large_file_lines"]["warnings"] += 1

    if long_line_cfg.get("enabled", True):
        long_warn_at = int(long_line_cfg.get("warn_at", 140))
        long_hits = []
        for idx, line in enumerate(lines, start=1):
            if len(line) > long_warn_at:
                long_hits.append((idx, len(line)))
        if long_hits:
            first_hit = long_hits[0]
            warnings.append(
                {
                    "severity": "warning",
                    "check": "long_line_length",
                    "path": rel_path,
                    "detail": (
                        f"{len(long_hits)} lines exceed {long_warn_at} chars; "
                        f"first at line {first_hit[0]} ({first_hit[1]} chars)"
                    ),
                }
            )
            check_summary["long_line_length"]["warnings"] += 1

    if todo_cfg.get("enabled", True) and todo_regex is not None:
        todo_hits = []
        for idx, line in enumerate(lines, start=1):
            if todo_regex.search(line):
                todo_hits.append(idx)
        if todo_hits:
            warnings.append(
                {
                    "severity": "warning",
                    "check": "todo_markers",
                    "path": rel_path,
                    "detail": f"{len(todo_hits)} markers; first at line {todo_hits[0]}",
                }
            )
            check_summary["todo_markers"]["warnings"] += 1

    if shell_cfg.get("enabled", True) and shell_candidate:
        if not has_shell_strict_mode(text):
            warnings.append(
                {
                    "severity": "warning",
                    "check": "shell_strict_mode",
                    "path": rel_path,
                    "detail": "missing strict mode set (-e, -u, pipefail)",
                }
            )
            check_summary["shell_strict_mode"]["warnings"] += 1

errors.sort(key=lambda item: (item.get("check", ""), item.get("path", "")))
warnings.sort(key=lambda item: (item.get("check", ""), item.get("path", "")))

present_errors = errors[:top_limit]
present_warnings = warnings[:top_limit]

result = {
    "contract": {
        "status": contract_status,
        "path": contract_path,
        "version": contract.get("version"),
    },
    "source": {
        "mode": source_mode,
        "candidate_files": len(raw_candidates),
    },
    "scope": {
        "include_globs": include_globs,
        "exclude_globs": exclude_globs,
        "include_extensions": sorted(include_extension_set),
        "scanned_files": scanned_files,
        "excluded_scope": excluded_scope,
        "excluded_extension": excluded_extension,
        "excluded_binary": excluded_binary,
    },
    "summary": {
        "errors": len(errors),
        "warnings": len(warnings),
        "total_lines": total_lines,
        "checks": check_summary,
    },
    "findings": {
        "errors": present_errors,
        "warnings": present_warnings,
    },
    "omitted_findings": {
        "errors": max(0, len(errors) - len(present_errors)),
        "warnings": max(0, len(warnings) - len(present_warnings)),
    },
}

if contract_warning:
    result["contract"]["warning"] = "; ".join(contract_warning)

print(json.dumps(result, indent=2))
PY
