# Section 6 Draft — Learning Resources

## Web Research Trace

- Date: 2026-02-16
- Search intent:
  - setup/skills에서 누락 의존성 감지 시 수동 경고가 아닌 상호작용형 설치 UX 설계 근거
  - shell 스크립트 품질 게이트(`shellcheck`)와 post-run hygiene 자동화 근거
  - README.ko SoT 전파와 장기 세션/compact 이후에도 남는 증거 중심 운영 근거
- Verified external URLs:
  - <https://docs.npmjs.com/cli/v7/commands/npx>
  - <https://github.com/koalaman/shellcheck>
  - <https://www.writethedocs.org/guide/docs-as-code/>

## Recommended Resources

1. npm Docs — npx
   URL: <https://docs.npmjs.com/cli/v7/commands/npx>
   - Key takeaway: `npx`는 로컬에 없는 패키지를 실행할 때 설치 여부를 프롬프트로 확인하고, 자동화 환경에서는 `--yes`/`--no`로 동작을 명시적으로 고정할 수 있다. 즉, 같은 도구라도 인터랙티브 모드와 비대화형 모드를 분리해서 설계할 수 있다는 점이 핵심이다.
   - Why it matters: setup/skills의 "missing dependency" 처리도 단순 경고에서 끝내지 말고, 기본은 사용자 확인형 설치 플로우로 두고 CI/자동 실행에서는 명시 플래그로 우회하는 이중 경로를 설계하는 근거가 된다.

2. ShellCheck (koalaman/shellcheck)
   URL: <https://github.com/koalaman/shellcheck>
   - Key takeaway: ShellCheck는 쉘 스크립트의 정적 분석기로, 런타임 전에 quoting/word splitting/조건식 등 반복되는 결함 패턴을 자동으로 잡아낸다. 저장소 README는 이를 빌드/테스트 스위트(즉, 품질 게이트) 안에 넣어 지속적으로 실행하는 운영 방식을 직접 권장한다.
   - Why it matters: 이번 워크플로우의 post-run script hygiene를 "사람이 보는 권고"가 아니라 결정적 게이트로 승격할 때, changed-files 대상 `shellcheck` 실행과 모드별 실패 정책(`warn` vs `strict`)을 정당화하는 1차 근거다.

3. Write the Docs — Docs as Code
   URL: <https://www.writethedocs.org/guide/docs-as-code/>
   - Key takeaway: Docs as Code는 문서를 코드와 같은 방식으로 다루며, 이슈 트래커·버전 관리·코드 리뷰·자동 테스트를 문서 운영에 그대로 적용한다. 이렇게 하면 문서 변경의 근거와 이력이 분산되지 않고 동일한 개발 워크플로우 안에서 추적 가능해진다.
   - Why it matters: README.ko를 SoT로 두고 관련 docs/skills에 의도를 전파할 때 "어디서 무엇이 어긋났는지"를 PR/리뷰/검증 로그로 남길 수 있어, 장기 세션이나 compact 이후에도 상태 복구와 증거 기반 회고를 안정적으로 수행할 수 있다.

<!-- AGENT_COMPLETE -->
