# Retro: Remove Legacy Skills

> Session date: 2026-01-30

## 1. Context Worth Remembering

- 이 레포의 사용자 규모는 작다. breaking change의 영향도 판단 시 "과감하게 정리"가 적절한 규모.
- gather-context 세션(같은 날)에서 "개별 스킬은 독립적 가치가 있으니 유지"라고 결정했으나, 같은 날 바로 뒤집혔다. 통합 스킬 제작 → 기존 스킬 삭제는 하나의 흐름으로 묶는 게 자연스럽다.
- 삭제된 스킬(g-export, slack-to-md, notion-to-md)의 스크립트는 gather-context에 번들되어 있으므로, 향후 스크립트 수정 시 `plugins/gather-context/skills/gather-context/scripts/`만 관리하면 된다.

## 2. Collaboration Preferences

**프로토콜 준수에 대한 기대 수준이 높다.** CLAUDE.md에 "The user expects protocols in CLAUDE.md to be followed without explicit reminders"라고 명시되어 있고, 이번 세션에서 실제로 확인되었다. 유저는 lessons.md 누락을 직접 지적했고, 단순히 "빠뜨렸네요"가 아니라 "왜 빠뜨렸을까요?"라고 근본 원인을 물었다. 결과물뿐 아니라 프로세스 준수 자체를 중시하는 스타일.

**태스크 난이도와 무관하게 프로토콜은 동일하게 적용되어야 한다.** 이번 태스크는 단순한 삭제 작업이었지만, 유저는 쉬운 태스크에서도 lessons.md가 빠지지 않을 것이라고 기대했다. "쉬운 일이니까 생략해도 되겠지"는 통하지 않는다.

### Suggested CLAUDE.md Updates

- `## Plan Mode` 섹션에 lessons.md 관련 리마인더 추가:

```markdown
When entering plan mode, follow the [Plan & Lessons Protocol](plugins/plan-and-lessons/protocol.md).
This is separate from the system plan file — create `prompt-logs/` directory with plan.md and lessons.md regardless of where the system stores its plan.

Create lessons.md at the same time as plan.md, not after implementation. Record learnings as they emerge — including insights from pre-plan-mode conversation.
```

## 3. Prompting Habits

이번 세션에서 유저의 프롬프팅에 특별한 개선점은 없었다. 요청이 명확했고, 의사결정 과정도 간결했다("사용자 안 많습니다. 삭제된 스킬들에 대한 안내를 최하단 섹션에 추가하면 될 것 같습니다"). 에이전트의 분석을 보고 빠르게 판단하여 지시하는 효율적인 패턴.

## 4. Learning Resources

- [Establishing a Documentation Culture](https://www.incrementalism.tech/p/establishing-a-documentation-culture) — 분산 팀에서 문서화를 습관으로 만드는 방법. "기록은 나중에"가 아니라 "진행하면서 동시에"라는 원칙이 lessons.md 점진적 기록과 같은 맥락.

### Post-Retro Findings

**Retro의 배움은 올바른 장소에 정착해야 한다.** retro에서 CLAUDE.md 업데이트를 제안하고 적용했는데, 유저가 "retro 할 때마다 CLAUDE.md가 늘어나기만 한다"고 지적. 이번 추가 내용("lessons.md는 plan.md와 동시에 생성")은 실제로 protocol.md의 Timing 섹션 보강이 적절한 위치였다. CLAUDE.md에 쌓이면 accumulate이지 compound가 아니다.

**조치:**
1. CLAUDE.md에서 방금 추가한 문장 제거 (원복)
2. protocol.md Timing 섹션에 "Create lessons.md at the same time as plan.md" 추가 (올바른 위치)
3. retro SKILL.md Section 2에 "right-placement check" 로직 추가 — 배움이 CLAUDE.md가 참조하는 문서에 속하면 그쪽을 수정 제안

**Post-retro에서 플러그인 코드를 수정하면 배포 절차도 따라야 한다.** retro SKILL.md와 protocol.md를 수정했으나 plugin.json 버전 업데이트를 잊음. post-retro는 "대화와 기록"에 초점을 맞추고 있어서 코드 변경의 배포 절차가 빠져 있었음. retro SKILL.md Section 6에 "플러그인 코드를 변경했다면 plugin.json, CHANGELOG도 업데이트하라"는 안내 추가.

**규칙을 추가한 변경 자체에도 규칙을 적용하라.** "post-retro에서 플러그인 코드 변경 시 plugin.json 버전을 올리라"는 규칙을 retro SKILL.md에 추가하면서, 정작 그 SKILL.md 변경에 대한 plugin.json 버전 업데이트를 놓침(1.2.0 → 1.3.0 누락). 유저가 AI_NATIVE_PRODUCT_TEAM.md 점검 질문으로 발견 유도.

## 5. Relevant Skills

이번 세션에서 스킬 갭은 식별되지 않았다. 삭제 작업은 기존 도구(plan mode, git, 파일 편집)로 충분했다.
