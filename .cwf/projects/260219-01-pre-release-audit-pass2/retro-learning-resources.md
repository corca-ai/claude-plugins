## Section 6: Learning Resources
1. **8 strategies for developing resilient workflows** — https://www.redwood.com/article/it-workflow-automation-strategies/
   - Key takeaway: Redwood lays out eight concrete resilience levers (low-code design, event-driven scheduling, intelligent exception handling, strong encryption/data-transfer controls, centralized oversight, extensible automation, and deep platform guardrails) and pairs each with a “resilience factor” that explains how the pattern prevents downtime, adapts to unexpected demands, or surfaces incidents earlier.
   - Key takeaway: The article stresses that resilient workflows are the foundation for consistent IT operations, so automation platforms should emphasize recoverability, observability, and adjustable interfaces over brittle, schedule-only jobs.
   - Why it matters: Our pre-release audit is about shoring up deterministic gates and automation reliability, so this primer helps us argue for guardrails (e.g., centralized orchestration, configurable exception paths) when we document workflow contracts and resilience expectations.
2. **Chainloop Contracts (Workflow Contracts)** — https://docs.chainloop.dev/concepts/contracts
   - Key takeaway: Chainloop treats workflow contracts as immutable, versioned interfaces between developers and security/compliance teams, explicitly declaring what evidence (images, SBOMs, policies, runner metadata) must accompany each attestation and letting the same contract back multiple pipelines.
   - Key takeaway: Contracts can be managed via CLI or UI, scoped per project/org, and tied to policies and runner contexts so that a single contract revision propagates to every associated workflow run.
   - Why it matters: The project’s “contract-first” intent needs a concrete reference for how immutable, shareable workflow contracts should drive automation behavior, so this source grounds our documentation for deterministic gate requirements and evidence capture.
3. **Quality Gates: Automated Quality Enforcement in CI/CD** — https://testkube.io/glossary/quality-gates
   - Key takeaway: Testkube defines quality gates as automated checkpoints that evaluate metrics (tests, coverage, security scans, approvals) and block merges/deployments until the gate passes, turning raw test data into deterministic decisions with layered stages and immediate feedback loops.
   - Key takeaway: The doc highlights best practices—aligning gates to business-critical metrics, documenting configurations, combining multiple observability sources, and providing clear diagnostics—while also emphasizing how Kubernetes-native testing keeps feedback close to production.
   - Why it matters: Our deterministic quality-gate obsession for the release (review synthesis, contract checks, gating scripts) can cite this source when justifying gating behavior, observability expectations, and how to design blocking criteria that are both firm and actionable.

<!-- AGENT_COMPLETE -->
