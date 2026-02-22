#!/usr/bin/env bash
set -euo pipefail

DEFAULT_SOURCE=".cwf/projects/260219-01-pre-release-audit-pass2"
DEFAULT_OUTPUT=".cwf/projects/260222-02-scenario-dashboard-html/scenario-dashboard.html"
BUILD_SCRIPT=".cwf/projects/260222-02-scenario-dashboard-html/scripts/build-scenario-dashboard.mjs"

usage() {
  cat <<'USAGE'
refresh-scenario-dashboard.sh - refresh scenario simulation evidence dashboard

Usage:
  refresh-scenario-dashboard.sh [options]

Options:
  --source <dir>            Scenario project root (default: .cwf/projects/260219-01-pre-release-audit-pass2)
  --output <file>           Dashboard HTML output path (default: .cwf/projects/260222-02-scenario-dashboard-html/scenario-dashboard.html)
  --compare-mode <mode>     Delta mode: none|previous-iteration|baseline-project (default: previous-iteration)
  --baseline-source <dir>   Baseline project root (required for baseline-project mode)
  --run-gates               Run deterministic smoke/gate commands before dashboard build
  --fail-on-gate-error      Exit non-zero when any gate command fails (default: continue)
  --runtime-mode <mode>     Runtime residual mode for gate runs: observe|strict (default: strict)
  --plugin <name>           Plugin name for gate script (default: cwf)
  --plugin-dir <dir>        Plugin directory for smoke scripts (default: plugins/cwf)
  --workdir <dir>           Workdir for smoke scripts (default: current directory)
  --repo <owner/name>       Public repo for predeploy gate (default: corca-ai/claude-plugins)
  --ref <git-ref>           Public ref for predeploy gate (default: main)
  -h, --help                Show this message

Examples:
  # Rebuild with latest-vs-previous delta
  refresh-scenario-dashboard.sh

  # Compare a new audit project against an older baseline project
  refresh-scenario-dashboard.sh \
    --source .cwf/projects/260223-01-pre-release-audit-pass3 \
    --compare-mode baseline-project \
    --baseline-source .cwf/projects/260219-01-pre-release-audit-pass2 \
    --output .cwf/projects/260223-01-pre-release-audit-pass3/scenario-dashboard.html

  # Run gates first, then refresh dashboard
  refresh-scenario-dashboard.sh --run-gates --runtime-mode strict
USAGE
}

SOURCE="$DEFAULT_SOURCE"
OUTPUT="$DEFAULT_OUTPUT"
COMPARE_MODE="previous-iteration"
BASELINE_SOURCE=""
RUN_GATES=0
FAIL_ON_GATE_ERROR=0
RUNTIME_MODE="strict"
PLUGIN="cwf"
PLUGIN_DIR="plugins/cwf"
WORKDIR="$(pwd)"
REPO="corca-ai/claude-plugins"
REF="main"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source)
      if [[ -z "${2:-}" ]]; then
        echo "Error: --source requires a value." >&2
        exit 1
      fi
      SOURCE="$2"
      shift 2
      ;;
    --output)
      if [[ -z "${2:-}" ]]; then
        echo "Error: --output requires a value." >&2
        exit 1
      fi
      OUTPUT="$2"
      shift 2
      ;;
    --compare-mode)
      if [[ -z "${2:-}" ]]; then
        echo "Error: --compare-mode requires a value." >&2
        exit 1
      fi
      COMPARE_MODE="$2"
      shift 2
      ;;
    --baseline-source)
      if [[ -z "${2:-}" ]]; then
        echo "Error: --baseline-source requires a value." >&2
        exit 1
      fi
      BASELINE_SOURCE="$2"
      shift 2
      ;;
    --run-gates)
      RUN_GATES=1
      shift
      ;;
    --fail-on-gate-error)
      FAIL_ON_GATE_ERROR=1
      shift
      ;;
    --runtime-mode)
      if [[ -z "${2:-}" ]]; then
        echo "Error: --runtime-mode requires a value." >&2
        exit 1
      fi
      RUNTIME_MODE="$2"
      shift 2
      ;;
    --plugin)
      if [[ -z "${2:-}" ]]; then
        echo "Error: --plugin requires a value." >&2
        exit 1
      fi
      PLUGIN="$2"
      shift 2
      ;;
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
    --repo)
      if [[ -z "${2:-}" ]]; then
        echo "Error: --repo requires a value." >&2
        exit 1
      fi
      REPO="$2"
      shift 2
      ;;
    --ref)
      if [[ -z "${2:-}" ]]; then
        echo "Error: --ref requires a value." >&2
        exit 1
      fi
      REF="$2"
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

case "$COMPARE_MODE" in
  none|previous-iteration|baseline-project)
    ;;
  *)
    echo "Error: invalid --compare-mode: $COMPARE_MODE" >&2
    exit 1
    ;;
esac

case "$RUNTIME_MODE" in
  observe|strict)
    ;;
  *)
    echo "Error: invalid --runtime-mode: $RUNTIME_MODE" >&2
    exit 1
    ;;
esac

if [[ ! -d "$SOURCE" ]]; then
  echo "Error: source directory does not exist: $SOURCE" >&2
  exit 1
fi

if [[ -n "$BASELINE_SOURCE" && "$COMPARE_MODE" == "previous-iteration" ]]; then
  COMPARE_MODE="baseline-project"
fi

if [[ "$COMPARE_MODE" == "baseline-project" ]]; then
  if [[ -z "$BASELINE_SOURCE" ]]; then
    echo "Error: --compare-mode baseline-project requires --baseline-source." >&2
    exit 1
  fi
  if [[ ! -d "$BASELINE_SOURCE" ]]; then
    echo "Error: baseline directory does not exist: $BASELINE_SOURCE" >&2
    exit 1
  fi
fi

if [[ ! -f "$BUILD_SCRIPT" ]]; then
  echo "Error: dashboard build script not found: $BUILD_SCRIPT" >&2
  exit 1
fi

run_with_log() {
  local name="$1"
  local artifact_dir="$2"
  shift 2
  local log_file="$artifact_dir/$name.log"

  echo "[RUN] $*"
  if "$@" >"$log_file" 2>&1; then
    echo "[PASS] $name -> $log_file"
  else
    echo "[FAIL] $name -> $log_file" >&2
    return 1
  fi
}

gate_failures=0

if [[ "$RUN_GATES" -eq 1 ]]; then
  latest_iter_num=""
  for iter_dir in "$SOURCE"/iter*; do
    if [[ ! -d "$iter_dir" ]]; then
      continue
    fi
    iter_base="$(basename "$iter_dir")"
    case "$iter_base" in
      iter[0-9]*)
        iter_num="${iter_base#iter}"
        if [[ -z "$latest_iter_num" ]] || [[ "$iter_num" -gt "$latest_iter_num" ]]; then
          latest_iter_num="$iter_num"
        fi
        ;;
    esac
  done

  if [[ -z "$latest_iter_num" ]]; then
    echo "Error: no iterN directories found under source: $SOURCE" >&2
    exit 1
  fi

  ts="$(date +%y%m%d-%H%M%S)"
  artifact_dir="$SOURCE/iter${latest_iter_num}/artifacts/dashboard-refresh-$ts"
  mkdir -p "$artifact_dir"

  if ! run_with_log "premerge" "$artifact_dir" \
      bash scripts/premerge-cwf-gate.sh --mode premerge --plugin "$PLUGIN"; then
    gate_failures=$((gate_failures + 1))
  fi

  if ! run_with_log "predeploy" "$artifact_dir" \
      bash scripts/premerge-cwf-gate.sh \
        --mode predeploy \
        --plugin "$PLUGIN" \
        --repo "$REPO" \
        --ref "$REF" \
        --runtime-residual-mode "$RUNTIME_MODE"; then
    gate_failures=$((gate_failures + 1))
  fi

  if ! run_with_log "runtime-residual" "$artifact_dir" \
      bash scripts/runtime-residual-smoke.sh \
        --mode "$RUNTIME_MODE" \
        --plugin-dir "$PLUGIN_DIR" \
        --workdir "$WORKDIR" \
        --k46-timeout 120 \
        --s10-timeout 120 \
        --s10-runs 5 \
        --output-dir "$artifact_dir/runtime-residual-smoke"; then
    gate_failures=$((gate_failures + 1))
  fi

  if ! run_with_log "noninteractive-smoke" "$artifact_dir" \
      bash scripts/noninteractive-skill-smoke.sh \
        --plugin-dir "$PLUGIN_DIR" \
        --workdir "$WORKDIR" \
        --adaptive-review-timeout \
        --output-dir "$artifact_dir/noninteractive-smoke"; then
    gate_failures=$((gate_failures + 1))
  fi

  echo "[INFO] Gate artifacts: $artifact_dir"
fi

build_cmd=(
  node "$BUILD_SCRIPT"
  --source "$SOURCE"
  --output "$OUTPUT"
  --compare-mode "$COMPARE_MODE"
)

if [[ -n "$BASELINE_SOURCE" ]]; then
  build_cmd+=(--baseline-source "$BASELINE_SOURCE")
fi

"${build_cmd[@]}"

echo "[DONE] Dashboard refreshed: $OUTPUT"

if [[ "$gate_failures" -gt 0 ]]; then
  echo "[WARN] Gate failures: $gate_failures (see gate logs)." >&2
  if [[ "$FAIL_ON_GATE_ERROR" -eq 1 ]]; then
    exit 1
  fi
fi
