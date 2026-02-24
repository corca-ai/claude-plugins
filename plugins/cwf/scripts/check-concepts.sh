#!/usr/bin/env bash
set -euo pipefail

# check-concepts.sh — concept governance conformance check.
#
# Verifies that:
# - registry.yaml is structurally usable
# - every active skill and hook entry is bound to >=1 concept or explicitly excluded
# - target docs include required concept reference links from the registry
# - concept-specific checker scripts execute and aggregate pass/warn/fail
#
# Exit codes:
#   0  no failures (warnings allowed unless --strict)
#   1  one or more failures (or warnings with --strict)
#   2  usage/config error

usage() {
  cat <<'USAGE'
check-concepts.sh — concept governance conformance check

Usage:
  check-concepts.sh [--summary] [--strict]

Options:
  --summary   Suppress PASS detail and print compact results.
  --strict    Treat warnings as failures.
  -h, --help  Show this message.
USAGE
}

SUMMARY="false"
STRICT="false"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --summary)
      SUMMARY="true"
      shift
      ;;
    --strict)
      STRICT="true"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$REPO_ROOT"

REGISTRY_PATH="plugins/cwf/concepts/registry.yaml"
HOOKS_PATH="plugins/cwf/hooks/hooks.json"

if [[ ! -f "$REGISTRY_PATH" ]]; then
  echo "[FAIL] missing registry: $REGISTRY_PATH" >&2
  exit 2
fi

if [[ ! -f "$HOOKS_PATH" ]]; then
  echo "[FAIL] missing hooks manifest: $HOOKS_PATH" >&2
  exit 2
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "[FAIL] jq is required" >&2
  exit 2
fi

PASS_COUNT=0
WARN_COUNT=0
FAIL_COUNT=0

report_pass() {
  local msg="$1"
  PASS_COUNT=$((PASS_COUNT + 1))
  if [[ "$SUMMARY" != "true" ]]; then
    echo "[PASS] $msg"
  fi
}

report_warn() {
  local msg="$1"
  WARN_COUNT=$((WARN_COUNT + 1))
  echo "[WARN] $msg"
}

report_fail() {
  local msg="$1"
  FAIL_COUNT=$((FAIL_COUNT + 1))
  echo "[FAIL] $msg"
}

trim() {
  local value="$1"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"
  printf '%s' "$value"
}

strip_quotes() {
  local value
  value="$(trim "$1")"
  if [[ "$value" == \"*\" && "$value" == *\" ]]; then
    value="${value:1:${#value}-2}"
  fi
  printf '%s' "$value"
}

split_csv() {
  local csv="$1"
  local -n out_ref="$2"
  local part=""
  out_ref=()

  if [[ -z "$(trim "$csv")" ]]; then
    return 0
  fi

  IFS=',' read -r -a raw_parts <<< "$csv"
  for part in "${raw_parts[@]}"; do
    part="$(trim "$part")"
    [[ -n "$part" ]] && out_ref+=("$part")
  done
}

declare -A CONCEPT_IDS=()
declare -A CONCEPT_DOC=()
declare -A CONCEPT_CHECKER=()
declare -A CONCEPT_TARGET_DOCS=()
declare -A CONCEPT_REQUIRED_LINKS=()
declare -A SKILL_BINDINGS=()
declare -A HOOK_BINDINGS=()
declare -A SKILL_EXCLUDED=()
declare -A HOOK_EXCLUDED=()

parse_registry() {
  local line=""
  local section=""
  local current_concept=""
  local key=""
  local value=""

  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%$'\r'}"

    if [[ -z "$(trim "$line")" ]]; then
      continue
    fi

    case "$line" in
      version:*)
        continue
        ;;
      concepts:)
        section="concepts"
        current_concept=""
        continue
        ;;
      skill_bindings:)
        section="skill_bindings"
        current_concept=""
        continue
        ;;
      skill_exclusions:*)
        section="skill_exclusions"
        current_concept=""
        continue
        ;;
      hook_bindings:)
        section="hook_bindings"
        current_concept=""
        continue
        ;;
      hook_exclusions:*)
        section="hook_exclusions"
        current_concept=""
        continue
        ;;
    esac

    case "$section" in
      concepts)
        if [[ "$line" =~ ^[[:space:]]{2}([a-z0-9-]+):[[:space:]]*$ ]]; then
          current_concept="${BASH_REMATCH[1]}"
          CONCEPT_IDS["$current_concept"]=1
          continue
        fi

        if [[ -z "$current_concept" ]]; then
          continue
        fi

        if [[ "$line" =~ ^[[:space:]]{4}doc:[[:space:]]*(.+)$ ]]; then
          CONCEPT_DOC["$current_concept"]="$(strip_quotes "${BASH_REMATCH[1]}")"
        elif [[ "$line" =~ ^[[:space:]]{4}checker:[[:space:]]*(.+)$ ]]; then
          CONCEPT_CHECKER["$current_concept"]="$(strip_quotes "${BASH_REMATCH[1]}")"
        elif [[ "$line" =~ ^[[:space:]]{4}target_docs:[[:space:]]*(.+)$ ]]; then
          CONCEPT_TARGET_DOCS["$current_concept"]="$(strip_quotes "${BASH_REMATCH[1]}")"
        elif [[ "$line" =~ ^[[:space:]]{4}required_links:[[:space:]]*(.+)$ ]]; then
          CONCEPT_REQUIRED_LINKS["$current_concept"]="$(strip_quotes "${BASH_REMATCH[1]}")"
        fi
        ;;
      skill_bindings)
        if [[ "$line" =~ ^[[:space:]]{2}\"([^\"]+)\":[[:space:]]*(.*)$ ]]; then
          key="${BASH_REMATCH[1]}"
          value="$(strip_quotes "${BASH_REMATCH[2]}")"
          SKILL_BINDINGS["$key"]="$value"
        elif [[ "$line" =~ ^[[:space:]]{2}([^:\"]+):[[:space:]]*(.*)$ ]]; then
          key="$(trim "${BASH_REMATCH[1]}")"
          value="$(strip_quotes "${BASH_REMATCH[2]}")"
          SKILL_BINDINGS["$key"]="$value"
        fi
        ;;
      hook_bindings)
        if [[ "$line" =~ ^[[:space:]]{2}\"([^\"]+)\":[[:space:]]*(.*)$ ]]; then
          key="${BASH_REMATCH[1]}"
          value="$(strip_quotes "${BASH_REMATCH[2]}")"
          HOOK_BINDINGS["$key"]="$value"
        fi
        ;;
      skill_exclusions)
        if [[ "$line" =~ ^[[:space:]]{2}-[[:space:]]*(.+)$ ]]; then
          key="$(strip_quotes "${BASH_REMATCH[1]}")"
          [[ -n "$key" ]] && SKILL_EXCLUDED["$key"]=1
        fi
        ;;
      hook_exclusions)
        if [[ "$line" =~ ^[[:space:]]{2}-[[:space:]]*(.+)$ ]]; then
          key="$(strip_quotes "${BASH_REMATCH[1]}")"
          [[ -n "$key" ]] && HOOK_EXCLUDED["$key"]=1
        fi
        ;;
    esac
  done < "$REGISTRY_PATH"
}

parse_registry

if [[ "${#CONCEPT_IDS[@]}" -eq 0 ]]; then
  echo "[FAIL] registry has no concepts: $REGISTRY_PATH" >&2
  exit 2
fi

mapfile -t SORTED_CONCEPTS < <(printf '%s\n' "${!CONCEPT_IDS[@]}" | sort)

validate_concept_definitions() {
  local concept_id=""
  local docs_csv=""
  local links_csv=""
  local doc_path=""
  local checker_path=""
  local link_token=""
  local -a target_docs=()
  local -a required_links=()

  for concept_id in "${SORTED_CONCEPTS[@]}"; do
    doc_path="${CONCEPT_DOC[$concept_id]-}"
    checker_path="${CONCEPT_CHECKER[$concept_id]-}"
    docs_csv="${CONCEPT_TARGET_DOCS[$concept_id]-}"
    links_csv="${CONCEPT_REQUIRED_LINKS[$concept_id]-}"

    if [[ -z "$doc_path" ]]; then
      report_fail "concept missing doc path: $concept_id"
    elif [[ ! -f "$doc_path" ]]; then
      report_fail "concept doc not found: $concept_id -> $doc_path"
    else
      report_pass "concept doc exists: $concept_id"
    fi

    if [[ -z "$checker_path" ]]; then
      report_fail "concept missing checker path: $concept_id"
    elif [[ ! -x "$checker_path" ]]; then
      report_fail "concept checker missing or not executable: $concept_id -> $checker_path"
    else
      report_pass "concept checker exists: $concept_id"
    fi

    split_csv "$docs_csv" target_docs
    if [[ "${#target_docs[@]}" -eq 0 ]]; then
      report_fail "concept has no target_docs: $concept_id"
      continue
    fi

    split_csv "$links_csv" required_links
    if [[ "${#required_links[@]}" -eq 0 ]]; then
      report_fail "concept has no required_links: $concept_id"
      continue
    fi

    for doc_path in "${target_docs[@]}"; do
      if [[ ! -f "$doc_path" ]]; then
        report_fail "target doc missing for concept $concept_id: $doc_path"
        continue
      fi

      for link_token in "${required_links[@]}"; do
        if grep -Fq "$link_token" "$doc_path"; then
          report_pass "concept link present: $concept_id -> $doc_path"
        else
          report_fail "missing concept link: concept=$concept_id doc=$doc_path link=$link_token"
        fi
      done
    done
  done
}

validate_binding_concepts() {
  local owner_kind="$1"
  local owner_key="$2"
  local concepts_csv="$3"
  local concept_id=""
  local -a bound_concepts=()

  split_csv "$concepts_csv" bound_concepts

  if [[ "${#bound_concepts[@]}" -eq 0 ]]; then
    report_fail "$owner_kind has empty concept binding: $owner_key"
    return
  fi

  for concept_id in "${bound_concepts[@]}"; do
    if [[ -z "${CONCEPT_IDS[$concept_id]-}" ]]; then
      report_fail "$owner_kind binds unknown concept: $owner_key -> $concept_id"
      return
    fi
  done

  report_pass "$owner_kind bound to concepts: $owner_key"
}

check_skill_coverage() {
  local skill_path=""
  local binding_csv=""
  local -A ACTIVE_SKILLS=()

  mapfile -t ACTIVE_SKILL_LIST < <(find plugins/cwf/skills -mindepth 2 -maxdepth 2 -type f -name 'SKILL.md' | sort)

  for skill_path in "${ACTIVE_SKILL_LIST[@]}"; do
    ACTIVE_SKILLS["$skill_path"]=1

    if [[ -n "${SKILL_BINDINGS[$skill_path]-}" && -n "${SKILL_EXCLUDED[$skill_path]-}" ]]; then
      report_fail "skill has both binding and exclusion: $skill_path"
      continue
    fi

    if [[ -n "${SKILL_EXCLUDED[$skill_path]-}" ]]; then
      report_pass "skill explicitly excluded: $skill_path"
      continue
    fi

    binding_csv="${SKILL_BINDINGS[$skill_path]-}"
    if [[ -z "$(trim "$binding_csv")" ]]; then
      report_fail "active skill missing binding/exclusion: $skill_path"
      continue
    fi

    validate_binding_concepts "skill" "$skill_path" "$binding_csv"
  done

  for skill_path in "${!SKILL_BINDINGS[@]}"; do
    if [[ -z "${ACTIVE_SKILLS[$skill_path]-}" ]]; then
      report_warn "stale skill binding (not active): $skill_path"
    fi
  done

  for skill_path in "${!SKILL_EXCLUDED[@]}"; do
    if [[ -z "${ACTIVE_SKILLS[$skill_path]-}" ]]; then
      report_warn "stale skill exclusion (not active): $skill_path"
    fi
  done
}

check_hook_coverage() {
  local hook_key=""
  local binding_csv=""
  local -A ACTIVE_HOOKS=()

  mapfile -t ACTIVE_HOOK_KEYS < <(
    jq -r '
      .hooks
      | to_entries[]
      | .key as $event
      | .value[]?
      | .matcher as $matcher
      | .hooks[]?
      | .command as $command
      | select($command != null and $command != "")
      | "\($event)@@\($matcher // "")@@\($command)"
    ' "$HOOKS_PATH"
  )

  for hook_key in "${ACTIVE_HOOK_KEYS[@]}"; do
    ACTIVE_HOOKS["$hook_key"]=1

    if [[ -n "${HOOK_BINDINGS[$hook_key]-}" && -n "${HOOK_EXCLUDED[$hook_key]-}" ]]; then
      report_fail "hook has both binding and exclusion: $hook_key"
      continue
    fi

    if [[ -n "${HOOK_EXCLUDED[$hook_key]-}" ]]; then
      report_pass "hook explicitly excluded: $hook_key"
      continue
    fi

    binding_csv="${HOOK_BINDINGS[$hook_key]-}"
    if [[ -z "$(trim "$binding_csv")" ]]; then
      report_fail "active hook missing binding/exclusion: $hook_key"
      continue
    fi

    validate_binding_concepts "hook" "$hook_key" "$binding_csv"
  done

  for hook_key in "${!HOOK_BINDINGS[@]}"; do
    if [[ -z "${ACTIVE_HOOKS[$hook_key]-}" ]]; then
      report_warn "stale hook binding (not active): $hook_key"
    fi
  done

  for hook_key in "${!HOOK_EXCLUDED[@]}"; do
    if [[ -z "${ACTIVE_HOOKS[$hook_key]-}" ]]; then
      report_warn "stale hook exclusion (not active): $hook_key"
    fi
  done
}

run_concept_checkers() {
  local concept_id=""
  local checker_path=""
  local output=""
  local exit_code=0

  for concept_id in "${SORTED_CONCEPTS[@]}"; do
    checker_path="${CONCEPT_CHECKER[$concept_id]-}"
    if [[ -z "$checker_path" || ! -x "$checker_path" ]]; then
      report_fail "cannot run checker for concept: $concept_id"
      continue
    fi

    set +e
    output="$(bash "$checker_path" 2>&1)"
    exit_code=$?
    set -e

    case "$exit_code" in
      0)
        report_pass "concept checker passed: $concept_id"
        if [[ "$SUMMARY" != "true" && -n "$output" ]]; then
          while IFS= read -r line; do
            echo "  $line"
          done <<< "$output"
        fi
        ;;
      10)
        report_warn "concept checker warning: $concept_id"
        if [[ -n "$output" ]]; then
          while IFS= read -r line; do
            echo "  $line"
          done <<< "$output"
        fi
        ;;
      *)
        report_fail "concept checker failed: $concept_id (exit=$exit_code)"
        if [[ -n "$output" ]]; then
          while IFS= read -r line; do
            echo "  $line"
          done <<< "$output"
        fi
        ;;
    esac
  done
}

validate_concept_definitions
check_skill_coverage
check_hook_coverage
run_concept_checkers

echo "Concept governance check"
echo "  pass : $PASS_COUNT"
echo "  warn : $WARN_COUNT"
echo "  fail : $FAIL_COUNT"

if [[ "$FAIL_COUNT" -gt 0 ]]; then
  exit 1
fi

if [[ "$STRICT" == "true" && "$WARN_COUNT" -gt 0 ]]; then
  exit 1
fi

exit 0
