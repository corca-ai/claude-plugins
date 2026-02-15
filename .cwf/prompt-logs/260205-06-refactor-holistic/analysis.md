# Cross-Plugin Analysis

> Date: 2025-02-05
> Plugins analyzed: 7 skills, 5 hooks (4 hook-only + 1 hybrid), 2 local skills

## Plugin Map

| Plugin | Type | Words | Key Capabilities |
|--------|------|-------|-----------------|
| clarify | skill | 541 | Iterative Q&A requirement refinement |
| deep-clarify | skill | 987 | Research-first requirement clarification (codebase + web) |
| interview | skill | 556 | Long-form conversational requirements discovery |
| gather-context | hybrid | 596 | URL → local file (Google/Slack/Notion/WebFetch) |
| web-search | hybrid | 426 | Tavily/Exa web & code search, URL extraction |
| retro | skill | 970 | Session retrospective (7-section analysis) |
| suggest-tidyings | skill | 221 | Safe code cleanup suggestions from commits |
| plan-and-lessons | hook | — | EnterPlanMode → prompt-logs directory setup |
| smart-read | hook | — | Read hook → context injection |
| prompt-logger | hook | — | Stop/SessionEnd → turn logging |
| attention-hook | hook | — | User input tracking, idle notifications, timers |
| plugin-deploy | local | ~350 | Post-modification plugin lifecycle automation |
| refactor-skill | local | ~400 | Skill review (single, scan, holistic) |

## 1. Pattern Propagation

### a. Language Adaptation

**Source**: deep-clarify, web-search, retro, plugin-deploy — all specify language matching.

**Missing in**:
- **clarify**: No language rule. Directly converses with users via AskUserQuestion. High impact.
- **suggest-tidyings**: No language rule. Produces user-facing analysis report.
- **gather-context**: No language rule. Lower impact (mostly script output) but "Supplementary Research" section is user-facing.

**Fix**: Add `**Language**: Match the user's language.` after title in each SKILL.md.

### b. Sub-agent Maturity

**Source**: deep-clarify — most mature pattern:
- Reference guides in `references/` that sub-agents read
- Parallel execution with role separation
- Structured output format from guides

**Partially adopted by**: retro (expert-lens-guide.md), suggest-tidyings (tidying-guide.md)

**Gap**: suggest-tidyings' sub-agent prompt is more ad-hoc than deep-clarify's pattern. The tidying-guide.md reference exists but the prompt structure could follow deep-clarify's template more closely.

### c. Usage Message / No-args Help

**Source**: web-search, plugin-deploy — explicit usage message when invoked with no args or "help".

**Missing in**: clarify, gather-context, suggest-tidyings, interview.

**Fix**: Each skill with subcommands or required args should define a usage block.

## 2. Boundary Issues

### a. Requirements Trio: clarify vs deep-clarify vs interview

**Conflict**: All three trigger on requirement clarification intents. A user saying "이 기능 요구사항 정리해줘" could match any of them.

| | clarify | deep-clarify | interview |
|---|---------|-------------|-----------|
| Style | Q&A, every ambiguity asked | Research first, only Tier 3 asked | Conversational, open-ended |
| Speed | Fast (direct questions) | Slow (parallel sub-agents) | Slow (multi-turn dialogue) |
| Best for | Specific vague feature | Requirement needing codebase/web context | Greenfield discovery |
| Output | Before/After comparison | Decision table with evidence | Scratchpad + Synthesis |

**Resolution**: Group in README as "pick one based on preference." User primarily uses deep-clarify. Consider absorbing interview's strengths (scratchpad, why-dig methodology) into deep-clarify.

### b. web-search extract vs gather-context WebFetch fallback

**Conflict**: Both extract URL content to markdown.
- `web-search extract <url>` → Tavily API (paid, reranking)
- `gather-context <url>` → pattern-match specific services, fallback to WebFetch

**Resolution (decided)**: Absorb web-search into gather-context. gather-context becomes the unified information acquisition layer. Major version bump. See "Decided Actions" below.

## 3. Missing Connections

### a. interview → deep-clarify handoff

**Flow**: interview produces SYNTHESIS.md → user manually invokes deep-clarify on remaining ambiguities.

**Gap**: No suggestion to continue with deep-clarify after interview.

**Fix**: Add to interview's "Closing" section: if ambiguities remain, suggest `/deep-clarify`. Gate on deep-clarify being installed.

### b. deep-clarify sub-agents ↔ web-search compatibility

**Flow**: deep-clarify's Sub-agent B does web research. web-search hook blocks WebSearch tool and redirects to `/web-search`.

**Gap**: Sub-agent may fail if hook blocks its WebSearch calls. Even if it works, misses Tavily/Exa quality.

**Fix (decided)**: After web-search is absorbed into gather-context, deep-clarify will use gather-context for research. Defensive fallback to self-contained research when gather-context is not installed.

### c. retro → installed skills awareness

**Flow**: retro Section 7 identifies skill gaps and suggests find-skills / skill-creator.

**Gap**: Doesn't check already-installed skills. User may have a skill that would have helped but wasn't used.

**Fix (decided)**: Before external search, scan installed skills (Glob `~/.claude/plugins/*/skills/*/SKILL.md`). Suggest both "could have used this session" and "try this going forward."

### d. prompt-logger → retro session matching

**Flow**: retro Step 5 guesses which session log matches by date.

**Gap**: Heuristic matching, no session ID linkage.

**Assessment**: Current approach is pragmatic. Adding session ID would couple two independent plugins. Not worth the coupling cost. Keep as-is.

## Marketplace v2 Architecture (decided)

### Workflow-Ordered Plugin Map

| Stage | Plugin | Status | Description |
|-------|--------|--------|-------------|
| 1. Context | **gather-context v2** | major rewrite | Unified info acquisition: URL auto-detect + `--local` + `--search` |
| 2. Clarify | **clarify v2** | major rewrite | deep-clarify + interview → unified. `--light` for Q&A only |
| 3. Plan | plan-and-lessons | unchanged | EnterPlanMode hook |
| 4. Implement | (Claude Code itself) | — | — |
| 5. Reflect | **retro v2** | minor update | waste lens, installed skills awareness |
| 6. Refactor | **refactor** (new) | new plugin | `--code`, `--skill`, `--docs`, `--holistic` |
| Infra | smart-read, attention-hook, prompt-logger | unchanged | — |

**Deprecated**: web-search (→ gather-context), clarify v1 (→ clarify v2), deep-clarify (→ clarify v2), interview (→ clarify v2), suggest-tidyings (→ refactor --code)

### gather-context v2

```
<url>              → auto-detect: Google/Slack/Notion/GitHub(gh cli)/generic(Tavily extract, fallback WebFetch)
--local <query>    → local codebase exploration
--search <query>   → web search (query intelligence auto-routes: general/news/code/best-practice)
```

- `--search` replaces all of web-search's subcommands via query intelligence (already proven in web-search)
- WebSearch hook moves from web-search plugin to gather-context
- 2 flags + URL auto-detect. Simple interface, smart routing.

### clarify v2

```
/clarify <requirement>         → default: gather-context로 리서치 → Tier 분류 → 끈질기게 질문
/clarify <requirement> --light → 리서치 없이 바로 Q&A (old clarify 수준)
```

- deep-clarify의 핵심: Tier 분류 (T1/T2 자동 결정, T3만 질문), advisory sub-agents
- interview의 장점을 기본 동작에 흡수 (flag 없이): scratchpad, why 2-3번 파기, tension detection
- 사용자와 토론이 필요한 건 끈질기게 하는 것이 기본 태도
- gather-context 미설치 시 self-contained fallback (자체 리서치)

### retro v2

```
/retro              → 에이전트 판단 (대부분 light, 큰 세션이면 --deep 제안)
/retro --deep       → 강제 full (expert lens sub-agents + learning resources + 웹 리서치)
```

- Light (default): Section 1-4 + Section 7 (installed skills scan only). 외부 리서치 없음.
- Deep (--deep): 전체 7 sections. Expert Lens sub-agents (웹 검색 + citation), Learning Resources (웹 검색).
- 명시적 요청 없으면 에이전트가 세션 무게에 따라 판단.
- Section 3: "misunderstanding prevention" → **"waste reduction"** 렌즈. 렌즈만 지정, 포맷은 자유.
- Section 7: find-skills 전에 **installed skills scan** 추가. "이 세션에서 썼으면 좋았을 것" + "앞으로 써볼 만한 것" 제안.

### refactor (new marketplace plugin)

```
/refactor --code [branch]        → 커밋 분석, 안전한 코드 tidying (suggest-tidyings 계승)
/refactor --code --{level} [br]  → 더 큰 리팩토링 (이름 TBD, 미래 확장)
/refactor --skill [name]         → single skill 리뷰 (Progressive Disclosure 기준)
/refactor --skill --holistic     → cross-plugin 분석
/refactor --docs                 → CLAUDE.md, project-context, README 리뷰
/refactor                        → quick scan all
```

- refactor-skill (local) → refactor (marketplace) 승격
- suggest-tidyings 흡수: `--code` flag, tidying-guide.md 이관
- `--code`의 기본은 tidying. 더 큰 리팩토링 레벨은 미래 확장 영역.

## Implementation Order

| Phase | Work | Dependencies |
|-------|------|-------------|
| 1 | gather-context v2 | 기반 레이어. 다른 플러그인이 이걸 사용 |
| 2 | clarify v2 | gather-context v2 사용 |
| 3 | retro v2 | 독립적 (Section 3, 7 수정) |
| 4 | refactor plugin | 독립적 (local skill → marketplace 승격 + suggest-tidyings 흡수) |
| 5 | README v2 | 워크플로우 기반 재구성. 모든 v2 완료 후 |
| 6 | Deprecation | 이전 플러그인 deprecated 마킹, marketplace.json 정리 |

## Notes

- web-search hook (WebSearch → redirect) moves to gather-context after absorption
- All cross-plugin dependencies must be defensive (gate on plugin existence)
- clarify v2의 interview 장점은 flag 없이 기본 동작에 흡수 — 끈질기게 파는 것이 default
- refactor --code의 tidying 이상 레벨은 이름 미정 (--deep은 직관적이지 않음), 미래 확장
- find-skills는 유지 (marketplace 탐색용); installed skills scan은 retro의 새 preceding step
