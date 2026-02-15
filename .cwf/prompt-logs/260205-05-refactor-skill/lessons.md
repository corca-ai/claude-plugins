# Lessons: refactor-skill

## Implementation

- **skill-creator location**: Not at `~/.claude/plugins/marketplaces/` as expected in plan. Found at `~/.codex/skills/.system/skill-creator/SKILL.md`. Glob search was essential to discover the actual path.
- **Bash array JSON serialization**: `printf '"%s",' "${arr[@]}"` produces `""` for empty arrays. Need explicit empty-array handling: `if [[ "${#arr[@]}" -gt 0 ]]; then ... else printf '[]'; fi`.
- **grep -c in heredoc**: Using `grep -c` on a string being built within the same script is fragile. Better to count during the loop itself.
- **check-consistency.sh extension pattern**: Adding new checks follows a clear pattern — new section between structure checks and type detection, new fields in JSON output. The `gaps[]` array is the standard way to surface issues.

## Design Decisions

- **Local skill, not marketplace plugin**: refactor-skill is repo-specific tooling. It evaluates plugins in this repo against the skill-creator philosophy — no cross-project utility.
- **Separate quick-scan.sh from SKILL.md logic**: The bash script handles structural/quantitative checks (word count, unreferenced files). The SKILL.md instructs the agent to do qualitative review (progressive disclosure compliance, duplication, writing style). Clean separation of concerns.
- **review-criteria.md as reference, not inline**: Keeps SKILL.md lean (the skill practices what it preaches). The criteria can be updated independently without changing the skill's workflow.

## Holistic Analysis Insights

- **Token cost of reading all SKILL.md was low**: ~4,300 words total across 7 skills. The "too expensive" assumption was wrong — reading all SKILL.md bodies (excluding references) fits easily in one context.
- **Three-dimension framework worked well**: "pattern propagation / boundary issues / missing connections" produced structured, actionable findings. Worth encoding as a reusable reference file.
- **Discussion-driven refinement**: The initial analysis proposed 7 actions. User feedback changed 3 fundamentally (gather-context scope, retro tidying connection, retro prompting lens). Presenting analysis → discussing → refining is better than presenting a final plan.
- **gather-context as unified info acquisition**: User's vision of gather-context absorbing web-search is architecturally cleaner than keeping them separate. The concern about mega-plugin was acknowledged but the conceptual clarity outweighed it.
- **Waste reduction > misunderstanding prevention**: For retro prompting habits, the user wants efficiency analysis (fewer turns for same quality), not just "avoid misunderstandings." Trust the model to find creative improvements rather than prescribing a rigid format.

## Marketplace v2 Design Lessons

- **"모드인가 태도인가"**: interview의 "끈질기게 파기"를 clarify에 흡수할 때, --interview flag가 아니라 기본 동작에 녹이는 것이 맞음. 끈질기게 파는 것은 모드 전환이 아니라 기본 태도.
- **Flag 설계 원칙**: 차이가 "무엇을 하느냐"이면 flag 분리 (--light: 리서치 skip). 차이가 "어떻게 하느냐"이면 기본 동작에 흡수.
- **retro light/deep 패턴**: 실제 사용에서 light가 압도적으로 많음. heavy 기능(expert lens, learning resources)은 --deep으로 opt-in. 에이전트가 세션 무게를 판단해서 deep을 제안하는 것이 올바른 default.
- **holistic 분석의 촉매 효과**: refactor-skill --holistic이 단순 코드 리뷰가 아니라 아키텍처 전체 재설계의 촉매가 됨. "전체를 한 번 보는" 도구의 가치가 개별 리뷰의 합보다 큼.
