#!/usr/bin/env bash
set -euo pipefail

# migrate-env-vars.sh
# Scans shell profiles for legacy CWF-related env vars and migrates them to
# canonical CWF_* names.
#
# Modes:
#   --scan (default): report migration candidates and missing required keys
#   --apply: write canonical exports to target profile
#
# Options:
#   --target-profile <path>  Target profile for managed exports (default: shell-based)
#   --cleanup-legacy         Comment legacy assignments in scanned files
#   --include-placeholders   Add commented placeholders for missing required keys
#
# Notes:
# - TAVILY_API_KEY and EXA_API_KEY remain unchanged by policy.
# - The script never deletes user files.

MODE="scan"
TARGET_PROFILE=""
CLEANUP_LEGACY="false"
INCLUDE_PLACEHOLDERS="false"

usage() {
    cat <<'EOF'
Usage:
  migrate-env-vars.sh --scan
  migrate-env-vars.sh --apply [--target-profile <path>] [--cleanup-legacy] [--include-placeholders]
EOF
}

while [ $# -gt 0 ]; do
    case "$1" in
        --scan)
            MODE="scan"
            ;;
        --apply)
            MODE="apply"
            ;;
        --target-profile)
            TARGET_PROFILE="${2-}"
            if [ -z "$TARGET_PROFILE" ]; then
                echo "Error: --target-profile requires a value" >&2
                exit 1
            fi
            shift
            ;;
        --cleanup-legacy)
            CLEANUP_LEGACY="true"
            ;;
        --include-placeholders)
            INCLUDE_PLACEHOLDERS="true"
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
    shift
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
unset SCRIPT_DIR

if [ -n "$TARGET_PROFILE" ]; then
    PRIMARY_PROFILE="$TARGET_PROFILE"
else
    case "${SHELL:-}" in
        */zsh) PRIMARY_PROFILE="$HOME/.zshrc" ;;
        */bash) PRIMARY_PROFILE="$HOME/.bashrc" ;;
        *) PRIMARY_PROFILE="$HOME/.zshrc" ;;
    esac
fi

SCAN_FILES=""
for file in "$HOME/.zshrc" "$HOME/.bashrc" "$HOME/.claude/.env"; do
    if [ -f "$file" ]; then
        if [ -z "$SCAN_FILES" ]; then
            SCAN_FILES="$file"
        else
            SCAN_FILES="$SCAN_FILES"$'\n'"$file"
        fi
    fi
done

if [ -z "$SCAN_FILES" ]; then
    touch "$PRIMARY_PROFILE"
    SCAN_FILES="$PRIMARY_PROFILE"
fi

# canonical|legacy (one mapping per line)
MAPPINGS=$(cat <<'EOF'
CWF_ATTENTION_DELAY|CLAUDE_CORCA_ATTENTION_DELAY
CWF_ATTENTION_REPLY_BROADCAST|CLAUDE_CORCA_ATTENTION_REPLY_BROADCAST
CWF_ATTENTION_TRUNCATE|CLAUDE_CORCA_ATTENTION_TRUNCATE
CWF_ATTENTION_USER_ID|CLAUDE_CORCA_ATTENTION_USER_ID
CWF_ATTENTION_USER_HANDLE|CLAUDE_CORCA_ATTENTION_USER_HANDLE
CWF_ATTENTION_PARENT_MENTION|CLAUDE_CORCA_ATTENTION_PARENT_MENTION
CWF_ATTENTION_HEARTBEAT_USER_IDLE|CLAUDE_CORCA_ATTENTION_HEARTBEAT_USER_IDLE
CWF_ATTENTION_HEARTBEAT_INTERVAL|CLAUDE_CORCA_ATTENTION_HEARTBEAT_INTERVAL
CWF_ATTENTION_DELAY|CLAUDE_ATTENTION_DELAY
CWF_ATTENTION_HEARTBEAT_USER_IDLE|CLAUDE_ATTENTION_HEARTBEAT_USER_IDLE
CWF_ATTENTION_HEARTBEAT_INTERVAL|CLAUDE_ATTENTION_HEARTBEAT_INTERVAL
CWF_READ_WARN_LINES|CLAUDE_CORCA_SMART_READ_WARN_LINES
CWF_READ_DENY_LINES|CLAUDE_CORCA_SMART_READ_DENY_LINES
CWF_SESSION_LOG_DIR|CLAUDE_CORCA_PROMPT_LOGGER_DIR
CWF_SESSION_LOG_ENABLED|CLAUDE_CORCA_PROMPT_LOGGER_ENABLED
CWF_SESSION_LOG_TRUNCATE|CLAUDE_CORCA_PROMPT_LOGGER_TRUNCATE
CWF_SESSION_LOG_AUTO_COMMIT|CLAUDE_CORCA_PROMPT_LOGGER_AUTO_COMMIT
CWF_GATHER_OUTPUT_DIR|CLAUDE_CORCA_GATHER_CONTEXT_OUTPUT_DIR
CWF_GATHER_OUTPUT_DIR|CLAUDE_CORCA_URL_EXPORT_OUTPUT_DIR
CWF_GATHER_OUTPUT_DIR|CLAUDE_CORCA_SLACK_TO_MD_OUTPUT_DIR
CWF_GATHER_GOOGLE_OUTPUT_DIR|CLAUDE_CORCA_G_EXPORT_OUTPUT_DIR
CWF_GATHER_NOTION_OUTPUT_DIR|CLAUDE_CORCA_NOTION_TO_MD_OUTPUT_DIR
CWF_PROJECTS_DIR|CWF_PROMPT_LOGS_DIR
EOF
)

# Keys that should exist for full capability.
REQUIRED_KEYS=$(cat <<'EOF'
SLACK_BOT_TOKEN
SLACK_CHANNEL_ID
TAVILY_API_KEY
EXA_API_KEY
EOF
)

escape_regex() {
    printf '%s' "$1" | sed 's/[][(){}.^$+*?|\\]/\\&/g'
}

find_assignment() {
    # Prints: value<TAB>source
    # source format: /path:line
    local key="$1"
    local file
    local regex
    regex="^[[:space:]]*(export[[:space:]]+)?$(escape_regex "$key")[[:space:]]*="

    while IFS= read -r file; do
        [ -n "$file" ] || continue
        local hit
        hit=$(grep -nE "$regex" "$file" | grep -vE '^[0-9]+:[[:space:]]*#' | tail -1 || true)
        if [ -n "$hit" ]; then
            local line_no
            local line
            local rhs
            line_no="${hit%%:*}"
            line="${hit#*:}"
            rhs="${line#*=}"
            rhs="$(printf '%s' "$rhs" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
            printf '%s\t%s:%s\n' "$rhs" "$file" "$line_no"
            return 0
        fi
    done <<< "$SCAN_FILES"

    return 1
}

is_defined_anywhere() {
    local key="$1"
    if find_assignment "$key" >/dev/null 2>&1; then
        return 0
    fi
    if [ -n "${!key:-}" ]; then
        return 0
    fi
    return 1
}

comment_out_legacy_key() {
    local key="$1"
    local file
    while IFS= read -r file; do
        [ -n "$file" ] || continue
        [ -f "$file" ] || continue

        local tmp
        tmp="$(mktemp)"
        awk -v key="$key" '
            BEGIN {
                regex = "^[[:space:]]*(export[[:space:]]+)?" key "[[:space:]]*="
            }
            $0 ~ regex && $0 !~ /^[[:space:]]*#/ {
                print "# migrated-to-CWF: " $0
                next
            }
            { print }
        ' "$file" > "$tmp"
        mv "$tmp" "$file"
    done <<< "$SCAN_FILES"
}

MIGRATIONS=""
LEGACY_KEYS_SEEN=""
while IFS= read -r map; do
    [ -n "$map" ] || continue
    canonical="${map%%|*}"
    legacy="${map#*|}"

    if is_defined_anywhere "$canonical"; then
        continue
    fi

    found="$(find_assignment "$legacy" || true)"
    if [ -n "$found" ]; then
        value="${found%%$'\t'*}"
        source="${found#*$'\t'}"

        # Ensure each canonical key appears once (first found wins).
        if ! printf '%s\n' "$MIGRATIONS" | grep -q "^${canonical}|"; then
            if [ -z "$MIGRATIONS" ]; then
                MIGRATIONS="${canonical}|${value}|${legacy}|${source}"
            else
                MIGRATIONS="${MIGRATIONS}"$'\n'"${canonical}|${value}|${legacy}|${source}"
            fi
        fi

        if [ -z "$LEGACY_KEYS_SEEN" ]; then
            LEGACY_KEYS_SEEN="$legacy"
        else
            if ! printf '%s\n' "$LEGACY_KEYS_SEEN" | grep -qx "$legacy"; then
                LEGACY_KEYS_SEEN="$LEGACY_KEYS_SEEN"$'\n'"$legacy"
            fi
        fi
    fi
done <<< "$MAPPINGS"

MISSING_REQUIRED=""
while IFS= read -r key; do
    [ -n "$key" ] || continue
    if ! is_defined_anywhere "$key"; then
        if [ -z "$MISSING_REQUIRED" ]; then
            MISSING_REQUIRED="$key"
        else
            MISSING_REQUIRED="$MISSING_REQUIRED"$'\n'"$key"
        fi
    fi
done <<< "$REQUIRED_KEYS"

print_report() {
    echo "Scan files:"
    while IFS= read -r file; do
        [ -n "$file" ] || continue
        echo "  - $file"
    done <<< "$SCAN_FILES"
    echo

    if [ -n "$MIGRATIONS" ]; then
        echo "Migration candidates (legacy -> canonical):"
        while IFS= read -r row; do
            [ -n "$row" ] || continue
            canonical="${row%%|*}"
            rest="${row#*|}"
            value="${rest%%|*}"
            rest="${rest#*|}"
            legacy="${rest%%|*}"
            source="${rest#*|}"
            echo "  - $legacy -> $canonical (source: $source, value: $value)"
        done <<< "$MIGRATIONS"
    else
        echo "Migration candidates: none"
    fi
    echo

    if [ -n "$MISSING_REQUIRED" ]; then
        echo "Missing required keys:"
        while IFS= read -r key; do
            [ -n "$key" ] || continue
            echo "  - $key"
        done <<< "$MISSING_REQUIRED"
    else
        echo "Missing required keys: none"
    fi
}

if [ "$MODE" = "scan" ]; then
    print_report
    exit 0
fi

mkdir -p "$(dirname "$PRIMARY_PROFILE")"
touch "$PRIMARY_PROFILE"

START_MARKER="# >>> CWF ENV (managed by cwf:setup) >>>"
END_MARKER="# <<< CWF ENV (managed by cwf:setup) <<<"

tmp_profile="$(mktemp)"
awk -v start="$START_MARKER" -v end="$END_MARKER" '
    $0 == start { skip=1; next }
    $0 == end { skip=0; next }
    skip != 1 { print }
' "$PRIMARY_PROFILE" > "$tmp_profile"
mv "$tmp_profile" "$PRIMARY_PROFILE"

if [ -n "$MIGRATIONS" ] || [ "$INCLUDE_PLACEHOLDERS" = "true" ]; then
    {
        echo ""
        echo "$START_MARKER"
        echo "# Canonical CWF environment variables."
        echo "# Generated by plugins/cwf/skills/setup/scripts/migrate-env-vars.sh"

        if [ -n "$MIGRATIONS" ]; then
            while IFS= read -r row; do
                [ -n "$row" ] || continue
                canonical="${row%%|*}"
                rest="${row#*|}"
                value="${rest%%|*}"
                rest="${rest#*|}"
                legacy="${rest%%|*}"
                source="${rest#*|}"
                echo "export ${canonical}=${value}  # migrated from ${legacy} (${source})"
            done <<< "$MIGRATIONS"
        fi

        if [ "$INCLUDE_PLACEHOLDERS" = "true" ] && [ -n "$MISSING_REQUIRED" ]; then
            echo ""
            echo "# Fill required keys:"
            while IFS= read -r key; do
                [ -n "$key" ] || continue
                echo "# export ${key}=\"\""
            done <<< "$MISSING_REQUIRED"
        fi

        echo "$END_MARKER"
    } >> "$PRIMARY_PROFILE"
fi

if [ "$CLEANUP_LEGACY" = "true" ] && [ -n "$LEGACY_KEYS_SEEN" ]; then
    while IFS= read -r key; do
        [ -n "$key" ] || continue
        comment_out_legacy_key "$key"
    done <<< "$LEGACY_KEYS_SEEN"
fi

print_report
echo
echo "Applied profile: $PRIMARY_PROFILE"
if [ "$CLEANUP_LEGACY" = "true" ]; then
    echo "Legacy cleanup: enabled"
else
    echo "Legacy cleanup: disabled"
fi
