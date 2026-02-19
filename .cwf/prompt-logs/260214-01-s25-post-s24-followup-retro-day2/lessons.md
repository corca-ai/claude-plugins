# Lessons — S25: Post-S24 Follow-up

### Colon-delimited string encoding is a code smell for positional data

- **Expected**: The existing check-schemas.sh colon-delimited format (`"schema:data:converter"`) was a compact way to associate validation targets
- **Actual**: IFS parsing with colons is fragile and hides the parameter structure — a classic information hiding violation (Parnas)
- **Takeaway**: When data has positional structure (schema, data file, converter), use parallel arrays or positional function args. String encoding saves lines but costs readability and debuggability.

### Hook group reuse simplifies toggling but merges unrelated concerns

- **Expected**: Giving check-links-local.sh its own HOOK_GROUP would allow independent toggling
- **Actual**: Using `HOOK_GROUP="lint_markdown"` means link checking is controlled by the same toggle as markdown linting — appropriate since both are write-quality checks on .md files
- **Takeaway**: Hook group assignment should follow the user's mental model of "what kind of checking is this?" rather than strict functional separation. Users think "turn off markdown quality checks" not "turn off link validation separately from lint validation."

### Verified expert field eliminates a common turn-budget waste pattern

- **Expected**: Expert sub-agents would benefit from verified field to skip web identity verification
- **Actual**: Each expert agent spent 2-4 turns on web verification per invocation. With 15 verified experts and typical 2-expert usage per retro/review, this saves ~4-8 turns per deep analysis
- **Takeaway**: When a sub-agent repeatedly performs the same verification task that produces stable results, cache the verification status at the orchestrator level (cwf-state.yaml) rather than relying on agent-level deduplication.

### Mode-namespaced output files prevent silent data loss

- **Expected**: Review output files would be unique per session
- **Actual**: A session running both review-plan and review-code would overwrite review-security.md (and others) — the second review silently destroys the first review's output
- **Takeaway**: When an operation can run multiple times per session with different modes, namespace the output files by mode. This is the file-level equivalent of Parnas's namespace sharing violation.

### 날짜 prefix는 작업일이 아니라 세션 생성일로 해석될 수 있다

- **Expected**: 오늘이 260214이면 retro 출력 경로도 자동으로 260214로 잡힐 것이라 예상
- **Actual**: retro 경로 우선순위가 `live.dir` 재사용 중심이라 기존 260213 세션 디렉토리가 선택됨
- **Takeaway**: 세션 연속성과 날짜 정합성은 별도 축이다. 날짜 롤오버 시에는 `기존 세션 유지` vs `신규 날짜 디렉토리 생성`을 명시적으로 질문하는 규칙이 필요하다.

### setup는 단일 진입점이어야 온보딩 마찰이 줄어든다

- **Expected**: 사용자에게 `--git-hooks`, `--gate-profile` 같은 플래그를 안내하면 충분할 것이라 예상
- **Actual**: 옵션이 늘수록 사용자가 기억해야 할 표면적이 커져 실제 적용 누락 가능성이 증가함
- **Takeaway**: 외부 사용자 UX는 `cwf:setup` 한 번으로 끝나야 한다. 필요한 선택은 setup가 질문으로 수집하고, 실행은 스크립트가 결정론적으로 적용해야 한다.

### 3계층 게이트는 유효하지만 역할 분리를 지키지 않으면 중복 마찰이 생긴다

- **Expected**: Claude hook + pre-commit + pre-push를 모두 켜면 품질이 자동으로 개선될 것이라 예상
- **Actual**: 스코프/속도/차단 기준이 섞이면 같은 검사라도 체감 마찰이 급증함
- **Takeaway**: 같은 체크라도 계층별 책임을 분리해야 한다. 즉시 피드백(Claude hook), 변경 단위 보장(pre-commit), 전체 일관성 보장(pre-push)으로 분담하면 마찰 대비 효과가 가장 좋다.
