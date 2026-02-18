#!/usr/bin/env bash
set -euo pipefail

# select-codebase-experts.sh: Select mandatory + contextual experts for
# refactor codebase deep review.
#
# Usage:
#   select-codebase-experts.sh --scan <scan-json> [--contract <path>]
#
# Output:
#   JSON report with fixed/contextual/selected experts.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
RESOLVER_SCRIPT="$SCRIPT_DIR/../../../scripts/cwf-artifact-paths.sh"

SCAN_PATH=""
CONTRACT_PATH=""

usage() {
  cat <<'USAGE'
select-codebase-experts.sh — select experts for codebase deep review

Usage:
  select-codebase-experts.sh --scan <scan-json> [options]

Options:
  --scan <path>       Codebase scan JSON path (required)
  --contract <path>   Contract path (default: {artifact_root}/codebase-contract.json)
  -h, --help          Show help
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
    --scan)
      SCAN_PATH="${2-}"
      [[ -n "$SCAN_PATH" ]] || { echo "Error: --scan requires a path" >&2; exit 1; }
      shift 2
      ;;
    --contract)
      CONTRACT_PATH="${2-}"
      [[ -n "$CONTRACT_PATH" ]] || { echo "Error: --contract requires a path" >&2; exit 1; }
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Error: unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ -z "$SCAN_PATH" ]]; then
  echo "Error: --scan is required" >&2
  usage >&2
  exit 1
fi

SCAN_PATH="$(path_to_abs "$PWD" "$SCAN_PATH")"
if [[ ! -f "$SCAN_PATH" ]]; then
  echo "Error: scan JSON not found: $SCAN_PATH" >&2
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

python3 - "$SCAN_PATH" "$CONTRACT_PATH" <<'PY'
import json
import os
import sys
from copy import deepcopy

scan_path = os.path.abspath(sys.argv[1])
contract_path = os.path.abspath(sys.argv[2])


def load_json(path):
    if not os.path.isfile(path):
        return None
    try:
        with open(path, encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return None


def norm_expert(raw):
    if isinstance(raw, str):
        return {
            "name": raw.strip(),
            "domain": "",
            "source": "",
            "rationale": "",
            "usage_count": 0,
        }

    if isinstance(raw, dict):
        return {
            "name": str(raw.get("name", "")).strip(),
            "domain": str(raw.get("domain", "")).strip(),
            "source": str(raw.get("source", "")).strip(),
            "rationale": str(raw.get("rationale", "")).strip(),
            "usage_count": int(raw.get("usage_count", 0) or 0),
        }

    return {
        "name": "",
        "domain": "",
        "source": "",
        "rationale": "",
        "usage_count": 0,
    }


def unique_experts(items):
    out = []
    seen = set()
    for raw in items:
        entry = norm_expert(raw)
        name = entry.get("name", "")
        if not name or name in seen:
            continue
        seen.add(name)
        out.append(entry)
    return out


def score_weight(checks, name):
    row = checks.get(name) or {}
    warn = int(row.get("warnings", 0) or 0)
    err = int(row.get("errors", 0) or 0)
    return warn + (err * 4)


def select_keywords(contract_deep):
    default_map = {
        "large_file_lines": ["modular", "decomposition", "architecture", "design"],
        "long_line_length": ["readability", "clarity", "maintainability"],
        "todo_markers": ["technical debt", "process", "improvement"],
        "shell_strict_mode": ["safety", "risk", "reliability", "resilience"],
    }
    override = contract_deep.get("selection_keywords")
    if not isinstance(override, dict):
        return default_map

    merged = deepcopy(default_map)
    for key, value in override.items():
        if isinstance(value, list):
            merged[key] = [str(v).lower() for v in value if str(v).strip()]
    return merged


def enrich_fixed(entry, defaults):
    name = entry.get("name", "")
    if name in defaults:
        if not entry.get("domain"):
            entry["domain"] = defaults[name]["domain"]
        if not entry.get("source"):
            entry["source"] = defaults[name]["source"]
    return entry


def main():
    scan = load_json(scan_path) or {}
    loaded = load_json(contract_path) or {}

    default_contract = {
        "deep_review": {
            "enabled": True,
            "fixed_experts": [
                {
                    "name": "Martin Fowler",
                    "domain": "refactoring patterns, duplication reduction, shared abstractions",
                    "source": "Refactoring (2nd ed., 2018)",
                },
                {
                    "name": "Kent Beck",
                    "domain": "small safe refactorings, TDD, simple design",
                    "source": "Tidy First? (2023)",
                },
            ],
            "context_experts": [
                {
                    "name": "Nancy Leveson",
                    "domain": "systems safety engineering, control-structure analysis",
                    "source": "Engineering a Safer World (2011)",
                },
                {
                    "name": "Donella Meadows",
                    "domain": "systems thinking, leverage points, feedback loops",
                    "source": "Thinking in Systems (2008)",
                },
                {
                    "name": "David Parnas",
                    "domain": "information hiding, modular decomposition",
                    "source": "CACM 1972 paper on modular decomposition",
                },
                {
                    "name": "John Ousterhout",
                    "domain": "deep modules, strategic programming",
                    "source": "A Philosophy of Software Design (2018)",
                },
            ],
            "context_expert_count": 2,
        }
    }

    contract = deepcopy(default_contract)
    for key, value in loaded.items():
        if isinstance(value, dict) and isinstance(contract.get(key), dict):
            contract[key].update(value)
        else:
            contract[key] = value

    deep_cfg = contract.get("deep_review", {})
    warnings = []

    fixed_defaults = {
        "Martin Fowler": {
            "domain": "refactoring patterns, duplication reduction, shared abstractions",
            "source": "Refactoring (2nd ed., 2018)",
        },
        "Kent Beck": {
            "domain": "small safe refactorings, TDD, simple design",
            "source": "Tidy First? (2023)",
        },
    }

    fixed = []
    for item in unique_experts(deep_cfg.get("fixed_experts", [])):
        entry = enrich_fixed(item, fixed_defaults)
        if entry.get("name") in fixed_defaults:
            entry["selection_reason"] = "fixed (contract/default profile)"
            entry["source_type"] = "fixed"
        else:
            entry["selection_reason"] = "fixed (contract)"
            entry["source_type"] = "fixed"
        fixed.append(entry)

    if not fixed:
        warnings.append("no fixed experts resolved from contract/defaults")

    context_pool = unique_experts(deep_cfg.get("context_experts", []))
    if not context_pool:
        warnings.append("no context experts in contract; using built-in defaults")
        context_pool = unique_experts(default_contract["deep_review"]["context_experts"])

    checks = (scan.get("summary") or {}).get("checks") or {}
    weights = {
        "large_file_lines": score_weight(checks, "large_file_lines"),
        "long_line_length": score_weight(checks, "long_line_length"),
        "todo_markers": score_weight(checks, "todo_markers"),
        "shell_strict_mode": score_weight(checks, "shell_strict_mode"),
    }

    keyword_map = select_keywords(deep_cfg)
    fixed_names = {entry.get("name") for entry in fixed}

    candidates = []
    for expert in context_pool:
        name = expert.get("name")
        if not name or name in fixed_names:
            continue

        domain_text = " ".join(
            [expert.get("domain", ""), expert.get("rationale", ""), expert.get("source", "")]
        ).lower()

        score = 0
        reasons = []
        for check_name, kws in keyword_map.items():
            w = weights.get(check_name, 0)
            if w <= 0:
                continue
            if any(kw in domain_text for kw in kws):
                score += w
                reasons.append(f"{check_name}(w={w})")

        reason = "context match: " + ", ".join(reasons) if reasons else "context fallback candidate"
        candidates.append(
            {
                "name": name,
                "domain": expert.get("domain", ""),
                "source": expert.get("source", ""),
                "usage_count": int(expert.get("usage_count", 0) or 0),
                "score": score,
                "selection_reason": reason,
                "source_type": "contract",
            }
        )

    candidates.sort(key=lambda row: (-row["score"], -row["usage_count"], row["name"]))

    context_count = int(deep_cfg.get("context_expert_count", 2) or 0)
    if context_count < 0:
        context_count = 0

    contextual = [row for row in candidates if row.get("score", 0) > 0][:context_count]

    if len(contextual) < context_count:
        for row in candidates:
            if row["name"] in {e["name"] for e in contextual}:
                continue
            fallback = dict(row)
            fallback["selection_reason"] = "context fallback: contract fill order"
            contextual.append(fallback)
            if len(contextual) >= context_count:
                break

    if len(contextual) < context_count:
        warnings.append(
            f"context expert count shortfall: requested={context_count}, resolved={len(contextual)}"
        )

    selected = fixed + contextual

    result = {
        "deep_review_enabled": bool(deep_cfg.get("enabled", True)),
        "inputs": {
            "scan_path": scan_path,
            "contract_path": contract_path,
        },
        "weights": weights,
        "fixed": fixed,
        "contextual": contextual,
        "selected": selected,
        "warnings": warnings,
    }

    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
PY
