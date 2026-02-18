#!/usr/bin/env bash
set -euo pipefail

# select-codebase-experts.sh: Select mandatory + contextual experts for
# refactor codebase deep review.
#
# Usage:
#   select-codebase-experts.sh --scan <scan-json> [--contract <path>] [--state <path>]
#
# Output:
#   JSON report with fixed/contextual/selected experts.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
RESOLVER_SCRIPT="$SCRIPT_DIR/../../../scripts/cwf-artifact-paths.sh"

SCAN_PATH=""
CONTRACT_PATH=""
STATE_PATH=""

usage() {
  cat <<'USAGE'
select-codebase-experts.sh — select experts for codebase deep review

Usage:
  select-codebase-experts.sh --scan <scan-json> [options]

Options:
  --scan <path>       Codebase scan JSON path (required)
  --contract <path>   Contract path (default: {artifact_root}/codebase-contract.json)
  --state <path>      State file path (default from contract or resolver)
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
    --state)
      STATE_PATH="${2-}"
      [[ -n "$STATE_PATH" ]] || { echo "Error: --state requires a path" >&2; exit 1; }
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

if [[ -z "$STATE_PATH" ]]; then
  if [[ -f "$CONTRACT_PATH" ]]; then
    contract_state_path="$(jq -r '.deep_review.roster_state_file // empty' "$CONTRACT_PATH" 2>/dev/null || true)"
    if [[ -n "$contract_state_path" ]]; then
      STATE_PATH="$(path_to_abs "$REPO_ROOT" "$contract_state_path")"
    fi
  fi
fi

if [[ -z "$STATE_PATH" ]]; then
  if [[ -f "$RESOLVER_SCRIPT" ]]; then
    resolved_state="$(
      bash -c 'source "$1" && resolve_cwf_state_file "$2"' _ "$RESOLVER_SCRIPT" "$REPO_ROOT" 2>/dev/null || true
    )"
    if [[ -n "$resolved_state" ]]; then
      STATE_PATH="$resolved_state"
    fi
  fi
fi

if [[ -z "$STATE_PATH" ]]; then
  STATE_PATH="$REPO_ROOT/.cwf/cwf-state.yaml"
else
  STATE_PATH="$(path_to_abs "$PWD" "$STATE_PATH")"
fi

python3 - "$SCAN_PATH" "$CONTRACT_PATH" "$STATE_PATH" <<'PY'
import json
import os
import re
import sys
from copy import deepcopy

scan_path = os.path.abspath(sys.argv[1])
contract_path = os.path.abspath(sys.argv[2])
state_path = os.path.abspath(sys.argv[3])


def load_json(path):
    if not os.path.isfile(path):
        return None
    try:
        with open(path, encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return None


def parse_yaml_scalar(raw):
    text = raw.strip()
    if text.startswith('"') and text.endswith('"') and len(text) >= 2:
        return text[1:-1]
    if text.startswith("'") and text.endswith("'") and len(text) >= 2:
        return text[1:-1]
    return text


def parse_expert_roster(path):
    if not os.path.isfile(path):
        return []
    experts = []
    current = None
    in_roster = False
    with open(path, encoding="utf-8", errors="replace") as f:
        for line in f:
            stripped = line.strip()

            if not in_roster:
                if stripped == "expert_roster:":
                    in_roster = True
                continue

            if line and line[0] not in (" ", "\t", "-") and stripped:
                break

            name_match = re.match(r'^\s*-\s+name:\s*(.+)\s*$', line)
            if name_match:
                if current and current.get("name"):
                    experts.append(current)
                current = {"name": parse_yaml_scalar(name_match.group(1))}
                continue

            if current is None:
                continue

            field_match = re.match(r'^\s+(domain|source|rationale):\s*(.+)\s*$', line)
            if field_match:
                current[field_match.group(1)] = parse_yaml_scalar(field_match.group(2))
                continue

            verified_match = re.match(r'^\s+verified:\s*(true|false)\s*$', line)
            if verified_match:
                current["verified"] = (verified_match.group(1) == "true")
                continue

            usage_match = re.match(r'^\s+usage_count:\s*(\d+)\s*$', line)
            if usage_match:
                current["usage_count"] = int(usage_match.group(1))
                continue

    if current and current.get("name"):
        experts.append(current)
    return experts


default_contract = {
    "deep_review": {
        "enabled": True,
        "fixed_experts": [
            {
                "name": "Martin Fowler",
                "domain": "refactoring patterns, knowledge duplication (Rule of Three), shared abstractions, evolutionary design",
                "source": "Refactoring: Improving the Design of Existing Code 2nd ed. (2018), Is Design Dead? (martinfowler.com), BeckDesignRules (martinfowler.com/bliki)",
            },
            {
                "name": "Kent Beck",
                "domain": "Tidy First, small safe refactorings, test-driven development, simple design",
                "source": "Tidy First? (2023), Test-Driven Development: By Example (2002), Extreme Programming Explained (2004)",
            },
        ],
        "context_expert_count": 2,
    }
}

scan = load_json(scan_path) or {}
contract_loaded = load_json(contract_path) or {}
contract = deepcopy(default_contract)
for k, v in contract_loaded.items():
    if isinstance(v, dict) and isinstance(contract.get(k), dict):
        contract[k].update(v)
    else:
        contract[k] = v

deep_cfg = contract.get("deep_review", {})
fixed_cfg = deep_cfg.get("fixed_experts", [])
context_count = int(deep_cfg.get("context_expert_count", 2))
if context_count < 0:
    context_count = 0

roster = parse_expert_roster(state_path)
roster_by_name = {entry.get("name"): entry for entry in roster if entry.get("name")}

known_defaults = {
    "Martin Fowler": {
        "domain": "refactoring patterns, knowledge duplication (Rule of Three), shared abstractions, evolutionary design",
        "source": "Refactoring: Improving the Design of Existing Code 2nd ed. (2018), Is Design Dead? (martinfowler.com), BeckDesignRules (martinfowler.com/bliki)",
    },
    "Kent Beck": {
        "domain": "Tidy First, small safe refactorings, test-driven development, simple design",
        "source": "Tidy First? (2023), Test-Driven Development: By Example (2002), Extreme Programming Explained (2004)",
    },
}

warnings = []
fixed = []


def normalize_fixed(item):
    if isinstance(item, dict):
        return {
            "name": item.get("name", "").strip(),
            "domain": item.get("domain", "").strip(),
            "source": item.get("source", "").strip(),
        }
    if isinstance(item, str):
        return {"name": item.strip(), "domain": "", "source": ""}
    return {"name": "", "domain": "", "source": ""}


for raw in fixed_cfg:
    entry = normalize_fixed(raw)
    name = entry.get("name")
    if not name:
        continue
    if any(e.get("name") == name for e in fixed):
        continue

    roster_hit = roster_by_name.get(name)
    if roster_hit:
        entry["domain"] = entry["domain"] or roster_hit.get("domain", "")
        entry["source"] = entry["source"] or roster_hit.get("source", "")
        entry["selection_reason"] = "fixed (from roster or contract)"
        entry["source_type"] = "roster"
    elif name in known_defaults:
        entry["domain"] = entry["domain"] or known_defaults[name]["domain"]
        entry["source"] = entry["source"] or known_defaults[name]["source"]
        entry["selection_reason"] = "fixed (contract default profile)"
        entry["source_type"] = "default-profile"
    else:
        entry["selection_reason"] = "fixed (name only, metadata unavailable)"
        entry["source_type"] = "name-only"
        warnings.append(f"fixed expert metadata not found: {name}")

    fixed.append(entry)

if not fixed:
    warnings.append("no fixed experts resolved from contract/defaults")

checks = (scan.get("summary") or {}).get("checks") or {}


def check_weight(name):
    data = checks.get(name) or {}
    warn = int(data.get("warnings", 0) or 0)
    err = int(data.get("errors", 0) or 0)
    return warn + (err * 4)


weights = {
    "large_file_lines": check_weight("large_file_lines"),
    "long_line_length": check_weight("long_line_length"),
    "todo_markers": check_weight("todo_markers"),
    "shell_strict_mode": check_weight("shell_strict_mode"),
}

keyword_map = {
    "large_file_lines": ["refactor", "modular", "decomposition", "information hiding", "architecture", "design"],
    "long_line_length": ["readability", "refactor", "simple", "design", "maintain"],
    "todo_markers": ["quality", "process", "technical debt", "learning", "maintenance", "improvement"],
    "shell_strict_mode": ["safety", "risk", "reliability", "failure", "resilience", "defense", "hazard"],
}

fixed_names = {entry.get("name") for entry in fixed}
context_candidates = []

for expert in roster:
    name = expert.get("name")
    if not name or name in fixed_names:
        continue
    domain_text = " ".join(
        [
            expert.get("domain", ""),
            expert.get("rationale", ""),
        ]
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
    if score == 0:
        continue
    usage = int(expert.get("usage_count", 0) or 0)
    context_candidates.append(
        {
            "name": name,
            "domain": expert.get("domain", ""),
            "source": expert.get("source", ""),
            "score": score,
            "usage_count": usage,
            "selection_reason": "context match: " + ", ".join(reasons),
            "source_type": "roster",
        }
    )

context_candidates.sort(key=lambda item: (-item["score"], -item["usage_count"], item["name"]))
contextual = context_candidates[:context_count]

if len(contextual) < context_count:
    for expert in roster:
        name = expert.get("name")
        if not name or name in fixed_names or any(e["name"] == name for e in contextual):
            continue
        contextual.append(
            {
                "name": name,
                "domain": expert.get("domain", ""),
                "source": expert.get("source", ""),
                "score": 0,
                "usage_count": int(expert.get("usage_count", 0) or 0),
                "selection_reason": "context fallback: roster fill",
                "source_type": "roster",
            }
        )
        if len(contextual) >= context_count:
            break

if len(contextual) < context_count:
    warnings.append(f"context expert count shortfall: requested={context_count}, resolved={len(contextual)}")

selected = fixed + contextual

result = {
    "deep_review_enabled": bool(deep_cfg.get("enabled", True)),
    "inputs": {
        "scan_path": scan_path,
        "contract_path": contract_path,
        "state_path": state_path,
    },
    "weights": weights,
    "fixed": fixed,
    "contextual": contextual,
    "selected": selected,
    "warnings": warnings,
}

print(json.dumps(result, indent=2))
PY
