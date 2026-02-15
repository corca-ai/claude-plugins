# Retro: Markdown Guard 플러그인 및 린트 품질 개선

> Session date: 2026-02-07
> Mode: light

## 1. Context Worth Remembering

- **markdownlint-cli2 ≠ markdownlint-cli**: 이 프로젝트는 `markdownlint-cli2` (v0.20.0)를 사용하고 있다. 두 도구는 설정 파일 형식이 다르다:
  - `markdownlint-cli` (v1): `.markdownlintignore` 지원
  - `markdownlint-cli2`: `.markdownlint-cli2.jsonc`의 `"ignores"` 속성 사용, `.markdownlintignore` 미지원
- **PostToolUse vs PreToolUse JSON 형식**: PreToolUse 훅은 `hookSpecificOutput.permissionDecision` 방식이지만, PostToolUse 훅은 `{"decision": "block", "reason": "..."}` 형태의 더 단순한 top-level JSON을 사용한다
- **중첩 코드 펜스 문제**: 마크다운 예시에서 ` ```markdown ` 안에 ` ```gherkin ` 같은 내부 코드 펜스가 있으면 바깥 블록이 조기 종료된다. 4-backtick 펜스(```` ```` ````)로 감싸는 것이 해법
- **현재 마크다운 린트 설정**: `.markdownlint.json`(규칙 설정) + `.markdownlint-cli2.jsonc`(무시 패턴) 조합. MD013, MD031-034, MD036, MD041, MD060 비활성화
- **플러그인 개수**: 마켓플레이스에 9개 플러그인 등록 (markdown-guard 추가 후). INFRA 카테고리에 3개: attention-hook, prompt-logger, markdown-guard

## 2. Collaboration Preferences

이번 세션은 계획 모드에서 설계한 plan.md를 구현하는 세션이었다. 유저가 plan.md를 직접 제공하고 "Implement the following plan" 명령으로 시작했으므로, 별도의 요구사항 확인 없이 바로 구현에 돌입했다.

**관찰된 작업 스타일**:
- 병렬 작업 선호 — plan에 WS1-3 병렬 수행이 명시되어 있었고, 실제로 파일 읽기와 편집을 최대한 병렬로 실행
- 유저는 plan에 구체적인 파일, 라인 번호, 언어 specifier까지 미리 조사해둠 → 구현 단계에서 불확실성 최소화

CLAUDE.md 업데이트 제안 없음 — 현재 CLAUDE.md의 마크다운 코드 펜스 규칙(line 49)이 이미 정확하게 반영되어 있다.

## 3. Waste Reduction

**효율적이었던 부분**:
- plan에서 미리 조사한 파일/라인 정보 덕분에 탐색 시간이 절약됨. 34개 린트 에러의 위치가 모두 사전 파악되어 있었다
- Explore agent로 모든 파일 내용을 한 번에 읽어온 뒤 개별 편집으로 이어간 패턴은 컨텍스트 효율적이었다

**개선 가능한 부분**:
- Explore agent가 18개 파일을 읽었지만, 이후 편집에 필요한 파일들을 또 개별적으로 Read해야 했다 (Edit 도구가 사전 Read를 요구하기 때문). Explore agent 결과는 "이해"에는 도움이 되지만, Edit의 "사전 Read 요건"을 충족시키지 못한다. 향후에는 편집 대상 파일을 직접 Read로 먼저 읽고, Explore는 구조 파악 목적으로만 사용하는 것이 더 효율적
- `.markdownlint.json` 편집 시 "File has not been read yet" 에러가 한 번 발생 — Explore agent가 이미 읽었으므로 괜찮을 것이라 예상했지만, Edit 도구는 Read 도구의 직접 호출만 인정한다. 1턴 낭비

## 4. Critical Decision Analysis (CDM)

### CDM 1: markdownlintignore 버그의 해결 방식 선택

| Probe | Analysis |
|-------|----------|
| **Cues** | `npx markdownlint-cli2 "**/*.md"`가 prompt-logs/ 파일을 1244개 에러와 함께 린트한 것 — `.markdownlintignore`가 작동하지 않음 |
| **Goals** | prompt-logs/ 제외 + 기존 `.markdownlintignore` 파일과의 공존 |
| **Options** | (1) `.markdownlint-cli2.jsonc` 파일 생성, (2) CLI 인자로 `"!prompt-logs/"` 추가, (3) `.gitignore`에 의존 (`"gitignore": true`), (4) `.markdownlintignore`를 작동시키기 위해 markdownlint-cli (v1)으로 전환 |
| **Basis** | `.markdownlint-cli2.jsonc`가 가장 명시적이고 영구적인 해결책. CLI 인자는 매번 타이핑해야 하고, gitignore 의존은 prompt-logs/가 git에 추적되고 있어 적용 불가, v1 전환은 과도한 변경 |
| **Aiding** | WebFetch로 공식 GitHub README를 확인하여 `.markdownlintignore`가 미지원됨을 검증한 것이 결정적 |
| **Hypothesis** | CLI 인자 방식을 선택했다면, hook 스크립트에서도 매번 `!prompt-logs/`를 전달해야 해서 유지보수 부담이 증가했을 것 |

**핵심 교훈**: 도구의 공식 문서를 반드시 확인하라. 비슷한 이름의 도구(markdownlint-cli vs markdownlint-cli2)가 호환되지 않는 설정 형식을 사용할 수 있다.

### CDM 2: protocol.md의 중첩 코드 펜스 처리 전략

| Probe | Analysis |
|-------|----------|
| **Cues** | plan.md에서 "structural false positive, may need markdownlint-disable"로 사전 분석됨 |
| **Goals** | MD040 위반 해결 + 기존 마크다운 렌더링 보존 |
| **Options** | (1) `<!-- markdownlint-disable MD040 -->` + 4-backtick fence 조합, (2) language specifier를 `text`로 지정 (내용이 gherkin이므로 부정확), (3) 해당 파일만 MD040 비활성화, (4) `.markdownlintignore`에 추가 |
| **Basis** | 4-backtick fence는 마크다운 파서가 내부 3-backtick을 그대로 보존하므로 구조적으로 올바른 해결책. markdownlint-disable 주석과 함께 사용하면 린트도 통과하고 렌더링도 정확 |
| **Knowledge** | 마크다운 스펙에서 N개의 backtick으로 여는 코드 블록은 정확히 N개 이상의 backtick으로만 닫힌다는 규칙 |
| **Experience** | 경험이 적은 사람이었다면 `text`로 language specifier를 붙여 "형식적으로" 해결했겠지만, 실제 내용(gherkin 코드 블록이 포함된 markdown 예시)과 불일치 발생 |

**핵심 교훈**: 린트 에러를 표면적으로 해결하지 말고 구조적 원인을 파악하라. 중첩 코드 펜스는 backtick 개수를 늘리는 것이 마크다운 스펙 상 정식 해법이다.

### CDM 3: PostToolUse 훅의 decision 형식 선택

| Probe | Analysis |
|-------|----------|
| **Cues** | plan.md에서 "official PostToolUse pattern per docs"로 `{"decision": "block", "reason": "..."}` 형식을 지정 |
| **Goals** | 훅이 린트 위반을 감지했을 때 Claude가 자체 수정하도록 유도 |
| **Options** | (1) `{"decision": "block", "reason": "..."}` (plan 제안), (2) PreToolUse 형식 (`hookSpecificOutput.permissionDecision`) 차용, (3) 표준 exit code만 사용 (exit 1) |
| **Basis** | plan에서 이미 공식 문서 기반으로 결정됨. 단위 테스트에서 실제 동작 확인 |
| **Situation Assessment** | lessons.md에 기록된 대로 PreToolUse와 PostToolUse의 JSON 스키마가 다르다는 점이 구현 과정에서 확인됨 |

**핵심 교훈**: Claude Code의 훅 이벤트 타입(Pre/Post/Notification)마다 output 스키마가 다르다. 공식 문서 또는 기존 작동하는 훅을 참조 패턴으로 사용하라.

## 5. Expert Lens

> Run `/retro --deep` for expert analysis.

## 6. Learning Resources

> Run `/retro --deep` for learning resources.

## 7. Relevant Skills

### Installed Skills

| Skill | 세션 관련성 |
|-------|------------|
| `retro` (corca) | 현재 사용 중 — 세션 회고 |
| `refactor --docs` (corca) | 이번에 수정한 docs-criteria.md에 bare code fence 체크를 추가함. 향후 `/refactor --docs`로 린트 컴플라이언스 검증 가능 |
| `plugin-deploy` (local) | `/plugin-deploy`로 버전 체크, marketplace 동기화, README 업데이트를 자동화할 수 있었으나 이번 세션에서는 수동으로 처리함 |
| `hookify` (claude-plugins-official) | 훅 개발용 공식 스킬. 이번 세션에서는 기존 smart-read 패턴을 참조하여 직접 작성했으나, 복잡한 훅 개발 시 참고할 가치 있음 |

### Skill Gaps

`markdown-guard` 플러그인 자체가 이번 세션에서 만들어진 스킬 갭의 해결책이다. 이전 세션들에서 반복적으로 발생한 bare code fence 문제를 PostToolUse 훅으로 자동 감지하도록 구조화했다.

추가적인 스킬 갭은 식별되지 않음.

---

이번 세션은 설계와 구현이 긴밀하게 연결된 multi-file 변경 세션이었다. 사전 계획(plan.md)에서 구체적인 파일/라인/언어 specifier까지 조사한 덕분에 구현이 효율적이었고, 예상치 못한 문제(markdownlintignore 비호환)도 빠르게 해결했다. Run `/retro --deep` for expert analysis and learning resources.
