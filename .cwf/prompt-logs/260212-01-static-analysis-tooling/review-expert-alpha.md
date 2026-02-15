### Expert Reviewer Alpha: John Ousterhout

**Framework Context**: Deep vs. shallow modules, information leakage, strategic vs. tactical programming, interface complexity -- grounded in *A Philosophy of Software Design* (2nd edition, 2021), particularly chapters on deep modules (Ch. 4), information hiding and leakage (Ch. 5), general-purpose modules are deeper (Ch. 6), and define errors out of existence (Ch. 10).

---

#### Analysis Preamble

The central thesis of *A Philosophy of Software Design* is that the primary source of software complexity is **dependencies** (things you need to know to understand or modify a piece of code) and **obscurity** (important information that is not obvious). The antidote is modules that are "deep" -- providing powerful functionality behind simple interfaces, hiding complexity rather than leaking it. A "shallow" module, by contrast, has an interface nearly as complex as its implementation, offering little abstraction benefit and contributing to what I term "interface bloat."

Strategic programming invests in good design now to reduce total complexity over the system's lifetime. Tactical programming optimizes for getting something working quickly, accumulating complexity incrementally through small design compromises that compound over time.

The implementation under review consists of 5 standalone scripts (92-390 lines each), 3 JSON schemas, and supporting configuration files. I analyze whether these scripts are **deep modules** providing meaningful abstraction, whether they exhibit **information leakage** across boundaries, and whether the overall approach reflects **strategic or tactical** design thinking.

---

#### Concerns (blocking)

- [Medium] **`doc-graph.mjs` is a shallow module with a complex, leaking implementation surface.**

  At 390 lines, `doc-graph.mjs` is the largest script in this set, yet its interface complexity approaches its implementation complexity. The script exposes four modes (`--orphans`, `--impact <file>`, `--json`, default summary), each producing a different output structure with different exit code semantics (`--impact` always exits 0; others exit 1 on findings). A caller must understand these mode-specific behaviors to use the script correctly. This is the definition of a shallow module: the interface does not simplify the underlying complexity; it mirrors it.

  More concerning is the internal implementation leakage. The `readdirRecursive` function at line 113 uses an unnecessary indirection pattern -- `await_import_fs()` (line 137) wraps an already-imported `readdirSyncImpl` (line 141) in a function that returns an object `{ readdirSync: readdirSyncImpl }`. This is pure implementation noise: a workaround artifact that leaks into the code structure without serving any abstraction purpose. The comment "Synchronous fs import workaround (already imported at top)" confirms it was a tactical fix rather than a design choice.

  Additionally, the output section (lines 276-379) contains duplicated JSON construction logic: lines 276-290 and lines 330-344 produce identical JSON output objects for two different code paths (`mode === 'json'` and `mode === 'summary' && jsonOutput`). This is information leakage through code duplication -- a change to the JSON output schema requires modification in two places within the same file.

  **Specific references**: `scripts/doc-graph.mjs` lines 113-141 (await_import_fs indirection), lines 276-290 vs. 330-344 (duplicated JSON output), lines 384-390 (mode-dependent exit code semantics).

  **Recommendation**: Collapse the duplicated JSON output paths. Remove the `await_import_fs` indirection entirely -- import `readdirSync` at the top and use it directly. Consider whether `--impact` mode belongs in this script at all or whether it should be a separate deep module with a clear single-purpose interface: "given a file, who references it?"

- [Medium] **`check-schemas.sh` target parsing is a shallow abstraction that leaks its encoding format.**

  The `validate_target` function (line 97) accepts a colon-delimited string `"schema_file:data_file[:converter]"` and then immediately re-parses it using bash string operations (`${spec%%:*}`, `${rest#*:}`, etc.). This is a textbook example of what *A Philosophy of Software Design* Ch. 4 describes as a "pass-through method" -- a function whose interface is essentially the same as its implementation. The caller must understand the colon-delimited encoding to construct the target spec; the function must re-parse it to use it. The encoding format leaks in both directions.

  The guard `if [[ "$converter" == "$data" ]]; then converter="" fi` (line 105) is a semantic hack: it detects the absence of a converter field by checking whether parameter expansion produced an unchanged string. This is obscurity in the sense of *A Philosophy of Software Design* Ch. 5 -- an important behavioral detail (how to signal "no converter") that is non-obvious from reading the interface.

  **Specific references**: `scripts/check-schemas.sh` lines 87-91 (target encoding), lines 97-145 (validate_target function), lines 105-107 (converter detection hack).

  **Recommendation**: Define the targets as parallel arrays or as separate function arguments rather than encoding structured data into a delimited string that must be parsed. For example: `validate_target "$schema" "$data" "$converter"` eliminates the encoding layer entirely. Alternatively, since there are only 3 targets, inline the calls: `validate_yaml "cwf-state.schema.json" "cwf-state.yaml"` and `validate_json "plugin.schema.json" "plugins/cwf/.claude-plugin/plugin.json"`. This would make each validation call self-documenting.

---

#### Suggestions (non-blocking)

- **`check-links.sh` is the deepest module in this set -- and that is the right design.**

  At 92 lines, `check-links.sh` provides the simplest interface (`--local`, `--json`, `--help`) while hiding the most complexity (lychee configuration, path exclusions via `.lychee.toml`, caching behavior, concurrency settings, HTTP status code acceptance rules). The caller does not need to understand any of lychee's 40+ configuration options to use this script. The `.lychee.toml` file acts as what Ch. 5 calls a "private" implementation detail -- it is hidden behind the script's interface. This is deep module design: simple interface, significant functionality hidden below.

  The other scripts should aspire to this ratio. `find-duplicates.py` comes close: its core interface (`--threshold`, `--json`, `--shingle-size`) hides the MinHash/LSH algorithm, the block extraction logic, and the query-before-insert self-match prevention strategy. The `--shingle-size` flag is the one interface element that leaks implementation detail (shingles are an algorithm concept, not a user concept), but the help text partially compensates.

- **The 5 scripts collectively exhibit "information leakage through convention replication."**

  *A Philosophy of Software Design* Ch. 5 defines information leakage as occurring when "the same knowledge is used in multiple places." The TTY-guarded color pattern (`if [[ -t 1 ]] && [[ "$JSON_OUTPUT" != "true" ]]; then RED=...; fi`) is implemented identically in `check-links.sh` (line 42), `check-schemas.sh` (line 34), and `doc-churn.sh` (line 69). The Python equivalent appears in `find-duplicates.py` (line 181: `_init_colors(sys.stdout.isatty() and not args.json)`), and the Node.js equivalent in `doc-graph.mjs` (line 65: `const useColor = process.stdout.isTTY && !jsonOutput`).

  This is a design decision replicated five times in three languages. If the color convention changes (e.g., adding `NO_COLOR` environment variable support, which is an emerging standard), all five implementations must be updated independently. The previous plan-phase reviewer (Parnas) flagged this same pattern from an information-hiding perspective. From the Ousterhout framework, this is specifically "temporal decomposition" (Ch. 5) -- the scripts were decomposed by what each tool does sequentially, rather than by what information each should hide. The color/output convention is a cross-cutting design decision that should live in one place.

  However, I observe a pragmatic tension: extracting shared behavior across three languages (Bash, Node.js, Python) requires either a shared configuration file that each language reads, or a wrapper layer that each script calls. Both introduce coupling that may not be justified for 5 scripts. The strategic question is whether this tool suite will grow beyond 5 scripts. If it will, the extraction pays for itself. If it stabilizes at 5, the replication is an acceptable tactical debt.

- **The `find-duplicates.py` _C color class is an example of good depth despite small scale.**

  The `_C` class (line 50) and `_init_colors()` function (line 60) hide the ANSI escape code details behind named attributes. This is a micro-level deep module: the interface (`_C.BOLD`, `_C.GREEN`, etc.) is simpler than what it hides (the conditional initialization, the TTY detection, the JSON-mode suppression). The rest of the script uses `_C.CYAN` without knowing how color enablement was decided. This is the right instinct applied at small scale. The bash scripts, by contrast, expose the color variable names (`$RED`, `$GREEN`) at the same level as the conditional logic that sets them -- a flatter, shallower approach.

- **`doc-churn.sh` defines errors out of existence in the right way.**

  Chapter 10 of *A Philosophy of Software Design* argues that the best way to handle exceptions is to define them out of existence -- design the normal case so that special cases do not arise. `doc-churn.sh` does this by unconditionally exiting 0 (line 227): since it is an informational tool, there is no error case to handle. The untracked-file guard (lines 159-164, checking `if [[ -z "$last_epoch" ]]` and defaulting to "unknown" status) is another good example -- rather than crashing on files with no git history, it defines the normal behavior to include that case. Compare this with how `check-schemas.sh` handles validation failure: it could have let `set -e` abort on the first failure (the default bash behavior), but instead it wraps `validate_target` in an `if` block (line 159: `if validate_target "$pair"`) that captures failure as a normal result. Both scripts define their error conditions out of existence at the interface level.

- **The JSON output construction in bash scripts is a tactical pattern that will not scale.**

  `check-schemas.sh` (lines 161-164) and `doc-churn.sh` (lines 190-199) both construct JSON by concatenating `printf`-formatted strings with manual comma management (`if [[ -n "$json_results" ]]; then json_results="$json_results,"; fi`). This is a tactical approach: it works for the current output structure, but any structural change (nested objects, arrays within entries, special characters in values) requires rethinking the concatenation logic. The Python script uses `json.dumps` (line 254) and the Node.js script uses `JSON.stringify` (line 290) -- proper serializers that hide JSON formatting complexity. The bash scripts cannot easily use equivalent tooling without adding a `jq` dependency. This is not a defect but an inherent shallowness of using bash for structured output. The strategic alternative would be to pipe bash-collected data through `jq` for JSON construction, but this adds a dependency. Documenting this limitation would be sufficient.

- **Schema design demonstrates strategic thinking.**

  The differentiation between `additionalProperties: true` in `cwf-state.schema.json` and `plugin.schema.json` versus `additionalProperties: false` in `hooks.schema.json` (on the hooks object, with an explanatory `$comment` at line 12) reflects strategic reasoning about which boundaries should be permissive vs. strict. The `$comment` field in `hooks.schema.json` -- "Unknown event names indicate drift -- the Claude hooks runtime only supports these 7 event types" -- is exactly the kind of documentation *A Philosophy of Software Design* Ch. 13 advocates: it explains the *why* behind a design decision, not just the *what*. This is one of the strongest design decisions in the implementation.

---

#### Behavioral Criteria Verification

**Behavioral (BDD)**

- [PASS] `check-links.sh` validates internal links: wraps lychee with `.lychee.toml` config that includes `exclude_path = ["prompt-logs/"]` and `include_fragments = true`. `--local` maps to `--offline`. Exit code passes through from lychee (0 = clean, non-zero = broken links).
- [PASS] `doc-graph.mjs` detects orphan documents: lines 255-262 filter orphans by checking `!inbound[f] || inbound[f].length === 0`, with root-level file exclusions at lines 246-252. Handles anchor fragments correctly at lines 175-179 (strips `#fragment` before path resolution).
- [PASS] `find-duplicates.py` reports near-duplicate blocks without self-matches: lines 228-246 implement query-before-insert pattern (`lsh.query(mh)` before `lsh.insert(key, mh)`), which inherently prevents self-matches and produces each pair exactly once.
- [PASS] `check-schemas.sh` validates all config files per-file without aborting: lines 154-179 use a `failed=0` counter with `if validate_target` pattern that prevents `set -e` from aborting on first failure.
- [PASS] `doc-churn.sh` reports staleness per file with classification: lines 112-125 implement `classify_status()` returning fresh/current/stale/archival based on epoch thresholds.
- [PASS] All scripts respond to `--help` (exit 0) and exit 1 on missing deps: verified in each script's argument parsing and dependency check sections.

**Qualitative**

- [PASS] TTY-guarded color with `--json` suppression: all 5 scripts implement the combined guard.
- [PASS] Each script independently runnable: no shared runtime dependencies between scripts.
- [PASS] JSON output valid: Python and Node.js use native serializers; bash uses manual construction (functional but fragile, as noted above).
- [PASS] No shared state between scripts: each script discovers its own context (repo root, file list, exclusions) independently.
- [PASS] Exit code taxonomy: 0 = success, 1 = findings, except `doc-churn.sh` (always 0).

---

#### Verdict

The implementation reflects **primarily strategic design** with some tactical compromises. The scripts are well-structured as independent tools, and the best of them (`check-links.sh`, `find-duplicates.py`) are genuinely deep modules that provide simple interfaces over meaningful complexity. The schemas demonstrate thoughtful strategic reasoning about where to be strict versus permissive.

The two blocking concerns are both instances of **shallow modules** -- `doc-graph.mjs` with its duplicated output paths and implementation-leaking indirections, and `check-schemas.sh` with its string-encoded target specification that leaks its parsing format. Neither is architecturally fatal; both are fixable without structural changes.

The replicated conventions across scripts are an acceptable tactical debt at the current scale of 5 scripts, but would become a strategic liability if the suite grows. The implementation is ready for use with the caveat that the `doc-graph.mjs` code quality should be cleaned up before it becomes a template for future scripts.

**Overall: Conditional Pass** -- address the `doc-graph.mjs` duplicated JSON output and `await_import_fs` indirection; the `check-schemas.sh` target encoding is lower priority but worth improving if touched again.

---

#### Provenance
- source: REAL_EXECUTION
- tool: claude-code
- expert: John Ousterhout
- framework: deep vs. shallow modules, information leakage, strategic vs. tactical programming, interface complexity
- grounding: *A Philosophy of Software Design*, 2nd edition (2021) -- Ch. 4 (Modules Should Be Deep), Ch. 5 (Information Hiding and Leakage), Ch. 6 (General-Purpose Modules are Deeper), Ch. 10 (Define Errors Out of Existence), Ch. 13 (Comments Should Describe Things That Aren't Obvious)
<!-- AGENT_COMPLETE -->
