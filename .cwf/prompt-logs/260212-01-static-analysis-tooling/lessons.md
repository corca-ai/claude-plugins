# Lessons — Static Analysis Tooling

### Explore 에이전트는 파일을 쓸 수 없다

- **Expected**: Explore 서브에이전트가 분석 결과를 파일로 직접 기록할 것
- **Actual**: Explore 타입은 Write/Edit 도구가 없어서 파일 영속화 불가
- **Takeaway**: 파일 출력이 필요한 연구 작업은 `general-purpose` 에이전트를 사용해야 함

When Explore 에이전트에게 파일 쓰기가 필요한 작업 → general-purpose 서브에이전트 사용

### 이 규모에서 생물정보학 알고리즘은 과잉

- **Expected**: Smith-Waterman, suffix array 등이 문서 중복 감지에 유용할 것
- **Actual**: 10K 줄 규모에서는 MinHash + LSH가 충분하고, 생물정보학 도구는 수백만 줄 게놈 비교에 최적화된 것
- **Takeaway**: 데이터 규모를 먼저 확인하고 도구를 선택해야 함. 이 규모에서는 datasketch 단독으로 충분

### textstat/readability는 LLM-to-LLM 문서에 무의미

- **Expected**: 가독성 지표가 문서 품질 개선에 기여할 것
- **Actual**: Flesch-Kincaid 등은 인간 독자를 위한 음절/문장길이 기반 공식이며, LLM은 이에 영향받지 않음
- **Takeaway**: 도구 도입 시 실제 소비자(이 경우 LLM)의 특성을 고려해야 함

### node_modules must be excluded from all file-scanning scripts

- **Expected**: `.gitignore`'d directories like `scripts/node_modules/` would naturally be excluded from analysis
- **Actual**: `pathlib.rglob()` and `find` scan all filesystem paths regardless of `.gitignore`. Both `find-duplicates.py` and `doc-churn.sh` picked up node_modules readme files (713 false positive duplicate pairs, dozens of "unknown" churn entries)
- **Takeaway**: Every script that scans for `.md` files must explicitly exclude `node_modules/` and `.git/`. The `doc-graph.mjs` script got this right by design (it already excluded `node_modules`), but the other two did not

### provenance-check.sh color pattern has a latent bug

- **Expected**: The TTY-guarded color pattern from `provenance-check.sh` would be safe to replicate
- **Actual**: `provenance-check.sh` only checks `[[ -t 1 ]]` but does NOT disable color when `--json` output is active. Piping `--json` to a TTY would embed ANSI codes in JSON strings
- **Takeaway**: New scripts use a combined guard: `if [[ -t 1 ]] && [[ "$JSON_OUTPUT" != "true" ]]`. The existing bug in `provenance-check.sh` should be fixed separately
