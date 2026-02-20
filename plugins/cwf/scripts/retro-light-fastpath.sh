#!/usr/bin/env bash
set -euo pipefail

# retro-light-fastpath.sh — deterministic light-mode retro bootstrap.
# Writes a minimal, gate-compliant retro.md quickly for non-interactive runs.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIVE_STATE_SCRIPT="$SCRIPT_DIR/cwf-live-state.sh"
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

SESSION_DIR=""
OUT_FILE=""
TITLE=""
DATE_STR="$(date +%Y-%m-%d)"
LANG_CODE="${CWF_RETRO_LANG:-ko}"
INVOCATION_MODE="direct"

usage() {
  cat <<'USAGE'
retro-light-fastpath.sh — write minimal light retro artifact

Usage:
  retro-light-fastpath.sh [options]

Options:
  --session-dir <path>       Session directory (default: resolve from live state)
  --out <path>               Output file path (default: {session_dir}/retro.md)
  --title <text>             Retro title override
  --date <YYYY-MM-DD>        Session date override (default: today)
  --lang <ko|en>             Output language (default: ko)
  --invocation <direct|run_chain>
  -h, --help                 Show help
USAGE
}

derive_title_from_dir() {
  local dir_name="$1"
  if [[ "$dir_name" =~ ^[0-9]{6}-[0-9]{2}-(.+)$ ]]; then
    printf '%s\n' "${BASH_REMATCH[1]}"
    return 0
  fi
  printf '%s\n' "$dir_name"
}

resolve_session_dir_from_live() {
  local raw_dir=""
  [[ -x "$LIVE_STATE_SCRIPT" ]] || return 1
  raw_dir="$(bash "$LIVE_STATE_SCRIPT" get "$REPO_ROOT" dir 2>/dev/null || true)"
  [[ -n "$raw_dir" ]] || return 1
  if [[ "$raw_dir" == /* ]]; then
    printf '%s\n' "$raw_dir"
  else
    printf '%s\n' "$REPO_ROOT/$raw_dir"
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --session-dir)
      SESSION_DIR="${2:-}"
      shift 2
      ;;
    --out)
      OUT_FILE="${2:-}"
      shift 2
      ;;
    --title)
      TITLE="${2:-}"
      shift 2
      ;;
    --date)
      DATE_STR="${2:-}"
      shift 2
      ;;
    --lang)
      LANG_CODE="${2:-}"
      shift 2
      ;;
    --invocation)
      INVOCATION_MODE="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Error: unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ -z "$SESSION_DIR" ]]; then
  SESSION_DIR="$(resolve_session_dir_from_live || true)"
fi

if [[ -z "$SESSION_DIR" ]]; then
  echo "Error: failed to resolve session directory (use --session-dir)." >&2
  exit 1
fi

if [[ "$SESSION_DIR" != /* ]]; then
  SESSION_DIR="$REPO_ROOT/$SESSION_DIR"
fi

mkdir -p "$SESSION_DIR"

if [[ -z "$OUT_FILE" ]]; then
  OUT_FILE="$SESSION_DIR/retro.md"
elif [[ "$OUT_FILE" != /* ]]; then
  OUT_FILE="$REPO_ROOT/$OUT_FILE"
fi

mkdir -p "$(dirname "$OUT_FILE")"

if [[ -z "$TITLE" ]]; then
  TITLE="$(derive_title_from_dir "$(basename "$SESSION_DIR")")"
fi

if [[ "$LANG_CODE" == "en" ]]; then
  cat > "$OUT_FILE" <<EOF
# Retro: $TITLE

- Session date: $DATE_STR
- Mode: light
- Invocation mode: $INVOCATION_MODE
- Fast path: enabled

## 1. Context Worth Remembering
- This light retro was generated via fast path for deterministic non-interactive completion.
- Read \`retro-evidence.md\`, \`plan.md\`, and \`lessons.md\` for detailed context expansion.

## 2. Collaboration Preferences
- Keep user-facing summaries concise and decision-oriented.

## 3. Waste Reduction
- Primary waste signal: avoid AskUserQuestion stalls in non-interactive runs.

## 4. Critical Decision Analysis (CDM)
- Decision: prioritize guaranteed artifact completion over deep analysis depth in this pass.

## 5. Expert Lens
> Run \`/retro --deep\` for expert analysis.

## 6. Learning Resources
> Run \`/retro --deep\` for learning resources.

## 7. Relevant Tools (Capabilities Included)
### Installed Capabilities
- See \`retro-evidence.md\` source snapshot.

### Tool Gaps
- If timeout/no-output recurs, add script-level fail-fast checks before long analysis.
EOF
else
  cat > "$OUT_FILE" <<EOF
# Retro: $TITLE

- Session date: $DATE_STR
- Mode: light
- Invocation mode: $INVOCATION_MODE
- Fast path: enabled

## 1. Context Worth Remembering
- non-interactive 안정 종료를 위해 light fast-path로 최소 회고 아티팩트를 먼저 생성했다.
- 상세 맥락은 \`retro-evidence.md\`, \`plan.md\`, \`lessons.md\`를 기준으로 후속 보강한다.

## 2. Collaboration Preferences
- 사용자 보고는 짧고 결정 중심으로 유지한다.

## 3. Waste Reduction
- 핵심 낭비 신호: non-interactive에서 AskUserQuestion 대기로 멈추는 경로.

## 4. Critical Decision Analysis (CDM)
- 결정: 이번 패스는 분석 심도보다 결정론적 산출물 완결을 우선한다.

## 5. Expert Lens
> Run \`/retro --deep\` for expert analysis.

## 6. Learning Resources
> Run \`/retro --deep\` for learning resources.

## 7. Relevant Tools (Capabilities Included)
### Installed Capabilities
- 소스 스냅샷은 \`retro-evidence.md\` 참고.

### Tool Gaps
- timeout/무출력 재발 시 장시간 분석 단계 전에 스크립트 fail-fast를 먼저 둔다.
EOF
fi

echo "$OUT_FILE"
