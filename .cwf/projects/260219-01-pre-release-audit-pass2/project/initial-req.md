# Initial Request and Operating Philosophy

## Original User Request (verbatim)

> 퍼블릭 배포 전 점검 중입니다. 할때마다 새로운 게 발견되어 몇 번 반복하고 있습니다. 토큰 많이 들어도 되니 서브에이전트 최대한 활용해서 제대로 다음을 해주세요.
> 1. refactor --codebase 후 발견된 것 수정
> 2. --skill 전체에 대해 deep 후 발견된 것 수정
> 3. --docs 후 발견된 것 수정
> 4. 리드미가 주장하는 SoT에 대해 cwf 플러그인이(모든 스킬과 훅이) 그 약속을 정말 잘 맞추고 있는지, 그리고 플러그인이 repo-agnostic하게 / 또는 첫 실행시 계약 기반으로 훌륭하게 동작하는지 (즉 이 repo -> cwf 는 강하게 의존하지만, cwf -> 이 repo 의존성은 없어서, 다른 유저의 리포에서 독립적으로 잘 동작하게 되는지), 쓸데없이 하위호환을 유지하려고 하진 않는지(v3는 아직 미배포 상태고 v2 대비 어치피 대격변이라서 하위호환 불필요. v3가 깔끔하게 잘 되는 게 가장 중요) 등등, 그리고 그 외 여러가지 더 지능적으로 잘, 깊이 검토해주세요.
>
> 이 과정에서 제 의사결정이 필요한 게 있으면 멈추고, 각 선택지의 트레이드오프를 보여주세요. 함께 논의하고 결정해서 갑시다. 모호한 점이 있으면 clarify 하고, cwf:plan 해서 시작합시다. 구현 후에는 cwf:review 하고, 마지막에 retro. 이해하셨나요? 적절한 단위로 커밋하면서 진행하고, 마지막에는 retro 결과 보여주면서 persist 후보도 제안해주세요.

## Operating Philosophy

1. v3 release readiness is prioritized over backward compatibility with v2.
2. Deterministic gates are the final pass/fail authority.
3. Repo-agnostic and contract-first behavior must be verifiable with concrete evidence.
4. Ambiguous/high-impact design choices require explicit user confirmation with trade-offs.
5. Changes must be committed in meaningful concern boundaries.

## Iteration Execution Contract

1. Run and record evidence for `plan -> review -> impl -> review -> refactor -> retro`.
2. Stop immediately and record evidence when runtime behavior diverges from intent.
3. Persist lessons and progress updates so the next iteration can resume from files alone.
