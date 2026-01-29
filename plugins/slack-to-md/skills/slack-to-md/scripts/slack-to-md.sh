#!/bin/bash
# Slack thread to Markdown converter
# Reads JSON from stdin (from slack-api.mjs)
# Usage: ./slack-to-md.sh <channel_id> <thread_ts> <workspace> <output_file> [title]

set -e

CHANNEL_ID="$1"
THREAD_TS="$2"
WORKSPACE="$3"
OUTPUT_FILE="$4"
TITLE="${5:-Slack Thread}"

if [[ -z "$CHANNEL_ID" || -z "$THREAD_TS" || -z "$WORKSPACE" || -z "$OUTPUT_FILE" ]]; then
    echo "Usage: $0 <channel_id> <thread_ts> <workspace> <output_file> [title]" >&2
    echo "       JSON is read from stdin" >&2
    exit 1
fi

# Read JSON from stdin
echo "Reading messages from stdin..." >&2
JSON=$(cat)

if [[ -z "$JSON" ]]; then
    echo "Error: No JSON data received from stdin" >&2
    exit 1
fi

# Generate thread URL (remove dot from timestamp)
THREAD_URL="https://${WORKSPACE}.slack.com/archives/${CHANNEL_ID}/p${THREAD_TS//./}"

# Create output directory if needed
mkdir -p "$(dirname "$OUTPUT_FILE")"

# Get current timestamp
UPDATED_AT=$(date "+%Y-%m-%d %H:%M")

# Write header
cat > "$OUTPUT_FILE" << EOF
# $TITLE

> Slack thread archive
> Source: $THREAD_URL
> Last updated: $UPDATED_AT

EOF

# Extract user map as TSV (id<tab>name)
USER_MAP=$(echo "$JSON" | jq -r '.users[] | "\(.id)\t\(.real_name)"')

# Function to get username from user_id
get_username() {
    local user_id="$1"
    echo "$USER_MAP" | grep "^$user_id	" | cut -f2 || echo "$user_id"
}

# Function to convert Slack links to markdown
convert_links() {
    local text="$1"
    # Convert <url|text> to [text](url)
    text=$(echo "$text" | perl -pe 's/<(https?:\/\/[^|>]+)\|([^>]+)>/[$2]($1)/g')
    # Convert <url> to plain url
    text=$(echo "$text" | perl -pe 's/<(https?:\/\/[^>]+)>/$1/g')
    # Convert &amp; &lt; &gt;
    text=$(echo "$text" | sed 's/&amp;/\&/g; s/&lt;/</g; s/&gt;/>/g')
    echo "$text"
}

# Image file extensions for inline rendering
IMAGE_EXTS="png jpg jpeg gif webp svg bmp"

is_image() {
    local ext="${1##*.}"
    ext=$(echo "$ext" | tr '[:upper:]' '[:lower:]')
    for img_ext in $IMAGE_EXTS; do
        if [[ "$ext" == "$img_ext" ]]; then
            return 0
        fi
    done
    return 1
}

# Compute relative path from output file to attachments directory
OUTPUT_DIR=$(dirname "$OUTPUT_FILE")

# Get total message count
MSG_COUNT=$(echo "$JSON" | jq '.messages | sort_by(.ts) | length')

# Process each message sorted by timestamp
for (( i=0; i<MSG_COUNT; i++ )); do
    # Extract message fields
    ts=$(echo "$JSON" | jq -r ".messages | sort_by(.ts) | .[$i].ts")
    user_id=$(echo "$JSON" | jq -r ".messages | sort_by(.ts) | .[$i].user")
    text=$(echo "$JSON" | jq -r ".messages | sort_by(.ts) | .[$i].text | gsub(\"\\n\"; \"\\\\n\")")

    # Get username
    user_name=$(get_username "$user_id")

    # Convert timestamp to date (uses system timezone - should be KST)
    unix_ts="${ts%%.*}"
    date_str=$(date -r "$unix_ts" "+%Y-%m-%d %H:%M" 2>/dev/null || date -d "@$unix_ts" "+%Y-%m-%d %H:%M" 2>/dev/null)

    # Convert \n back to newlines and convert links
    text=$(echo -e "$text")
    text=$(convert_links "$text")

    # Replace user mentions with names
    while [[ "$text" =~ \<@(U[A-Z0-9]+)\> ]]; do
        mention_id="${BASH_REMATCH[1]}"
        mention_name=$(get_username "$mention_id")
        text="${text//<@$mention_id>/@$mention_name}"
    done

    # Write message
    cat >> "$OUTPUT_FILE" << EOF
---

**${user_name}** · ${date_str}

$text

EOF

    # Process file attachments
    FILE_COUNT=$(echo "$JSON" | jq ".messages | sort_by(.ts) | .[$i].files // [] | length")
    if [[ "$FILE_COUNT" -gt 0 ]]; then
        # Write attachments header (using unicode directly instead of emoji shortcode)
        printf '\xf0\x9f\x93\x8e **Attachments**\n' >> "$OUTPUT_FILE"

        for (( j=0; j<FILE_COUNT; j++ )); do
            file_name=$(echo "$JSON" | jq -r ".messages | sort_by(.ts) | .[$i].files[$j].name // \"unknown\"")
            local_path=$(echo "$JSON" | jq -r ".messages | sort_by(.ts) | .[$i].files[$j].local_path // empty")

            if [[ -n "$local_path" ]]; then
                # File was downloaded - use relative path from output file
                # Wrap in <angle brackets> to handle special chars (spaces, parentheses, etc.)
                rel_path="attachments/$local_path"
                if is_image "$file_name"; then
                    echo "- ![${file_name}](<${rel_path}>)" >> "$OUTPUT_FILE"
                else
                    echo "- [${file_name}](<${rel_path}>)" >> "$OUTPUT_FILE"
                fi
            else
                # File not downloaded - just list the name
                echo "- ${file_name}" >> "$OUTPUT_FILE"
            fi
        done

        echo "" >> "$OUTPUT_FILE"
    fi
done

echo "Saved to $OUTPUT_FILE" >&2
echo "$OUTPUT_FILE"
