# Plan — cwf-watch-automation

## Task
"Design and implement `cwf watch` automation that reacts to GitHub issue/PR-comment events safely, deterministically, and within bounded cost."

## Scope Summary
- **Goal**: Automate issue/comment handling with explicit authorization, routing, idempotency, and budget controls.
- **In Scope**:
  - workflow scaffold generation (`cwf watch`)
  - event router for `issues.opened` and `issue_comment.created`
  - question vs implementation vs ambiguous classification
  - authorization policy enforcement
  - cost/concurrency caps
  - disturbance handling (duplicate/out-of-order events)
- **Out of Scope**:
  - replacing human governance entirely
  - unbounded autonomous loops

## Key Decisions Needed

### D1. Authorization Policy
Options:
1. strict: write/admin actors only for implementation path
2. policy-gated: public actors allowed only with maintainer-applied label or slash-command
3. permissive: classifier-only

Recommended: **2** (policy-gated)

### D2. Routing Policy
Options:
1. deterministic rules + confidence threshold + ambiguous fallback
2. classifier-only hard routing

Recommended: **1**

### D3. Side-Effect Policy
Options:
1. single updatable status comment per issue/PR
2. per-stage new comments

Recommended: **1** (noise/cost control)

### D4. Budget Policy
Options:
1. hard caps only (retry/time/concurrency)
2. soft warnings + manual tuning

Recommended: **1** with explicit defaults and override in contract.

### D5. Rollout Policy
Options:
1. direct full automation from start
2. staged rollout (`dry-run` -> `comment-only` -> `mutating`)

Recommended: **2** for safety; user can explicitly opt into direct mode.

## Threat Model & Safety Constraints

### Top Hazards
- Unauthorized implementation trigger
- Prompt/command injection from issue/comment text
- Duplicate or out-of-order event replay causing duplicate side effects
- Bot feedback loops
- Unbounded runner spend

### Safety Constraints
- Authorization gate before implementation route
- Data-only prompt construction for untrusted text
- Idempotency key required for every external side effect
- Hard caps for retries/runtime/concurrency
- Ambiguous/low-confidence route must escalate to clarification path

## Control Loop Contract

For each event:
1. ingest event payload
2. validate authorization
3. classify route with confidence
4. enforce budget envelope
5. execute route action
6. persist checkpoint + idempotency markers
7. emit summary comment/status

Unsafe control actions prevented by:
- route denial on auth failure
- abstain on low confidence
- dedupe drop on repeated event ids
- stop on budget exhaustion

## Files to Create/Modify

### Create
- `plugins/cwf/scripts/cwf-watch.sh`
- `plugins/cwf/scripts/cwf-watch-router.sh`
- `plugins/cwf/scripts/cwf-watch-contract.sh`
- `.github/workflows/cwf-watch.yml` (generated)
- `plugins/cwf/contracts/watch-contract.yaml`

### Modify
- `plugins/cwf/scripts/cwf` (add `watch` subcommand)
- `plugins/cwf/skills/setup/SKILL.md` (watch setup knobs)
- `plugins/cwf/scripts/check-setup-readiness.sh` (optional watch readiness checks)
- `README.md`
- `README.ko.md`

## Implementation Steps

### Step 0 — Watch Contract
- Define contract keys:
  - auth modes
  - route confidence threshold
  - max retries/runtime/concurrency
  - bot-loop guard patterns

### Step 1 — Router Core
- Implement deterministic classifier wrapper:
  - output: `question|implementation_request|ambiguous`
  - include confidence + reason

### Step 2 — Authorization and Budget Gates
- Implement auth gate before implementation route.
- Implement runtime/retry/concurrency caps.

### Step 3 — Idempotency + Disturbance Handling
- Dedupe by event id + route key.
- Ignore stale/out-of-order events per checkpoint rule.
- Add bot-loop guard.

### Step 4 — Workflow Scaffold
- Generate GitHub workflow and required env/permission blocks.
- Add least-privilege permissions defaults.

### Step 5 — Rollout Modes
- `dry-run`: no repo mutation, comment diagnostics only.
- `comment-only`: route/result comments without implementation actions.
- `mutating`: full automation.

### Step 6 — Docs + Verification
- Document policy knobs and failure modes.
- Verify with replay fixtures and workflow syntax checks.

## Validation Plan
1. Authorization tests
   - unauthorized actor denied for implementation route
   - trusted label/slash-command path accepted
2. Classification tests
   - question/request/ambiguous fixture coverage
   - low-confidence fallback behavior
3. Disturbance tests
   - duplicate event replay
   - out-of-order event sequence
   - bot-loop prevention
4. Budget tests
   - retry cap
   - stage/runtime cap
   - concurrency cap
5. Workflow tests
   - generated YAML validation
   - least-privilege permission checks

## Success Criteria

### Behavioral (BDD)

```gherkin
Given an issue-opened event from an unauthorized actor
When `cwf watch` processes the event
Then implementation automation is denied and safe response path is used

Given an event payload classified with confidence below threshold
When routing is evaluated
Then the route is `ambiguous` and clarification response is emitted

Given duplicate delivery of the same event id
When `cwf watch` processes both deliveries
Then side effects run exactly once

Given event traffic exceeds configured concurrency budget
When new events arrive
Then additional events are queued or deferred without exceeding cap

Given rollout mode is `dry-run`
When events are processed
Then no mutating repo actions are executed
```

### Qualitative
- Routing decisions are explainable from logs alone.
- Operator can tune safety/cost knobs without code edits.
- Failure states are explicit and recoverable.

## Deferred Actions
- [ ] Finalize D1-D5 with user-approved values before implementation.
- [ ] Decide default rollout mode (`dry-run` vs `mutating`).
