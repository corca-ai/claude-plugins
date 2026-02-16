#!/bin/bash
# Usage: csv-to-toon.sh <csv-file>
# Converts CSV file to TOON (Token-Oriented Object Notation) format for LLM consumption.
# TOON reduces token usage by ~40% compared to CSV for structured data.
#
# Input: Standard CSV with headers in first row
# Output: TOON format written to stdout

set -e

CSV_FILE="$1"

if [[ -z "$CSV_FILE" ]]; then
    echo "Usage: csv-to-toon.sh <csv-file>" >&2
    exit 1
fi

if [[ ! -f "$CSV_FILE" ]]; then
    echo "Error: File not found: $CSV_FILE" >&2
    exit 1
fi

# Use awk to parse CSV and convert to TOON format
# This handles quoted fields with commas and newlines
# tr -d '\r' removes Windows-style CRLF line endings
tr -d '\r' < "$CSV_FILE" | awk '
BEGIN {
    FS = ""  # We parse character by character
    row_count = 0
}

{
    # Append line to buffer (handles multi-line fields)
    if (buffer != "") {
        buffer = buffer "\n" $0
    } else {
        buffer = $0
    }

    # Count quotes to check if we have complete row
    n = gsub(/"/, "\"", buffer)
    if (n % 2 != 0) {
        # Odd number of quotes means we are inside a quoted field, continue
        next
    }

    # Parse the complete row
    line = buffer
    buffer = ""

    # Parse CSV fields
    delete fields
    field_count = 0
    in_quotes = 0
    field = ""

    for (i = 1; i <= length(line); i++) {
        c = substr(line, i, 1)

        if (in_quotes) {
            if (c == "\"") {
                # Check for escaped quote
                if (substr(line, i+1, 1) == "\"") {
                    field = field "\""
                    i++
                } else {
                    in_quotes = 0
                }
            } else {
                field = field c
            }
        } else {
            if (c == "\"") {
                in_quotes = 1
            } else if (c == ",") {
                field_count++
                fields[field_count] = field
                field = ""
            } else {
                field = field c
            }
        }
    }
    # Add last field
    field_count++
    fields[field_count] = field

    row_count++

    if (row_count == 1) {
        # First row is headers
        for (j = 1; j <= field_count; j++) {
            headers[j] = fields[j]
        }
        header_count = field_count
    } else {
        # Data rows - store for later output (skip empty rows)
        is_empty = 1
        for (j = 1; j <= field_count; j++) {
            if (fields[j] != "") {
                is_empty = 0
                break
            }
        }
        if (!is_empty) {
            data_row_count++
            for (j = 1; j <= field_count; j++) {
                data[data_row_count, j] = fields[j]
            }
            if (field_count > max_cols) max_cols = field_count
        }
    }
}

END {
    if (header_count == 0) {
        print "Error: No headers found in CSV" > "/dev/stderr"
        exit 1
    }

    # Build header string (quote headers containing special chars)
    header_str = ""
    for (i = 1; i <= header_count; i++) {
        if (i > 1) header_str = header_str ","
        header_str = header_str quote_if_needed(headers[i])
    }

    # Output TOON format
    # rows[count]{header1,header2,...}:
    printf "rows[%d]{%s}:\n", data_row_count, header_str

    # Output each row (indented with 2 spaces per TOON spec)
    for (r = 1; r <= data_row_count; r++) {
        row_str = "  "
        for (c = 1; c <= header_count; c++) {
            val = data[r, c]
            if (c > 1) row_str = row_str ","
            row_str = row_str quote_if_needed(val)
        }
        print row_str
    }
}

# Check if value needs quoting per TOON spec (Section 7.2)
function needs_quoting(val) {
    # Empty string
    if (val == "") return 1
    # Leading/trailing whitespace
    if (val ~ /^[ \t]/ || val ~ /[ \t]$/) return 1
    # Reserved words
    if (val == "true" || val == "false" || val == "null") return 1
    # Numeric-like patterns (integers, decimals, scientific notation)
    if (val ~ /^-?[0-9]+(\.[0-9]+)?([eE][+-]?[0-9]+)?$/) return 1
    # Contains special chars: comma, colon, quote, backslash, brackets
    if (val ~ /[,:"\\{}\[\]]/) return 1
    # Contains control chars: newline, carriage return, tab
    if (val ~ /[\n\r\t]/) return 1
    # Starts with hyphen or equals hyphen
    if (val ~ /^-/) return 1
    return 0
}

# Quote and escape a value if needed per TOON spec (Section 7.1)
function quote_if_needed(val) {
    if (!needs_quoting(val)) return val

    # Escape special characters (order matters: backslash first)
    gsub(/\\/, "\\\\", val)
    gsub(/"/, "\\\"", val)
    gsub(/\n/, "\\n", val)
    gsub(/\r/, "\\r", val)
    gsub(/\t/, "\\t", val)

    return "\"" val "\""
}
'
