# graphify 설치 계획 — `<WORKSPACE_NAME>`

> 작성일: YYYY-MM-DD
> 목적: 본 워크스페이스에 graphifyy v0.7.5+ 부트스트랩
> 근거: `graphify_pkg/INSTALL.md`, `graphify_pkg/skills/graphify-bootstrap/SKILL.md`
> 본 문서는 일회성 셋업 체크리스트. 완료 후 audit 용도로 보존.

---

## 0. 사용 방법

이 템플릿을 새 워크스페이스에 복사 후 `<...>` 자리를 채우고 실행:

```bash
cd ~/dev/<your-workspace>
mkdir -p docs
cp /path/to/graphify_pkg/templates/install_plan.template.md docs/graphify_install_plan.md
# 그 다음 docs/graphify_install_plan.md 의 <WORKSPACE_NAME>, 옵션 표시, 빈 셀 등 채움
```

`<...>` 가 모두 채워졌으면 §3 단계대로 진행. 각 단계 끝 **Verify** clause 로 다음 단계 진행 여부 결정.

---

## 1. 현재 상태 점검 (read-only 결과 — 채울 자리)

| 항목 | 상태 | 이번 작업 처리 |
|---|---|---|
| Python | `python3 --version` 결과 | 그대로 사용 / 변경 |
| pip | `pip --version` 결과 | 그대로 / 업그레이드 |
| 글로벌 graphifyy | `pip show graphifyy \| grep Version` (있/없) | 사용 / 미사용 / 무시 |
| `.venv` | 존재 / 없음 | 신규 생성 / skip |
| `.graphifyignore` | 존재 / 없음 | template 복사 / skip |
| `graphify-out/` | 존재 / 없음 | 첫 빌드로 생성 / 재빌드 |
| `.claude/` | 존재 / 없음 | hook 설치 시 생성 |
| `.gitignore` | `cat .gitignore` 검토 | graphify 정책 추가 |
| git repo | yes / no | hook 옵션 가능 / 불가 |

---

## 2. 설치 옵션 결정

| 항목 | 결정 | 근거 |
|---|---|---|
| 첫 빌드 모드 | A (`graphify update .`) / B (`/graphify .`) / C (`graphify extract .`) | (LLM 비용·docs 풍부도·사내 보안) |
| graphifyy 설치 위치 | 글로벌 / `.venv` 격리 | (다른 프로젝트와의 격리 필요성, INSTALL §1.4) |
| `.venv` scope (해당 시) | graphifyy 만 / 프로젝트 deps 통합 | (본 작업 범위) |
| 다국어/다도메인 분리 빌드 | yes / no | (frontend/backend 분리 필요성, USAGE §4.6) |
| always-on hook | 설치 / skip | (Claude Code 사용 시 강력 권장) |
| git post-commit hook | 설치 / skip | (`.venv` 사용 시 PATH 이슈 — INSTALL §1.4 참조) |

---

## 3. 단계별 절차 (verify clause 포함)

### Step 1 — `.venv` 생성 (해당 시)

```bash
python3 -m venv .venv
.venv/bin/pip install --upgrade pip
```

**Verify**:
```bash
test -f .venv/bin/python && .venv/bin/python --version
```

### Step 2 — graphifyy 설치

```bash
# 글로벌:
pip install graphifyy

# 또는 .venv:
.venv/bin/pip install graphifyy
```

**Verify**:
```bash
graphify --help | head -3                          # 또는 .venv/bin/graphify --help
pip show graphifyy | grep Version                  # 0.7.5+
```

### Step 3 — `.graphifyignore` 적용

```bash
cp /path/to/graphify_pkg/templates/graphifyignore.template .graphifyignore
```

**Verify**:
```bash
test -f .graphifyignore && wc -l .graphifyignore   # >50 lines
```

### Step 4 — 첫 빌드

옵션 A (default, AST-only):
```bash
graphify update .
# 또는 분리 빌드 (다국어 모노레포):
# graphify update src/backend
# graphify update src/frontend
```

옵션 B / C 는 INSTALL §2.2 참조.

**Verify**:
```bash
test -s graphify-out/graph.json
test -f graphify-out/graph.html
test -f graphify-out/GRAPH_REPORT.md
```

### Step 5 — `.gitignore` 보강

```bash
cat /path/to/graphify_pkg/templates/gitignore-graphify.template >> .gitignore
```

**Verify**:
```bash
grep -q "graphify-out/cache" .gitignore
```

### Step 6 — 결과 확인 (필수, 5분)

```bash
ls -la graphify-out/
head -100 graphify-out/GRAPH_REPORT.md             # god nodes top 5~10 통독
open graphify-out/graph.html                       # 시각화 (macOS)
```

읽기 우선 순위:
1. **God Nodes top 5~10** — 코어 추상. 예상과 일치하면 ✅, 의외면 *리팩토링 후보*
2. **Communities — cohesion < 0.1** — 분할 가능 = 정리 후보
3. **Surprising Connections** — 놓쳤던 연결
4. **Suggested Questions** — graph 가 *직접 추천하는* 질문 — 그대로 AI에 던짐

상세 → `graphify_pkg/skills/graphify-bootstrap/SKILL.md` "부트스트랩 직후 5분 행동" 섹션.

### Step 7 — (옵션, 컨펌 후) always-on hook

```bash
graphify claude install
# 다른 AI 도구: codex / cursor / gemini / opencode / aider / ... — INSTALL §3.2
```

**Verify**:
```bash
grep -q "^## graphify" CLAUDE.md
grep -q "PreToolUse" .claude/settings.json
```

### Step 8 — (옵션) git post-commit hook

```bash
graphify hook install
```

**Verify**:
```bash
graphify hook status                               # "installed" 출력
```

---

## 4. Risks & Tradeoffs (본 워크스페이스 특화 메모)

| Risk | 영향 | 대응 |
|---|---|---|
| `.venv` shebang stale (폴더 이동·재생성) | `.venv/bin/graphify` 깨짐 | `.venv/bin/pip install --force-reinstall graphifyy` |
| `CLAUDE.md` 본문이 한국어인데 영문 graphify 섹션 추가됨 | 가독성 약간 저하 | 컨펌 단계에서 검토. 마음에 안 들면 `graphify claude uninstall` |
| 첫 빌드 노드 5,000+ | HTML viz 무거움 | `.graphifyignore` 차단 강화 또는 디렉토리 분할 빌드 (USAGE §4.6) |
| (워크스페이스별 추가 risk 채울 자리) |  |  |

---

## 5. 완료 기준

- [ ] `graphify --help` 정상 출력
- [ ] `graphify-out/graph.json` 비어있지 않음
- [ ] `graphify-out/GRAPH_REPORT.md` god nodes 섹션 존재
- [ ] `.gitignore` graphify 정책 적용
- [ ] (옵션) always-on hook 활성
- [ ] (옵션) git post-commit hook 활성
- [ ] **5분 행동 체크리스트 완료** (GRAPH_REPORT.md 통독, AI 첫 질문)
