### Expert Reviewer α: David Parnas
**Framework Context**: 정보 은닉 기준으로 모듈 경계와 coupling을 살피며 외부에 내부 세부를 누설하지 않는지를 본다 (On the Criteria To Be Used in Decomposing Systems into Modules, CACM 1972)
#### Concerns (blocking)
- [blocking] `plugins/cwf/scripts/codex/sync-skills.sh:17-190` — 이제 모듈이 `PLUGIN_ROOT/skills`만 바라보고 이전처럼 `REPO_ROOT/skills`/`REPO_ROOT/plugins/<name>/skills` 감지나 `--plugin` 옵션 없이 단일 레이아웃을 강제합니다. 이로 인해 `cwf:setup --codex`나 `cwf:update`가 설치 레이아웃이 달라지는 개발/패키징 환경(예: 플러그인을 repo 루트로 풀어놓거나 다른 `plugins/*` 하위로 옮겨둔 상태)에서 `SOURCE_SKILLS_DIR`를 찾지 못하고 “Source skills directory not found”로 종료합니다. 이러한 레이아웃 지식의 누설은 정보 은닉 위반이며, 모듈 경계를 뚜렷하게 유지해 다른 패스에서도 재사용할 수 있어야 하는 명세를 깨므로 blocking입니다.
#### Suggestions (non-blocking)
- 재사용성과 정보 은닉을 회복하려면 `SOURCE_SKILLS_DIR`를 외부에서 덧입힐 수 있는 옵션(`--source-path`, `--plugin` 등)이나 루트 감지 코드를 다시 도입하고, 감지 실패 시 명확한 안내(현재 기대하는 루트와 어떻게 맞출 것인지)를 출력하면 좋겠습니다. 그렇게 하면 스크립트가 현재 리포의 물리적 레이아웃에 결합되지 않고 다양한 통합 환경에서도 안전하게 호출될 수 있습니다.
#### Provenance
- source: REAL_EXECUTION
- tool: claude-task
- expert: David Parnas
- framework: Information Hiding
- grounding: On the Criteria To Be Used in Decomposing Systems into Modules (CACM, 1972)

<!-- AGENT_COMPLETE -->
