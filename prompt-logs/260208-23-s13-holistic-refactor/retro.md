# Retro: S13 Holistic Refactor

> Session date: 2026-02-08
> Mode: light

## 1. Context Worth Remembering

- CWF v3 마이그레이션은 S0-S14 로드맵으로 진행 중이며, S13은 머지 전 quality gate 역할
- `plugins/cwf/` 하위에 9개 스킬과 14개 hook 스크립트가 존재. 10번째 스킬(review)은 아직 별도 플러그인으로 존재
- 유저는 린터 설정의 false negative을 false positive보다 더 우려함 — 규칙을 풀어주는 것보다 잡지 못하는 것을 걱정
- markdownlint는 55개 규칙 중 7개만 비활성화 (87% 활성). shellcheck은 전체 규칙 적용
- 유저는 반복 패턴을 발견하면 공유 레퍼런스로 추출하는 것이 당연하다고 봄 — holistic 분석 도구가 이를 자동 제안하길 기대

## 2. Collaboration Preferences

- 유저는 보고서 요약에서 "주요 마찰 규칙 7개 비활성화"를 "거의 모든 룰 해제"로 해석함 → 비율이나 전체 중 일부라는 맥락 제공이 중요
- 디자인 제안을 유저가 먼저 함 ("추출해서 바깥 레퍼런스에 넣어야 하지 않나") → 에이전트가 선제적으로 제안했어야 하는 케이스
- 유저는 마일스톤 완료 시점에 방향 확인을 함 — "다음 세션 의도 이해했나?" 형태로

### Suggested CLAUDE.md Updates

해당 없음. 기존 규칙으로 충분.

## 3. Waste Reduction

### 패턴 추출 제안의 누락

유저가 "동일 패턴이면 추출해야 하지 않나?"라고 물었을 때, holistic 분석을 이미 완료한 시점이었다. 분석 단계에서 이를 선제적으로 발견하고 제안했어야 했다.

**5 Whys**:
1. Why: 왜 선제적으로 제안하지 못했나? → holistic-criteria.md에 패턴 추출 항목이 없었음
2. Why: 왜 기준에 없었나? → 기존 criteria는 "좋은 패턴을 다른 스킬에 전파"에 집중, "반복 패턴을 추출"은 스코프 밖이었음
3. Why: 왜 스코프 밖이었나? → criteria 작성 시점(S11a)에는 스킬이 5개뿐이라 반복 패턴이 충분히 축적되지 않았음
4. **근본 원인**: 프로젝트가 성장하면서 새로운 분석 차원이 필요해졌으나, 분석 도구(holistic-criteria)가 그에 맞춰 진화하지 않았음

**해결**: holistic-criteria.md에 1c (패턴 추출 분석) 추가 — 이 세션에서 이미 적용함. **Process gap → FIXED**.

### 린터 규칙 보고의 프레이밍 오류

"7개 규칙 비활성화"로 보고했으나, 유저는 이를 "대부분 해제"로 인식. 전체 대비 비율(7/55 = 13% 해제)을 먼저 제시했어야 함.

**근본 원인**: 보고 시 절대 수치만 제시하고 비율/맥락을 빠뜨린 one-off 실수. 구조적 문제는 아님.

### 서브에이전트 미사용

cwf:refactor --holistic 스킬은 3개 병렬 서브에이전트를 지시하지만, 이미 모든 파일을 읽은 상태라 인라인 분석을 선택했다. 결과적으로 효율적이었으나 스킬 지시와 괴리가 있었음.

**근본 원인**: 서브에이전트 패턴은 "데이터를 아직 안 읽은 상태에서 병렬 수집+분석"에 최적화. 이미 데이터가 컨텍스트에 있으면 인라인이 나음. 스킬에 "이미 데이터가 컨텍스트에 있으면 인라인 분석 허용" 조건을 추가하면 해결. lessons.md에 기록 완료.

## 4. Critical Decision Analysis (CDM)

### CDM 1: 인라인 분석 vs 서브에이전트 (holistic 모드)

| Probe | Analysis |
|-------|----------|
| **Cues** | 9개 SKILL.md + 14개 hook 스크립트를 이미 전부 읽은 상태. 서브에이전트에 데이터를 넘기려면 요약을 만들어야 하고, 상세 정보가 손실됨 |
| **Goals** | (1) 스킬 지시 준수 vs (2) 분석 정확도 vs (3) 컨텍스트 효율 |
| **Options** | A: 스킬대로 3개 서브에이전트 실행. B: 인라인 분석. C: 부분만 서브에이전트 |
| **Basis** | 이미 읽은 30+ 파일의 세부 내용이 서브에이전트에 전달되면 요약 과정에서 손실됨. 인라인 분석이 더 정확한 결과를 낼 것으로 판단 |
| **Hypothesis** | 서브에이전트를 사용했다면 참조 경로 깊이 문제(F1)를 놓쳤을 가능성 있음. `../` vs `../../`의 차이는 전체 경로 컨텍스트가 있어야 탐지 가능 |
| **Aiding** | 스킬에 "이미 인벤토리가 컨텍스트에 있으면 인라인 분석 가능" 분기를 추가 |

**Key lesson**: 서브에이전트 패턴의 가치는 데이터 수집 비용이 높을 때 극대화됨. 데이터가 이미 있으면 인라인이 우월.

### CDM 2: skill-conventions.md 추출 결정

| Probe | Analysis |
|-------|----------|
| **Cues** | 유저가 "동일 패턴이면 추출해야 하지 않나"라고 직접 제안. 9개 스킬 전부가 동일 구조를 따르는 것을 분석에서 이미 확인 |
| **Goals** | (1) DRY 원칙 vs (2) 스킬의 자기 완결성 vs (3) 새 스킬 작성 가이드 |
| **Options** | A: 규약만 문서화 (conventions reference). B: 스킬 내 공통 Rules를 실제로 include/import. C: 아무것도 안 함 |
| **Basis** | B는 Claude Code 스킬 시스템이 include를 지원하지 않아 불가. A가 유일한 실현 가능 옵션이면서 가이드 + 리뷰 체크리스트 역할도 수행 |
| **Knowledge** | SKILL.md는 세션 시작 시 독립적으로 로드됨. 런타임 공유는 불가하므로, conventions doc는 작성 시점과 리뷰 시점에만 참조됨 |
| **Aiding** | holistic-criteria 1c (패턴 추출)에 자동 탐지 기준을 추가하여 향후 유사 상황에서 에이전트가 선제 제안하도록 개선 |

**Key lesson**: 런타임 공유가 불가능한 환경에서도, "작성 시점 + 리뷰 시점" 가이드 문서는 일관성 유지에 효과적. 추출이 아닌 참조 표준화.

## 5. Expert Lens

> Run `/retro --deep` for expert analysis.

## 6. Learning Resources

> Run `/retro --deep` for learning resources.

## 7. Relevant Skills

### Installed Skills

| 스킬 | 적용 가능성 |
|------|------------|
| cwf:refactor (marketplace) | 이 세션의 메인 도구. --holistic 모드 사용 |
| cwf:review (local) | 유저가 다음 세션에서 사용 예정. 이 세션에서도 마스터 플랜 대비 검증에 사용할 수 있었음 |
| plugin-deploy (local) | 버전 범프가 필요한 경우 사용 가능했으나, 이 세션은 코드 수정이라 불필요 |

### Skill Gaps

이 세션에서 "참조 경로 검증"이 수동으로 grep 기반으로 이루어졌다. markdownlint는 파일 내부 문법만 검사하고 파일 간 링크 유효성은 검사하지 않음. **link checker** (markdown 파일 간 상대 경로 검증 도구)가 있으면 F1 같은 이슈를 자동 탐지 가능. `remark-validate-links`나 `markdown-link-check` 같은 도구를 PostToolUse hook이나 CI에 통합하는 것을 고려할 수 있음.

---

> 이 세션은 아키텍처 결정이 있었습니다. `/retro --deep`으로 전문가 분석과 학습 리소스를 받을 수 있습니다.
