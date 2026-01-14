# 플러그인 수정/테스트/배포

이 repo의 플러그인을 수정할 때의 워크플로우:

## 1. 수정

- `plugins/<plugin-name>/` 디렉토리의 파일을 수정한다.
- plugin.json에서 적절하게 해당 플러그인의 버전을 업데이트한다.

## 2. 테스트

플러그인 종류에 따라 테스트 방법이 다르다:

- **테스트 스크립트가 있는 경우** (예: `attention-hook`): 해당 스크립트 실행
  ```bash
  plugins/attention-hook/hooks/scripts/attention.test.sh
  ```
- **스킬의 경우**: 로컬 적용 후 직접 실행하여 동작 확인

## 3. 로컬 적용

플러그인은 설치 시 캐시로 복사되므로, 수정 후 반드시 재설치해야 한다:
```bash
/plugin install <plugin-name>@corca-plugins
```

## 4. 배포

수정이 완료되면 commit & push한다. 유저에게는 다음과 같이 안내:
```
플러그인이 업데이트되었습니다. 적용하려면:
1. /plugin marketplace update
2. /plugin install <plugin-name>@corca-plugins
```