# Structural Review (Criteria 1-4)

## 1. SKILL.md 크기 (Severity: warning)
- `review` SKILL.md는 frontmatter에서 Quick Reference와 다양한 단계(Phase 1~4)를 설명하는 본문까지 포함하여 `plugins/cwf/skills/review/SKILL.md:1`부터 시작하는 섹션을 넘어 `plugins/cwf/skills/review/SKILL.md:400` 이후까지 이어지며, 총 500줄 이상, 3,000단어도 넘는 문서입니다. 기준을 넘어선 문서 크기는 트리거 시 컨텍스트 창을 크게 소모하므로 정책상 경고로 기록합니다.

## 2. Progressive Disclosure 준수 (Severity: 없음)
- frontmatter는 `name`/`description`만 사용하고, 본문은 요약(quick reference, mode routing) 위주이며 상세 템플릿과 출력 포맷은 `references/prompts.md`, `references/external-review.md` 등을 참조하게 되어 있어 중복 없이 Progressive Disclosure 계층을 지키고 있습니다 (`plugins/cwf/skills/review/SKILL.md:1`, `plugins/cwf/skills/review/SKILL.md:232-277`).

## 3. Duplication Check (Severity: 없음)
- 핵심 템플릿 내용은 모두 references에 저장되어 있고, SKILL.md는 해당 파일들을 읽으라는 참조만 하므로 동일 정보가 양쪽에 중복되지 않습니다 (`plugins/cwf/skills/review/SKILL.md:234-277`).

## 4. Resource Health (Severity: moderate)
- `references/orchestration-and-fallbacks.md`와 `references/synthesis-and-gates.md`는 각각 200줄이 넘는 문서인데, 파일 머리글이 `plugins/cwf/skills/review/references/orchestration-and-fallbacks.md:1`과 `plugins/cwf/skills/review/references/synthesis-and-gates.md:1`에서 알 수 있듯이 Table of Contents 없이 바로 내용으로 시작하므로, 100줄 초과 참조 파일에 TOC를 요구하는 `review-criteria`를 만족하지 못합니다. 문서 도입부에 TOC를 추가하면 빠른 찾아보기를 보장할 수 있습니다.

<!-- AGENT_COMPLETE -->
