#!/usr/bin/env python3
"""Convert a public Notion page to a local Markdown file.

Usage:
    python3 notion-to-md.py <notion_url> [output_path]

Supported URL formats:
    https://workspace.notion.site/Title-{32hex}
    https://www.notion.so/Title-{32hex}
    https://www.notion.so/{32hex}
    32-character hex string (bare page ID)

Requirements: Python 3.7+, no external dependencies.
"""

import json
import os
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

API_URL = "https://www.notion.so/api/v3/loadPageChunk"
HEADERS = {
    "Content-Type": "application/json",
    "User-Agent": "Mozilla/5.0 notion-to-md/1.0",
    "Accept": "application/json",
}
HTTP_TIMEOUT = 30
MAX_RETRIES = 3
MAX_CHUNKS = 50


def eprint(*args, **kwargs):
    """Print to stderr."""
    print(*args, file=sys.stderr, **kwargs)


# ---------------------------------------------------------------------------
# 1. URL Parsing
# ---------------------------------------------------------------------------

def parse_notion_url(url: str) -> str:
    """Extract page ID from a Notion URL and return as UUID format.

    Accepts:
        - Full Notion URL (notion.site or notion.so)
        - 32-char hex string (bare ID)
        - UUID with dashes (36 chars)
    """
    raw = url.strip().rstrip("/")

    # Strip query/fragment
    raw = urllib.parse.urlparse(raw).path if raw.startswith("http") else raw

    # Find last 32 hex chars (ignoring dashes)
    clean = raw.replace("-", "")
    match = re.search(r"([0-9a-f]{32})\s*$", clean, re.IGNORECASE)
    if not match:
        raise ValueError(
            f"Cannot extract page ID from: {url}\n"
            "Supported formats:\n"
            "  https://workspace.notion.site/Title-{32hex}\n"
            "  https://www.notion.so/Title-{32hex}\n"
            "  32-character hex string"
        )

    hex_id = match.group(1).lower()
    return f"{hex_id[:8]}-{hex_id[8:12]}-{hex_id[12:16]}-{hex_id[16:20]}-{hex_id[20:]}"


# ---------------------------------------------------------------------------
# 2. HTTP / API
# ---------------------------------------------------------------------------

def _api_request(payload: dict) -> dict:
    """POST to Notion v3 API with retry and timeout."""
    data = json.dumps(payload).encode("utf-8")

    for attempt in range(MAX_RETRIES):
        try:
            req = urllib.request.Request(API_URL, data=data, headers=HEADERS)
            with urllib.request.urlopen(req, timeout=HTTP_TIMEOUT) as resp:
                return json.loads(resp.read().decode("utf-8"))
        except urllib.error.HTTPError as e:
            if e.code in (429, 500, 502, 503) and attempt < MAX_RETRIES - 1:
                wait = 2 ** attempt
                eprint(f"  HTTP {e.code}, retrying in {wait}s...")
                time.sleep(wait)
                continue
            if e.code in (401, 403):
                raise RuntimeError(
                    "Page not accessible. Ensure the page is published to the web "
                    "via Share > Publish in Notion."
                ) from e
            raise RuntimeError(f"HTTP error {e.code}: {e.reason}") from e
        except urllib.error.URLError as e:
            if attempt < MAX_RETRIES - 1:
                wait = 2 ** attempt
                eprint(f"  Network error, retrying in {wait}s...")
                time.sleep(wait)
                continue
            raise RuntimeError(f"Network error: {e.reason}") from e

    raise RuntimeError("Max retries exceeded")


def fetch_page(page_id: str) -> tuple:
    """Fetch all blocks for a page with automatic pagination.

    Returns: (block_map, page_title)
    """
    eprint("Fetching page...")
    block_map = {}
    cursor = {"stack": []}
    chunk_number = 0

    while chunk_number < MAX_CHUNKS:
        payload = {
            "page": {"id": page_id},
            "limit": 100,
            "cursor": cursor,
            "chunkNumber": chunk_number,
            "verticalColumns": False,
        }
        resp = _api_request(payload)

        # Merge blocks (last-write-wins)
        blocks = resp.get("recordMap", {}).get("block", {})
        for bid, bdata in blocks.items():
            value = bdata.get("value")
            if value:
                block_map[bid] = value

        # Check pagination
        next_cursor = resp.get("cursor", {})
        if not next_cursor.get("stack"):
            break
        cursor = next_cursor
        chunk_number += 1

    if chunk_number >= MAX_CHUNKS:
        eprint(f"  Warning: reached max {MAX_CHUNKS} chunks, some content may be missing.")

    # Extract page title
    page_block = block_map.get(page_id, {})
    title_arr = page_block.get("properties", {}).get("title")
    page_title = render_rich_text(title_arr)

    eprint(f"  Fetched {len(block_map)} blocks")
    return block_map, page_title


# ---------------------------------------------------------------------------
# 3. Rich Text
# ---------------------------------------------------------------------------

def render_rich_text(title_array) -> str:
    """Convert Notion rich text array to Markdown inline text.

    Format: [[text, [[format_code, value?], ...]], ...]
    """
    if not title_array:
        return ""

    parts = []
    for segment in title_array:
        if not segment or not isinstance(segment, list):
            continue

        text = segment[0] if segment else ""
        if not isinstance(text, str):
            continue

        formats = segment[1] if len(segment) > 1 else []

        if not formats:
            parts.append(text)
            continue

        # Parse format codes
        is_bold = False
        is_italic = False
        is_code = False
        is_strike = False
        link_url = None

        for fmt in formats:
            if not isinstance(fmt, list) or not fmt:
                continue
            code = fmt[0]
            if code == "b":
                is_bold = True
            elif code == "i":
                is_italic = True
            elif code == "c":
                is_code = True
            elif code == "s":
                is_strike = True
            elif code == "a" and len(fmt) > 1:
                link_url = fmt[1]
            # h (highlight), _ (underline) → ignored

        # Apply formats: code wins (no nesting inside backticks)
        if is_code:
            result = f"`{text}`"
        else:
            result = text
            if is_bold and is_italic:
                result = f"***{result}***"
            elif is_bold:
                result = f"**{result}**"
            elif is_italic:
                result = f"*{result}*"
            if is_strike:
                result = f"~~{result}~~"

        if link_url and link_url.startswith(("http://", "https://")):
            result = f"[{result}]({link_url})"

        parts.append(result)

    return "".join(parts)


# ---------------------------------------------------------------------------
# 4. Block Conversion
# ---------------------------------------------------------------------------

def convert_table(table_block: dict, block_map: dict) -> str:
    """Convert a table block and its row children to GFM table."""
    fmt = table_block.get("format", {})
    col_order = fmt.get("table_block_column_order", [])
    has_header = fmt.get("table_block_column_header", False)
    content_ids = table_block.get("content", [])

    if not col_order or not content_ids:
        return ""

    rows = []
    for row_id in content_ids:
        row_block = block_map.get(row_id, {})
        props = row_block.get("properties", {})
        cells = []
        for col_id in col_order:
            cell_val = render_rich_text(props.get(col_id))
            # Escape pipes and newlines in cell content
            cell_val = cell_val.replace("|", "\\|").replace("\n", "<br>")
            cells.append(cell_val)
        rows.append(cells)

    if not rows:
        return ""

    lines = []
    num_cols = len(col_order)

    if has_header and len(rows) > 0:
        header = rows[0]
        lines.append("| " + " | ".join(header) + " |")
        lines.append("| " + " | ".join(["---"] * num_cols) + " |")
        data_rows = rows[1:]
    else:
        # No header: generate empty header
        lines.append("| " + " | ".join([""] * num_cols) + " |")
        lines.append("| " + " | ".join(["---"] * num_cols) + " |")
        data_rows = rows

    for row in data_rows:
        lines.append("| " + " | ".join(row) + " |")

    return "\n".join(lines)


def convert_block(block: dict, block_map: dict, depth: int, visited: set) -> str:
    """Convert a single Notion block to Markdown."""
    block_id = block.get("id", "")
    block_type = block.get("type", "")
    props = block.get("properties", {})
    fmt = block.get("format", {})
    title = render_rich_text(props.get("title"))
    content_ids = block.get("content", [])
    indent = "  " * depth

    result = ""

    if block_type == "page":
        # Root page title is rendered by blocks_to_markdown, not here.
        # Sub-page references render as bold text (not H1).
        result = f"**{title}**" if title else ""

    elif block_type == "header":
        result = f"# {title}"

    elif block_type == "sub_header":
        result = f"## {title}"

    elif block_type == "sub_sub_header":
        result = f"### {title}"

    elif block_type == "text":
        result = title if title else ""

    elif block_type == "bulleted_list":
        result = f"{indent}- {title}"

    elif block_type == "numbered_list":
        result = f"{indent}1. {title}"

    elif block_type == "quote":
        result = f"> {title}"

    elif block_type == "divider":
        result = "---"

    elif block_type == "code":
        lang = render_rich_text(props.get("language"))
        # Code block content: plain text only, no Markdown formatting
        code_text = "".join(
            seg[0] for seg in (props.get("title") or [])
            if isinstance(seg, list) and seg and isinstance(seg[0], str)
        )
        result = f"```{lang}\n{code_text}\n```"

    elif block_type == "to_do":
        checked = props.get("checked", [])
        is_checked = checked and checked[0] and checked[0][0] == "Yes"
        mark = "x" if is_checked else " "
        result = f"- [{mark}] {title}"

    elif block_type == "toggle":
        result = f"**{title}**"

    elif block_type == "callout":
        icon = fmt.get("page_icon", "")
        prefix = f"{icon} " if icon else ""
        result = f"> {prefix}{title}"

    elif block_type == "image":
        source = fmt.get("display_source", "")
        if not source:
            try:
                source = props.get("source", [[""]])[0][0]
            except (IndexError, TypeError):
                source = ""
        caption = render_rich_text(props.get("caption")) or title
        if source and source.startswith(("http://", "https://")):
            result = f"![{caption}]({source})"

    elif block_type == "bookmark":
        try:
            link = props.get("link", [[""]])[0][0] if props.get("link") else ""
        except (IndexError, TypeError):
            link = ""
        bookmark_title = title or link
        if link and link.startswith(("http://", "https://")):
            result = f"[{bookmark_title}]({link})"

    elif block_type in ("column_list", "column"):
        # Layout blocks: just render children
        pass

    elif block_type == "table":
        result = convert_table(block, block_map)

    elif block_type == "table_row":
        # Handled by convert_table
        pass

    elif block_type:
        result = f"<!-- unsupported: {block_type} -->"

    # Recurse into children (except table and table_row)
    if content_ids and block_type not in ("table", "table_row"):
        children_md = _render_children(content_ids, block_map, depth, block_type, visited)
        if children_md:
            if block_type in ("quote",):
                # Prefix children with >
                children_lines = children_md.split("\n")
                children_md = "\n".join(f"> {line}" for line in children_lines)
            if result:
                result = result + "\n" + children_md
            else:
                result = children_md

    return result


def _render_children(content_ids: list, block_map: dict, depth: int,
                     parent_type: str, visited: set) -> str:
    """Render a list of child block IDs."""
    parts = []
    child_depth = depth
    if parent_type in ("bulleted_list", "numbered_list"):
        child_depth = depth + 1

    for child_id in content_ids:
        if child_id in visited:
            continue
        visited.add(child_id)

        child_block = block_map.get(child_id)
        if not child_block:
            parts.append(f"<!-- missing block: {child_id} -->")
            continue

        md = convert_block(child_block, block_map, child_depth, visited)
        if md is not None:
            parts.append(md)

    return "\n".join(parts)


def blocks_to_markdown(page_id: str, block_map: dict) -> str:
    """Convert the block tree starting from page root to Markdown."""
    page_block = block_map.get(page_id, {})
    title = render_rich_text(page_block.get("properties", {}).get("title"))
    content_ids = page_block.get("content", [])

    visited = {page_id}
    lines = []

    if title:
        lines.append(f"# {title}")
        lines.append("")

    for child_id in content_ids:
        if child_id in visited:
            continue
        visited.add(child_id)

        child_block = block_map.get(child_id)
        if not child_block:
            lines.append(f"<!-- missing block: {child_id} -->")
            continue

        md = convert_block(child_block, block_map, 0, visited)
        if md:
            lines.append(md)
            # Add blank line between non-list blocks
            child_type = child_block.get("type", "")
            if child_type not in ("bulleted_list", "numbered_list"):
                lines.append("")

    return "\n".join(lines).rstrip() + "\n"


# ---------------------------------------------------------------------------
# 5. Filename
# ---------------------------------------------------------------------------

def sanitize_filename(title: str) -> str:
    """Convert page title to a safe filename."""
    if not title:
        return "notion-export"

    # Remove dangerous characters
    name = re.sub(r'[/\\:*?"<>|]', "", title)
    # Remove .. sequences
    name = name.replace("..", "")
    # Remove leading dots
    name = name.lstrip(".")
    # Spaces to hyphens
    name = re.sub(r"\s+", "-", name.strip())
    # Truncate
    name = name[:200]
    # Fallback
    return name if name else "notion-export"


# ---------------------------------------------------------------------------
# 6. Main
# ---------------------------------------------------------------------------

def main():
    if len(sys.argv) < 2 or sys.argv[1] in ("-h", "--help"):
        print(__doc__.strip())
        sys.exit(0 if sys.argv[1:] and sys.argv[1] in ("-h", "--help") else 1)

    url = sys.argv[1]
    output_path = sys.argv[2] if len(sys.argv) > 2 else None

    try:
        page_id = parse_notion_url(url)
        eprint(f"  Page ID: {page_id}")

        block_map, page_title = fetch_page(page_id)

        if not output_path:
            filename = sanitize_filename(page_title) + ".md"
            output_dir = os.environ.get("CLAUDE_CORCA_NOTION_TO_MD_OUTPUT_DIR", "./notion-outputs")
            os.makedirs(output_dir, exist_ok=True)
            output_path = os.path.join(output_dir, filename)

        # Path validation: reject paths outside current directory
        real_path = os.path.realpath(output_path)
        cwd = os.path.realpath(".")
        if not (real_path == cwd or real_path.startswith(cwd + os.sep)):
            raise ValueError(f"Output path must be within current directory: {output_path}")

        markdown = blocks_to_markdown(page_id, block_map)

        with open(output_path, "w", encoding="utf-8") as f:
            f.write(markdown)

        eprint(f"  Saved: {output_path} ({len(markdown)} bytes)")

    except (ValueError, RuntimeError) as e:
        eprint(f"Error: {e}")
        sys.exit(1)
    except KeyboardInterrupt:
        eprint("\nAborted.")
        sys.exit(1)


if __name__ == "__main__":
    main()
