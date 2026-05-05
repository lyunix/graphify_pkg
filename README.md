# graphify_pkg

> 코드 워크스페이스에 [Graphify](https://github.com/safishamsi/graphify)를 깔고 *코드베이스 학습·기술 부채 분석*에 쓰기 위한 부트스트랩 패키지.
> 새 프로젝트마다 이 폴더 통째로 가져가서 5분 안에 셋업.
>
> **본 가이드의 모든 명령은 graphifyy v0.7.5에서 실증 검증.**

---

## 무엇을 위한 패키지인가

[Graphify](https://graphify.net/kr/)는 폴더(코드·문서·논문·이미지·영상)를 *queryable knowledge graph*로 자동 변환하는 도구. AST + LLM 시멘틱 추출 + Leiden 클러스터링으로 god nodes·커뮤니티·의외 연결을 발견.

**이 패키지의 범위 — 코드 워크스페이스 단독 사용**:
- 새 프로젝트 온보딩 (코드베이스 학습)
- 기술 부채 식별 (과결합·분리 가능 모듈)
- 아키텍처 의도 추적 (god nodes·bridge nodes)
- 변경 영향 분석 (cross-module 관계)

**이 패키지의 *범위 외* — 별도 시스템 필요**:
- PKM/세컨드 브레인 운영 (raw/wiki/Output 3계층) → Karpathy [LLM Wiki 패턴](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f) 참조
- 다중 도메인 지식 누적 → 별도 wiki 볼트 부트스트랩

→ 이 패키지는 *Graphify-only*. wiki 시스템 만들지 않음. 기존 코드 디렉토리에 깔고 끝.

---

## 파일 안내 — 무엇을 언제 읽나

| 파일 | 청중 | 언제 |
|---|---|---|
| `README.md` (this) | 모두 | 처음 한 번. 패키지 전체 그림 |
| [`INSTALL.md`](INSTALL.md) | AI 에이전트 + 사람 | 새 워크스페이스에 graphify 깔 때 |
| [`USAGE.md`](USAGE.md) | 사람 | 설치 후 일상 사용·베스트 프랙티스·FAQ |
| [`templates/graphifyignore.template`](templates/graphifyignore.template) | 사람 | 새 워크스페이스 부트스트랩 시 `.graphifyignore`로 복사 |
| [`templates/claude-md-section.template.md`](templates/claude-md-section.template.md) | 사람 | 기존 `CLAUDE.md`에 graphify 섹션 수동 통합 시 |
| [`templates/claude-settings-hook.json`](templates/claude-settings-hook.json) | 사람 | `.claude/settings.json` PreToolUse hook 수동 등록 시 |
| [`skills/graphify-bootstrap/SKILL.md`](skills/graphify-bootstrap/SKILL.md) | AI 에이전트 | 새 워크스페이스에서 `/graphify-bootstrap` 한 줄로 자동 셋업 |

---

## 5분 부트스트랩 (3가지 진입 옵션)

### 옵션 A — 가장 빠름·무비용 (AST-only first build)

```bash
cd ~/dev/your-project
pip install graphifyy                                                    # 1회만
cp /path/to/graphify_pkg/templates/graphifyignore.template .graphifyignore
graphify update .                                                         # 첫 빌드 (LLM 무호출)
```

→ `graphify-out/` 자동 생성. AST 기반 그래프 즉시 확보. **API key 불필요**.

### 옵션 B — Claude Code 사용자 (가장 풍부)

```bash
cd ~/dev/your-project
pip install graphifyy
cp /path/to/graphify_pkg/templates/graphifyignore.template .graphifyignore
graphify install --platform claude  # 또는 `graphify claude install` — 글로벌 스킬 + 프로젝트 always-on
```

```
/graphify .                          # Claude Code 슬래시 — 현재 세션이 LLM 시멘틱 추출 수행
```

→ 풀 그래프 (AST + LLM 시멘틱 + 커뮤니티). 토큰은 *현재 Claude 세션 한도* 사용.

### 옵션 C — 헤드리스 풀 추출 (CI/배치 자동화)

```bash
export ANTHROPIC_API_KEY=sk-ant-...   # 또는 MOONSHOT_API_KEY=...
cd ~/dev/your-project
graphify extract .                     # 풀 추출 (AST + LLM)
```

→ API key 필수. CI 파이프라인·자동화 시 사용.

상세 절차·트러블슈팅 → [`INSTALL.md`](INSTALL.md). 사용·베스트 프랙티스 → [`USAGE.md`](USAGE.md).

---

## 사전 요구사항

| 도구 | 최소 버전 | 비고 |
|---|---|---|
| Python | 3.10+ | graphify가 networkx·tree-sitter 사용 |
| pip | 21+ | graphifyy 설치 |
| git | 2.30+ | (선택) post-commit hook 사용 시 |
| AI 코딩 도구 | 최신 | (선택) always-on 통합 — Claude Code / Codex / Cursor / Gemini / OpenCode / Aider / Copilot / VS Code / Antigravity / Hermes / Kiro / Pi / Trae / Claw / Droid 지원 |
| LLM API key | (선택) | `graphify extract` 또는 `kimi` 백엔드 사용 시. `/graphify .` Claude Code 슬래시는 *불필요* |

---

## 핵심 가치 명제 (왜 도입하나)

| 문제 | 도구 없이 | graphify 적용 후 |
|---|---|---|
| 새 코드베이스 이해 | 파일별 grep·읽기 반복 | god nodes 5개로 *코어 추상* 1분 파악 |
| 코드 질문 답변 비용 | 매번 grep → 풀 컨텍스트 로드 | graph 먼저 참조 → 토큰 5~70× 절감 (코퍼스 크기 의존) |
| 기술 부채 발견 | 직관·경험에 의존 | cohesion < 0.1 커뮤니티 = 분리 가능 모듈 자동 식별 |
| 변경 영향 추적 | 수동 추적 | `graphify path "X" "Y"` BFS 경로 |

→ **쉽게 말해**: 코드를 grep하기 전에 graph를 먼저 본다. 검색이 *연결 추적*으로 바뀜.

---

## 라이선스 / 출처

**라이선스**: [MIT License](LICENSE) — Copyright (c) 2026 lyunix.
Graphify 본체와 동일 라이선스로 일관성·호환성 유지.

**Upstream attribution** (Graphify 본체):
- GitHub: [github.com/safishamsi/graphify](https://github.com/safishamsi/graphify) (MIT, Copyright 2026 Safi Shamsi)
- 한국어 랜딩: [graphify.net/kr](https://graphify.net/kr/)
- 본 패키지의 `templates/claude-md-section.template.md`·`templates/claude-settings-hook.json`은 `graphify claude install` 명령이 산출하는 내용을 *오프라인 참조용*으로 수록 (Graphify MIT 라이선스 하).

**본 패키지 (graphify_pkg)**: graphify 사용을 위한 *부트스트랩 키트*. graphify 소스 코드는 재배포하지 않음 — 문서·템플릿·스킬만 제공.

본 패키지의 가이드는 실제 운영 경험 (cc_wiki 풀 빌드 305 nodes / 27 communities / 4.2× 절감, 2026-05-05) 기반으로 작성. 모든 명령은 graphifyy v0.7.5에서 실증 검증.
