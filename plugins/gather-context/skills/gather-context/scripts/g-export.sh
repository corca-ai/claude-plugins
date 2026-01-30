#!/bin/bash
# Usage: g-export.sh <google-doc-url> [format] [output-dir]
# Downloads public Google Slides/Docs/Sheets to local files.
#
# Supported formats:
# - Slides: pptx, odp, pdf, txt (default: txt)
# - Docs: docx, odt, pdf, txt, epub, html, md (default: md)
# - Sheets: xlsx, ods, pdf, csv, tsv, toon (default: toon)
#
# The 'toon' format (Token-Oriented Object Notation) is optimized for LLM consumption.
# It provides clearer structure indication while handling multi-line content explicitly.
# See: https://github.com/toon-format/toon

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

URL="$1"
FORMAT="$2"
OUTPUT_DIR="${3:-${CLAUDE_CORCA_G_EXPORT_OUTPUT_DIR:-./g-exports}}"

# Extract document type and ID from URL
if [[ "$URL" =~ docs\.google\.com/(presentation|document|spreadsheets)/d/([^/]+) ]]; then
    TYPE="${BASH_REMATCH[1]}"
    ID="${BASH_REMATCH[2]}"
else
    echo "Error: Invalid Google document URL" >&2
    echo "Expected: docs.google.com/{presentation|document|spreadsheets}/d/{id}/..." >&2
    exit 1
fi

# Extract gid from URL (for spreadsheets - specifies which sheet to export)
GID=""
if [[ "$URL" =~ [?#\&]gid=([0-9]+) ]]; then
    GID="${BASH_REMATCH[1]}"
fi

# Set default format based on document type
if [[ -z "$FORMAT" ]]; then
    case "$TYPE" in
        presentation) FORMAT="txt" ;;
        document)     FORMAT="md" ;;
        spreadsheets) FORMAT="toon" ;;
    esac
fi

# Handle TOON format for spreadsheets (requires CSV conversion)
CONVERT_TO_TOON=false
DOWNLOAD_FORMAT="$FORMAT"
if [[ "$FORMAT" == "toon" ]]; then
    if [[ "$TYPE" != "spreadsheets" ]]; then
        echo "Error: TOON format is only supported for Google Sheets" >&2
        exit 1
    fi
    CONVERT_TO_TOON=true
    DOWNLOAD_FORMAT="csv"
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Build export URL
EXPORT_URL="https://docs.google.com/${TYPE}/d/${ID}/export?format=${DOWNLOAD_FORMAT}"

# Add gid parameter for spreadsheets (to export specific sheet)
if [[ -n "$GID" && "$TYPE" == "spreadsheets" ]]; then
    EXPORT_URL="${EXPORT_URL}&gid=${GID}"
fi

# Get filename from Content-Disposition header
echo "Downloading ${TYPE} as ${DOWNLOAD_FORMAT}..."
HEADER=$(curl -sLI "$EXPORT_URL" | grep -i '^content-disposition:' | tr -d '\r')

# Parse filename from header
# Try filename*=UTF-8'' first (RFC 5987), then fallback to filename=
if [[ "$HEADER" =~ filename\*=UTF-8\'\'([^[:space:]]+) ]]; then
    # URL-decode the filename (pure bash: replace % with \x, then interpret escape sequences)
    ENCODED="${BASH_REMATCH[1]}"
    HEX_STRING="${ENCODED//\%/\\x}"
    printf -v FILENAME "%b" "$HEX_STRING"
elif [[ "$HEADER" =~ filename=\"([^\"]+)\" ]]; then
    FILENAME="${BASH_REMATCH[1]}"
else
    # Fallback to document ID
    FILENAME="${ID}.${FORMAT}"
fi

OUTPUT_PATH="${OUTPUT_DIR}/${FILENAME}"

# Download
curl -sL -o "$OUTPUT_PATH" "$EXPORT_URL"

# For markdown files, remove base64 embedded images (they waste context for LLM analysis)
# Google Docs uses reference-style images: [imageN]: <data:image/...>
if [[ "$FORMAT" == "md" ]]; then
    grep -v '^\[image[0-9]*\]: <data:image' "$OUTPUT_PATH" > "${OUTPUT_PATH}.tmp" || true
    mv "${OUTPUT_PATH}.tmp" "$OUTPUT_PATH"
fi

# Check if download succeeded (non-empty file)
if [[ ! -s "$OUTPUT_PATH" ]]; then
    echo "Error: Download failed or document is not publicly accessible" >&2
    rm -f "$OUTPUT_PATH"
    exit 1
fi

# Convert to TOON format if requested
if [[ "$CONVERT_TO_TOON" == "true" ]]; then
    echo "Converting to TOON format..."
    TOON_PATH="${OUTPUT_PATH%.csv}.toon"
    if "$SCRIPT_DIR/csv-to-toon.sh" "$OUTPUT_PATH" > "$TOON_PATH"; then
        rm -f "$OUTPUT_PATH"  # Remove intermediate CSV file
        OUTPUT_PATH="$TOON_PATH"
    else
        echo "Error: Failed to convert to TOON format" >&2
        rm -f "$TOON_PATH"
        exit 1
    fi
fi

echo "Saved to: $OUTPUT_PATH"
