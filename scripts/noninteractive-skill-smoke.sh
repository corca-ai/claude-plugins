#!/usr/bin/env bash
set -euo pipefail

# noninteractive-skill-smoke.sh — run non-interactive Claude skill smoke checks with timeout.
#
# Usage:
#   noninteractive-skill-smoke.sh [options]
#
# Exit codes:
#   0 = gate passed within configured failure/timeout thresholds
#   1 = gate failed or usage/dependency error

usage() {
  cat <<'USAGE'
noninteractive-skill-smoke.sh — run non-interactive CWF skill smoke checks

Usage:
  noninteractive-skill-smoke.sh [options]

Options:
  --plugin-dir <path>      Plugin directory passed to Claude (default: plugins/cwf)
  --workdir <path>         Working directory where prompts are executed (default: current directory)
  --timeout <seconds>      Per-case timeout in seconds (default: 45)
  --output-dir <path>      Output directory for logs/summaries (default: .cwf/smoke-<timestamp>)
  --cases-file <path>      Case definition file (format: id|prompt). If omitted, built-in cases are used.
  --max-failures <n>       Allowed FAIL count before gate failure (default: 0)
  --max-timeouts <n>       Allowed TIMEOUT count before gate failure (default: 0)
  --claude-bin <path>      Claude CLI executable (default: CLAUDE_BIN env or "claude")
  -h, --help               Show this message

Case file format:
  - One case per line: <id>|<prompt>
  - Empty lines and '#' comments are ignored.

Summary fields:
  - result: PASS|FAIL|TIMEOUT
  - reason: OK|ERROR|TIMEOUT|WAIT_INPUT|NO_OUTPUT
USAGE
}

PLUGIN_DIR="plugins/cwf"
WORKDIR="$(pwd)"
TIMEOUT_SEC=45
OUTPUT_DIR=""
CASES_FILE=""
MAX_FAILURES=0
MAX_TIMEOUTS=0
CLAUDE_BIN="${CLAUDE_BIN:-claude}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --plugin-dir)
      if [[ -z "${2:-}" ]]; then
        echo "Error: --plugin-dir requires a value." >&2
        exit 1
      fi
      PLUGIN_DIR="$2"
      shift 2
      ;;
    --workdir)
      if [[ -z "${2:-}" ]]; then
        echo "Error: --workdir requires a value." >&2
        exit 1
      fi
      WORKDIR="$2"
      shift 2
      ;;
    --timeout)
      if [[ -z "${2:-}" ]] || [[ ! "$2" =~ ^[0-9]+$ ]] || [[ "$2" -le 0 ]]; then
        echo "Error: --timeout expects a positive integer." >&2
        exit 1
      fi
      TIMEOUT_SEC="$2"
      shift 2
      ;;
    --output-dir)
      if [[ -z "${2:-}" ]]; then
        echo "Error: --output-dir requires a value." >&2
        exit 1
      fi
      OUTPUT_DIR="$2"
      shift 2
      ;;
    --cases-file)
      if [[ -z "${2:-}" ]]; then
        echo "Error: --cases-file requires a value." >&2
        exit 1
      fi
      CASES_FILE="$2"
      shift 2
      ;;
    --max-failures)
      if [[ -z "${2:-}" ]] || [[ ! "$2" =~ ^[0-9]+$ ]]; then
        echo "Error: --max-failures expects a non-negative integer." >&2
        exit 1
      fi
      MAX_FAILURES="$2"
      shift 2
      ;;
    --max-timeouts)
      if [[ -z "${2:-}" ]] || [[ ! "$2" =~ ^[0-9]+$ ]]; then
        echo "Error: --max-timeouts expects a non-negative integer." >&2
        exit 1
      fi
      MAX_TIMEOUTS="$2"
      shift 2
      ;;
    --claude-bin)
      if [[ -z "${2:-}" ]]; then
        echo "Error: --claude-bin requires a value." >&2
        exit 1
      fi
      CLAUDE_BIN="$2"
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

if [[ ! -d "$WORKDIR" ]]; then
  echo "Error: workdir does not exist: $WORKDIR" >&2
  exit 1
fi

if [[ ! -d "$PLUGIN_DIR" ]]; then
  echo "Error: plugin-dir does not exist: $PLUGIN_DIR" >&2
  exit 1
fi
PLUGIN_DIR="$(cd "$PLUGIN_DIR" && pwd)"

if [[ -n "$CASES_FILE" ]] && [[ ! -f "$CASES_FILE" ]]; then
  echo "Error: cases file does not exist: $CASES_FILE" >&2
  exit 1
fi

if [[ "$CLAUDE_BIN" == */* ]]; then
  if [[ ! -x "$CLAUDE_BIN" ]]; then
    echo "Error: claude executable not found: $CLAUDE_BIN" >&2
    exit 1
  fi
else
  if ! command -v "$CLAUDE_BIN" >/dev/null 2>&1; then
    echo "Error: claude executable not found in PATH: $CLAUDE_BIN" >&2
    exit 1
  fi
fi

if [[ -z "$OUTPUT_DIR" ]]; then
  TS="$(date +%y%m%d-%H%M%S)"
  OUTPUT_DIR=".cwf/smoke-$TS"
fi

mkdir -p "$OUTPUT_DIR"

SUMMARY_FILE="$OUTPUT_DIR/summary.tsv"
printf "id\tresult\treason\texit_code\tduration_sec\tlog_file\n" > "$SUMMARY_FILE"

declare -a CASE_IDS=()
declare -a CASE_PROMPTS=()

add_case() {
  local case_id="$1"
  local prompt="$2"
  CASE_IDS+=("$case_id")
  CASE_PROMPTS+=("$prompt")
}

load_default_cases() {
  add_case "setup-env" "cwf:setup --env"
  add_case "setup-git-hooks" "cwf:setup --git-hooks both --gate-profile balanced"
  add_case "gather" "cwf:gather docs/plugin-dev-cheatsheet.md"
  add_case "clarify" "cwf:clarify --light smoke test only"
  add_case "plan" "cwf:plan create a minimal smoke plan"
  add_case "review" "/review --mode plan project/iter1/improvement-plan.md"
  add_case "impl" "cwf:impl run smoke implementation only"
  add_case "refactor" "cwf:refactor --mode quick"
  add_case "retro" "cwf:retro --light"
  add_case "handoff" "cwf:handoff"
  add_case "ship" "/ship --help"
  add_case "update" "cwf:update"
  add_case "run" "cwf:run"
  add_case "hitl" "cwf:hitl"
}

load_cases_from_file() {
  local line
  local line_no=0
  local case_id
  local prompt

  while IFS= read -r line || [[ -n "$line" ]]; do
    line_no=$((line_no + 1))

    if [[ -z "$line" ]]; then
      continue
    fi
    if [[ "$line" =~ ^[[:space:]]*# ]]; then
      continue
    fi

    case_id="${line%%|*}"
    prompt="${line#*|}"

    if [[ "$case_id" == "$line" ]] || [[ -z "$case_id" ]] || [[ -z "$prompt" ]]; then
      echo "Error: invalid case format at $CASES_FILE:$line_no (expected id|prompt)." >&2
      exit 1
    fi

    add_case "$case_id" "$prompt"
  done < "$CASES_FILE"
}

if [[ -n "$CASES_FILE" ]]; then
  load_cases_from_file
else
  load_default_cases
fi

if [[ "${#CASE_IDS[@]}" -eq 0 ]]; then
  echo "Error: no smoke cases configured." >&2
  exit 1
fi

PASS_COUNT=0
FAIL_COUNT=0
TIMEOUT_COUNT=0
WAIT_INPUT_COUNT=0

is_wait_input_log() {
  local log_file="$1"
  grep -Eiq \
    'waiting for your selection|wait for your answer|select one of the options|질문이 표시|선택해 주세요|what task would you like|what task should .* pipeline execute|what would you like .* to work on|please describe the task|please provide your task description|which option would you like|which file should i review|choose one of the following|what did you have in mind|which would you like|would you like me to|would you like to provide|could you confirm|please confirm|please reply with your choice|any learnings from the setup process|should i create the project config templates|save this clarified requirement to a file|let me know,? or i can proceed' \
    "$log_file"
}

run_case() {
  local case_index="$1"
  local case_id="$2"
  local prompt="$3"
  local safe_id
  local log_file
  local marker_file
  local start_ts
  local end_ts
  local duration
  local exit_code
  local result
  local reason
  local case_pid
  local watcher_pid

  safe_id="$(echo "$case_id" | tr -cs 'A-Za-z0-9._-' '_')"
  log_file="$OUTPUT_DIR/$case_index-$safe_id.log"
  marker_file="$OUTPUT_DIR/.timeout-$case_index-$safe_id.marker"

  start_ts="$(date +%s)"

  set +e
  (
    cd "$WORKDIR" && "$CLAUDE_BIN" --print "$prompt" --dangerously-skip-permissions --plugin-dir "$PLUGIN_DIR"
  ) >"$log_file" 2>&1 &
  case_pid=$!

  (
    sleep "$TIMEOUT_SEC"
    if kill -0 "$case_pid" >/dev/null 2>&1; then
      echo "timeout" > "$marker_file"
      kill "$case_pid" >/dev/null 2>&1 || true
      sleep 1
      kill -9 "$case_pid" >/dev/null 2>&1 || true
    fi
  ) &
  watcher_pid=$!

  wait "$case_pid"
  exit_code=$?

  kill "$watcher_pid" >/dev/null 2>&1 || true
  wait "$watcher_pid" >/dev/null 2>&1 || true
  set -e

  end_ts="$(date +%s)"
  duration=$((end_ts - start_ts))

  reason=""

  if [[ -f "$marker_file" ]]; then
    rm -f "$marker_file" >/dev/null 2>&1 || true
    result="TIMEOUT"
    reason="TIMEOUT"
    TIMEOUT_COUNT=$((TIMEOUT_COUNT + 1))
    exit_code=124
    if is_wait_input_log "$log_file"; then
      reason="WAIT_INPUT"
      WAIT_INPUT_COUNT=$((WAIT_INPUT_COUNT + 1))
    fi
  elif [[ "$exit_code" -eq 0 ]]; then
    if is_wait_input_log "$log_file"; then
      result="FAIL"
      reason="WAIT_INPUT"
      FAIL_COUNT=$((FAIL_COUNT + 1))
      WAIT_INPUT_COUNT=$((WAIT_INPUT_COUNT + 1))
    elif [[ ! -s "$log_file" ]] || [[ "$(wc -c < "$log_file")" -le 1 ]]; then
      result="FAIL"
      reason="NO_OUTPUT"
      FAIL_COUNT=$((FAIL_COUNT + 1))
    else
      result="PASS"
      reason="OK"
      PASS_COUNT=$((PASS_COUNT + 1))
    fi
  else
    result="FAIL"
    if is_wait_input_log "$log_file"; then
      reason="WAIT_INPUT"
      WAIT_INPUT_COUNT=$((WAIT_INPUT_COUNT + 1))
    else
      reason="ERROR"
    fi
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi

  printf "%s\t%s\t%s\t%s\t%s\t%s\n" "$case_id" "$result" "$reason" "$exit_code" "$duration" "$log_file" >> "$SUMMARY_FILE"
  printf "[%s] id=%s reason=%s exit=%s duration=%ss log=%s\n" "$result" "$case_id" "$reason" "$exit_code" "$duration" "$log_file"
}

echo "Smoke output dir: $OUTPUT_DIR"
echo "Smoke workdir: $WORKDIR"
echo "Smoke plugin-dir: $PLUGIN_DIR"
echo "Smoke timeout: ${TIMEOUT_SEC}s"
echo "Smoke cases: ${#CASE_IDS[@]}"
echo "---"

for i in "${!CASE_IDS[@]}"; do
  index=$((i + 1))
  run_case "$index" "${CASE_IDS[$i]}" "${CASE_PROMPTS[$i]}"
done

echo "---"
echo "Totals: pass=$PASS_COUNT fail=$FAIL_COUNT timeout=$TIMEOUT_COUNT wait_input=$WAIT_INPUT_COUNT"
echo "Thresholds: max_failures=$MAX_FAILURES max_timeouts=$MAX_TIMEOUTS"
echo "Summary: $SUMMARY_FILE"

if [[ "$FAIL_COUNT" -gt "$MAX_FAILURES" ]] || [[ "$TIMEOUT_COUNT" -gt "$MAX_TIMEOUTS" ]]; then
  echo "Gate result: FAIL"
  exit 1
fi

echo "Gate result: PASS"
exit 0
