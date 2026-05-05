# INSTALL.md — Graphify 설치 가이드

> 청중: AI 에이전트 + 사람. 양쪽이 그대로 따라할 수 있는 단계별 절차.
> 환경: macOS / Linux / Windows (WSL 권장)
> **모든 명령은 graphifyy v0.7.5+ (v0.7.6 포함)에서 검증.**

---

## 0. 사전 확인 (1분)

```bash
python3 --version    # 3.10+ 필요
pip --version        # 21+ 권장
git --version        # 2.30+ 권장 (hook 사용 시)
which graphify       # 미설치면 결과 없음 → §1로
```

기존 graphify 버전 확인 (이미 설치된 경우):
```bash
pip show graphifyy | grep Version
```
v0.7.5+ 권장 (구버전이면 §1.2 업그레이드). v0.7.6 까지 검증됨.

---

## 1. CLI 설치 (1회만, 사용자별 전역)

### 1.1 신규 설치

```bash
pip install graphifyy
```

`graphifyy` (y 두 개) — Python 패키지명. 명령어는 `graphify` (y 하나).

설치 후 검증:
```bash
graphify --help | head -3
which graphify
pip show graphifyy | grep Version
```

(선택) Kimi K2.6 백엔드 추가 — 시멘틱 추출 3× 저렴:
```bash
pip install 'graphifyy[kimi]'
export MOONSHOT_API_KEY=sk-...
```

### 1.2 기존 설치 업그레이드

```bash
pip install --upgrade graphifyy
graphify install                # 글로벌 SKILL 동기화 (~/.claude/skills/graphify/)
```

`graphify install` 출력 예시:
```
  skill installed  ->  /Users/<user>/.claude/skills/graphify/SKILL.md
  CLAUDE.md        ->  already registered (no change)
```

### 1.3 환경별 주의

| 환경 | 주의 |
|---|---|
| **macOS (pyenv)** | shim은 `~/.pyenv/shims/graphify`. shebang 확인: `head -1 $(which graphify)` |
| **Linux (system python)** | `pip install --user`로 사용자 스코프 권장 |
| **Windows (native)** | PreToolUse hook 미지원. WSL 권장 |
| **Windows (WSL)** | macOS와 동일 동작 |
| **여러 Python 버전** | `python3 -m pip install graphifyy`로 어떤 python에 설치되는지 명확화 |

### 1.4 프로젝트 `.venv` 격리 (선택, 권장)

글로벌 설치 (§1.1) 대신 프로젝트별 `.venv` 안에 graphifyy 를 두면 *워크스페이스 격리*가 가능합니다. 한 머신에 여러 프로젝트가 서로 다른 graphifyy 버전을 요구할 때 충돌 회피, 프로젝트 deps 와 함께 관리.

```bash
cd ~/dev/your-project
python3 -m venv .venv
.venv/bin/pip install --upgrade pip
.venv/bin/pip install graphifyy
```

검증:
```bash
.venv/bin/graphify --help | head -3
.venv/bin/pip show graphifyy | grep Version       # 0.7.5+
```

이후 모든 graphify 명령은 `.venv/bin/` prefix 사용 또는 `source .venv/bin/activate` 후 사용:

```bash
.venv/bin/graphify update .
.venv/bin/graphify claude install

# 또는 활성화 후:
source .venv/bin/activate
graphify update .
```

#### 글로벌 + `.venv` 동시 설치 시 — skill 버전 동기화

`.venv` 의 graphify 와 글로벌 graphify 가 다른 버전인 경우, 명령 실행 시 다음 경고가 출력됩니다:

```
warning: skill is from graphify 0.7.5, package is 0.7.6. Run 'graphify install' to update.
```

해석:
- 글로벌 `~/.claude/skills/graphify/SKILL.md` 가 *예전 버전 시점*에 등록됨
- 현재 실행 중인 graphify (보통 `.venv` 의 더 최신 버전) 와 skill 버전 불일치
- **동작에는 영향 없음** — 경고만 출력

해결 옵션:

| 의도 | 명령 | 효과 |
|---|---|---|
| 글로벌 skill 을 현재 graphify 버전으로 동기화 | `graphify install` (또는 `.venv/bin/graphify install`) | `~/.claude/skills/graphify/SKILL.md` 가 현재 버전으로 덮어쓰기 됨 |
| 다중 워크스페이스 운영 — 글로벌만 단일 진실 | 글로벌 graphify (예: pyenv 또는 system) 에서만 `graphify install` 실행 | 다른 워크스페이스의 `.venv` graphify 가 다른 버전이어도 글로벌 skill 하나로 일관됨 |

다중 워크스페이스 환경에서는 *글로벌 graphify 만 `install`* 하는 것이 안전합니다. 각 워크스페이스의 `.venv` graphify 가 글로벌 skill 을 덮어쓰면, 다른 워크스페이스에서 다른 버전 skill 을 보게 될 수 있습니다.

#### `.venv` 격리의 한계

| 항목 | 영향 | 대응 |
|---|---|---|
| `.venv` 폴더 이동·재생성 | `.venv/bin/graphify` 의 shebang stale → `command not found` 또는 import error | `.venv/bin/pip install --force-reinstall graphifyy` 또는 `.venv` 재생성 |
| git post-commit hook | hook 환경에 `.venv` 활성화 안 됨 → `graphify` PATH 못 찾음 | 글로벌 graphify 병용, 또는 hook 안에서 `.venv/bin/graphify` 절대경로 wrapper 사용 |
| `manifest.json` 절대경로 | 머신간 incremental 비호환 | `.venv` 와 무관 — 풀 빌드 1회로 재생성 |

---

## 2. 워크스페이스 부트스트랩 (프로젝트마다 1회)

### 2.1 ignore 패턴 적용

```bash
cd ~/dev/your-project
cp /path/to/graphify_pkg/templates/graphifyignore.template .graphifyignore
```

수동 작성도 가능 — `.gitignore` 문법 동일. 권장 패턴 → `templates/graphifyignore.template`.

### 2.2 첫 그래프 빌드 (3가지 옵션 — 환경에 따라 선택)

#### 옵션 A — `graphify update .` (가장 빠름·무비용·권장)

```bash
graphify update .
```

특징:
- **AST-only 추출** (LLM 호출 없음)
- 빈 graphify-out/ 폴더에서 시작 가능 — *first build*도 동작
- 코드 위주 프로젝트의 default 진입점
- 출력: `graphify-out/{graph.json, graph.html, GRAPH_REPORT.md, manifest.json, cache/}`

검증된 출력 예시:
```
Re-extracting code files in . (no LLM needed)...
[graphify watch] Rebuilt: N nodes, M edges, K communities
[graphify watch] graph.json, graph.html and GRAPH_REPORT.md updated in graphify-out
Code graph updated. For doc/paper/image changes run /graphify --update in your AI assistant.
```

코드만 변경되는 프로젝트는 이 명령만으로 평생 운영 가능.

#### 옵션 B — `/graphify .` (Claude Code 사용자, 가장 풍부)

Claude Code 세션에서:
```
/graphify .
```

특징:
- 9-step 파이프라인 (Detect → AST + LLM 시멘틱 → Cluster → Visualize)
- LLM 시멘틱 추출이 docs·논문·이미지까지 풍부 추출
- **현재 Claude 세션의 토큰** 사용 (별도 API key 불필요)
- 사전 조건: `graphify install --platform claude` 또는 `graphify claude install` 1회 (글로벌 스킬 등록)

#### 옵션 C — `graphify extract .` (헤드리스, CI/배치)

```bash
export ANTHROPIC_API_KEY=sk-ant-...   # 또는 MOONSHOT_API_KEY=sk-...
graphify extract .
```

특징:
- 풀 추출 (AST + LLM 시멘틱) — 헤드리스
- **API key 필수**: `ANTHROPIC_API_KEY` 또는 `MOONSHOT_API_KEY` (Kimi)
- 백엔드 명시: `--backend kimi` 또는 `--backend claude`
- 출력 디렉토리: `--out DIR` (기본 현재 디렉토리)
- `--no-cluster`: 클러스터링 skip, raw extraction만

API key 없으면 다음 에러:
```
error: no LLM API key found. Set MOONSHOT_API_KEY (kimi) or ANTHROPIC_API_KEY (claude), or pass --backend.
```

→ API key 없으면 **옵션 A 또는 B 사용**.

### 2.3 결과 확인

```bash
ls graphify-out/
# graph.json          ← 쿼리 가능 데이터
# graph.html          ← 인터랙티브 시각화 (브라우저로 open)
# GRAPH_REPORT.md     ← 사람용 audit 보고서
# manifest.json       ← 다음 update 기준
# cache/              ← content-hash 기반 캐시 (옵션 B/C에서만 채워짐)

open graphify-out/graph.html       # macOS
xdg-open graphify-out/graph.html   # Linux
start graphify-out/graph.html      # Windows
```

성공 신호:
- `graph.json` 크기 > 0
- `GRAPH_REPORT.md`에 god nodes 섹션 존재
- 브라우저에 노드·엣지 시각화 표시

### 2.4 `graphify-out/` git tracking 정책 (권장 default)

빌드 후 `graphify-out/` 의 어떤 파일을 git 으로 추적할지. **권장 default**:

```
# .gitignore 에 추가
graphify-out/cache/         # 머신별 다름
graphify-out/manifest.json  # 절대경로 — 머신마다 다름
graphify-out/cost.json      # 로컬 토큰 트래킹

# 결과: graph.json, graph.html, GRAPH_REPORT.md 만 commit
```

또는 `templates/gitignore-graphify.template` 한 줄로 적용:
```bash
cat /path/to/graphify_pkg/templates/gitignore-graphify.template >> .gitignore
```

각 파일 trade-off 상세 → [`USAGE.md` §6 Q4](USAGE.md).

#### 정책 비교

| 정책 | .gitignore 패턴 | 장점 | 단점 |
|---|---|---|---|
| **default — 권장** | cache, manifest.json, cost.json | 팀이 최신 그래프 공유 + repo 가벼움 | graph.json 이 코드 변경마다 diff 발생 |
| 보고서만 commit | `graphify-out/*` + `!graphify-out/GRAPH_REPORT.md` (force-add) | 모노레포·repo 최소화 | 그래프 본체는 각자 빌드 필요 |
| 전체 ignore | `graphify-out/` | 가장 가벼움 | 그래프 공유 0, 각자 매번 빌드 |
| 전체 commit | (ignore 안 함) | 단일 머신 — 간단 | manifest 절대경로 stale, repo 비대화 |

---

## 3. 통합 (선택, 권장) — AI 코딩 도구별

### 3.1 Always-on Hook — Claude Code

```bash
cd ~/dev/your-project
graphify claude install
```

자동 수행:
1. 프로젝트 `CLAUDE.md`에 `## graphify` 섹션 추가 (4 rules)
2. `.claude/settings.json`에 PreToolUse hook 등록 (Bash matcher: grep|rg|find|fd|ack|ag)

검증:
```bash
grep -A 6 "## graphify" CLAUDE.md
cat .claude/settings.json | grep PreToolUse
```

이후 Claude Code 세션에서 grep/find 명령 직전마다 자동 출력:
```
PreToolUse:Bash hook additional context: graphify: Knowledge graph exists.
Read graphify-out/GRAPH_REPORT.md for god nodes and community structure before searching raw files.
```

→ AI가 graph 우선 참조하도록 유도. 응답 품질 ↑, 토큰 ↓.

**제거**: `graphify claude uninstall`

### 3.2 다른 AI 코딩 도구

같은 패턴, 도구만 교체:

| 도구 | 명령 | 설치 산출물 |
|---|---|---|
| Codex CLI | `graphify codex install` | `AGENTS.md` 섹션 추가 |
| Cursor | `graphify cursor install` | `.cursor/rules/graphify.mdc` |
| Gemini CLI | `graphify gemini install` | `GEMINI.md` 섹션 + BeforeTool hook |
| OpenCode | `graphify opencode install` | `AGENTS.md` 섹션 + tool.execute.before plugin |
| Aider | `graphify aider install` | `AGENTS.md` 섹션 |
| GitHub Copilot CLI | `graphify copilot install` | `~/.copilot/skills/graphify/` |
| VS Code Copilot Chat | `graphify vscode install` | skill + `.github/copilot-instructions.md` |
| Google Antigravity | `graphify antigravity install` | `.agents/rules` + `.agents/workflows` |
| OpenClaw | `graphify claw install` | `AGENTS.md` 섹션 |
| Factory Droid | `graphify droid install` | `AGENTS.md` 섹션 |
| Trae / Trae CN | `graphify trae install` / `graphify trae-cn install` | `AGENTS.md` 섹션 |
| Hermes | `graphify hermes install` | `~/.hermes/skills/graphify/` |
| Kiro IDE/CLI | `graphify kiro install` | `.kiro/skills/graphify/` + steering |
| Pi coding agent | `graphify pi install` | `~/.pi/agent/skills/graphify/` |

각각 `<tool> uninstall`로 제거.

### 3.3 Git post-commit Hook — 매 commit 후 자동 incremental

```bash
graphify hook install
```

이후 매 `git commit` 직후:
- `git diff HEAD~1`로 변경 코드 파일 식별
- AST-only re-extraction (LLM 무비용)
- `graph.json`·`GRAPH_REPORT.md` 자동 갱신
- 추가: `merge-driver` 자동 등록 (graph.json 충돌 시 union-merge)

검증·제거:
```bash
graphify hook status      # 설치 여부 확인
graphify hook uninstall   # 제거
```

기존 post-commit hook 있으면 graphify가 *append*함 (덮어쓰기 X).

### 3.4 Watch 모드 (실시간) — 선택

```bash
python3 -m graphify.watch . --debounce 3 &
```

- `--debounce N` (default 3초): 파일 활동 멈춘 후 N초 후 트리거
- 코드 변경 → AST 즉시 갱신 (LLM 무관)
- docs/papers 변경 → `graphify-out/needs_update` 플래그만 (수동 풀 빌드 필요)
- Ctrl+C로 정지

검증:
```bash
graphify check-update .   # needs_update 플래그 확인 (cron-safe)
```

### 3.5 MCP 서버 — 다른 AI 도구가 graph 쿼리

```bash
python3 -m graphify.serve graphify-out/graph.json
```

stdio MCP 서버 시작.

Claude Desktop config 예 (`~/Library/Application Support/Claude/claude_desktop_config.json`):
```json
{
  "mcpServers": {
    "graphify-myproject": {
      "command": "python3",
      "args": ["-m", "graphify.serve", "/abs/path/to/graphify-out/graph.json"]
    }
  }
}
```

노출 도구: `query_graph` · `get_node` · `get_neighbors` · `get_community` · `god_nodes` · `graph_stats` · `shortest_path`.

---

## 4. 검증 체크리스트

설치 직후 다음 모두 PASS여야 정상:

- [ ] `graphify --help`가 사용법 출력 (Usage: graphify <command>)
- [ ] `pip show graphifyy | grep Version` → 0.7.5+
- [ ] `graphify-out/graph.json` 존재, 크기 > 0
- [ ] `graphify-out/graph.html` 브라우저로 열기 → 노드 시각화 표시
- [ ] `graphify-out/GRAPH_REPORT.md`에 god nodes·communities 섹션 존재
- [ ] (always-on 설치 시) `CLAUDE.md`에 `## graphify` 섹션 4 rules 존재
- [ ] (always-on 설치 시) `.claude/settings.json`에 PreToolUse hook + Bash matcher 존재
- [ ] (git hook 설치 시) `graphify hook status` → "installed" 출력
- [ ] (실증 검증) Claude Code 세션에서 Bash grep 호출 직전 hook 알림 출력

---

## 5. 트러블슈팅

| 증상 | 원인 후보 | 해결 |
|---|---|---|
| `graphify: command not found` | PATH 또는 pip install 실패 | `pip show graphifyy`로 위치 확인. `~/.pyenv/shims` 또는 `~/.local/bin` PATH 검사 |
| `skill is from graphify X.Y.Z, package is A.B.C` 경고 | CLI ≠ skill 버전 (특히 글로벌 + `.venv` 병용 시 자주 발생) | 동작에는 영향 없음. 동기화하려면 `graphify install` 실행. 다중 워크스페이스는 §1.4 정책 참조 |
| `error: no LLM API key found` | `graphify extract` 실행 시 | `export ANTHROPIC_API_KEY=...` 또는 `MOONSHOT_API_KEY=...` 또는 옵션 A·B 사용 |
| `Refusing to overwrite (new graph N nodes < existing M)` | 의도적 corpus 축소 | `graphify update . --force` 또는 `GRAPHIFY_FORCE=1 graphify update .` |
| `manifest.json` 절대경로 stale (다른 머신) | manifest는 머신 절대경로 사용 | 풀 빌드 1회로 manifest 재생성 |
| HTML viz 5,000+ 노드 경고 | 대형 모노레포 | `cluster-only --no-viz` 또는 디렉토리 단위 분할 후 `merge-graphs` |
| `.graphifyignore` 무시됨 | 패턴 문법 오류 | `.gitignore` 동일 문법 사용. 절대경로 `/` 의미 주의 |
| Windows native에서 hook 미작동 | PreToolUse 미지원 | WSL 사용 권장 |
| pyenv `.venv` graphify가 stale shebang | .venv 경로 변경됨·재생성됨 | `.venv/bin/pip install --force-reinstall graphifyy` 또는 `.venv` 재생성 (§1.4 참조) |
| MCP 서버 경로 오류 | 상대경로 사용 | `claude_desktop_config.json`은 *절대경로* 필수 |
| 비-AST 언어 (Verilog, Tcl 등) | tree-sitter 미지원 | LLM 시멘틱 추출에 의존 (옵션 B/C) |

---

## 6. AI 에이전트용 부트스트랩 (한 줄)

스킬 글로벌 등록 (머신당 1회):

```bash
~/dev/graphify_pkg/bootstrap.sh
```

또는 수동:
```bash
mkdir -p ~/.claude/skills
cp -R ~/dev/graphify_pkg/skills/graphify-bootstrap ~/.claude/skills/
```

이후 어느 워크스페이스에서든 Claude Code 세션에서:

```
/graphify-bootstrap
```

자동 수행:
1. graphify CLI 설치 확인 (없으면 안내)
2. `.graphifyignore` 적용
3. 첫 빌드 (옵션 A — `graphify update .`)
4. `graphify claude install` (always-on hook)
5. 검증 체크리스트 실행
6. 결과 보고 — god nodes top 5 + community 수 + 토큰 절감 측정

수동 트리거 형식 (스킬 미설치 시):
```
이 워크스페이스에 graphify 부트스트랩해줘. graphify_pkg/INSTALL.md §1·§2.1·§2.2(옵션 A)·§3.1·§4 순서.
```

---

## 7. 제거 (필요 시)

```bash
cd ~/dev/your-project

# 1. always-on hook 제거 (CLAUDE.md 섹션 + settings.json hook)
graphify claude uninstall                # 또는 사용한 도구의 uninstall

# 2. git post-commit hook 제거
graphify hook uninstall

# 3. graph 산출물 삭제
rm -rf graphify-out/

# 4. (선택) ignore 파일 제거
rm .graphifyignore

# 5. (글로벌, 모든 프로젝트에서 제거하려면)
pip uninstall graphifyy
```

---

## 8. 다음 단계

설치 완료 후 → [`USAGE.md`](USAGE.md)로 이동:
- 일상 사용 명령어 카탈로그 (`extract`, `tree`, `save-result`, `check-update` 포함)
- god nodes·communities 해석법
- 베스트 프랙티스 (incremental 전략·docs/ 추가 시점)
- FAQ
