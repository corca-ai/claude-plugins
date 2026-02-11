### Shared Loader Beats Copy-Pasted 3-Tier Blocks

- **Expected**: profile-first migration would require touching many scripts.
- **Actual**: introducing one shared loader reduced code churn and kept behavior consistent.
- **Takeaway**: cross-cutting runtime policy changes should start with a shared helper, then migrate call sites.

When a policy appears in 3+ scripts -> extract a shared loader first, then replace call sites.

### Provider Slots Should Bind to Perspective, Not Vendor

- **Expected**: external review slots were tied to Codex/Gemini names.
- **Actual**: routing by perspective (Correctness/Architecture) allows flexible provider selection without changing synthesis structure.
- **Takeaway**: reviewer slots should represent responsibilities; provider choice should be runtime-routed.

When multiple model vendors are optional -> keep slot semantics stable and route providers separately.
