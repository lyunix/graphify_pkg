---
name: graphify-bootstrap
description: Use when user wants to set up graphify on a NEW code workspace from scratch — installs CLI if missing, copies .graphifyignore, runs first build (AST-only, no LLM cost), installs Claude Code always-on hook, and verifies. Triggers — "graphify 부트스트랩해줘" / "graphify 설치해줘" / "이 워크스페이스에 graphify 깔아줘" / "/graphify-bootstrap".
---

# Graphify Bootstrap

## Overview

새 코드 워크스페이스에 graphify를 한 번에 셋업. 기본 모드는 *옵션 A* (AST-only `graphify update .`) — LLM API key 없이 first-build 가능, 무비용. 사용자 명시 요청 시 옵션 B (Claude Code `/graphify .`) 또는 옵션 C (헤드리스 `extract`)로 전환.

핵심 원칙:
- **API key 없어도 작동**: 옵션 A가 default. 옵션 C(extract)는 API key 필수임을 사전 체크
- **검증 강제**: 각 단계 후 산출물 존재 확인. 실패 시 즉시 중단·보고
- **idempotent**: 이미 설치된 경우 중복 동작 안 함
- **사용자 명시 옵션 우선**: B/C 요청 시 그대로 따름

## When to Use

- 사용자 발화: *"graphify 부트스트랩"*, *"graphify 설치"*, *"이 워크스페이스에 graphify 깔아줘"*, *"코드 분석 그래프 셋업"*
- 명시적 `/graphify-bootstrap` 호출
- 새 프로젝트 디렉토리에서 `graphify-out/` 부재 + 사용자가 graphify 사용 의향 표시

**Skip when**:
- 이미 `graphify-out/graph.json` 존재 → `/graphify .` 또는 `graphify update .` 직접 호출 안내
- PKM/wiki 시스템 셋업이 목적 → graphify-bootstrap 범위 외. Karpathy LLM Wiki 패턴 안내

## Workflow (7 단계)

| # | 단계 | 동작 |
|---|---|---|
| 0 | **사전 점검** | `pwd` 출력 + git repo 여부 확인 + `graphify --version`(또는 `--help`) 실행. 미설치면 §1.1 진행 |
| 1 | **CLI 확인·설치** | `which graphify` 결과 없으면 `pip install graphifyy`. 설치 후 `graphify --help`로 검증 |
| 2 | **버전 동기화** | `pip show graphifyy \| grep Version` 확인. v0.7.5 미만이면 `pip install --upgrade graphifyy && graphify install` |
| 3 | **`.graphifyignore` 적용** | 프로젝트 루트에 `.graphifyignore` 파일 부재 시 graphify_pkg/templates/graphifyignore.template 복사. 존재하면 skip (사용자 커스터마이즈 보존) |
| 4 | **첫 빌드** | 옵션 결정 후 실행 (§2.1 참조). 사용자 명시 없으면 옵션 A. 출력 파일 존재 검증 |
| 5 | **Always-on hook** | `graphify claude install` 실행. CLAUDE.md 섹션 + .claude/settings.json hook 등록 검증 |
| 6 | **(선택) git hook** | `git rev-parse --is-inside-work-tree` 성공 시 사용자 확인 후 `graphify hook install` |
| 7 | **검증·보고** | §검증 체크리스트 모두 PASS 확인. god nodes top 5 + community 수 + token 측정값 보고 |

## Decisions

### 옵션 결정 (Step 4)

| 사용자 발화 또는 환경 | 옵션 | 명령 |
|---|---|---|
| 명시 없음 (default) | **A — AST-only** | `graphify update .` |
| "Claude Code로 풀 빌드" / "LLM 시멘틱 추출 포함" | **B** | `/graphify .` (Claude Code 슬래시 — *현재 세션*에서 LLM 처리) |
| "CI/배치", "헤드리스", "API key 있음" | **C** | `graphify extract .` (`ANTHROPIC_API_KEY` 또는 `MOONSHOT_API_KEY` 환경변수 사전 확인) |
| 옵션 C인데 API key 없음 | A로 자동 fallback | 사용자에 안내 후 옵션 A 진행 |

### Hook 설치 결정 (Step 5·6)

- **Claude Code 사용자**: Step 5 강제. 설치 안 하면 graphify 효과 50%
- **다른 AI 도구**: 사용자에게 도구 묻고 해당 명령 실행 (codex/cursor/gemini/opencode/aider/copilot/vscode/antigravity/claw/droid/trae/trae-cn/hermes/kiro/pi)
- **git hook**: git repo가 아니면 skip. git repo면 사용자 yes/no 확인. 기본 yes 권장 (commit마다 자동 incremental)

## Templates & Rules

설치 명령·플랫폼 통합·트러블슈팅 → `graphify_pkg/INSTALL.md` (전체 17개 도구 통합 표).
일상 사용·해석법·베스트 프랙티스 → `graphify_pkg/USAGE.md`.
ignore 패턴·CLAUDE.md 섹션·settings.json hook 양식 → `graphify_pkg/templates/`.

**핵심 원칙**:
- `.graphifyignore` 부재 시 즉시 적용 (코드 외 노이즈 차단)
- 옵션 C 선택 시 API key 환경변수 *반드시* 사전 체크 — 없으면 옵션 A fallback
- 검증 체크리스트 모두 PASS 후 보고. 하나라도 FAIL이면 보고 + 사용자 결정 위임
- raw/ 같은 별도 데이터 레이어 만들지 X (LLM Wiki 시스템과 혼동 금지)

## 검증 체크리스트 (Step 7)

```bash
# 모두 PASS여야 정상
test -d graphify-out/                                       # graphify-out 디렉토리 존재
test -s graphify-out/graph.json                             # graph.json 비어있지 않음
test -f graphify-out/GRAPH_REPORT.md                        # 사람용 보고서 존재
test -f graphify-out/graph.html                             # 인터랙티브 시각화 존재
grep -q "^## graphify" CLAUDE.md 2>/dev/null               # CLAUDE.md graphify 섹션 (옵션)
grep -q "PreToolUse" .claude/settings.json 2>/dev/null     # hook 등록 (옵션)
test -f .graphifyignore                                     # ignore 파일 적용
```

성공 시 보고:
```
✓ graphify v<X.Y.Z> bootstrap 완료
  - 빌드 옵션: A (AST-only) / B (Claude Code) / C (extract)
  - 산출물: graphify-out/{graph.json, graph.html, GRAPH_REPORT.md, manifest.json}
  - 노드/엣지/커뮤니티: N/M/K
  - God nodes top 5: <list>
  - Always-on hook: 활성 / 미활성
  - git hook: 활성 / 미활성
  
다음 행동:
  - open graphify-out/graph.html  # 시각화 확인
  - cat graphify-out/GRAPH_REPORT.md  # 사람용 보고서 통독 (5분)
  - 자연어로 코드 질문 → AI가 graph 우선 참조
```

실패 시:
```
✗ Step <N> 실패: <증상>
  - 원인 후보: ...
  - 해결: graphify_pkg/INSTALL.md §5 트러블슈팅 표 참조
사용자 결정 필요: 계속 / 중단 / 다른 옵션
```

## Common Mistakes

| 실수 | 결과 | 회피 |
|---|---|---|
| API key 없는데 옵션 C 강행 | `error: no LLM API key found` 즉시 실패 | Step 4 직전 환경변수 체크. 없으면 옵션 A fallback |
| `.graphifyignore` 없이 큰 모노레포 build | node_modules·dist 포함 → 5000+ 노드 경고 | Step 3 강제 |
| 이미 설치된 환경에서 중복 install | 시간 낭비, 사용자 혼란 | Step 0 점검에서 idempotent 처리 |
| Step 5 hook 설치 skip | always-on 효과 0 → graphify 가치 절반 | Claude Code 사용자에게 강력 권장. 명시 거부 시만 skip |
| LLM Wiki 시스템 (raw/wiki/Output) 부트스트랩 시도 | 본 스킬 범위 외 | Karpathy LLM Wiki 패턴 별도 안내 후 종료 |
| graphify-out/ 이미 있는데 풀 빌드 강행 | 기존 그래프 덮어쓰기 위험 | Step 0에서 감지 → `graphify update .` 안내 |
| docs/ 신설 자동화 시도 | 본 스킬 범위 외 (USAGE.md §4.2 사람 결정) | docs/ 추가는 사용자 결정에 위임 |

## Real-World Impact

코드 워크스페이스에 graphify를 *제대로 깔면*:
- 새 프로젝트 인수인계: 코드 읽기 시간 1시간 → 5분 (god nodes 5개로 코어 추상 즉시 파악)
- 코드 질문 답변: 토큰 4~70× 절감 (코퍼스 크기 의존), 응답 품질 ↑
- 리팩토링 우선순위: cohesion < 0.1 커뮤니티 자동 식별 → 분리 가능 모듈 발견
- 변경 영향 분석: `graphify path "X" "Y"` BFS 경로로 간접 영향 추적

본 스킬은 위 효과를 *셋업 부담 없이* 확보하기 위한 한 줄 부트스트랩.

## 참고 자료

- INSTALL.md: 모든 단계 상세 + 17개 도구 통합 표 + 트러블슈팅
- USAGE.md: 일상 사용·결과 해석·베스트 프랙티스·FAQ
- 공식: github.com/safishamsi/graphify · graphify.net/kr
- 검증: graphifyy v0.7.5 풀 빌드 환경에서 305 nodes / 27 communities / 4.2× 절감 실측
