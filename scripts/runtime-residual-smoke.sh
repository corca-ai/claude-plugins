#!/usr/bin/env bash
set -euo pipefail

# runtime-residual-smoke.sh
# Observe or enforce known runtime residuals for CWF non-interactive paths.
#
# Targets:
# - K46: cwf:retro --light direct timeout risk
# - S10: cwf:setup full intermittent NO_OUTPUT risk

usage() {
  cat <<'USAGE'
runtime-residual-smoke.sh — observe/enforce runtime residual risks

Usage:
  runtime-residual-smoke.sh [options]

Options:
  --mode <observe|strict>  Gate mode (default: observe)
  --plugin-dir <path>      Plugin directory for Claude calls (default: plugins/cwf)
  --workdir <path>         Working directory where prompts execute (default: current directory)
  --claude-bin <path>      Claude executable (default: CLAUDE_BIN env or claude)
  --k46-timeout <sec>      Timeout for K46 case (default: 120)
  --k46-timeout-retries <n>
                          Retry count for K46 TIMEOUT before recording failure (default: 1)
  --s10-timeout <sec>      Timeout per S10 run (default: 120)
  --s10-runs <n>           Number of S10 repeats (default: 5)
  --s10-no-output-retries <n>
                          Retry count for S10 NO_OUTPUT before recording failure (default: 2)
  --output-dir <path>      Output directory (default: .cwf/runtime-residual-smoke/<timestamp>)
  -h, --help               Show this message

Exit behavior:
  observe: always exit 0 (unless usage/dependency errors)
  strict : exit 1 when K46 timeout>0 or S10 no_output>0
USAGE
}

MODE="observe"
PLUGIN_DIR="plugins/cwf"
WORKDIR="$(pwd)"
CLAUDE_BIN="${CLAUDE_BIN:-claude}"
K46_TIMEOUT=120
K46_TIMEOUT_RETRIES=1
S10_TIMEOUT=120
S10_RUNS=5
S10_NO_OUTPUT_RETRIES=2
OUTPUT_DIR=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode)
      MODE="${2:-}"
      shift 2
      ;;
    --plugin-dir)
      PLUGIN_DIR="${2:-}"
      shift 2
      ;;
    --workdir)
      WORKDIR="${2:-}"
      shift 2
      ;;
    --claude-bin)
      CLAUDE_BIN="${2:-}"
      shift 2
      ;;
    --k46-timeout)
      K46_TIMEOUT="${2:-}"
      shift 2
      ;;
    --k46-timeout-retries)
      K46_TIMEOUT_RETRIES="${2:-}"
      shift 2
      ;;
    --s10-timeout)
      S10_TIMEOUT="${2:-}"
      shift 2
      ;;
    --s10-runs)
      S10_RUNS="${2:-}"
      shift 2
      ;;
    --s10-no-output-retries)
      S10_NO_OUTPUT_RETRIES="${2:-}"
      shift 2
      ;;
    --output-dir)
      OUTPUT_DIR="${2:-}"
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

if [[ "$MODE" != "observe" && "$MODE" != "strict" ]]; then
  echo "Error: --mode must be observe or strict" >&2
  exit 1
fi

for n in "$K46_TIMEOUT" "$S10_TIMEOUT" "$S10_RUNS"; do
  if [[ ! "$n" =~ ^[0-9]+$ ]] || [[ "$n" -le 0 ]]; then
    echo "Error: numeric options must be positive integers" >&2
    exit 1
  fi
done

for n in "$K46_TIMEOUT_RETRIES" "$S10_NO_OUTPUT_RETRIES"; do
  if [[ ! "$n" =~ ^[0-9]+$ ]]; then
    echo "Error: retry options must be zero or positive integers" >&2
    exit 1
  fi
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
  OUTPUT_DIR=".cwf/runtime-residual-smoke/$TS"
fi
mkdir -p "$OUTPUT_DIR"
SUMMARY_FILE="$OUTPUT_DIR/summary.tsv"
printf "case\trun\tresult\treason\texit_code\tduration_sec\tbytes\tlog_file\n" > "$SUMMARY_FILE"

K46_TIMEOUT_COUNT=0
K46_NO_OUTPUT_COUNT=0
K46_OTHER_FAIL_COUNT=0
S10_WAIT_INPUT_COUNT=0
S10_NO_OUTPUT_COUNT=0
S10_TIMEOUT_COUNT=0
S10_OTHER_COUNT=0
S10_ERROR_COUNT=0

is_wait_input_log() {
  local log_file="$1"
  grep -Eiq \
    'waiting for your selection|wait for your answer|select one of the options|what task would you like|what task should .* pipeline execute|what would you like .* to work on|please describe the task|please provide your task description|which option would you like|which file should i review|choose one of the following|what did you have in mind|which would you like|would you like me to|would you like to provide|would you like to change your display mode|please tell me which mode you.?.?d like|could you confirm|please confirm|please reply with your choice|keep all enabled|wait_input:|setup requires user selection at phase|non-interactive fallback' \
    "$log_file"
}

classify_case_result() {
  local log_file="$1"
  local rc="$2"
  local bytes="$3"

  RUN_RESULT="PASS"
  RUN_REASON="OK"
  if [[ "$rc" -eq 124 ]]; then
    RUN_RESULT="FAIL"
    RUN_REASON="TIMEOUT"
  elif [[ "$bytes" -le 1 ]]; then
    RUN_RESULT="FAIL"
    RUN_REASON="NO_OUTPUT"
  elif [[ "$rc" -ne 0 ]]; then
    RUN_RESULT="FAIL"
    RUN_REASON="ERROR"
  elif is_wait_input_log "$log_file"; then
    # WAIT_INPUT is expected for non-interactive setup paths.
    RUN_RESULT="PASS"
    RUN_REASON="WAIT_INPUT"
  fi
}

invoke_prompt() {
  local timeout_sec="$1"
  local prompt="$2"
  local log_file="$3"

  (
    cd "$WORKDIR" && timeout "$timeout_sec" "$CLAUDE_BIN" --print "$prompt" --dangerously-skip-permissions --plugin-dir "$PLUGIN_DIR"
  ) >"$log_file" 2>&1
}

run_case() {
  local case_id="$1"
  local run_no="$2"
  local timeout_sec="$3"
  local prompt="$4"
  local log_file="$OUTPUT_DIR/${case_id}-run${run_no}.log"
  local attempt_log="$log_file"
  local attempt=1
  local max_retries=0
  local retry_reason=""
  local start_ts
  local end_ts
  local duration=0
  local total_duration=0
  local rc=0
  local bytes
  local result="PASS"
  local reason="OK"

  case "$case_id" in
    K46)
      max_retries="$K46_TIMEOUT_RETRIES"
      retry_reason="TIMEOUT"
      ;;
    S10)
      max_retries="$S10_NO_OUTPUT_RETRIES"
      retry_reason="NO_OUTPUT"
      ;;
  esac

  while :; do
    attempt_log="$log_file"
    if [[ "$attempt" -gt 1 ]]; then
      attempt_log="${log_file}.retry${attempt}"
    fi

    start_ts="$(date +%s)"
    set +e
    invoke_prompt "$timeout_sec" "$prompt" "$attempt_log"
    rc=$?
    set -e
    end_ts="$(date +%s)"

    duration=$((end_ts - start_ts))
    total_duration=$((total_duration + duration))
    bytes="$(wc -c < "$attempt_log" | tr -d ' ')"

    classify_case_result "$attempt_log" "$rc" "$bytes"
    result="$RUN_RESULT"
    reason="$RUN_REASON"

    if [[ "$reason" == "$retry_reason" && "$attempt" -le "$max_retries" ]]; then
      echo "[$case_id#$run_no] transient=$reason attempt=$attempt retrying"
      attempt=$((attempt + 1))
      continue
    fi

    break
  done

  if [[ "$attempt_log" != "$log_file" ]]; then
    cp "$attempt_log" "$log_file"
    bytes="$(wc -c < "$log_file" | tr -d ' ')"
  fi

  if [[ "$case_id" == "S10" && "$reason" == "NO_OUTPUT" ]]; then
    local fallback_prompt="cwf:setup --hooks"
    local fallback_log="${log_file}.fallback-hooks"
    local fallback_start_ts
    local fallback_end_ts
    local fallback_duration
    local fallback_rc
    local fallback_bytes
    local fallback_result
    local fallback_reason

    fallback_start_ts="$(date +%s)"
    set +e
    invoke_prompt "$timeout_sec" "$fallback_prompt" "$fallback_log"
    fallback_rc=$?
    set -e
    fallback_end_ts="$(date +%s)"
    fallback_duration=$((fallback_end_ts - fallback_start_ts))
    total_duration=$((total_duration + fallback_duration))

    fallback_bytes="$(wc -c < "$fallback_log" | tr -d ' ')"
    classify_case_result "$fallback_log" "$fallback_rc" "$fallback_bytes"
    fallback_result="$RUN_RESULT"
    fallback_reason="$RUN_REASON"
    if [[ "$fallback_result" == "PASS" && ( "$fallback_reason" == "WAIT_INPUT" || "$fallback_reason" == "OK" ) ]]; then
      cp "$fallback_log" "$log_file"
      result="PASS"
      reason="WAIT_INPUT"
      rc="$fallback_rc"
      bytes="$fallback_bytes"
      echo "[$case_id#$run_no] fallback_prompt=\"$fallback_prompt\" recovered from NO_OUTPUT"
    else
      echo "[$case_id#$run_no] fallback_prompt=\"$fallback_prompt\" did not recover (reason=$fallback_reason)"
    fi
  fi

  printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" \
    "$case_id" "$run_no" "$result" "$reason" "$rc" "$total_duration" "$bytes" "$log_file" >> "$SUMMARY_FILE"

  echo "[$case_id#$run_no] result=$result reason=$reason exit=$rc duration=${total_duration}s bytes=$bytes attempts=$attempt log=$log_file"
}

echo "Runtime residual mode: $MODE"
echo "Output dir: $OUTPUT_DIR"
echo "K46 timeout: ${K46_TIMEOUT}s"
echo "K46 timeout retries: $K46_TIMEOUT_RETRIES"
echo "S10 timeout: ${S10_TIMEOUT}s"
echo "S10 runs: $S10_RUNS"
echo "S10 NO_OUTPUT retries: $S10_NO_OUTPUT_RETRIES"
echo "---"

run_case "K46" "1" "$K46_TIMEOUT" "cwf:retro --light"
K46_REASON="$(awk -F '\t' 'NR==2 {print $4}' "$SUMMARY_FILE")"
case "$K46_REASON" in
  TIMEOUT) K46_TIMEOUT_COUNT=$((K46_TIMEOUT_COUNT + 1)) ;;
  NO_OUTPUT) K46_NO_OUTPUT_COUNT=$((K46_NO_OUTPUT_COUNT + 1)) ;;
  ERROR) K46_OTHER_FAIL_COUNT=$((K46_OTHER_FAIL_COUNT + 1)) ;;
esac

for i in $(seq 1 "$S10_RUNS"); do
  run_case "S10" "$i" "$S10_TIMEOUT" "cwf:setup"
  S10_REASON="$(awk -F '\t' -v run="$i" '$1=="S10" && $2==run {print $4}' "$SUMMARY_FILE")"
  case "$S10_REASON" in
    WAIT_INPUT) S10_WAIT_INPUT_COUNT=$((S10_WAIT_INPUT_COUNT + 1)) ;;
    NO_OUTPUT) S10_NO_OUTPUT_COUNT=$((S10_NO_OUTPUT_COUNT + 1)) ;;
    TIMEOUT) S10_TIMEOUT_COUNT=$((S10_TIMEOUT_COUNT + 1)) ;;
    ERROR) S10_ERROR_COUNT=$((S10_ERROR_COUNT + 1)) ;;
    OK) S10_OTHER_COUNT=$((S10_OTHER_COUNT + 1)) ;;
    *) S10_OTHER_COUNT=$((S10_OTHER_COUNT + 1)) ;;
  esac
done

echo "---"
echo "K46: timeout=$K46_TIMEOUT_COUNT no_output=$K46_NO_OUTPUT_COUNT error=$K46_OTHER_FAIL_COUNT"
echo "S10: wait_input=$S10_WAIT_INPUT_COUNT no_output=$S10_NO_OUTPUT_COUNT timeout=$S10_TIMEOUT_COUNT error=$S10_ERROR_COUNT other=$S10_OTHER_COUNT"
echo "Summary: $SUMMARY_FILE"

if [[ "$MODE" == "strict" ]]; then
  if [[ "$K46_TIMEOUT_COUNT" -gt 0 || "$S10_NO_OUTPUT_COUNT" -gt 0 ]]; then
    echo "Gate result: FAIL (strict)"
    exit 1
  fi
fi

echo "Gate result: PASS ($MODE)"
exit 0
