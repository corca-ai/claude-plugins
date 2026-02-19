# Deterministic Evidence Report

## Collected Command Outputs

### Growth Drift Check
Command: `bash plugins/cwf/scripts/check-growth-drift.sh --level warn`
```bash
CWF Growth Drift Check (v2)
Level: warn
---
  PASS [skills_vs_readme_ko] Skill inventory aligned (filesystem=13, readme_ko=13)
  PASS [run_chain_sync] Default chain aligned: gather → clarify → plan → review(plan) → impl → review(code) → refactor → retro → ship
  PASS [plugin_runtime_scripts] All plugin runtime scripts present (17 files)
  PASS [state_pointer_validity] live pointers are structurally valid (effective=session-state.yaml)
  PASS [provenance_freshness] All provenance files fresh (7 checked)
  PASS [runtime_placeholder_style] No legacy {SKILL_DIR}/../../scripts placeholders in skills/references
  PASS [hook_exit_code_regression] Skipped (enable with --strict-hooks)
---
Summary: 7 pass, 0 fail
Aligned: no drift detected
```

### Refactor Quick Scan
Command: `bash plugins/cwf/skills/refactor/scripts/quick-scan.sh "$(git rev-parse --show-toplevel)"`
```json
{
  "total_skills": 13,
  "warnings": 7,
  "errors": 0,
  "flagged_skills": 4,
  "results": [{
    "plugin": "cwf",
    "skill": "clarify",
    "word_count": 2100,
    "line_count": 451,
    "size_severity": "ok",
    "resource_files": 4,
    "unreferenced_files": [],
    "large_references": [],
    "flag_count": 0,
    "flags": []
  },{
    "plugin": "cwf",
    "skill": "gather",
    "word_count": 1405,
    "line_count": 263,
    "size_severity": "ok",
    "resource_files": 14,
    "unreferenced_files": [],
    "large_references": [],
    "flag_count": 0,
    "flags": []
  },{
    "plugin": "cwf",
    "skill": "handoff",
    "word_count": 2072,
    "line_count": 415,
    "size_severity": "ok",
    "resource_files": 0,
    "unreferenced_files": [],
    "large_references": [],
    "flag_count": 0,
    "flags": []
  },{
    "plugin": "cwf",
    "skill": "hitl",
    "word_count": 1235,
    "line_count": 209,
    "size_severity": "ok",
    "resource_files": 0,
    "unreferenced_files": [],
    "large_references": [],
    "flag_count": 0,
    "flags": []
  },{
    "plugin": "cwf",
    "skill": "impl",
    "word_count": 2456,
    "line_count": 446,
    "size_severity": "ok",
    "resource_files": 2,
    "unreferenced_files": [],
    "large_references": [],
    "flag_count": 0,
    "flags": []
  },{
    "plugin": "cwf",
    "skill": "plan",
    "word_count": 1705,
    "line_count": 351,
    "size_severity": "ok",
    "resource_files": 0,
    "unreferenced_files": [],
    "large_references": [],
    "flag_count": 0,
    "flags": []
  },{
    "plugin": "cwf",
    "skill": "refactor",
    "word_count": 2283,
    "line_count": 451,
    "size_severity": "ok",
    "resource_files": 11,
    "unreferenced_files": [
  "references/review-criteria.provenance.yaml",
  "references/holistic-criteria.provenance.yaml",
  "references/docs-criteria.provenance.yaml"
],
    "large_references": [],
    "flag_count": 3,
    "flags": [
  "unreferenced: references/review-criteria.provenance.yaml",
  "unreferenced: references/holistic-criteria.provenance.yaml",
  "unreferenced: references/docs-criteria.provenance.yaml"
]
  },{
    "plugin": "cwf",
    "skill": "retro",
    "word_count": 3108,
    "line_count": 414,
    "size_severity": "warning",
    "resource_files": 2,
    "unreferenced_files": [
  "references/expert-lens-guide.md"
],
    "large_references": [],
    "flag_count": 2,
    "flags": [
  "word_count_warning (3108w > 3000)",
  "unreferenced: references/expert-lens-guide.md"
]
  },{
    "plugin": "cwf",
    "skill": "review",
    "word_count": 4567,
    "line_count": 783,
    "size_severity": "warning",
    "resource_files": 2,
    "unreferenced_files": [],
    "large_references": [],
    "flag_count": 2,
    "flags": [
  "word_count_warning (4567w > 3000)",
  "line_count_warning (783L > 500)"
]
  },{
    "plugin": "cwf",
    "skill": "run",
    "word_count": 1930,
    "line_count": 366,
    "size_severity": "ok",
    "resource_files": 0,
    "unreferenced_files": [],
    "large_references": [],
    "flag_count": 0,
    "flags": []
  },{
    "plugin": "cwf",
    "skill": "setup",
    "word_count": 4063,
    "line_count": 957,
    "size_severity": "warning",
    "resource_files": 7,
    "unreferenced_files": [],
    "large_references": [],
    "flag_count": 2,
    "flags": [
  "word_count_warning (4063w > 3000)",
  "line_count_warning (957L > 500)"
]
  },{
    "plugin": "cwf",
    "skill": "ship",
    "word_count": 1714,
    "line_count": 337,
    "size_severity": "ok",
    "resource_files": 2,
    "unreferenced_files": [],
    "large_references": [],
    "flag_count": 0,
    "flags": []
  },{
    "plugin": "cwf",
    "skill": "update",
    "word_count": 382,
    "line_count": 112,
    "size_severity": "ok",
    "resource_files": 0,
    "unreferenced_files": [],
    "large_references": [],
    "flag_count": 0,
    "flags": []
  }]
}
```

### Review Routing Cutoff
Command: `bash plugins/cwf/scripts/check-review-routing.sh`
```bash
Review routing cutoff check
[PASS] cutoff comparison exists: prompt_lines > 1200
[PASS] routing state exists: external_cli_allowed=false
[PASS] cutoff reason token exists: prompt_lines_gt_1200
[PASS] line_count=1199 -> expected_route=external_cli_allowed
[PASS] line_count=1200 -> expected_route=external_cli_allowed
[PASS] line_count=1201 -> expected_route=task_fallback_only reason=prompt_lines_gt_1200
[PASS] review routing contract is aligned
```

### Shared Reference Conformance
Command: `bash plugins/cwf/scripts/check-shared-reference-conformance.sh`
```bash
Shared reference conformance check
[PASS] reference anchor exists in plugins/cwf/references/agent-patterns.md
[PASS] shared contract reference present: plugins/cwf/skills/plan/SKILL.md
[PASS] shared contract reference present: plugins/cwf/skills/clarify/SKILL.md
[PASS] shared contract reference present: plugins/cwf/skills/retro/SKILL.md
[PASS] shared contract reference present: plugins/cwf/skills/refactor/SKILL.md
[PASS] shared contract reference present: plugins/cwf/skills/review/SKILL.md
Inline Output Persistence markers: 24 (threshold=24)
[PASS] inline Output Persistence markers are within threshold
[PASS] shared-reference conformance aligned
```

### Run Gate Artifact Check
Command: `bash plugins/cwf/scripts/check-run-gate-artifacts.sh`
```bash
Run gate artifact check
  session_dir : .cwf/projects/260217-05-full-skill-refactor-run
  stages      : review-code refactor retro ship
  pass        : 0
  warn        : 0
  fail        : 16
[FAIL] [review-code] artifact missing or empty: review-security-code.md
[FAIL] [review-code] missing sentinel <!-- AGENT_COMPLETE --> in review-security-code.md
[FAIL] [review-code] artifact missing or empty: review-ux-dx-code.md
[FAIL] [review-code] missing sentinel <!-- AGENT_COMPLETE --> in review-ux-dx-code.md
[FAIL] [review-code] artifact missing or empty: review-correctness-code.md
[FAIL] [review-code] missing sentinel <!-- AGENT_COMPLETE --> in review-correctness-code.md
[FAIL] [review-code] artifact missing or empty: review-architecture-code.md
[FAIL] [review-code] missing sentinel <!-- AGENT_COMPLETE --> in review-architecture-code.md
[FAIL] [review-code] artifact missing or empty: review-expert-alpha-code.md
[FAIL] [review-code] missing sentinel <!-- AGENT_COMPLETE --> in review-expert-alpha-code.md
[FAIL] [review-code] artifact missing or empty: review-expert-beta-code.md
[FAIL] [review-code] missing sentinel <!-- AGENT_COMPLETE --> in review-expert-beta-code.md
[FAIL] [review-code] artifact missing or empty: review-synthesis-code.md
[FAIL] [refactor] no refactor artifact found (expected summary/quick-scan/deep/tidy outputs)
[FAIL] [retro] artifact missing or empty: retro.md
[FAIL] [ship] artifact missing or empty: ship.md
```

### Live State Resolve
Command: `bash plugins/cwf/scripts/cwf-live-state.sh resolve`
```bash
./.cwf/projects/260217-05-full-skill-refactor-run/session-state.yaml
```

### Session State Snapshot
Command: `cat .cwf/projects/260217-05-full-skill-refactor-run/session-state.yaml`
```yaml
# session-state.yaml — volatile session live state
# Synced from .cwf/cwf-state.yaml live section.

live:
  session_id: "S260217-05"
  dir: ".cwf/projects/260217-05-full-skill-refactor-run"
  branch: "marketplace-v3"
  phase: "gather"
  task: "Run full cwf:run refactor across all skills before deploy"
  key_files: []
  decisions: []
  decision_journal: []
  hitl:
    session_id: "260216-03-hitl"
    state_file: ".cwf/projects/260216-03-hitl-readme-restart/hitl/state.yaml"
    rules_file: ".cwf/projects/260216-03-hitl-readme-restart/hitl/rules.yaml"
    updated_at: "2026-02-16T02:42:35Z"

  remaining_gates:
    - "review-code"
    - "refactor"
    - "retro"
    - "ship"
  state_version: "4"
  worktree_root: "/home/hwidong/codes/claude-plugins"
  worktree_branch: "marketplace-v3"
  active_pipeline: "cwf:run"
  user_directive: "토큰이 많이 들어도 상관없으니 서브에이전트와 외부 에이전트 최대한 활용하여 이 리포의 모든 skill에 대해 refactor 돌리고 싶습니다. gemini 제외하면 외부 에이전트는 여러 개 써도 됩니다. 리팩토링을 위한 계획부터 탐색까지 모두 cwf:run으로 하고, 발견한 것도 cwf:run 으로 고치기. 중간 결과 하나하나 모두 파일로 저장하고 적절히 커밋하면서 진행."
  pipeline_override_reason: ""
  ambiguity_mode: "defer-blocking"
  blocking_decisions_pending: "false"
  ambiguity_decisions_file: ".cwf/projects/260217-05-full-skill-refactor-run/run-ambiguity-decisions.md"
```

## Actionable Refactor Implications
- **Review artifact generation** has not occurred: all twelve review gate artifacts (security, ux/dx, correctness, architecture, expert alpha/beta, synthesis) are missing or empty and also lack the `<!-- AGENT_COMPLETE -->` sentinel. These artifacts must be produced and finalized before the review-code gate can pass.
- **Refactor/retro/ship artifacts** are also missing, preventing gate progression beyond review-code. Schedule re-runs or manual creation of the summaries/quick scans tidies/retro/ship outputs to satisfy gate expectations.
- **Refactor documentation references** (references/{review,holistic,docs}-criteria.provenance.yaml) remain unreferenced per the quick scan; ensure every provenance file is either referenced in a skill or intentionally retired so deterministic scans no longer flag them.
- **High-volume skills** (`retro`, `review`, `setup`) exceed the 3,000-word or 500-line thresholds, which may complicate maintenance and gating; consider trimming explanations, splitting guidance, or deferring non-critical content during this refactor wave.
- **Live state remains in `gather` phase** with the cwf:run refactor task active and gates open; track gate completion order (review-code → refactor → retro → ship) defined in the session state when planning next steps so artifacts align with expected progression.
