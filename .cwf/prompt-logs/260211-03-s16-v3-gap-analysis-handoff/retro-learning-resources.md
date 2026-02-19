# Section 6: 학습 리소스

> S16 세션 핵심 테마 기반 — 멀티모델 오케스트레이션 에러 분류, STAMP/STPA의 소프트웨어 프로토콜 적용, 자율 에이전트 명세 품질

---

## 리소스 1: MAST — Why Do Multi-Agent LLM Systems Fail?

**Cemri et al. (UC Berkeley), NeurIPS 2025 Spotlight**

- 논문: <https://arxiv.org/abs/2503.13657>
- GitHub (데이터셋 + 코드): <https://github.com/multi-agent-systems-failure-taxonomy/MAST>

**핵심 내용**: 7개 MAS 프레임워크에서 수집한 1,642개 실행 트레이스를 분석하여, 멀티 에이전트 시스템의 실패 모드를 14가지로 분류한 최초의 실증 기반 taxonomy(MAST)를 제시한다. 3개 카테고리로 구분된다: (i) 시스템 설계 문제 (역할 명세 불이행, 대화 구조 오류 등), (ii) 에이전트 간 정렬 실패 (정보 은닉, 잘못된 위임 등), (iii) 태스크 검증 실패. 41%~86.7%의 실패율을 보이며, 대부분의 실패가 LLM 한계가 아닌 시스템 설계 결함에서 기인한다는 점을 입증한다. ChatDev에서 'Failure Mode 1.2 - Disobey Role Specification' 수정만으로 성공률이 +9.4% 향상된 사례 연구도 포함되어 있다.

**CWF 작업과의 연관성**: S16에서 Gemini CLI의 `Tool "run_shell_command" not found` 에러를 기존 CAPACITY/INTERNAL/AUTH 패턴이 포착하지 못해 TOOL_ERROR 카테고리를 추가한 것은, MAST 분류 체계에서 "시스템 설계 문제" 카테고리에 해당한다. CWF의 외부 CLI 에러 분류 체계가 ad hoc으로 성장하고 있는 현 시점에서, MAST의 3-카테고리 14-모드 프레임워크는 에러 분류를 체계화할 참조 모델이 된다. 특히 `agentdash` Python 라이브러리(`pip install agentdash`)를 통해 MAST 기반 자동 어노테이션 파이프라인도 활용할 수 있어, CWF의 프로세스 로그 분석 자동화에 직접 적용 가능하다.

---

## 리소스 2: STPA Handbook — Systems-Theoretic Process Analysis

**Nancy Leveson & John Thomas (MIT)**

- PDF: <http://www.flighttestsafety.org/images/STPA_Handbook.pdf>
- 관련 배경: Leveson, *Engineering a Safer World*, MIT Press, 2012

**핵심 내용**: STPA Handbook(188페이지)은 STAMP 모델 기반의 위험 분석 방법론을 실무 수준에서 가이드하는 참조 문서다. 핵심 절차는 4단계로 구성된다: (1) 손실과 위험 식별, (2) 제어 구조 다이어그램 작성 (주요 컴포넌트와 제어/피드백 화살표), (3) 안전하지 않은 제어 행동(UCA) 식별 — 4가지 유형 테이블 사용 (Not providing causes hazard / Providing causes hazard / Wrong timing / Stopped too soon), (4) 인과 시나리오 생성 (컨트롤러 프로세스 모델, 제어 경로, 피드백 경로, 프로세스 분석). Appendix B에 제어 구조 예시, Appendix C에 UCA 테이블 예시, Appendix D에 안전 관리 시스템 설계/평가 가이드라인이 포함되어 있다.

**CWF 작업과의 연관성**: S16 리뷰에서 Expert beta(Leveson 분석)가 핸드오프 프로토콜을 안전 제어 구조로 해석하여 Type 2 UCA(전제 조건 미검증 상태에서 진행)와 Type 3 UCA(stale process model)를 식별한 것은 이 핸드북의 방법론을 정확히 따른 것이다. 현재 CWF에서 이 분석은 retro의 전문가 페르소나가 수행하고 있지만, STPA의 4단계 절차를 `cwf:review` 스킬의 명시적 체크리스트로 코드화할 수 있다. 특히 "제어 구조 다이어그램 작성 -> UCA 식별" 단계를 프로토콜 문서 리뷰에 체계적으로 적용하면, open-loop 제어 구조(프로토콜이 자체 실패를 탐지할 수 없는 상태)를 사전에 발견하는 반복 가능한 절차가 된다.

---

## 리소스 3: Taxonomy of Failure Modes in Agentic AI Systems

**Microsoft AI Red Team (Pete Bryan, Ram Shankar Siva Kumar et al.), 2025**

- 블로그: <https://www.microsoft.com/en-us/security/blog/2025/04/24/new-whitepaper-outlines-the-taxonomy-of-failure-modes-in-ai-agents/>
- 백서 PDF: <https://cdn-dynmedia-1.microsoft.com/is/content/microsoftcorp/microsoft/final/en-us/microsoft-brand/documents/Taxonomy-of-Failure-Mode-in-Agentic-AI-Systems-Whitepaper.pdf>

**핵심 내용**: Microsoft AI Red Team이 내부 에이전트 시스템 레드팀, 사내 이해관계자(MSR, Azure Research, MSRC, Office of Responsible AI 등) 검토, 외부 실무자 인터뷰를 거쳐 구축한 에이전트 AI 시스템 실패 모드 분류 체계다. 두 축으로 분류한다: (1) **Safety vs Security** — Safety는 사용자/사회 피해(할당 편향, 투명성 부족, 기생적 관계 등), Security는 기밀성/가용성/무결성 침해(에이전트 탈취, 인젝션, 흐름 조작 등), (2) **Novel vs Existing** — Novel은 에이전트 고유 실패(에이전트 흐름 조작, 프로비저닝 포이즈닝, 멀티 에이전트 탈옥 등), Existing은 기존 AI 실패의 에이전트 맥락 확장(환각, 메모리 포이즈닝, XPIA 등). 특히 "Function compromise and malicious functions", "Incorrect permissions", "Excessive agency" 같은 도구 관련 실패 모드가 명시되어 있으며, 각 모드별 완화 전략(아키텍처, 기술적 제어, 사용자 설계)을 제공한다.

**CWF 작업과의 연관성**: CWF의 멀티모델 오케스트레이션에서 외부 CLI(Codex, Gemini)를 호출할 때, "Function compromise"와 "Incorrect permissions" 모드가 직접적으로 해당한다. S16에서 발견한 Gemini의 `Tool "run_shell_command" not found` 에러는 이 분류에서 도구 해상도 실패에 해당하며, Microsoft의 완화 전략 중 "에이전트가 자율적으로 기능을 호출할 때 외부 인증/검증 요구"와 "메모리에 저장할 항목의 구조/형식 제한" 같은 접근이 CWF의 에러 분류 체계 확장에 참조할 만하다. MAST 논문이 실패 *진단*에 초점을 맞추었다면, 이 백서는 실패 *방어* 설계에 초점을 맞추어 상호 보완적이다.

---

## 리소스 간 관계

```text
STPA Handbook (Leveson)          MAST (Berkeley)          MS Taxonomy (Red Team)
  제어 구조 + UCA 분석               실패 모드 진단              실패 모드 방어
  프로토콜 설계 시점                  실행 후 분석 시점            설계 + 운영 시점
         │                              │                          │
         └──── CWF에서의 적용 ───────────┴──────────────────────────┘
               │
               ├─ cwf:review → STPA 체크리스트 (open-loop 탐지)
               ├─ 에러 분류 → MAST 3-category 14-mode 참조
               └─ 방어 설계 → MS taxonomy 완화 전략 참조
```

세 리소스는 CWF의 에이전트 프로토콜 안전성을 다른 시점에서 다룬다: STPA는 **설계 시점**에서 프로토콜의 구조적 결함을 사전에 발견하고, MAST는 **실행 후** 실패 트레이스를 체계적으로 분류하며, Microsoft 분류 체계는 **설계와 운영 전반**에 걸쳐 방어 전략을 제공한다.

<!-- AGENT_COMPLETE -->
