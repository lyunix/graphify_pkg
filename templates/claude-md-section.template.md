<!--
  CLAUDE.md graphify 섹션 템플릿
  
  사용법:
    1. `graphify claude install` 실행이 가장 쉬움 (이 내용을 자동으로 CLAUDE.md에 추가).
    2. 수동 통합 시: 아래 `<!-- ↓ COPY ↓ -->` 와 `<!-- ↑ COPY ↑ -->` 사이를
       기존 프로젝트 CLAUDE.md 끝에 붙여넣기.
    3. 함께: .claude/settings.json에 PreToolUse hook 등록 필요
       (templates/claude-settings-hook.json 참조 또는 `graphify claude install`)
  
  검증: graphifyy v0.7.5에서 `graphify claude install`로 실측 적용된 양식.
-->

<!-- ↓ COPY ↓ -->
## graphify

This project has a graphify knowledge graph at graphify-out/.

Rules:
- Before answering architecture or codebase questions, read graphify-out/GRAPH_REPORT.md for god nodes and community structure
- If graphify-out/wiki/index.md exists, navigate it instead of reading raw files
- For cross-module "how does X relate to Y" questions, prefer `graphify query "<question>"`, `graphify path "<A>" "<B>"`, or `graphify explain "<concept>"` over grep — these traverse the graph's EXTRACTED + INFERRED edges instead of scanning files
- After modifying code files in this session, run `graphify update .` to keep the graph current (AST-only, no API cost)
<!-- ↑ COPY ↑ -->
