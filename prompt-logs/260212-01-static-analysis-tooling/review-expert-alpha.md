### Expert Reviewer Alpha: David Parnas

**Framework Context**: Information hiding and modular decomposition criteria -- grounded in "On the Criteria To Be Used in Decomposing Systems into Modules" (Communications of the ACM, Vol. 15, No. 12, December 1972) and "Designing Software for Ease of Extension and Contraction" (IEEE Transactions on Software Engineering, Vol. SE-5, No. 2, March 1979).

---

#### Analysis Preamble

Parnas's 1972 paper established that the primary criterion for decomposing a system into modules should be **which design decisions are likely to change**, not the sequential steps of a processing pipeline or the convenience of implementation. Each module should hide one design decision -- its "secret" -- behind an interface that remains stable as the secret changes. The companion 1979 paper on extension and contraction argues that a well-designed system should allow subsets and supersets of its functionality to be produced without requiring understanding of the entire system.

The plan under review proposes 5 standalone scripts in 3 languages (Bash, Node/ESM, Python), each independently implementing a set of shared behavioral conventions: `--json` output, `--help`, TTY color detection, dependency checking, and `prompt-logs/` exclusion. The critical question from an information-hiding standpoint is: **what are the design decisions likely to change, and does the proposed decomposition isolate them behind stable interfaces?**

---

#### Concerns (blocking)

- [Medium] **Replicated policy decisions are not hidden behind a module boundary.** The plan specifies that all 5 scripts independently implement the same behavioral policies: `prompt-logs/` exclusion paths, TTY color detection patterns, `--json` flag semantics, dependency-check-and-exit-1 protocol, and exit code taxonomy (0 = clean, 1 = findings). These are not independent design decisions -- they are a single policy decision ("how analysis tools present results in this repository") replicated across 5 implementations in 3 languages. Parnas's criterion holds that when a design decision appears in multiple modules, a change to that decision requires coordinated changes across all of them, defeating the purpose of modular decomposition. Today, the policy is "exclude `prompt-logs/`"; tomorrow it may be "exclude `prompt-logs/` and `archived/`." That single policy change would require editing all 5 scripts, each in a different language.
  - Specific locations: Step 1 (check-links.sh line patterns), Step 2 (doc-graph.mjs exclusion logic), Step 3 (find-duplicates.py `--include-prompt-logs` flag), Step 4 (check-schemas.sh has no exclusion but hardcodes target paths), Step 5 (doc-churn.sh `--include-prompt-logs` flag).
  - **Recommendation**: Extract the shared policy decisions into a single configuration artifact -- a shared configuration file (e.g., `scripts/analysis.config.json` or a shared shell-sourceable `scripts/common-paths.sh`) that each script reads. This does not require a shared library in the traditional sense; it requires a shared **data module** that hides the "what to exclude" decision. Each script's secret remains its own analysis algorithm. The shared config's secret is the repository-wide exclusion and output policy. This is precisely the distinction Parnas draws between decomposition by processing step (current plan: each script handles everything) versus decomposition by information to be hidden (proposed: separate "analysis logic" from "repository policy").

- [Medium] **The `.lychee.toml` config partially contradicts the "no shared state" claim.** The plan states "No shared state or dependencies between scripts" as a success criterion, yet `.lychee.toml` at the repo root is a configuration file that `check-links.sh` depends on and that encodes the same exclusion policy (`exclude_path: prompt-logs/, node_modules/`) that other scripts hardcode. This is actually a good instinct -- lychee externalizes its policy into a config file -- but the plan does not recognize this as a pattern worth generalizing. The existence of `.lychee.toml` demonstrates that the plan's own tool choices already support externalized policy. The inconsistency is that lychee gets a config file while the other 4 scripts embed equivalent policy decisions in source code.
  - Specific location: `.lychee.toml` (Step 1) vs. hardcoded exclusions in Steps 2, 3, 5.

#### Suggestions (non-blocking)

- **Introduce a "uses" relationship rather than claiming full independence.** The plan's framing of "no shared state between scripts" conflates independence of execution (good -- each script can run alone) with independence of design decisions (problematic -- they share policy). Parnas's modular decomposition does not require modules to be unrelated; it requires that each module hide a specific secret. Reframing the architecture as "5 analysis modules + 1 policy module" would be more honest and more maintainable. The scripts remain independently executable; they simply read shared configuration at startup. This is analogous to Parnas's KWIC example where the "Line Storage" module provides a shared data abstraction without creating runtime coupling.

- **The `scripts/package.json` introduction deserves scrutiny as a module boundary decision.** Adding `scripts/package.json` creates a Node.js dependency management scope that only `doc-graph.mjs` uses. If a second Node.js script is added later, it will silently inherit these dependencies. If it needs different versions, the single `package.json` becomes a coupling point. The 1979 paper on extension and contraction specifically warns about this: designing for extension requires that adding a new component does not force changes to existing infrastructure. Consider whether `doc-graph.mjs` should instead manage its own dependencies (e.g., `scripts/doc-graph/package.json`) so that future Node.js scripts are not constrained by its choices. Alternatively, if the intent is that `scripts/package.json` serves all future Node.js analysis scripts, document this explicitly as a shared infrastructure decision with versioning implications.

- **Schema design shows good information-hiding instincts.** The choice of `additionalProperties: true` with `required` fields in `cwf-state.schema.json` and `plugin.schema.json` is well-aligned with Parnas's extension principle. It hides future fields behind a permissive boundary while enforcing the current contract. The deliberate contrast with `hooks.schema.json` using `additionalProperties: false` (because unknown event names represent drift, not extension) shows thoughtful differentiation of which secrets each schema protects. This is one of the plan's strongest architectural decisions.

- **Exit code taxonomy is a hidden interface contract.** The plan specifies exit 0 = clean, exit 1 = findings, with `doc-churn.sh` as an exception (always exit 0 because it is informational). This exit code convention is an interface contract that future consumers (hooks, CI, orchestrator skills listed in "Deferred Actions") will depend on. It is currently documented only in the plan and in inline comments within each script. From an information-hiding perspective, this convention should be documented once in a location that future consumers will find, not reconstructed from reading 5 different scripts. A brief `scripts/README.md` or a conventions section in the existing `AGENTS.md` would serve this purpose. However, since the plan explicitly defers hook integration and CI to future sessions, this is advisory rather than blocking.

- **The 3-language approach creates a hidden maintenance cost.** The choice of Bash, Node/ESM, and Python is pragmatically justified (each language is natural for its tool's domain), but Parnas's framework asks: what is the secret each language choice hides? If the secret is "implementation algorithm," the language diversity is justified. If a future maintainer needs to change the shared behavioral conventions (color output, JSON formatting, argument parsing), they must understand idioms in all 3 languages. The plan mitigates this somewhat by referencing `provenance-check.sh` as the pattern to follow, but this pattern reference is a social convention, not an enforced interface. This is an inherent trade-off that the plan should acknowledge explicitly rather than treating as a non-issue.

---

#### Verdict

The plan is **sound in its primary decomposition** -- each script hides its own analysis algorithm, which is the most volatile design decision (algorithms for link checking, graph analysis, duplicate detection, schema validation, and churn analysis are all likely to change independently). The concern is at the secondary level: **shared behavioral policy is not hidden behind a stable interface** but is instead replicated across implementations. This does not make the plan unworkable, but it creates a maintenance trajectory where policy changes require coordinated edits across 5 files in 3 languages -- precisely the scenario Parnas's criteria were designed to prevent.

The blocking concerns are addressable without restructuring the plan: introducing a shared configuration file for exclusion paths and output conventions would satisfy the information-hiding criterion without sacrificing the scripts' independent executability.

---

#### Provenance
- source: REAL_EXECUTION
- tool: claude-code
- expert: David Parnas
- framework: information hiding, modular decomposition criteria
- grounding: "On the Criteria To Be Used in Decomposing Systems into Modules" (Communications of the ACM, Vol. 15, No. 12, December 1972); "Designing Software for Ease of Extension and Contraction" (IEEE Transactions on Software Engineering, Vol. SE-5, No. 2, March 1979)
<!-- AGENT_COMPLETE -->
