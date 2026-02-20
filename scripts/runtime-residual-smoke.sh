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
  --s10-timeout <sec>      Timeout per S10 run (default: 120)
  --s10-runs <n>           Number of S10 repeats (default: 5)
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
S10_TIMEOUT=120
S10_RUNS=5
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
    --s10-timeout)
      S10_TIMEOUT="${2:-}"
      shift 2
      ;;
    --s10-runs)
      S10_RUNS="${2:-}"
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

run_case() {
  local case_id="$1"
  local run_no="$2"
  local timeout_sec="$3"
  local prompt="$4"
  local log_file="$OUTPUT_DIR/${case_id}-run${run_no}.log"
  local start_ts
  local end_ts
  local duration
  local rc
  local bytes
  local result="PASS"
  local reason="OK"

  start_ts="$(date +%s)"

  set +e
  (
    cd "$WORKDIR" && timeout "$timeout_sec" "$CLAUDE_BIN" --print "$prompt" --dangerously-skip-permissions --plugin-dir "$PLUGIN_DIR"
  ) >"$log_file" 2>&1
  rc=$?
  set -e

  end_ts="$(date +%s)"
  duration=$((end_ts - start_ts))
  bytes="$(wc -c < "$log_file" | tr -d ' ')"

  if [[ "$rc" -eq 124 ]]; then
    result="FAIL"
    reason="TIMEOUT"
  elif [[ "$bytes" -le 1 ]]; then
    result="FAIL"
    reason="NO_OUTPUT"
  elif [[ "$rc" -ne 0 ]]; then
    result="FAIL"
    reason="ERROR"
  elif is_wait_input_log "$log_file"; then
    # WAIT_INPUT is expected for non-interactive setup paths.
    result="PASS"
    reason="WAIT_INPUT"
  fi

  printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" \
    "$case_id" "$run_no" "$result" "$reason" "$rc" "$duration" "$bytes" "$log_file" >> "$SUMMARY_FILE"

  echo "[$case_id#$run_no] result=$result reason=$reason exit=$rc duration=${duration}s bytes=$bytes log=$log_file"
}

echo "Runtime residual mode: $MODE"
echo "Output dir: $OUTPUT_DIR"
echo "K46 timeout: ${K46_TIMEOUT}s"
echo "S10 timeout: ${S10_TIMEOUT}s"
echo "S10 runs: $S10_RUNS"
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
