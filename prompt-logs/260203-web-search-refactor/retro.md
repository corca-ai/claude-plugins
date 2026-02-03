# Retro: web-search Script Delegation Refactoring

> Session date: 2026-02-03

## 1. Context Worth Remembering

- **Script delegation pattern**이 corca-plugins의 execution-heavy skill 아키텍처 원칙으로 확립됨. SKILL.md는 intent 분석, 스크립트는 deterministic 실행 담당.
- Claude Code Bash tool은 bash 세션으로 실행됨. `~/.zshrc` export가 자동 로드되지 않으므로, 스크립트에서 env var를 로딩할 때 shell profile grep이 필요함.
- web-search 플러그인이 v1.2.1 → v2.0.0으로 breaking change. 실행 모델이 "SKILL.md가 curl 직접 지시" → "SKILL.md가 스크립트 호출 지시"로 변경.
- `api-reference.md`는 삭제하지 않고 유지. 스크립트가 로직을 embed하고 있지만, 사람이 읽는 API 레퍼런스로서의 가치가 있음. 향후 제거 여부는 deferred.

## 2. Collaboration Preferences

- 사용자가 "세션에서 나갔다 오겠습니다"라고 했을 때, 에이전트가 자율적으로 전체 워크플로우(구현→테스트→문서→커밋)를 실행하는 것을 기대함. 중간에 질문하지 않고 최대한 진행하되, 블로커가 있으면 호출.
- 사용자가 env key 로딩 문제를 직접 지적함. 에이전트가 `source ~/.zshrc`로 테스트를 통과시킨 것은 "작동하지만 실사용에서는 문제"인 케이스. 사용자는 이런 실용적 gap을 중요하게 봄.

### Suggested CLAUDE.md Updates

- `Collaboration Style`에 추가 제안: "스크립트 테스트 시, 수동으로 환경을 세팅한 뒤 테스트하지 말고 clean 환경에서 테스트하여 실사용 조건을 재현할 것"

## 3. Prompting Habits

- 사용자의 "plan-web-search-refactor.md 를 plan-and-lesson 프로토콜에 따라 구현해주세요" 프롬프트는 매우 효율적이었음. 기존 플랜 파일을 지정하고, 프로토콜을 참조하고, 자율 실행을 위임하는 세 가지를 한 문장에 담음.
- "필요시 저를 호출해주세요"까지 포함하여 에이전트의 자율성 범위를 명확히 설정. 개선할 부분 없음.

## 4. Learning Resources

- [Loading .env (dotenv) using bash or zsh](https://www.cicoria.com/loading-env-dotenv-using-bash-or-zsh/) — bash/zsh 간 .env 로딩 차이와 best practice. 이번 세션에서 다룬 env 로딩 문제의 배경지식
- [Beyond Function Calling: How Claude Code's Plugin Architecture Is Redefining AI Development Tools](https://thamizhelango.medium.com/beyond-function-calling-how-claude-codes-plugin-architecture-is-redefining-ai-development-tools-67ccec9b5954) — Claude Code 플러그인 아키텍처의 protocol-first 설계 철학. script delegation pattern의 상위 맥락
- [Environment variables in bash_profile or bashrc?](https://superuser.com/questions/409186/environment-variables-in-bash-profile-or-bashrc) — `.bash_profile` vs `.bashrc` vs `.zshrc`에서 env var를 어디에 둘지에 대한 canonical 답변

## 5. Relevant Skills

이번 세션에서 새로운 스킬 gap은 식별되지 않음. 기존 플러그인의 아키텍처 개선 작업이었으며, `/retro`, `/web-search` 등 기존 스킬이 워크플로우에 잘 활용됨.
