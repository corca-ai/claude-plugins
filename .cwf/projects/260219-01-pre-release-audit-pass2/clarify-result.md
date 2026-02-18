# Clarify Result — pre-release-audit-pass2

## Original Requirement (verbatim)
"퍼블릭 배포 전 점검 중입니다. 할때마다 새로운 게 발견되어 몇 번 반복하고 있습니다. 토큰 많이 들어도 되니 서브에이전트 최대한 활용해서 제대로 다음을 해주세요.
1. refactor --codebase 후 발견된 것 수정
2. --skill 전체에 대해 deep 후 발견된 것 수정
3. --docs 후 발견된 것 수정
4. 리드미가 주장하는 SoT에 대해 cwf 플러그인이(모든 스킬과 훅이) 그 약속을 정말 잘 맞추고 있는지, 그리고 플러그인이 repo-agnostic하게 / 또는 첫 실행시 계약 기반으로 훌륭하게 동작하는지 (즉 이 repo -> cwf 는 강하게 의존하지만, cwf -> 이 repo 의존성은 없어서, 다른 유저의 리포에서 독립적으로 잘 동작하게 되는지), 쓸데없이 하위호환을 유지하려고 하진 않는지(v3는 아직 미배포 상태고 v2 대비 어치피 대격변이라서 하위호환 불필요. v3가 깔끔하게 잘 되는 게 가장 중요) 등등, 그리고 그 외 여러가지 더 지능적으로 잘, 깊이 검토해주세요.

이 과정에서 제 의사결정이 필요한 게 있으면 멈추고, 각 선택지의 트레이드오프를 보여주세요. 함께 논의하고 결정해서 갑시다. 모호한 점이 있으면 clarify 하고, cwf:plan 해서 시작합시다. 구현 후에는 cwf:review 하고, 마지막에 retro. 이해하셨나요? 적절한 단위로 커밋하면서 진행하고, 마지막에는 retro 결과 보여주면서 persist 후보도 제안해주세요."

## Scope Summary
- Goal: Raise release readiness of CWF v3 by fixing concrete findings from codebase/skill/docs reviews and validating architecture-level promises (SoT compliance, repo-agnostic behavior, contract-first first-run behavior, and no unnecessary v2 compatibility baggage).
- Non-goal: Preserve v2 behavior if it weakens v3 clarity or robustness.
- Process constraint: Use sub-agents aggressively for analysis and parallel review.
- Human gate constraint: Stop and ask the user when a meaningful design/policy choice has trade-offs.
- Delivery constraint: Commit in meaningful units during execution.

## Decision Points
1. Should this pass prioritize v3 cleanliness over v2 compatibility where both cannot be kept safely?
2. What is the minimum evidence bar to claim repo-agnostic behavior and SoT conformance?
3. What should be the commit granularity across codebase/skill/docs/systemic fixes?
4. How should we handle findings that are architectural and cannot be safely auto-fixed in one pass?

## Resolutions
1. v3 cleanliness wins by default (explicitly requested by user). Any breaking cleanup is allowed when it improves v3 reliability.
2. Evidence must include deterministic checks + code/document references + at least one cross-check against contracts/provenance/hook behavior.
3. Commit by concern boundary: (a) codebase-scan findings, (b) skill-deep findings, (c) docs findings, (d) systemic SoT/repo-agnostic/back-compat cleanup.
4. For architectural findings with high-impact trade-offs, pause and present options before implementation.

## Success Criteria (BDD + Qualitative)
### Behavioral (BDD)
- Given `cwf:refactor --codebase` findings, when this pass finishes, then all actionable findings selected for this pass are fixed or explicitly documented with rationale.
- Given deep review over all CWF skills, when this pass finishes, then each skill has either a fix applied or an explicit defer decision.
- Given `cwf:refactor --docs`, when this pass finishes, then deterministic docs gates pass for modified docs.
- Given SoT and portability promises in README/docs, when this pass finishes, then implementation and hooks show no repo-specific hard dependency and first-run contract bootstrap works.
- Given requested lifecycle, when this pass finishes, then review artifacts and retro artifacts exist in the active session directory.

### Qualitative
- Keep contracts and deterministic gates as source of truth (no prose override).
- Prefer removal/simplification over compatibility shims for unshipped v3.
- Keep changes auditable with focused commit boundaries.
