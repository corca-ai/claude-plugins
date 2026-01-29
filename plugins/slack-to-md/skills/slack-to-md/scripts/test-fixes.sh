#!/bin/bash
# Test script for two fixes in slack-to-md plugin:
#   1. File naming (no file.id prefix, collision handling with _N suffix)
#   2. Markdown link generation (angle brackets around paths)

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SLACK_TO_MD="$SCRIPT_DIR/slack-to-md.sh"
PASS=0
FAIL=0

pass() { echo "  PASS: $1"; PASS=$((PASS + 1)); }
fail() { echo "  FAIL: $1"; echo "        $2"; FAIL=$((FAIL + 1)); }

# ============================================================
# TEST 1: File naming logic (inline Node.js test)
# ============================================================
echo ""
echo "=== Test 1: File naming collision logic ==="
echo ""

node --input-type=module << 'NODEJS'
// Replicate the naming logic from slack-api.mjs downloadFile()
function resolveName(fileName, usedNames) {
  let localName = fileName;
  if (usedNames.has(localName)) {
    const dotIdx = localName.lastIndexOf('.');
    const base = dotIdx > 0 ? localName.slice(0, dotIdx) : localName;
    const ext  = dotIdx > 0 ? localName.slice(dotIdx) : '';
    let n = 2;
    while (usedNames.has(`${base}_${n}${ext}`)) n++;
    localName = `${base}_${n}${ext}`;
  }
  usedNames.add(localName);
  return localName;
}

let pass = 0, fail = 0;
function check(label, actual, expected) {
  if (actual === expected) {
    console.log(`  PASS: ${label}`);
    pass++;
  } else {
    console.log(`  FAIL: ${label}`);
    console.log(`        expected: "${expected}"`);
    console.log(`        actual:   "${actual}"`);
    fail++;
  }
}

const usedNames = new Set();

// 1a) Normal filename - used as-is (no file.id prefix)
const r1 = resolveName("report.pdf", usedNames);
check("Normal filename used as-is (no id prefix)", r1, "report.pdf");

// 1b) Duplicate filename - gets _2 suffix
const r2 = resolveName("report.pdf", usedNames);
check("Second duplicate gets _2 suffix", r2, "report_2.pdf");

// 1c) Third duplicate - gets _3 suffix
const r3 = resolveName("report.pdf", usedNames);
check("Third duplicate gets _3 suffix", r3, "report_3.pdf");

// 1d) Korean + special chars preserved
const usedNames2 = new Set();
const r4 = resolveName("36_(콘텐츠·문화예술)_토론과제.pdf", usedNames2);
check("Korean/special chars preserved as-is", r4, "36_(콘텐츠·문화예술)_토론과제.pdf");

// 1e) Spaces preserved
const r5 = resolveName("my document.pdf", usedNames2);
check("Spaces in filename preserved", r5, "my document.pdf");

// 1f) File with no extension
const usedNames3 = new Set();
const r6a = resolveName("README", usedNames3);
const r6b = resolveName("README", usedNames3);
check("No extension: first is as-is", r6a, "README");
check("No extension: duplicate gets _2 (no ext)", r6b, "README_2");

// Summary
console.log("");
console.log(`  Node.js naming tests: ${pass} passed, ${fail} failed`);
if (fail > 0) process.exit(1);
NODEJS

NODE_EXIT=$?

# ============================================================
# TEST 2: Markdown link generation via slack-to-md.sh
# ============================================================
echo ""
echo "=== Test 2: Markdown link generation ==="
echo ""

TMPDIR_TEST=$(mktemp -d)
OUTPUT_FILE="$TMPDIR_TEST/output.md"

# Build test JSON matching real slack-api.mjs output format
TEST_JSON='{
  "messages": [{
    "ts": "1700000000.000000",
    "user": "U123",
    "text": "test message",
    "files": [
      {
        "id": "F123",
        "name": "36_(콘텐츠·문화예술)_토론과제.pdf",
        "local_path": "36_(콘텐츠·문화예술)_토론과제.pdf"
      },
      {
        "id": "F456",
        "name": "my document.pdf",
        "local_path": "my document.pdf"
      },
      {
        "id": "F789",
        "name": "photo (1).png",
        "local_path": "photo (1).png"
      }
    ]
  }],
  "users": [{"id": "U123", "real_name": "Test User"}]
}'

echo "$TEST_JSON" | bash "$SLACK_TO_MD" "C123" "1700000000.000000" "testworkspace" "$OUTPUT_FILE" "Test Thread" 2>/dev/null

# 2a) Korean/parens filename wrapped in angle brackets
if grep -qF '[36_(콘텐츠·문화예술)_토론과제.pdf](<attachments/36_(콘텐츠·문화예술)_토론과제.pdf>)' "$OUTPUT_FILE"; then
    pass "Korean+parens filename has angle-bracket link"
else
    fail "Korean+parens filename angle-bracket link" "Pattern not found in output"
fi

# 2b) Spaces in filename wrapped in angle brackets
if grep -qF '[my document.pdf](<attachments/my document.pdf>)' "$OUTPUT_FILE"; then
    pass "Spaces filename has angle-bracket link"
else
    fail "Spaces filename angle-bracket link" "Pattern not found in output"
fi

# 2c) Image file uses ![](<...>) syntax
if grep -qF '![photo (1).png](<attachments/photo (1).png>)' "$OUTPUT_FILE"; then
    pass "Image file uses ![...](<...>) syntax with angle brackets"
else
    fail "Image file angle-bracket link" "Pattern not found in output"
fi

# 2d) No file.id prefix anywhere in paths (old format was F123_filename)
if grep -qE 'attachments/F[0-9]+_' "$OUTPUT_FILE"; then
    fail "No file.id prefix in paths" "Found old-style F<id>_ prefix in output"
else
    pass "No file.id prefix in attachment paths"
fi

# 2e) All links use angle brackets (no bare parenthetical paths)
# Correct: [...](<attachments/...>)   Wrong: [...](attachments/...)
# Use perl for portable regex (macOS grep lacks -P)
BARE_LINK_COUNT=$(perl -ne 'print if /\]\(attachments\/[^<]/' "$OUTPUT_FILE" | wc -l | tr -d ' ')
if [[ "$BARE_LINK_COUNT" -eq 0 ]]; then
    pass "All attachment links use angle brackets"
else
    fail "Some attachment links missing angle brackets" "Found $BARE_LINK_COUNT bare links"
fi

# Cleanup
rm -rf "$TMPDIR_TEST"

# ============================================================
# Summary
# ============================================================
echo ""
echo "==============================="
echo "  Shell tests: $PASS passed, $FAIL failed"
echo "==============================="
echo ""

if [[ "$FAIL" -gt 0 || "$NODE_EXIT" -ne 0 ]]; then
    echo "SOME TESTS FAILED"
    exit 1
else
    echo "ALL TESTS PASSED"
    exit 0
fi
