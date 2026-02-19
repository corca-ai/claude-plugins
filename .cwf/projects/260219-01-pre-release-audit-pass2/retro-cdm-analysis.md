### CDM 1: `sync-skills`에서 legacy 정리 옵션 제거

| Probe | Analysis |
|-------|----------|
| **Cues** | `refactor-summary.md:40-57`에 기록된 메모처럼 `sync-skills.sh`에서 `--cleanup-legacy` 옵션과 오래된 레이아웃 분기를 제거했다는 사실이 실행 결과에 바로 반영되었고, `review-synthesis-code.md:27-35`에서는 reviewer가 그 옵션을 다시 넣자고 제안했지만 사용자 결정(1A: cleanup 제거, v3 정리 우선)이 이 제안을 향해 수렴하지 않음을 명시하고 있다. |
| **Goals** | v3 준비성을 높이고 SoT/contract 간극을 줄이려면 더 이상 미지원 레이아웃/이전 키에 대해 고정된 복잡도를 유지할 필요가 없으며, deterministic gate가 폐쇄된 상태에서 단일 동작 경로를 가정하는 것이 중요했다. |
| **Options** | (1) 기존처럼 cleanup 플래그와 legacy layout 처리를 유지해 관성 있는 업그레이드 경로를 남겨두기, (2) cleanup branch를 아예 제거하고 현재 plugin root 레이아웃만 처리하도록 단순화하기, (3) 둘을 결합한 중간책으로 옵션을 두되 기본 경로만 유지하고 문서에 fallback을 명시하는 방식. |
| **Basis** | 사용자 결정과 세션 목표를 따르며 `plugins/cwf/scripts/codex/sync-skills.sh`의 단순화는 v3 이상에서 “SoT claim = 실제 행동”이라는 계약을 위배하지 않으면서도 유지비를 줄였다. 리뷰어가 제안한 재도입을 그대로 따르지 않은 것은 “관성 있는 backward compatibility”보다 “단일 진입/출구에 기반한 deterministic 동작”을 선택한 것이었다. |
| **Experience** | 경험 많은 엔지니어는 오래된 layout이 아직 사용되는지 telemetry/telemetry를 먼저 확인하고, 그 수요가 없으면 제거하는 쪽으로 판단한다. 이 세션에서는 해당 정보를 찾을 수 없었기에, 더 보수적인 경험이라도 사용자 수준의 명시적인 지침(1A)으로 결정을 정당화했을 것이다. |

**Key lesson**: legacy cleanup 경로를 제거할 때는 명시적인 사용자 결정과 심사 아티팩트(`review-synthesis-code.md`)를 통해 “왜 다시 끌어올 수 없는지”를 보여줘야 reviewer 제안이 돌아오더라도 정책적으로 지탱할 수 있다.

### CDM 2: 계약 부트스트랩 실패 시 fail-safe(non-zero) 반환

| Probe | Analysis |
|-------|----------|
| **Cues** | `refactor-summary.md:44-63`에는 `bootstrap-setup-contract.sh`와 `bootstrap-codebase-contract.sh`의 fallback 경로가 이제 non-zero를 반환하고, 이를 확인하는 runtime check 스크립트들도 함께 강화되었다는 점이 나온다. 이전에는 fallback 경로가 성공으로 떨어져 문서/코드 계약이 겉보기엔 통과된 것처럼 보였다는 문제가 있었다. |
| **Goals** | 수동으로나 자동으로 contract를 부트스트랩할 때 “성공하면 계약을 만족했다”는 불변식을 지키려면 실패 여부가 exit code로 분명히 드러나야 했고, SoT/contract 검증 흐름은 거짓 positive를 허용하면 신뢰를 잃는다. |
| **Options** | (1) 기존처럼 실패해도 로깅 후 성공으로 반환하여 downstream이 계속 접근할 수 있게 두기, (2) fallback 경로가 실패하면 즉시 non-zero로 빠지도록 해 gating hook이나 pipeline이 실패 상태를 인지하게 하기, (3) 중간 형태로 “soft fail” 로그 후 user prompt를 거쳐 재시도하지만 exit code는 0. |
| **Basis** | v3 deterministic gate 정신에 따라 `bootstrap-*.sh`는 성공/실패가 exit code에서 명확해야 하고, 이 기준을 `check-*.sh` runtime tooling과 함께 맞추려면 `(2)`가 가장 일관되었다. 해당 변경으로 gate가 뚫린 구멍(문서는 통과해도 계약이 불완전한 상황)을 꿰찼다. |
| **Tools** | 변경된 `check-setup-contract-runtime.sh`와 `check-codebase-contract-runtime.sh`가 fail-safe semantics를 확인하며, `bash plugins/cwf/scripts/check-setup-contract-runtime.sh`를 돌렸을 때도 패스했으므로 (정상적 실패 없이) 전체 pipeline 신뢰도를 회복했다. |
| **Hypothesis** | 만약 이 fail-safe 전환을 하지 않았다면, 내/외부 검사 도구가 실제 실패를 감지하지 못하고 계약이 깨진 상태에서도 “파란불”을 보여주어 이후 release gate를 오인하게 만들었을 것이다. |

**Key lesson**: contract bootstrap 스크립트는 exit code를 통해 시스템 계약을 표현하므로, fallback 경로가 실패하면 반드시 non-zero를 반환하고 로그로 안내하되, downstream 검증 스크립트도 그 semantics를 따라야 신뢰를 유지할 수 있다.

### CDM 3: legacy env migration 스크립트를 setup 흐름에서 제외하고 README prompt로 안내

| Probe | Analysis |
|-------|----------|
| **Cues** | `refactor-summary.md:51-57`은 setup flow에서 `migrate-env-vars.sh` 같은 legacy env migration 스크립트를 떼어냈고, 대신 `README.md:553-558`에서 “cwf:setup” 흐름에서는 자동 실행하지 말고 수동 명령을 Claude Code/Codex prompt로 띄워달라는 지침을 넣었다고 기록한다. |
| **Goals** | SoT와 portability 요구는 신규 v3 설치자가 예상치 못한 legacy 키를 자동 이관하다가 사용자 환경을 오염시킬 위험을 줄이면서, 그래도 업그레이드 경로를 완전히 닫지 않도록 명확한 수동 절차를 제공하는 것이다. |
| **Options** | (1) setup 단계에 legacy migration을 포함해서 모든 설치자에게 자동 실행되게 두기, (2) 일반 흐름에서는 제거하되 README/README.ko에 별도 prompt를 두어 사용자 요청이 있을 때만 실행하기, (3) README에만 안내하는 대신 유예 기간을 두고 자동화하지만 `--dry-run`을 기본으로 두는 정책. |
| **Basis** | 사용자 결정 3번에서 “migrate script는 유지하지만 setup flow에서는 제거”했고, README prompt로 manual migration path를 남겨 두도록 함으로써 SoT claim(README 흐름 = 실제 동작)과 사용자 컨텍스트에 대한 실수를 방지했다. |
| **Tools** | README prompt의 `claude`/`codex`용 텍스트가 migration 시나리오를 다시 설명해 주므로, 수작업으로 `migrate-env-vars.sh --scan` → `--apply` 과정을 안내하는 `README.md:553-558`이라는 문서적 도구가 있다. |
| **Experience** | 더 보수적인 경험을 가진 팀원은 초기에는 모든 legacy 변수를 하나도 놓치지 않길 바라면서 자동화하도록 권할 수 있으나, 배포 신뢰도를 높이려면 기본 흐름에는 불필요한 변환을 넣지 않고 사용자가 명시적으로 실행하는 방향으로 전환하는 것이 V3 안정화에 유리했다. |

**Key lesson**: 레거시 migration이 민감한 작업이라면, 자동화 흐름에서 제거하되 README/prompt 같은 문서 기반 트리거를 제공하여 “필요할 때만 수동으로”라는 정책을 한눈에 보여줘야 한다.

<!-- AGENT_COMPLETE -->
