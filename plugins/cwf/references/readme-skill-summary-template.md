# README Skill Summary Template (Pilot)

Template for high-level skill summaries in `README` locale mirrors.

## Purpose

Keep `README` summaries readable and comparable at a glance, while leaving execution contracts in each skill's `SKILL.md`.

## Scope Boundary

- `README`: overview only (intent, input category, processing approach, visible outcomes)
- `SKILL.md`: full execution details (flags, edge cases, rollback, low-level flow)

## Required Labels

Use this exact section order in localized summaries:

1. `의의`
2. `Input(입력값)`
3. `Process(입력의 처리 방법)`
4. `Output(파일 산출물 및 에이전트 응답)`

## Writing Rules

- Read the target skill's `SKILL.md` body first (`Quick Start`, workflow/phases, and rules) before drafting summary text.
- Do not add behavior not grounded in `SKILL.md`; if uncertain, keep wording conditional/neutral.
- Keep each section concise (1-2 short paragraphs or 2-3 bullets).
- Keep `Process(입력의 처리 방법)` to at most 3 sentences.
- In `Input(입력값)`, include both:
  - how users trigger the skill in natural request language
  - how the skill runs when users ask for `cwf:run`
- Coverage range `(지원 범위: ...)` is optional:
  - include it when scope boundaries are not obvious (for example, multi-source or multi-mode skills)
  - omit it when the skill intent is already self-evident
- Put concrete prompt examples in `샘플 시나리오`, not `Input(입력값)`.
- Prefer realistic prompts that users are likely to type in production sessions.
- In `Output(파일 산출물 및 에이전트 응답)`, use category bullets and include only relevant ones:
  - `파일 생성`
  - `파일 수정`
  - `에이전트 응답` (prefer to include in most skills)
- Describe coverage categories, not option/flag names.
- Focus on user-visible behavior, not internal command choreography.

## Minimal Template

```md
### [skill-name](plugins/cwf/skills/<skill>/SKILL.md)

**의의**

<Why this skill exists in the workflow.>

**Input(입력값)**

- 사용자가 <request category>를 요청할 때 실행됩니다.
- 필요할 때만 지원 범위를 덧붙입니다. (지원 범위: <coverage categories>)
- 사용자가 `cwf:run`으로 작업을 요청하면 <pipeline stage>에서 실행되어 <stage role>을 수행합니다.

**Process(입력의 처리 방법)**

<How the skill transforms the input at a high level.>

**Output(파일 산출물 및 에이전트 응답)**

- 파일 생성: <Generated artifacts/files, if applicable>
- 파일 수정: <Modified files/state, if applicable>
- 에이전트 응답: <User-visible response summary, decisions, gates, or follow-ups>

**샘플 시나리오**

1. 직접 실행:
    - 입력: "<sample prompt>"
    - 결과: <response summary + artifact/file outputs>
2. `cwf:run` 실행:
    - 입력: "<run request prompt>"
    - 결과: <pipeline-stage output handed to next skill>
```
