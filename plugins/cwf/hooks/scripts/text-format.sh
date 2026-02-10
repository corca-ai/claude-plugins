#!/usr/bin/env bash
# Shared multiline text formatting helpers for hooks.

# Normalize multiline text by:
# - trimming leading/trailing blank lines
# - collapsing multiple consecutive blank lines to a single blank line
normalize_multiline_text() {
    local text="${1:-}"
    if [ -z "$text" ]; then
        echo ""
        return
    fi

    printf '%s\n' "$text" | awk '
        {
            if ($0 ~ /^[[:space:]]*$/) {
                if (started) {
                    blank_pending=1
                }
                next
            }

            if (blank_pending && started) {
                print ""
            }

            print
            started=1
            blank_pending=0
        }
    '
}

text_line_count() {
    local text="${1:-}"
    if [ -z "$text" ]; then
        echo "0"
        return
    fi

    printf '%s\n' "$text" | wc -l | tr -d ' '
}

# Truncate long multiline text by keeping head/tail lines and a marker.
# Usage: truncate_middle_lines <text> [max_lines] [marker]
truncate_middle_lines() {
    local text="${1:-}"
    local max_lines="${2:-10}"
    local marker="${3:-...(truncated)...}"

    if [ -z "$text" ]; then
        echo ""
        return
    fi

    if ! [[ "$max_lines" =~ ^[0-9]+$ ]] || [ "$max_lines" -le 0 ]; then
        printf '%s\n' "$text"
        return
    fi

    local line_count
    line_count=$(text_line_count "$text")
    if [ "$line_count" -le "$max_lines" ]; then
        printf '%s\n' "$text"
        return
    fi

    local head_lines=$((max_lines / 2))
    local tail_lines=$((max_lines - head_lines))
    if [ "$head_lines" -eq 0 ]; then
        head_lines=1
        tail_lines=$((max_lines - head_lines))
    fi

    printf '%s\n' "$text" | head -n "$head_lines"
    printf '%s\n' "$marker"
    if [ "$tail_lines" -gt 0 ]; then
        printf '%s\n' "$text" | tail -n "$tail_lines"
    fi
}

# Normalize blank lines and optionally truncate in one step.
# Usage: normalize_and_truncate_text <text> [max_lines] [marker]
# - max_lines <= 0 or invalid: normalize only
normalize_and_truncate_text() {
    local text="${1:-}"
    local max_lines="${2:-0}"
    local marker="${3:-...(truncated)...}"

    if [ -z "$text" ]; then
        echo ""
        return
    fi

    local normalized
    normalized=$(normalize_multiline_text "$text")

    if [[ "$max_lines" =~ ^[0-9]+$ ]] && [ "$max_lines" -gt 0 ]; then
        truncate_middle_lines "$normalized" "$max_lines" "$marker"
        return
    fi

    printf '%s\n' "$normalized"
}
