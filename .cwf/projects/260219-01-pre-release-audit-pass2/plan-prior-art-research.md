# Prior-Art Research for Planning

Date: 2026-02-18  
Scope: planning input for pre-release audit pass 2 (not implementation decisions)

## 1) Repository-agnostic plugin/automation tooling

### Prior-art signals
- GitHub reusable workflows define a reusable contract surface (`on.workflow_call`) with typed inputs/secrets and explicit outputs, while keeping call sites repository-local in `.github/workflows`.
- Reusable workflow security/portability constraints are explicit: access policy boundaries, no redirects for action/workflow references, and preference for immutable references (SHA pinning).
- `pre-commit` demonstrates repository-agnostic hook orchestration across many languages, supporting both remote repos and `local`/`meta` sentinels with explicit `rev`.

### Planning implications for this repository
- Treat reusable automation interfaces as small, explicit contracts (inputs/secrets/outputs), with repository-specific behavior behind that interface.
- Plan portability boundaries up front: what must be cross-repo reusable vs what remains repo-owned adapters.
- Plan supply-chain trust posture as part of workflow architecture (immutable references, provenance/audit visibility), not as late hardening work.

## 2) Contract-first first-run bootstrap patterns

### Prior-art signals
- JSON Schema separates assertions from annotations; notably, `default` is annotation-oriented and not applied automatically during validation.
- Twelve-Factor guidance emphasizes strict config/code separation and environment-based variability for portability.
- Reusable workflow contracts require declared inputs/secrets before invocation, reinforcing “contract before execution.”

### Planning implications for this repository
- Plan first-run bootstrap as two distinct concerns:
  - Contract validation (schema/assertions).
  - Default/config materialization (bootstrap step), explicitly outside pure validation.
- Plan a clear config precedence model (for example: environment, checked-in project config, generated defaults) and capture it as planning constraints.
- Plan first-run success criteria around deterministic contract checks plus explicit bootstrap outputs/artifacts.

## 3) Deterministic gates vs narrative policy boundaries

### Prior-art signals
- GitHub rulesets encode hard deterministic controls (for example, required status checks before merge).
- GitHub rulesets also support an “Evaluate” enforcement mode, enabling non-blocking measurement before mandatory enforcement.
- GitHub explicitly scopes some narrative governance (metadata restrictions improve consistency but do not replace security controls).
- OPA formalizes policy-as-code and decouples policy decision from enforcement; CI usage patterns distinguish static config validation (often Conftest) from runtime/contextual checks.

### Planning implications for this repository
- Plan policy layers explicitly:
  - Deterministic blocking gates.
  - Evaluate/shadow gates.
  - Narrative guidance for non-automatable judgment.
- Plan to avoid narrative duplication of deterministic checks; prose should describe intent, risk model, and exception handling.
- Plan promotion criteria from narrative rules to deterministic gates when a rule becomes automatable and high-value.

## 4) Removing unnecessary backward compatibility in pre-release major versions

### Prior-art signals
- SemVer 2.0.0: `0.y.z` is initial development; anything may change; API not considered stable.
- Go modules guidance: `v0` has no compatibility guarantee; `v1` is the explicit compatibility commitment.
- Cargo SemVer guidance: in `0.y.z`, `y` is commonly treated as a breaking boundary (left-most non-zero component convention).

### Planning implications for this repository
- Plan an explicit “pre-1.0 compatibility envelope” stating what remains unstable vs temporarily preserved.
- Plan deprecation/removal decisions against published API surface inventory, so compatibility work is deliberate rather than habitual.
- Plan migration communication artifacts (changelog framing, upgrade notes, cutoff timelines) as part of release planning, not post-hoc cleanup.

## Planning notes and open decisions

- Define “public API” for this repository before compatibility policy is finalized (skills, command flags, manifests, docs contracts, generated artifacts).
- Decide which policy controls should start in evaluate mode vs immediate blocking mode.
- Decide compatibility horizon for remaining pre-1.0 releases (what is intentionally breakable now to reduce long-term maintenance load).

## Source Index (concrete URLs)

1. GitHub Docs: Reuse workflows  
   https://docs.github.com/en/actions/how-tos/reuse-automations/reuse-workflows
2. GitHub Docs: Reusing workflow configurations  
   https://docs.github.com/en/actions/reference/workflows-and-actions/reusing-workflow-configurations
3. GitHub Docs: Secure use reference for GitHub Actions  
   https://docs.github.com/en/actions/reference/security/secure-use
4. GitHub Docs: Available rules for rulesets  
   https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/available-rules-for-rulesets
5. GitHub Docs: Creating rulesets for a repository  
   https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/creating-rulesets-for-a-repository
6. pre-commit documentation  
   https://pre-commit.com/
7. JSON Schema: Annotations reference  
   https://json-schema.org/understanding-json-schema/reference/annotations
8. JSON Schema 2020-12 Validation vocabulary  
   https://json-schema.org/draft/2020-12/draft-bhutton-json-schema-validation-00
9. The Twelve-Factor App: Config  
   https://12factor.net/config
10. Open Policy Agent: Using OPA in CI/CD Pipelines  
    https://www.openpolicyagent.org/docs/cicd
11. Semantic Versioning 2.0.0  
    https://semver.org/
12. Go Modules Reference  
    https://go.dev/ref/mod
13. Go: Module release and versioning workflow  
    https://go.dev/doc/modules/release-workflow
14. Rust Cargo Book: SemVer compatibility  
    https://doc.rust-lang.org/cargo/reference/semver.html

<!-- AGENT_COMPLETE -->
