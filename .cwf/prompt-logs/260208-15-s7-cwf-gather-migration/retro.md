# Retro: S7 — Migrate gather-context → cwf:gather

> Session date: 2026-02-08
> Mode: light

## 1. Context Worth Remembering

- CWF v3 마이그레이션에서 첫 번째 스킬(gather) 통합 완료. 이전까지 CWF는 hooks만 보유.
- gather-context는 프로젝트에서 가장 복잡한 플러그인 (하이브리드: hook + skill, 8 스크립트, 6 레퍼런스, 외부 API 통합 다수).
- "복사 후 보존" 전략 채택 — 기존 `plugins/gather-context/`는 S14 deprecation까지 유지. 이중 유지보수 비용 발생하지만, 안전한 전환을 우선.
- CWF 스텁 패턴(S4에서 설계)이 실제 마이그레이션에서 검증됨 — `redirect-websearch.sh` 스텁을 최소 변경으로 활성화.

## 2. Collaboration Preferences

- 사전 설계된 플랜이 상세할수록 구현이 빠르고 정확함. 이 세션은 플랜 → 구현 → 검증이 2턴만에 완료.
- 사용자가 "yep" 수준의 확인만으로 전체 후속 작업(retro → commit → push → update-all) 진행을 허락하는 패턴.

### Suggested CLAUDE.md Updates

- 핸드오프(next-session.md) 작성 시: 최근 예시가 아닌 master-plan.md의 canonical 템플릿을 먼저 참조할 것. 컨벤션 변경 후 이전 예시는 stale할 수 있음.

## 3. Waste Reduction

### 핸드오프에서 stale 패턴 복제 (사용자 지적으로 발견)

next-session.md 작성 시 `cwf-state.yaml`이 SSOT라고 선언하면서, 바로 아래에 수동 상태 테이블을 중복 작성. 사용자가 지적하기 전까지 에이전트가 자체적으로 발견하지 못함.

**근본 원인 (5 Whys)**:
1. 왜 수동 테이블을 넣었나? → S6b next-session.md를 참고했으니까
2. 왜 S6b를 참고했나? → "가장 최근 예시 = 최신 컨벤션"이라 가정
3. 왜 그 가정이 틀렸나? → S7-prep에서 cwf-state.yaml 도입으로 컨벤션이 변경됨
4. 왜 변경을 인지 못했나? → cwf-state.yaml에 엔트리는 추가하면서, 핸드오프 작성 시에는 canonical 템플릿(master-plan.md line 414)을 재확인하지 않음
5. 왜 재확인하지 않았나? → **예시 기반 작성이 습관화** — 실제 예시 복사가 템플릿 참조보다 빠르다는 편향

**분류**: 프로세스 갭 (구조적)
**수정**: 핸드오프 작성 시 반드시 master-plan.md의 canonical 템플릿을 먼저 읽을 것. 최근 예시는 참고용이지 템플릿이 아님. 특히 컨벤션이 최근 변경된 경우 이전 예시는 stale.

### 마이너: `cp *`에서 `__pycache__`

- `cp *`에서 `__pycache__` 디렉토리 때문에 exit 1 반환 → 실제 문제 없음, 하지만 CI/CD 환경에서는 `set -e` 스크립트에서 실패할 수 있음.
- **근본 원인**: 일회성 문제, 구조적 수정 불필요.

## 4. Critical Decision Analysis (CDM)

### CDM 1: 스텁 교체 방식 — 전체 파일 교체 vs 부분 수정

| Probe | Analysis |
|-------|----------|
| **Cues** | 기존 스텁이 gate 메커니즘 + stdin 소비까지 이미 포함. `exit 0` 직전에 deny JSON만 추가하면 됨. |
| **Goals** | 최소 변경으로 안전한 전환 vs 플랜에 명시된 전체 교체 |
| **Options** | (A) Edit로 `exit 0` → deny JSON 변경, (B) Write로 전체 파일 교체 |
| **Basis** | 플랜이 전체 스크립트를 명시적으로 제공했고, 주석 문구도 변경 필요 (stub 참조 제거). Write가 더 명확. |
| **Hypothesis** | Edit 방식이었다면 주석의 "Stub: real implementation in S6a migration" 문구가 남았을 수 있음. |

**Key lesson**: 스텁 → 실제 전환 시, 주석과 코드를 모두 업데이트해야 하므로 전체 교체가 부분 수정보다 안전.

### CDM 2: notion-to-md.py 실행 권한 — 원본 따르기 vs 일괄 +x

| Probe | Analysis |
|-------|----------|
| **Cues** | `chmod +x *` 후 `ls -la` 확인에서 notion-to-md.py가 `-rw-` 상태 발견 |
| **Goals** | 모든 스크립트가 실행 가능해야 하지만, `.py`는 `python3`으로 호출하므로 shebang 실행과 무관 |
| **Options** | (A) +x 부여 (일관성), (B) 원본 유지 (-rw-, 어차피 python3으로 호출) |
| **Basis** | 플랜이 "Ensure `chmod +x` on all"을 명시. SKILL.md에서 `python3 {SKILL_DIR}/scripts/notion-to-md.py`로 호출하므로 +x 필수 아니지만, 일관성과 플랜 준수를 위해 부여. |
| **Aiding** | `cp`가 원본 권한을 보존하므로, 복사 후 별도 `chmod` 단계가 필요하다는 체크리스트가 유용 |

**Key lesson**: 마이그레이션 시 "복사 후 권한 확인"을 별도 단계로 분리하면 누락 방지.

## 5. Expert Lens

> Run `/retro --deep` for expert analysis.

## 6. Learning Resources

> Run `/retro --deep` for learning resources.

## 7. Relevant Skills

### Installed Skills

**마켓플레이스 (cache)**:
- `gather-context` v2.0.2 — 이 세션의 마이그레이션 대상. CWF 내 `cwf:gather`로 복제 완료.
- `retro` v2.0.2 — 현재 실행 중.
- `clarify` v2.0.1 — 이 세션에서는 플랜이 사전 확정되어 사용 불필요.
- `refactor` v1.1.2 — 마이그레이션 후 `--skill gather` 리뷰로 SKILL.md 품질 검증 가능 (선택적).

**로컬 스킬**:
- `plugin-deploy` — 커밋 후 버전/마켓플레이스 동기화에 사용 가능. 단, 이 세션은 CWF 내부 변경이므로 marketplace.json 업데이트 불필요 (S14에서 처리).
- `ship` — PR 생성/머지 자동화. marketplace-v3 브랜치 작업이므로 최종 머지 시 활용.
- `review` — 코드 리뷰 자동화. 대규모 변경 시 유용하지만 이 세션은 복사 + 어댑트 수준.

### Skill Gaps

이 세션에서 추가 스킬 갭은 식별되지 않음. 마이그레이션 작업은 기존 도구로 충분히 커버됨.
