#!/usr/bin/env python3
"""find-duplicates.py — Detect near-duplicate content blocks across Markdown files.

Uses MinHash/LSH (datasketch) to find blocks with high Jaccard similarity.
Blocks are defined by Markdown headings; each heading section becomes a block.

Usage:
    find-duplicates.py [--threshold N] [--shingle-size N] [--json] [--include-prompt-logs] [-h]

Options:
    --threshold N          Jaccard similarity threshold (default: 0.7)
    --shingle-size N       Word window size for similarity comparison (default: 3)
    --json                 Output as JSON array
    --include-prompt-logs  Also scan prompt-log artifact directories (off by default)
    -h, --help             Show this help message and exit

Exit codes:
    0  No duplicates above threshold found
    1  Duplicates above threshold found
"""

import argparse
import json
import re
import string
import sys
from pathlib import Path

try:
    from datasketch import MinHash, MinHashLSH
except ImportError:
    print(
        "Error: datasketch is required but not installed.\n"
        "Install it with: pip install --user datasketch",
        file=sys.stderr,
    )
    sys.exit(1)


def eprint(*args, **kwargs):
    """Print to stderr."""
    print(*args, file=sys.stderr, **kwargs)


# --- Color helpers -----------------------------------------------------------

USE_COLOR = False  # set in main() after arg parsing


class _C:
    """ANSI color codes, populated based on TTY detection."""

    BOLD = ""
    GREEN = ""
    YELLOW = ""
    CYAN = ""
    NC = ""


def _init_colors(enabled: bool) -> None:
    global USE_COLOR
    USE_COLOR = enabled
    if enabled:
        _C.BOLD = "\033[1m"
        _C.GREEN = "\033[0;32m"
        _C.YELLOW = "\033[1;33m"
        _C.CYAN = "\033[0;36m"
        _C.NC = "\033[0m"


# --- Block extraction --------------------------------------------------------

HEADING_RE = re.compile(r"^#{1,6}\s+", re.MULTILINE)
PUNCTUATION_TABLE = str.maketrans("", "", string.punctuation)


def _extract_blocks(filepath: Path):
    """Split a Markdown file into (title, line_number, text) blocks by headings.

    Blocks smaller than 3 lines or 20 words are discarded.
    """
    try:
        text = filepath.read_text(encoding="utf-8", errors="replace")
    except OSError as exc:
        eprint(f"Warning: cannot read {filepath}: {exc}")
        return

    lines = text.splitlines(keepends=True)
    if not lines:
        return

    # Find heading positions
    heading_positions = []  # (line_index, title_text)
    for idx, line in enumerate(lines):
        if HEADING_RE.match(line):
            title = HEADING_RE.sub("", line).strip()
            heading_positions.append((idx, title))

    # Build blocks
    blocks = []  # (title, start_line_1indexed, content_lines)
    if not heading_positions:
        # Entire file is one block
        blocks.append((filepath.name, 1, lines))
    else:
        # Content before first heading
        if heading_positions[0][0] > 0:
            blocks.append(
                (filepath.name, 1, lines[: heading_positions[0][0]])
            )
        # Each heading section
        for i, (start, title) in enumerate(heading_positions):
            end = (
                heading_positions[i + 1][0]
                if i + 1 < len(heading_positions)
                else len(lines)
            )
            blocks.append((title, start + 1, lines[start:end]))

    # Filter by minimum size
    for title, line_no, content_lines in blocks:
        if len(content_lines) < 3:
            continue
        word_count = sum(len(l.split()) for l in content_lines)
        if word_count < 20:
            continue
        yield title, line_no, "".join(content_lines)


# --- Shingling & MinHash -----------------------------------------------------


def _shingle(text: str, k: int):
    """Generate word-level k-shingles from text (lowercased, no punctuation)."""
    words = text.lower().translate(PUNCTUATION_TABLE).split()
    if len(words) < k:
        return set()
    return {" ".join(words[i : i + k]) for i in range(len(words) - k + 1)}


def _make_minhash(shingles: set, num_perm: int = 128) -> MinHash:
    mh = MinHash(num_perm=num_perm)
    for s in shingles:
        mh.update(s.encode("utf-8"))
    return mh


# --- Main logic --------------------------------------------------------------


def main():
    parser = argparse.ArgumentParser(
        description="Detect near-duplicate content blocks across Markdown files."
    )
    parser.add_argument(
        "--threshold",
        type=float,
        default=0.7,
        help="Jaccard similarity threshold (default: 0.7)",
    )
    parser.add_argument(
        "--shingle-size",
        type=int,
        default=3,
        help="Word window size for similarity comparison (default: 3)",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        default=False,
        help="Output as JSON array",
    )
    parser.add_argument(
        "--include-prompt-logs",
        action="store_true",
        default=False,
        help="Also scan prompt-log artifact directories (off by default)",
    )
    args = parser.parse_args()

    # Color: enabled only when stdout is a TTY and not in JSON mode
    _init_colors(sys.stdout.isatty() and not args.json)

    # Discover repo root (same heuristic as sibling scripts)
    repo_root = Path(__file__).resolve().parent.parent

    # Collect target .md files (no symlink following)
    md_files = sorted(repo_root.rglob("*.md"))

    # Always exclude non-documentation directories
    always_exclude = [repo_root / "node_modules", repo_root / ".git"]
    # Also exclude nested node_modules (e.g., scripts/node_modules/)
    md_files = [
        f for f in md_files
        if not any(part == "node_modules" or part == ".git" for part in f.relative_to(repo_root).parts)
    ]

    # Filter out prompt-log artifact directories unless requested
    if not args.include_prompt_logs:
        prompt_logs_dir = repo_root / "prompt-logs"
        prompt_logs_cwf_dir = repo_root / ".cwf" / "prompt-logs"
        md_files = [
            f
            for f in md_files
            if not _is_under(f, prompt_logs_dir) and not _is_under(f, prompt_logs_cwf_dir)
        ]

    if not md_files:
        eprint("No Markdown files found.")
        sys.exit(0)

    # Build blocks
    BlockInfo = tuple  # (filepath, title, line_no, minhash)
    block_index: list[tuple[Path, str, int, MinHash]] = []
    lsh = MinHashLSH(threshold=args.threshold, num_perm=128)

    duplicates: list[dict] = []

    block_counter = 0
    for fpath in md_files:
        rel = fpath.relative_to(repo_root)
        for title, line_no, content in _extract_blocks(fpath):
            shingles = _shingle(content, args.shingle_size)
            if not shingles:
                continue
            mh = _make_minhash(shingles)
            key = f"b{block_counter}"
            block_counter += 1

            # Query BEFORE insert to find matches (avoids self-match, each pair once)
            candidates = lsh.query(mh)
            for cand_key in candidates:
                cand_idx = int(cand_key[1:])
                cand_path, cand_title, cand_line, cand_mh = block_index[cand_idx]
                sim = mh.jaccard(cand_mh)
                if sim >= args.threshold:
                    duplicates.append(
                        {
                            "file_a": str(cand_path.relative_to(repo_root)),
                            "line_a": cand_line,
                            "file_b": str(rel),
                            "line_b": line_no,
                            "similarity": round(sim, 2),
                            "block_header": title,
                        }
                    )

            lsh.insert(key, mh)
            block_index.append((fpath, title, line_no, mh))

    # Sort by similarity descending
    duplicates.sort(key=lambda d: d["similarity"], reverse=True)

    # Output
    if args.json:
        print(json.dumps(duplicates, indent=2))
    else:
        if not duplicates:
            eprint("No near-duplicate blocks found above threshold.")
        else:
            eprint(
                f"Found {len(duplicates)} duplicate pair(s) "
                f"(threshold >= {args.threshold}):\n"
            )
            for d in duplicates:
                sim_str = f"{d['similarity']:.2f}"
                if USE_COLOR:
                    print(
                        f"  {_C.CYAN}{d['file_a']}:{d['line_a']}{_C.NC}"
                        f" {_C.YELLOW}->{_C.NC} "
                        f"{_C.CYAN}{d['file_b']}:{d['line_b']}{_C.NC}"
                        f" (similarity: {_C.GREEN}{sim_str}{_C.NC})"
                        f' "{_C.BOLD}{d["block_header"]}{_C.NC}"'
                    )
                else:
                    print(
                        f"  {d['file_a']}:{d['line_a']}"
                        f" -> {d['file_b']}:{d['line_b']}"
                        f" (similarity: {sim_str})"
                        f' "{d["block_header"]}"'
                    )

    # Exit code: 0 = clean, 1 = duplicates found
    sys.exit(1 if duplicates else 0)


def _is_under(child: Path, parent: Path) -> bool:
    """Check if *child* is inside *parent* (both must be resolved)."""
    try:
        child.resolve().relative_to(parent.resolve())
        return True
    except ValueError:
        return False


if __name__ == "__main__":
    main()
