# Retro Skill: Criteria 5-9 Deep Quality Review

## 기준 5 (작성 스타일)
- 심각도: 중간 — `AskUserQuestion`가 막혔을 때 fast-path를 택했다는 점을 감사하기 위해 “Fast path” 또는 “Post-Retro Findings”라는 짧은 기록을 남기라고 지시하지만, 기록 대상으로 삼을 문서나 필드를 어디에 두어야 하는지 정의하지 않아 실무자가 임의로 처리하게 되고 감사 추적이 일관성을 잃을 수 있습니다 (`plugins/cwf/skills/retro/SKILL.md:46`).

## 기준 6 (자유도)
- 심각도: 중간 — 새 날짜 디렉터리를 만들거나 기본 경로를 부트스트랩할 때 `{CWF_PLUGIN_DIR}/scripts/next-prompt-dir.sh --bootstrap <title>`처럼 `<title>` 플레이스홀더를 그대로 두고 있으므로 어떤 문자열을 넘겨야 하는지, 그리고 언제 이전 세션의 제목을 재사용해야 하는지가 명시되어 있지 않습니다. 이로 인해 실행자가 각 세션마다 서로 다른 명명 규칙이나 빈 값을 넣는 등 자유도만 커져 경로가 deterministic하지 않게 됩니다 (`plugins/cwf/skills/retro/SKILL.md:34`).

## 기준 7 (Anthropic Compliance)
- No significant issue.

## 기준 8 (개념 무결성)
- 심각도: 중간 — 개념 지도는 Expert Advisor의 필수 상태로 `expert roster`에 `framework` 정보까지 저장하도록 요구하지만 (`plugins/cwf/references/concept-map.md:23`), 레퍼런스 문서의 로스터 갱신 단계는 `name`, `domain`, `source`, `rationale`, `introduced`, `usage_count`만 언급하고 프레임워크가 빠져 있어, 미래에 서로 다른 방법론을 추적하거나 대안 식별에서 기준이 될 로직 상태가 누락됩니다. 반드시 롤 기반 전문가마다 적용한 프레임워크를 `cwf-state.yaml`에 기록하도록 명시해야 합니다 (`plugins/cwf/references/expert-advisor-guide.md:126`).

## 기준 9 (레포지토리 독립성)
- 심각도: 중간 — 도구 재고를 위한 Step 1은 마켓플레이스와 로컬 설치를 각각 `~/.claude/plugins/*/skills/*/SKILL.md`와 `.claude/skills/*/SKILL.md`로 제한하고 있어 Codex 전용 디렉터리(`~/.codex/skills/*`)를 전혀 살피지 않습니다. Codex 런타임에서 실행하면 로컬 스킬을 누락하고 도구 격차 분석이 왜곡될 가능성이 있기 때문에, 스킬 디렉터리 목록을 `~/.codex/skills/*/SKILL.md`까지 확장하거나 존재 여부를 감안한 분기 처리가 필요합니다 (`plugins/cwf/skills/retro/SKILL.md:260`).

<!-- AGENT_COMPLETE -->
