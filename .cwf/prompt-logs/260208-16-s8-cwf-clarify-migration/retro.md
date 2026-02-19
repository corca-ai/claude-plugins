# Retro: S8 — Migrate clarify → cwf:clarify

> Session date: 2026-02-08
> Mode: light

## 1. Context Worth Remembering

- CWF 마이그레이션은 이제 명확한 패턴이 확립됨: S7(gather-context → cwf:gather)의 패턴을 S8에서 그대로 재사용
- clarify 플러그인은 스크립트 없이 SKILL.md + 4개 참조 파일로만 구성되어 있어 가장 간단한 마이그레이션 대상
- `{SKILL_DIR}/references/` 패턴을 사용하는 참조 파일은 위치 변경 시 수정 불필요 — 런타임에 해석됨
- cwf:review --mode clarify 연동은 S5a/S5b에서 이미 완료되어 있어 별도 작업 불필요

## 2. Collaboration Preferences

- 사전에 잘 정의된 플랜이 있을 때 구현이 매우 효율적 — 이번 세션은 단일 턴으로 전체 구현 완료
- diff로 변경 검증하는 패턴이 효과적 (참조 파일 동일성 + SKILL.md 변경점 확인)

### Suggested CLAUDE.md Updates

없음 — 이미 `/clarify` → `cwf:clarify` 변경 완료.

## 3. Waste Reduction

이번 세션에서 의미 있는 낭비 없음. 잘 정의된 플랜 + 반복된 마이그레이션 패턴 덕분에 단일 턴으로 완료.

한 가지 관찰: 참조 파일 4개를 Write 도구로 각각 작성하는 대신 `cp` 명령으로 일괄 복사할 수 있었음. 하지만 Write 도구 사용은 내용이 정확히 복사되었는지 시스템 수준에서 보장하므로 trade-off가 있음 (diff 검증으로 확인함).

**근본 원인**: 일회성 선택 — 구조적 문제 아님.

## 4. Critical Decision Analysis (CDM)

### CDM 1: Path A 가용성 체크에 cwf:gather 추가

| Probe | Analysis |
|-------|----------|
| **Cues** | 원본 SKILL.md가 `/gather-context` 스킬 존재 여부로 Path A/B를 분기 — cwf:gather가 동일 기능을 제공하므로 체크 조건 확장 필요 |
| **Goals** | 하위 호환성 유지 (기존 gather-context 사용자) vs 전방 호환성 확보 (cwf:gather 사용자) |
| **Options** | (a) cwf:gather만 체크, (b) 두 가지 모두 체크, (c) 원본 그대로 유지 |
| **Basis** | 두 가지 모두 체크하면 S14 전환기 동안 어떤 조합으로든 동작 — 비용 없는 방어적 패턴 |
| **Aiding** | project-context.md의 "Defensive cross-plugin integration" 패턴이 이 결정을 가이드 |

**핵심 교훈**: 마이그레이션 중 스킬 간 참조는 old + new 모두 인식하도록 방어적으로 작성해야 전환기가 안전하다.

### CDM 2: Phase 5에 cwf:review --mode clarify 후속 제안 추가

| Probe | Analysis |
|-------|----------|
| **Cues** | S5a/S5b에서 review --mode clarify가 이미 구현됨 — 하지만 clarify SKILL.md에서는 이를 언급하지 않아 발견성이 낮음 |
| **Goals** | CWF 스킬 간 연결성 강화 vs SKILL.md 원본 충실도 |
| **Options** | (a) 추가하지 않음 (원본 그대로), (b) Phase 5 끝에 후속 제안 추가, (c) 별도 "Integration" 섹션 |
| **Basis** | (b) 선택 — 최소 변경으로 발견성 확보. CWF 통합의 가치는 스킬 간 연결에 있음 |

**핵심 교훈**: 통합 플러그인으로 마이그레이션할 때 단순 복사가 아닌 스킬 간 cross-reference 추가가 부가가치.

## 5. Expert Lens

> Run `/retro --deep` for expert analysis.

## 6. Learning Resources

> Run `/retro --deep` for learning resources.

## 7. Relevant Skills

### Installed Skills

| Skill | 관련성 |
|-------|--------|
| `cwf:gather` | Phase 2 Path A에서 직접 참조 — search.sh 경로를 cwf 내부로 업데이트함 |
| `cwf:review --mode clarify` | Phase 5에서 후속 제안으로 연결 — 이미 S5a/S5b에서 구현 완료 |
| `/plugin-deploy` | 커밋 후 배포 워크플로 자동화에 사용 예정 |
| `/retro` | 현재 사용 중 |

### Skill Gaps

추가 스킬 갭 식별되지 않음. CWF 마이그레이션은 기존 스킬 조합으로 충분히 커버됨.
