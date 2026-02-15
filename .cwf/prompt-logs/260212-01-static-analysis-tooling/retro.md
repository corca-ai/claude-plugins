# Retro: Static Analysis Tooling Integration

> Session date: 2026-02-12
> Mode: deep

## 1. Context Worth Remembering

- The repo now hosts a **mixed-paradigm `scripts/` directory**: bash (.sh), Node.js (.mjs), Python (.py), plus `scripts/package.json` (private, ESM), `scripts/package-lock.json`, `scripts/node_modules/`, and `scripts/schemas/`. This is cosmetically suboptimal but structurally functional — each tool uses the language best suited to its task.
- **Schema validation** uses ajv-cli@5 + yq (mikefarah/Go variant), chosen for JSON Schema standard portability over Python-native alternatives like yamale. Schemas use `$defs` for reusable definitions and `$comment` for rationale documentation.
- **datasketch threshold** for near-duplicate detection was tuned from 0.5 to 0.7 after empirical testing revealed false positive contamination from `node_modules/` README files scanned by `pathlib.rglob()`.
- **External CLI review providers** (Codex, Gemini) have reliability issues for large code reviews: Codex times out on prompts >3,000 lines (120s timeout), Gemini returns CAPACITY 429 errors unpredictably. Fallback Task agents are essential.
- **Review agent turn budgets**: 12 max_turns is insufficient for code review with 1,500+ line diffs. 4 of 6 agents exhausted turns without persisting output files. This is a systemic issue, not agent-specific.
- **Every file-scanning script must explicitly exclude `node_modules/` and `.git/`** — `.gitignore` is a git-layer concept, not a filesystem-layer concept. `pathlib.rglob()`, `find`, and `readdirSync` all operate at the filesystem layer.

## 2. Collaboration Preferences

- Full CWF pipeline execution via `cwf:run` worked well for this scope — all 8 stages completed with appropriate human gates pre-impl and autonomous operation post-impl.
- The autonomous review → fix → commit cycle (4 fixes applied from Conditional Pass verdict without human gate) was effective and matched the user's trust level.
- No collaboration friction observed this session.

### Suggested Agent-Guide Updates

- Consider adding to `docs/project-context.md`: "File-scanning scripts must explicitly exclude `node_modules/` and `.git/`. `.gitignore` exclusions do not apply to filesystem-level glob/rglob/find operations."

## 3. Waste Reduction

### Waste Item 1: 4/6 review agents failed to persist output files

The Security, UX/DX, Correctness fallback, and Expert Beta agents all performed code analysis but exhausted their 12-turn budgets before writing to session directory files. The stale plan-review artifacts from the earlier `cwf:review --mode plan` round remained in place undetected.

**5 Whys drill-down**:
1. Why didn't agents write output? They ran out of turns (12 max_turns).
2. Why did 12 turns run out? Code review requires reading a 1,515-line diff + multiple source files + writing structured analysis.
3. Why is 12 turns insufficient? It's calibrated for plan review (shorter targets, ~200-line plans).
4. Why is max_turns the same for all modes? The review skill uses a fixed value regardless of diff size.
5. Why wasn't this caught earlier? The S32 session that introduced file persistence only tested with plan reviews, not code reviews.

**Classification**: Process gap.
**Structural fix**: Mode-dependent `max_turns` — scale to diff size (e.g., 12 for <500 lines, 24 for <2000 lines). The review skill should measure diff size before dispatching agents.

### Waste Item 2: Expert Beta (Parnas) spent all turns on web research

The Parnas expert agent spent all 12 turns attempting WebFetch against academic sites (ACM, IEEE — 403/404 errors, redirects) trying to verify expert identity. Never reached the actual code review.

**5 Whys drill-down**:
1. Why did web research consume all turns? Multiple WebFetch failures required retries and fallback attempts.
2. Why did WebFetch fail on academic sites? ACM/IEEE return 403 for bot-like requests. WebFetch has ~9% success rate (documented in S14).
3. Why must agents do web research? expert-advisor-guide.md requires web-verified expert identity.
4. Why does web research compete with the actual review? Both share the same turn budget.
5. Why isn't expert identity cached? No mechanism exists to mark an expert as "previously verified."

**Classification**: Structural constraint.
**Structural fix**: Cache expert identity verification in `cwf-state.yaml` expert_roster entries (add `verified: true` field). Skip web research for previously-verified experts.

### Waste Item 3: External CLI failures (Codex timeout, Gemini CAPACITY)

Both external CLIs failed: Codex timed out (124) on a 3,929-line prompt, Gemini returned 429 CAPACITY. Both required fallback Task agents, adding latency.

**Classification**: Structural constraint.
**Structural fix**: For large diffs (>2000 lines), skip external CLIs entirely and route directly to Task agents. The fail-fast classification already exists for CAPACITY errors; extend it to a pre-dispatch size check.

### Waste Item 4: Stale review files from plan-review phase

Plan review and code review both write to `review-security.md`, `review-ux-dx.md`, etc. When code review agents failed to overwrite, stale plan-review content remained in the shared namespace — undetectable without timestamp comparison.

**5 Whys drill-down**:
1. Why were stale files present? Both review rounds use identical filenames.
2. Why are filenames the same? The review skill uses a single naming convention regardless of mode.
3. Why wasn't there cleanup between `review-plan` and `review-code`? `cwf:run` doesn't clear review files between stages.
4. Why isn't there a staleness check? The context recovery protocol checks for file existence and sentinel marker, not content freshness.

**Classification**: Process gap.
**Structural fix**: Namespace review output files by mode (`review-security-plan.md` vs `review-security-code.md`) or clean review files at the start of each review round.

### Waste Item 5: Retro expert agents also exhausted turns (first attempt)

During this retro itself, both Expert Alpha (Deming) and Expert Beta (Parnas) agents exhausted their 12-turn budgets without writing output files — the same failure pattern from the code review. The retry with explicit "write file first" instructions succeeded.

**Classification**: Same common cause as Waste Item 1.
**Structural fix**: Same as Waste Item 1 — increase max_turns for complex analysis tasks. Additionally, the "write first, research second" instruction pattern proved effective as a tactical workaround.

## 4. Critical Decision Analysis (CDM)

### CDM 1: Schema validation tool selection — ajv-cli + yq over yamale

At the tool selection stage, the session chose JSON Schema standard (ajv-cli for validation, yq for YAML-to-JSON conversion) over Python-native alternatives like yamale. This shaped the entire `check-schemas.sh` implementation: a multi-binary pipeline (bash wrapper calling Go binary yq and Node.js npx ajv-cli) instead of a single-language solution.

| Probe | Analysis |
|-------|----------|
| **Cues** | The prior-art research phase (`plan-prior-art-research.md`) documented the ajv-cli + yq pipeline pattern explicitly. The `scripts/` directory already contained bash and Node.js artifacts, establishing multi-language precedent. JSON Schema is the only schema language with cross-toolchain support (VS Code, CI validators, language servers). |
| **Knowledge** | JSON Schema is a W3C-adjacent standard with broad ecosystem support. yamale is Python-only with no JSON Schema export path. Schema files would eventually be consumed by hook integrations and CI pipelines (deferred), meaning format portability mattered more than runtime simplicity. |
| **Goals** | Competing: (1) minimize runtime dependencies — yamale needs only Python; (2) maximize schema reusability — JSON Schema is cross-toolchain; (3) maintain convention consistency — repo already uses Node.js. Goal (2) won because the session was building infrastructure for future sessions. |
| **Options** | (A) yamale — single dep, custom syntax, zero portability; (B) ajv-cli + yq — two deps, JSON Schema standard, full portability; (C) Cerberus/Pydantic — Python with lossy JSON Schema export. Option B chosen. Option C not explicitly considered. |
| **Basis** | Architecture review confirmed: the `additionalProperties` granular controls and `$comment` documentation pattern are JSON Schema capabilities yamale lacks. |
| **Experience** | Less experienced: choose yamale for simplicity. More experienced: also note the multi-tool pipeline creates fragile coupling — the `yq 2>&1` bug was a direct consequence of this complexity. |
| **Hypothesis** | yamale would have meant simpler implementation (~40 fewer lines), no `validate_target` colon encoding (flagged by Ousterhout review), but non-portable schemas and no `$comment` pattern. |

**Key lesson**: When building validation infrastructure, optimize for format portability over runtime simplicity. A standard schema format outlives the specific validator chosen to enforce it.

### CDM 2: datasketch threshold raised from 0.5 to 0.7

During implementation verification, the initial 0.5 threshold produced 713 false-positive pairs, traced to `node_modules/` contamination. A dual fix was applied: path exclusion + threshold raise.

| Probe | Analysis |
|-------|----------|
| **Cues** | 713 pairs from ~66 files — orders of magnitude above expected signal. Investigation revealed `pathlib.rglob()` scanned `node_modules/` despite `.gitignore`. |
| **Knowledge** | Prior-art research documented 0.7 as "standard near-duplicate threshold (recommended starting point)" — but the initial plan overrode this for higher recall. |
| **Goals** | (1) high recall (favoring 0.5); (2) high precision (favoring 0.7+); (3) first-run credibility — 713 findings would undermine tool trust. |
| **Options** | (A) raise threshold only; (B) add exclusion only; (C) both. Option C chosen — addressing independent failure modes (data contamination + sensitivity). |
| **Situation Assessment** | Incorrect: assumed `.gitignore` exclusions apply to filesystem scans. This is a common misconception corrected in `lessons.md`. |

**Key lesson**: When a detection tool produces an order-of-magnitude more findings than expected, investigate the input set before adjusting sensitivity. Data contamination and threshold miscalibration are independent failure modes.

### CDM 3: Review synthesis from 2/6 valid files

4 of 6 review agents failed to persist code-review output. The session synthesized from the 2 completed reviews (Architecture, Expert Alpha/Ousterhout) plus partial findings from agent activity logs.

| Probe | Analysis |
|-------|----------|
| **Cues** | Absence of expected output files. Only `review-architecture.md` and `review-expert-alpha.md` contained code-level analysis. |
| **Goals** | (1) thoroughness — re-run all 6; (2) forward progress — synthesize from available data; (3) signal integrity — ensure no bias from which agents completed. Goal (2) chosen. |
| **Options** | (A) re-run with higher turns — requires infra changes mid-session; (B) manually review; (C) synthesize from partial data; (D) skip review entirely. Option C chosen. |
| **Basis** | The 2 completed reviews were architecturally substantive — they identified all 4 moderate concerns that were subsequently fixed. Synthesis was feasible because the completed reviews were deep. |
| **Time Pressure** | Yes — already deep in the pipeline. Expert Beta/Parnas had spent all turns on web research, so retrying without fixing the root cause would likely repeat the failure. |

**Key lesson**: Partial multi-agent results should be treated as a system failure to diagnose, not normalized. Two deep reviews can be sufficient for synthesis, but the structural fix is ensuring all agents can complete.

### CDM 4: additionalProperties asymmetry in schema design

Applied `additionalProperties: false` only on hooks (closed vocabulary of 7 event types), `true` everywhere else.

| Probe | Analysis |
|-------|----------|
| **Cues** | The three config files have fundamentally different constraint profiles: hooks.json maps to a fixed runtime API, while cwf-state.yaml and plugin.json evolve organically across sessions. |
| **Analogues** | Postel's law: "be liberal in what you accept, conservative in what you send." Hooks runtime is a sender (strict), cwf-state.yaml is a receiver (liberal). |
| **Goals** | (1) catch drift early (strict); (2) allow organic evolution (permissive); (3) maintain developer trust (avoid false positives). Asymmetric approach satisfies all three. |
| **Options** | (A) strict everywhere; (B) permissive everywhere; (C) asymmetric (chosen); (D) permissive with logging of unknowns (recommended by Deming review but not implemented). |

**Key lesson**: Schema strictness should match vocabulary closure — strict for closed sets, permissive-with-observability for open sets.

## 5. Expert Lens

### Expert alpha: W. Edwards Deming

**Framework**: Systems thinking — common cause vs special cause variation, PDCA, build quality into process
**Source**: *Out of the Crisis* (MIT Press, 1986), particularly Point 3 (cease dependence on inspection) and Chapter 11 (common causes and special causes)
**Why this applies**: S24 introduced 5 inspection tools into a documentation workflow — a direct test case for Deming's tension between inspection and process quality.

The most revealing aspect of S24 is not the 5 tools themselves but the structural pattern they expose: a system that has accumulated 494 markdown files and 9,567 cross-references without any automated quality signal, then responds by bolting on 5 post-hoc detection scripts. This is the exact pattern Deming warned against in Point 3 — "cease dependence on inspection to achieve quality." The plan explicitly defers hook integration, CI/CD, and the `cwf:validate` orchestrator, meaning these tools can only be run manually after content is authored and committed. A broken link has already been written, committed, and possibly built upon before `check-links.sh` can detect it. The Deming-aligned alternative would be to integrate even one tool — `check-links.sh --local` is the obvious candidate, given its sub-second execution — into the authoring workflow immediately as a PostToolUse hook.

The 4/6 review agent failure is the session's clearest demonstration of common cause versus special cause variation. All 6 agents operated under the same system constraint: a 12-turn budget calibrated for plan review, applied unchanged to code review with a 1,515-line diff. Four agents failed identically — textbook common cause variation attributable to the system design, not individual agent performance. Contrast with the Expert Beta/Parnas agent, which failed for a special cause (403 errors on academic sites). Treating both as "agents failed" is the tampering Deming warned about: adjusting for common cause variation as if it were special cause.

The datasketch threshold 0.5→0.7 is a complete PDCA cycle: Plan (set 0.5 for recall), Do (run tool), Check (713 false positives from node_modules contamination), Act (dual fix). The prior-art research had documented 0.7 as the recommended starting point — the knowledge was available but overridden. The PDCA cycle self-corrected only because the signal was overwhelmingly obvious (713 pairs from 66 files). A subtler miscalibration might have persisted.

**Recommendations**:
1. **Close the inspection-to-prevention gap**: Integrate `check-links.sh --local` as a PostToolUse hook for Write/Edit on `.md` files before the next session. Convert one inspection tool into a process-quality mechanism.
2. **Implement mode-dependent turn budgets**: The 4/6 failure is common cause — fix the system by scaling `max_turns` to diff size. Separately address the Expert Beta special cause (academic site access) — do not apply the same fix to both.
3. **Add observability for permissive schemas**: Log unknown properties in `cwf-state.yaml` and `plugin.json` as informational output (not failures), creating a control chart of configuration evolution.

### Expert beta: David Parnas

**Framework**: Information hiding and modular decomposition criteria
**Source**: "On the Criteria To Be Used in Decomposing Systems into Modules" (CACM, 1972)
**Why this applies**: S24 decomposed static analysis into 5 independent scripts — a decomposition decision evaluable against Parnas's criteria.

S24's decomposition of static analysis into five scripts is a clear instance of Parnas's Decomposition 2: each script's "secret" is its detection algorithm and external tool dependency. check-links.sh hides lychee and .lychee.toml; doc-graph.mjs hides remark AST traversal; find-duplicates.py hides MinHash/LSH; check-schemas.sh hides yq+ajv-cli; doc-churn.sh hides git log query format. None leak through the shared CLI interface (--help, --json, exit 0/1). A caller need not know check-links.sh delegates to a Rust binary or that find-duplicates.py uses 128-permutation MinHash. If lychee were replaced, only check-links.sh changes — the module boundary (CLI interface) remains stable.

However, two information hiding failures are worth noting. First, `check-schemas.sh`'s `validate_target` accepts a colon-delimited `"schema:data:converter"` string, forcing the caller to know the internal validation structure. The converter choice (an implementation detail) leaks through the interface, with a detection hack at line 105 (`converter == data`). A deeper module would accept (schema, data) and internally decide the conversion strategy. Second, the review pipeline filename collision — plan-review and code-review sharing `review-security.md` — is a namespace sharing violation. Each phase should hide its artifacts behind its own interface.

A subtler finding: the replicated CLI convention across five scripts in three languages (TTY detection, --json semantics, color initialization, exit code taxonomy) represents a design decision that has leaked across module boundaries. Each replication is a point where the output formatting "secret" is exposed. If the convention changes (e.g., to support NO_COLOR), all five scripts must be updated independently.

**Recommendations**:
1. Eliminate the colon-delimited target encoding in check-schemas.sh — use positional arguments or named functions that hide the conversion strategy.
2. Namespace review artifacts by pipeline phase (`review-security-plan.md` vs `review-security-code.md`).
3. If the suite grows beyond 5 scripts, extract the shared output convention into per-language libraries.

## 6. Learning Resources

### 1. Locality Sensitive Hashing (LSH): The Illustrated Guide — Pinecone

**URL**: https://www.pinecone.io/learn/series/faiss/locality-sensitive-hashing/

Walks through the full MinHash/LSH pipeline with NumPy implementations and visual diagrams. The S-curve analysis explains how banding parameters control the threshold behavior — why the 0.5-to-0.7 adjustment in `find-duplicates.py` had the effect it did. The guide uses a 4,500-sentence dataset, comparable in scale to a documentation corpus.

**Why it matters**: The relationship between `threshold`, `num_perm`, and false-positive/false-negative rates is non-obvious. This guide provides the mathematical intuition for principled threshold adjustments rather than empirical tuning.

### 2. Evolving JSON Schemas — Creek Service (Part II)

**URL**: https://www.creekservice.org/articles/2024/01/09/json-schema-evolution-part-2.html

Introduces the producer/consumer schema split: producing schemas use `additionalProperties: false` (closed content model), consuming schemas use `additionalProperties: true` (open content model). Maps directly onto S24's pattern. Formalizes three compatibility modes (backward, forward, full) and safe evolution rules.

**Why it matters**: The three S24 schemas use the "consuming schema" pattern. This article provides the formal vocabulary and compatibility rules for explaining why the design is correct, and covers `patternProperties` interaction with `additionalProperties`.

### 3. Multi-Agent System Reliability — Maxim AI

**URL**: https://www.getmaxim.ai/articles/multi-agent-system-reliability-failure-patterns-root-causes-and-production-validation-strategies/

Categorizes multi-agent failures into four classes: state synchronization failures, communication protocol breakdowns, coordination overhead saturation, and resource contention. The quadratic coordination overhead insight explains why 4/6 agents exhausted turn budgets.

**Why it matters**: Turn-budget exhaustion maps to "coordination overhead saturation," CLI timeouts to "communication protocol breakdowns." The production validation strategies (adversarial testing, token consumption analysis) are directly applicable to improving `cwf:review`.

## 7. Relevant Skills

### Installed Skills

**Local skills**:
- `plugin-deploy` — automates post-modification plugin lifecycle (version checks, marketplace sync, README updates). Not directly relevant to this session but would apply if the CWF plugin itself needed deployment after changes.

**CWF skills used in this session**:
- `cwf:run` — full pipeline orchestration (all 8 stages)
- `cwf:plan` — plan drafting with parallel research
- `cwf:review` — 6-reviewer code review with external CLI routing
- `cwf:impl` — implementation from plan with parallel agents
- `cwf:retro` — this retrospective
- `cwf:gather` — web search for Parnas paper context

### Skill Gaps

**Identified gap**: A `cwf:validate` orchestrator skill that runs all 5 static analysis tools in sequence with unified reporting would reduce the friction of manual invocation. This was explicitly deferred in the plan's "Deferred Actions" but is now the natural next step.

No additional external skill gaps identified — the static analysis tools are standalone scripts, not skill-mediated workflows.
