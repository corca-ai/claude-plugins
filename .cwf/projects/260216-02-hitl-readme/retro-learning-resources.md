# Section 6 Draft — Learning Resources

## Web Research Trace

- Date: 2026-02-16
- Search intent:
  - AGENTS index vs long procedural docs
  - instruction density and follow-rate degradation
  - postmortem evidence quality and recurrence prevention
- Verified external URLs:
  - <https://vercel.com/blog/agents-md-outperforms-skills-in-our-agent-evals>
  - <https://www.humanlayer.dev/blog/writing-a-good-claude-md>
  - <https://sre.google/sre-book/postmortem-culture/>

## Recommended Resources

1. Vercel — AGENTS.md Outperforms Skills in Our Agent Evals  
   URL: <https://vercel.com/blog/agents-md-outperforms-skills-in-our-agent-evals>
   - Key takeaway: 엔트리 문서는 절차 모음이 아니라 압축 인덱스일 때 에이전트 라우팅 성능이 좋아진다.
   - Why it matters: 이번 세션의 SoT/핸드오프 계약을 "짧은 기준 + 깊은 참조" 구조로 정리하는 데 직접적인 근거가 된다.

2. HumanLayer — Writing a Good CLAUDE.md  
   URL: <https://www.humanlayer.dev/blog/writing-a-good-claude-md>
   - Key takeaway: 규칙 수가 늘수록 전체 준수율이 낮아지므로, 반복 규칙은 도구/게이트로 승격해야 한다.
   - Why it matters: `intent_resync_required`, `apply_patch via exec_command`, scratchpad 동기화를 문장 권고에서 결정적 체크로 옮기는 설계와 일치한다.

3. Google SRE Book — Postmortem Culture  
   URL: <https://sre.google/sre-book/postmortem-culture/>
   - Key takeaway: 회고는 비난이 아니라 재발 방지를 위한 구조적 개선으로 연결되어야 하며, 근거 기록이 일관되어야 한다.
   - Why it matters: `retro-collect-evidence` 자동화와 deep-mode 근거 산출물 규약(`AGENT_COMPLETE`)을 운영 표준으로 정당화한다.

<!-- AGENT_COMPLETE -->
