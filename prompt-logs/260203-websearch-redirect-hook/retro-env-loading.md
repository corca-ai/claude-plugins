# Retro: web-search env 로딩 표준화

> Session date: 2026-02-03

## 1. Context Worth Remembering

- web-search 스킬은 documentation-driven — Claude가 api-reference.md를 보고 매번 bash 코드를 생성함. env 로딩 방법이 명시되어 있지 않으면 Claude가 자체적으로 불안정한 패턴(`grep | cut`)을 생성할 수 있음.
- `~/.claude/.env`는 플러그인 생태계의 표준 env 파일 위치. `export`, 따옴표 등 다양한 형식이 가능하므로 `source`가 유일하게 안전한 로딩 방법.
- curl exit code 5 ("Couldn't resolve proxy")는 실제로는 API 키 로딩 실패로 인한 빈 값/잘못된 값 전달이 원인이었음.

## 2. Collaboration Preferences

- 이전 retro 세션에서 발생한 부수적 발견(env 로딩 에러)을 유저가 즉시 개선 기회로 포착하는 패턴. 에이전트도 작업 중 발견한 이상 징후를 적극적으로 보고하는 것이 좋음.

## 3. Prompting Habits

- 특별한 개선 사항 없음. "네, 적용해주세요. 플러그인 버전 업데이트, 별도 retro, commit 도 합시다" — 작업 범위를 한 문장으로 명확히 지정하는 효율적인 패턴.

## 4. Learning Resources

- [Dotenv file format conventions](https://hexdocs.pm/dotenvy/dotenv-file-format.html) — .env 파일 형식의 비공식 표준. `export` 접두사, 따옴표 처리 등의 규칙.

## 5. Relevant Skills

이번 세션에서 skill gap 없음.
