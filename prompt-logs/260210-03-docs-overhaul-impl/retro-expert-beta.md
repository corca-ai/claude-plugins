# Expert Retro — Session S32-impl

### Expert Beta: John Ousterhout

**Framework**: Deep vs Shallow 모듈, 복잡성 관리(complexity management), 정보 누출(information leakage), 전략적 vs 전술적 프로그래밍(strategic vs tactical programming), pass-through 메서드
**Source**: *A Philosophy of Software Design* (Yaknyam Press, 2018; 2nd ed. 2021), "Always Measure One Level Deeper" (*Communications of the ACM*, 2018). Ousterhout는 Stanford 컴퓨터과학과 교수이자 Tcl/Tk 창시자로, 2018년 출간한 이 저서에서 "소프트웨어를 작성하는 데 있어 가장 큰 제약은 우리가 만들고 있는 시스템을 이해하는 능력(The greatest limitation in writing software is our ability to understand the systems we are creating)"이라고 선언했다.
**Why this applies**: S32-impl은 9개 스킬에 걸친 cross-cutting 패턴 구현 세션이다. Ousterhout의 핵심 질문 — 각 모듈의 인터페이스가 숨기는 복잡성 대비 노출하는 복잡성의 비율은 적정한가? — 이 CWF 스킬 시스템의 추상화 품질을 평가하는 데 정확히 적용된다.

---

#### 1. Context Recovery Protocol — Deep 모듈인가, Shallow 모듈인가?

Ousterhout는 *A Philosophy of Software Design* 4장에서 모듈의 깊이(depth)를 인터페이스의 단순함 대비 내부 구현의 복잡성 비율로 정의했다. 그의 유명한 직사각형 비유에서, 상단 변이 인터페이스의 넓이, 높이가 구현의 깊이다. **Deep 모듈은 좁은 인터페이스 뒤에 방대한 기능을 숨기고, shallow 모듈은 넓은 인터페이스 뒤에 보잘것없는 구현을 감춘다.** 그는 Unix의 `open()`, `read()`, `write()`, `close()` 5개 시스템 콜이 파일 시스템의 거대한 복잡성을 숨기는 것을 deep 모듈의 전형이라 했다.

S32에서 추출된 `context-recovery-protocol.md`를 이 렌즈로 평가하면 흥미로운 결과가 나온다. 이 프로토콜의 **인터페이스**는 다음 3단계로 요약된다:

1. 세션 디렉토리를 resolve한다
2. 파일이 존재하고 sentinel marker가 있으면 유효하다
3. 유효하면 재사용, 아니면 재실행한다

이 인터페이스는 상당히 좁다(narrow). 그러나 이 인터페이스 뒤에 숨겨진 **구현의 깊이**는 얼마나 되는가? 실질적으로 거의 없다. 파일 존재 확인 + 문자열 비교(sentinel) — 이것이 전부다. Ousterhout의 기준에서 이것은 **shallow 모듈**이다. 인터페이스가 3단계인데 구현도 3단계라면, 이 모듈은 복잡성을 숨기는 게 아니라 **복잡성을 이동시킨 것**에 불과하다.

그런데 여기서 진짜 문제가 드러난다. Context recovery가 shallow한 것 자체가 나쁜 것이 아니다 — **shallow 모듈이 9번 복제된 것이 나쁜 것이다.** Ousterhout는 5장에서 "정보 누출(information leakage)은 두 모듈이 같은 지식을 공유할 때 발생한다"고 경고했다. CDM 1에서 밝혀진 9x 중복은 전형적인 정보 누출이다. 5개 스킬이 모두 "session_dir를 resolve하고, 파일을 확인하고, sentinel을 검증하는" 동일한 지식을 각자의 SKILL.md에 내장하고 있었다. Plan이 "동일 패턴 적용"이라고 기술한 순간, 이 지식은 공유 참조가 아닌 복제(duplication)로 전파되었다.

Ousterhout라면 이 상황을 이렇게 진단할 것이다: **context recovery의 문제는 깊이가 부족한 것이 아니라, 정보 은닉(information hiding)이 부재한 것이다.** 이 프로토콜이 `context-recovery-protocol.md`라는 공유 참조로 추출된 것은 정보 누출을 사후적으로 봉합한 올바른 조치였다. 하지만 이것이 plan 시점에서 이루어졌어야 한다는 CDM 1의 지적은, Ousterhout가 7장에서 강조한 "설계 결정은 가장 먼저, 한 곳에서 내려야 한다(Design decisions should be made early and in one place)"는 원칙과 정확히 일치한다.

#### 2. SKILL.md의 인터페이스 비대화 — 전술적 프로그래밍의 축적

Ousterhout는 3장에서 **전략적 프로그래밍(strategic programming)**과 **전술적 프로그래밍(tactical programming)**을 대비시켰다. 전술적 프로그래머는 "일단 동작하게 만들자"에 집중하고, 전략적 프로그래머는 "이 시스템의 복잡성을 장기적으로 관리 가능한 수준으로 유지하자"에 집중한다. 그는 Facebook의 초기 문화("Move fast and break things")를 전술적 프로그래밍의 대표 사례로 들며, 이것이 결국 "Move fast with stable infra"로 바뀔 수밖에 없었던 과정을 기술했다.

S32-impl 세션의 plan을 이 렌즈로 보면, 11개 step이 모두 **전술적 성격**이라는 점이 두드러진다. 각 step은 특정 스킬의 SKILL.md에 구체적인 코드 블록과 Phase를 삽입하는 것이다. L1(Branch Gate), L2(Clarify Gate), L3(File Persistence) — 모두 즉각적인 문제를 해결하는 전술적 응답이다. 93파일 monolithic diff → commit gate, compaction 후 결과 유실 → file persistence, 결정 유실 → clarify gate. 각각은 합리적이지만, 이들의 **누적 효과**를 고려하면 우려스럽다.

impl/SKILL.md를 구체적으로 보자. 이 세션에서 Phase 0.5 (Branch Gate), Phase 1.0 (Clarify Pre-condition), Phase 3a/3b Commit Gate, Phase 3b.3.5 (Batch Commit), Phase 3b.3.6 (Lesson-Driven Commits)이 추가되었다. 원래 4단계(Load → Decompose → Execute → Verify)였던 파이프라인이 이제 약 10개 이상의 세부 단계를 가진다. Ousterhout는 이런 상황을 "인터페이스 비대화(interface bloat)"라고 부른다. **모듈에 기능을 추가할 때마다 인터페이스가 넓어지면, 결국 모듈의 복잡성이 모듈을 사용하는 쪽으로 전가된다.**

여기서 핵심적인 질문은: **impl/SKILL.md의 "사용자"는 누구인가?** 사용자는 AI agent — Claude 자신이다. 이 agent는 SKILL.md를 읽고 단계별로 수행한다. 인터페이스가 넓어질수록 agent가 한 번에 파악해야 할 context가 증가하고, 이것은 compaction과 결합하여 CDM 3의 "결정 밀도 대비 해상도 부족" 문제를 더 악화시킬 수 있다. 즉, **전술적 수정의 축적이 오히려 원래 문제(context 과부하)를 심화시키는 역설적 구조**가 존재한다.

Ousterhout의 해법은 명확하다: "모듈이 비대해지면 분할하라, 단 깊이를 유지하면서." Branch Gate, Commit Gate, Clarify Gate는 각각 독립적인 관심사(concern)이다. 이들을 impl/SKILL.md에 인라인으로 기술하는 대신, 공유 참조(e.g., `references/git-workflow-gates.md`)로 추출하면 impl의 인터페이스가 다시 좁아진다. 이는 정보 은닉의 원칙에도 부합한다 — gate의 구체적 구현은 숨기고, "gate를 통과했다/못했다"라는 결과만 노출하는 것이다.

#### 3. "항상 한 단계 더 깊이 측정하라" — CDM 2의 Commit 전략 실패

Ousterhout는 *Communications of the ACM* (2018) 기고문 "Always Measure One Level Deeper"에서, 성능 문제를 진단할 때 표면적 지표에서 멈추지 말고 항상 한 단계 더 아래를 파야 한다고 주장했다. 이 원칙은 성능에만 적용되는 것이 아니다.

CDM 2에서 드러난 per-work-item commit 전략의 실패를 이 렌즈으로 분석하면: Plan은 "work item 단위 commit"이라는 설계 결정을 내렸다. 표면적으로 이것은 합리적이다 — 각 work item은 독립된 변경 단위이므로, 각각 커밋하는 것이 git 이력의 가독성을 높인다. 그러나 **한 단계 더 깊이 측정하면**, 이 세션의 work item들은 cross-cutting 패턴(context recovery protocol)이라는 공유 축으로 연결되어 있었다. 하나의 변경이 5개 스킬의 동일 부분을 동시에 건드리는 구조에서, work item은 "독립된 단위"가 아니라 **하나의 단위의 5개 투영(projection)**이었다.

Ousterhout라면 이것을 **pass-through 메서드 문제의 변형**으로 볼 것이다. 그는 7장에서 pass-through 메서드를 "한 모듈이 다른 모듈의 기능을 별다른 가치 추가 없이 중계하는 것"으로 정의하고, 이것이 "인터페이스를 추가하지만 깊이를 추가하지 않는" 복잡성이라고 비판했다. Plan의 per-work-item 분해는 각 스킬을 독립 모듈처럼 취급했지만, 실제로는 각 스킬에 대한 변경이 context-recovery-protocol이라는 단일 개념의 pass-through에 불과했다. **진짜 "work item"은 "context recovery protocol을 설계하고 5개 스킬에 적용하는 것"이라는 하나의 deep 작업이었다.**

한 단계 더 깊이 파면, 이것은 **plan 단계에서 추상화 수준의 선택 오류**로 귀결된다. Plan이 file-level 분해(어떤 파일을 수정할 것인가)를 했지만, concept-level 분해(어떤 개념을 도입할 것인가)를 하지 않았다. Ousterhout의 설계 철학에서 모듈은 **파일이 아니라 개념을 중심으로 구성되어야 한다.** "5개 스킬의 SKILL.md를 수정한다"는 파일 중심 분해이고, "context recovery protocol이라는 개념을 설계하고, 이를 참조하는 연결점을 5개 스킬에 배치한다"가 개념 중심 분해이다. 후자를 선택했다면 per-work-item commit은 자연스럽게 작동했을 것이다 — 첫 번째 commit이 공유 개념 파일, 이후 commit들이 각 스킬의 연결점이 되므로.

---

#### 관통 분석: Shallow 추상화의 전파

CDM이 도출한 관통 패턴 — "설계 시점 가정이 실행 시점에서 무효화" — 을 Ousterhout의 렌즈로 재해석하면, 이것은 **shallow 추상화가 시스템 전체에 전파되는 구조적 문제**로 보인다.

Plan의 분해 전략은 shallow했다: 파일 단위로 나누었을 뿐, 개념 단위로 나누지 않았다. Compact recovery의 decisions 필드는 shallow했다: 5개 고수준 결정만 보존하고, phase별 세부 결정의 밀도 차이를 반영하지 않았다. External CLI의 에러 처리는 shallow했다: exit code만 보고 에러 종류를 구분하지 않았다.

Ousterhout는 이 패턴을 "complexity is incremental"이라는 표현으로 설명했다: **복잡성은 하나의 거대한 결정이 아니라, 수많은 작은 결정의 축적에서 비롯된다.** 각각의 shallow 결정은 개별적으로는 무해해 보이지만, 이들이 축적되면 시스템 전체의 복잡성이 관리 불가능한 수준으로 치솟는다. S32-impl 세션에서 일어난 일이 정확히 이것이다 — 각 스킬에 대한 각 전술적 수정은 합리적이었지만, 그 총합이 SKILL.md의 인터페이스 비대화와 cross-cutting 중복이라는 창발적 복잡성을 만들어냈다.

**잘 작동한 것** 역시 이 프레임워크로 설명 가능하다. File persistence의 sentinel marker(`<!-- AGENT_COMPLETE -->`)는 단순하지만 효과적인 인터페이스다 — 파일 끝의 한 줄 문자열이 "이 agent는 작업을 완료했다"는 풍부한 의미를 전달한다. 이것은 Ousterhout가 말하는 **좁은 인터페이스 뒤의 의미론적 깊이** — 정확히 deep 모듈의 특성이다. 또한 clarify→impl 간의 completion gate(`clarify_completed_at` 필드)도 단일 타임스탬프라는 좁은 인터페이스로 "이 phase가 완료되었는가?"라는 풍부한 판단을 지원한다. 이런 개별 설계 결정은 전략적이었다.

문제는 이 전략적 개별 결정들이 **전술적 배치 방식**으로 시스템에 삽입되었다는 점이다. 좋은 개념(sentinel, completion gate, commit gate)이 각 스킬에 인라인으로 기술되면서, 그 개념적 일관성이 구현의 산발성에 의해 희석되었다.

---

**Recommendations**:

1. **Plan 분해를 file-level에서 concept-level로 전환**: Ousterhout의 "모듈은 파일이 아니라 개념을 중심으로" 원칙을 plan 단계에 적용하라. Cross-cutting 패턴이 감지되면, plan의 첫 번째 step을 "공유 개념 설계 및 참조 파일 작성"으로 배치하고, 이후 step들을 "각 스킬에서 공유 개념 참조"로 구성하라. 이렇게 하면 deep 모듈(공유 참조 파일) + shallow 연결점(각 스킬의 1-2줄 참조)이라는 건강한 구조가 자연스럽게 형성되고, per-work-item commit도 자연스럽게 작동한다.

2. **impl/SKILL.md의 gate들을 references로 추출하여 인터페이스 좁히기**: 현재 impl/SKILL.md에 인라인된 Branch Gate, Clarify Gate, Commit Gate를 각각 공유 참조 파일(또는 하나의 `git-workflow-gates.md`)로 추출하라. impl/SKILL.md는 "Phase 0.5에서 branch gate를 적용한다 → 참조: git-workflow-gates.md"로 1-2줄만 유지한다. 이것이 Ousterhout가 말하는 "인터페이스를 좁게, 구현을 깊게" 전환이며, agent가 한 번에 파악해야 할 SKILL.md의 context 부담을 줄여 compaction 내성을 높인다. Ousterhout의 표현을 빌리면: **"모듈에 기능을 추가할 때, 인터페이스가 넓어지고 있다면 설계를 재고하라(If adding functionality makes the interface more complex, rethink the design)."**

<!-- AGENT_COMPLETE -->
