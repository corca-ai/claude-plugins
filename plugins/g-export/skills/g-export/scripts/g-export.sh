#!/bin/bash
# Usage: g-export.sh <google-doc-url> [format] [output-dir]
# Downloads public Google Slides/Docs/Sheets to local files.

set -e

URL="$1"
FORMAT="$2"
OUTPUT_DIR="${3:-./g-exports}"

# Extract document type and ID from URL
if [[ "$URL" =~ docs\.google\.com/(presentation|document|spreadsheets)/d/([^/]+) ]]; then
    TYPE="${BASH_REMATCH[1]}"
    ID="${BASH_REMATCH[2]}"
else
    echo "Error: Invalid Google document URL" >&2
    echo "Expected: docs.google.com/{presentation|document|spreadsheets}/d/{id}/..." >&2
    exit 1
fi

# Set default format based on document type
if [[ -z "$FORMAT" ]]; then
    case "$TYPE" in
        presentation) FORMAT="txt" ;;
        document)     FORMAT="md" ;;
        spreadsheets) FORMAT="csv" ;;
    esac
fi

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Build export URL
EXPORT_URL="https://docs.google.com/${TYPE}/d/${ID}/export?format=${FORMAT}"

# Get filename from Content-Disposition header
echo "Downloading ${TYPE} as ${FORMAT}..."
HEADER=$(curl -sLI "$EXPORT_URL" | grep -i '^content-disposition:' | tr -d '\r')

# Parse filename from header
# Try filename*=UTF-8'' first (RFC 5987), then fallback to filename=
if [[ "$HEADER" =~ filename\*=UTF-8\'\'([^[:space:]]+) ]]; then
    # URL-decode the filename
    FILENAME=$(python3 -c "import urllib.parse, sys; print(urllib.parse.unquote(sys.argv[1]))" "${BASH_REMATCH[1]}")
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
    sed -i '' '/^\[image[0-9]*\]: <data:image/d' "$OUTPUT_PATH"
fi

# Check if download succeeded (non-empty file)
if [[ ! -s "$OUTPUT_PATH" ]]; then
    echo "Error: Download failed or document is not publicly accessible" >&2
    rm -f "$OUTPUT_PATH"
    exit 1
fi

echo "Saved to: $OUTPUT_PATH"
