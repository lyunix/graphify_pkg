# USAGE.md — Graphify 사용 가이드 (코드 워크스페이스)

> 청중: 사람. 설치 끝난 워크스페이스에서 일상적으로 graphify를 쓰는 법.
> 사전: [`INSTALL.md`](INSTALL.md) 완료 상태.
> **모든 명령은 graphifyy v0.7.5+ (v0.7.6 포함)에서 검증.**

---

## 1. 그래파이는 무엇을 해주나 — 4가지 사용 시나리오

| 시나리오 | 무엇을 알려주나 | 언제 가치 |
|---|---|---|
| **코드베이스 학습** | god nodes (가장 연결 많은 모듈) · 커뮤니티 (자연 분리 영역) · 아키텍처 의도 | 새 프로젝트 온보딩 / 인수인계 |
| **기술 부채 분석** | 과결합 노드 · cohesion < 0.1 커뮤니티 (분리 가능) · 의외 연결 (얽힘) | 리팩토링 우선순위 결정 |
| **연구 코퍼스** | 논문 ↔ 코드 통합 그래프 · 인용 관계 · 도메인 클러스터링 | 논문 구현 / 학술 코드 연결 |
| **개인 raw 폴더** | 트윗·메모·스크린샷 통합 · 의외 연결 · 시간 경과 후 쿼리 | PKM (별도 시스템 권장 — 본 패키지 범위 외) |

본 패키지는 **앞 두 시나리오에 집중**. 코드 워크스페이스 단독 사용.

---

## 2. 일상 명령어 카탈로그 (실증 검증된 것만)

### 2.1 자주 쓰는 7개 (90% 사용)

| 의도 | 명령 | 빈도 | LLM 비용 |
|---|---|---|---|
| 첫 빌드·풀 리빌드 (AST-only) | `graphify update .` | 1회 / 큰 리팩토링 후 | 무 |
| 첫 빌드·풀 리빌드 (LLM 풀) | `/graphify .` (Claude Code) | 1회 / 큰 리팩토링 후 | 세션 토큰 |
| 헤드리스 풀 추출 (CI) | `graphify extract .` | CI 빌드 | API key 사용 |
| 증분 갱신 (코드 변경) | `graphify update .` | 매 commit 후 (git hook) 또는 다음 작업 시작 직전 — §4.4 빈도 룰 참조 | 무 |
| 코드 질문 답변 | 자연어 질문 — AI가 GRAPH_REPORT.md 우선 참조 | 매일 | 응답 토큰만 |
| 그래프 시각화 | `open graphify-out/graph.html` | 작업 시 옆에 띄우기 | 무 |
| 사람용 보고서 | `cat graphify-out/GRAPH_REPORT.md` | 월 1회 audit | 무 |

### 2.2 가끔 쓰는 명령

| 의도 | 명령 |
|---|---|
| 두 노드 간 최단 경로 | `graphify path "AuthModule" "Database"` |
| 한 노드 plain-language 설명 | `graphify explain "SwinTransformer"` |
| 그래프 자연어 쿼리 (BFS) | `graphify query "how does X relate to Y" --budget 1500` |
| 그래프 자연어 쿼리 (DFS) | `graphify query "..." --dfs` |
| Q&A 결과 그래프에 환류 | `graphify save-result --question Q --answer A --type query --nodes N1 N2` |
| URL 추가 (논문·트윗·arXiv) | `graphify add https://arxiv.org/abs/...` |
| 토큰 절감 측정 | `graphify benchmark` |
| D3 collapsible-tree HTML | `graphify tree --output graphify-out/GRAPH_TREE.html` |
| 클러스터 재실행만 (재추출 없이) | `graphify cluster-only .` |
| 큰 그래프 (5000+) HTML 생략 | `graphify cluster-only . --no-viz` |
| Neo4j 내보내기 | `graphify extract .` 후 — graphify가 *Neo4j 명령은 없음* (export-only) — 수동 cypher 변환 필요 |
| GraphML 내보내기 | (export 명령 없음 — graph.json을 networkx로 직접 변환) |
| Cross-repo 통합 | `graphify clone <url> && graphify merge-graphs g1.json g2.json --out merged.json` |
| needs_update 플래그 확인 | `graphify check-update .` |

### 2.3 자동화 (한 번 깔고 잊기)

| 자동화 | 명령 | 효과 |
|---|---|---|
| Always-on (Claude Code) | `graphify claude install` | grep/find 호출 전 graph 알림 |
| Always-on (그 외 17개 도구) | `graphify <tool> install` | INSTALL §3.2 표 참조 |
| Git post-commit | `graphify hook install` | 매 commit 후 incremental + merge-driver |
| Watch 모드 | `python3 -m graphify.watch . --debounce 3 &` | 파일 저장 시 즉시 갱신 |
| MCP 서버 | `python3 -m graphify.serve graphify-out/graph.json` | 다른 AI 도구가 graph 쿼리 |

---

## 3. 결과 해석법 (`GRAPH_REPORT.md` 읽는 법)

### 3.1 Summary 섹션

```
- 305 nodes · 571 edges · 27 communities detected
- Extraction: 95% EXTRACTED · 5% INFERRED · 0% AMBIGUOUS
- Token cost: N input · M output (LLM 시멘틱 사용 시) 또는 0/0 (AST-only)
```

해석:
- **EXTRACTED 비율 > 90%** → 그래프 신뢰도 ↑ (소스에 명시된 관계만)
- **INFERRED ≈ 5~15%** → AI 추론 보강 (적당한 풍부도)
- **AMBIGUOUS > 10%** → 코퍼스 모호성 ↑ → docs 보강

### 3.2 God Nodes — 도메인의 코어 추상

> 가장 연결 많은 5~10개 노드. *코드베이스의 핵심 추상*을 자동 식별.

```
1. Claude Code - 38 edges
2. Graphify (Python library) - 23 edges
3. Building AI Second Brain - 22 edges
```

해석 가이드:
- **God nodes가 예상과 일치** → 아키텍처가 의도대로 설계됨
- **예상 외 노드가 god** → 의도치 않은 결합 발견 (리팩토링 후보)
- **God nodes 너무 많음 (10+ 비슷한 차수)** → 평탄한 구조 (계층 부재)
- **God node 1개에 압도적 차수** → "갓 클래스" 안티패턴 가능성

### 3.3 Communities — 자연 분리 영역

각 커뮤니티는 cohesion 점수 (0~1):
- **cohesion ≥ 0.5** — 강한 응집. 잘 정의된 모듈
- **0.2~0.5** — 적정. 정상 운영
- **< 0.1** — 약한 응집. 분할 후보 또는 연결 누락

활용:
- 약한 커뮤니티 → 모듈 분할 또는 cross-ref 보강
- 작은 커뮤니티 (n=1~3) → 고립 모듈. 통합 또는 제거 후보
- 큰 커뮤니티 (n=30+) → 비대화. 하위 카테고리 분리 후보

### 3.4 Surprising Connections — 의외 발견

```
- `ModuleA` --conceptually_related_to--> `ModuleB` [INFERRED]
```

해석:
- **EXTRACTED**: 소스에 명시된 관계 (놓쳤던 연결 발견)
- **INFERRED**: AI 추론 (검토 필요 — 진짜 연결인지 확인)

### 3.5 Suggested Questions — 그래프가 추천하는 질문

```
- Why does `Claude Code` connect `LLM Wiki + Graphify Core` to `Harness Building`?
  (betweenness 0.019 — bridge node)
```

→ **이 질문을 그대로 AI에 던져라**. graph 기반 답변이 자동으로 옴.

### 3.6 Knowledge Gaps — 약점 발견

```
- 202 isolated node(s): `AI = 위키 관리자`, `YAML frontmatter`, ...
  These have ≤1 connection - possible missing edges or undocumented components.
```

활용:
- 코드면: 미사용 모듈 또는 cross-cutting concern
- docs면: 본문에 등장하지만 페이지 없음 → 신규 문서 후보

---

## 4. 베스트 프랙티스

### 4.1 코드만 있는 프로젝트 — 가장 가벼운 운영

```bash
# 1회 부트스트랩
cd your-project
cp /path/to/graphify_pkg/templates/graphifyignore.template .graphifyignore
graphify update .              # AST-only 첫 빌드 (LLM 무비용)
graphify claude install        # always-on (Claude Code 사용 시)
graphify hook install          # 매 commit 자동 incremental

# 이후 사용자 행동 변화 0:
# - 코드 작성·commit → graph 자동 갱신 (AST-only, 무비용)
# - 코드 질문 → AI가 graph 우선 참조 (응답 품질 ↑, 토큰 ↓)
```

### 4.2 docs/ 추가는 *언제* 가치 있나

코드만으로 god nodes·communities 잘 보임 → docs/ 불필요.

다음 3가지 경우 docs/ 추가 시 가치 ↑ (단 LLM 시멘틱 추출 필요 — 옵션 B/C):

| 상황 | docs/에 뭘 넣나 | graphify가 추가로 답해주는 것 |
|---|---|---|
| 아키텍처 의도 부재 | `docs/decisions/ADR-NNNN.md` (Architecture Decision Records) | "*왜* 이 모듈 분리됐나" — 코드만으론 안 보임 |
| 도메인 모델 복잡 | `docs/domain-glossary.md`, `docs/business-rules.md` | 코드 클래스명 ↔ 비즈니스 개념 매핑 |
| 인터페이스 계약 | `docs/api-spec.md`, `openapi.yaml` | 외부 의존성·계약 변경 영향 추적 |

**docs/ 작성 형식 권장**:
```markdown
---
type: adr | domain | spec
created: 2026-05-05
related: ["module-name", "concept-name"]
---

# 제목

본문 — 코드와 *연결될 키워드*를 자연스럽게 사용 (graphify가 자동 추출).
```

### 4.3 .graphifyignore 운용

`templates/graphifyignore.template`을 시작점 → 프로젝트별 조정.

핵심 패턴 (`.gitignore` 문법 동일):
```
# 빌드 산출물 (재생성 가능)
node_modules/
dist/
build/
__pycache__/
.venv/

# 큰 binary·데이터
*.lock
*.min.js
coverage/

# graphify 자체
graphify-out/cache/         # (선택) 공유 시 그래프 캐시 차이 발생 가능
graphify-out/manifest.json  # 절대경로 — 머신마다 다름
```

### 4.4 Incremental vs 풀 빌드 — 언제 무엇을

| 변경 종류 | 권장 |
|---|---|
| 코드 파일만 수정 (함수·클래스) | `graphify update .` 또는 git hook 자동 (AST-only, 무비용) |
| 새 docs/ 파일 추가 | 옵션 B (`/graphify .`) 또는 옵션 C (`graphify extract .`) — LLM 필요 |
| 대량 rename·이동 | AST-only `update`로 충분 (cache가 content-hash 기반) |
| 코드 + docs 동시 변경 | 옵션 B/C 풀 빌드 |
| 1주~1개월 정기 audit | 옵션 B/C 풀 빌드 — 그래프 구조 재평가 |

cache는 content-hash 기반이라 rename은 cache hit 유지. 내용 바뀐 파일만 재추출.

#### 권장 갱신 빈도 (요약)

graphify update 를 *언제* 돌릴지에 대한 명확한 룰:

| 시점 | 명령 | 자동/수동 |
|---|---|---|
| **매 commit 후** (권장 default) | (자동) git post-commit hook | `graphify hook install` 1회 셋업 |
| 코드 변경 후 다음 작업 시작 직전 (hook 미설치 시) | `graphify update .` (서브트리는 sub-path) | 수동, 5~20초 |
| PR 리뷰 직전 | `graphify update .` | 수동 |
| 큰 리팩토링·corpus 축소 후 | `graphify update . --force` | 수동, 안전가드 무시 |
| 월 1회 audit (옵션 B/C) | `/graphify .` 또는 `graphify extract .` | 수동, LLM 비용 |

*안 돌려도 큰일 안 남* — 그래프가 stale 해질 뿐. 코드 질문 시 hook 알림은 stale 그래프도 어느 정도 가치 유지. 단 god nodes 가 의미 있게 변할 변경 (대형 리팩토링·rename) 후엔 즉시 갱신 권장.

빈도 결정 fallacy:

| ❌ 잘못된 패턴 | 문제 | ✅ 올바른 패턴 |
|---|---|---|
| "매 시간 cron" | 변경 없으면 무의미한 빌드 | git hook 으로 *변경 시점*에만 |
| "한 번도 안 돌림" | 그래프 stale → AI 답변 점점 부정확 | git hook 또는 daily 수동 |
| "매 파일 저장마다 watch" | 빈번한 disk IO + AST 재추출 | watch 모드는 `--debounce 3` 이상 |

### 4.5 `/graphify` 결과를 *읽는* 습관

설치만 하고 결과 안 보면 절반의 가치만 회수.

권장 루틴:
- **풀 빌드 직후**: `GRAPH_REPORT.md`의 god nodes / surprising connections / suggested questions 한 번 통독 (5분)
- **월 1회 audit**: 같은 보고서 재방문 — *시간이 지나며 god node가 어떻게 변했는지* 추적
- **리팩토링 전**: 약한 커뮤니티 (cohesion < 0.1) 우선 검토

### 4.6 큰 또는 다국어 모노레포 — 분리 vs 통합 그래프

분리 빌드를 권장하는 trigger 두 가지:

| Trigger | 이유 |
|---|---|
| **5,000+ 노드** | HTML viz 자동 경고. 빌드 시간 ↑ |
| **다국어/다도메인 모노레포** | 한 repo 안에 frontend (TS/JSX) + backend (Python) 처럼 언어·패러다임이 다른 코드 공존. 노드 수 적어도 god nodes·community 가 도메인별로 *더 정확*해짐 |

#### 분리 빌드 — 디렉토리 단위

```bash
graphify update src/backend       # ./src/backend/graphify-out/
graphify update src/frontend      # ./src/frontend/graphify-out/

# packages 패턴
graphify update packages/backend
graphify update packages/frontend
graphify update packages/shared
```

각 sub-tree 가 *자기 디렉토리에* graphify-out/ 를 따로 생성. 일상 작업은 자기 도메인 그래프만 참조.

#### 통합 빌드 — 풀스택 영향 분석용

```bash
graphify update .                 # 루트 — 전체 그래프
```

통합 그래프가 가치 있는 시점:
- API 계약 변경 (frontend fetcher ↔ backend endpoint 영향)
- 풀스택 리팩토링 시 cross-language *접점* 추적
- 월 1회 audit — 도메인 간 결합도 모니터링

분리 그래프에선 안 보이는 cross-language INFERRED edges (예: `handleGenerate() --calls--> postGenerate()` frontend→backend) 가 통합 그래프에서만 드러남.

#### 분리 vs 통합 비교

| 측면 | 분리 그래프 | 통합 그래프 |
|---|---|---|
| god nodes 정확도 | 도메인별로 *선명* | 일부 희석 |
| community 응집도 | 도메인 내부 — 정확 | 도메인별 자연 분리 + 통합 노이즈 |
| cross-language 접점 | 안 보임 | 보임 (INFERRED edges) |
| 빌드 시간 | 짧음 (sub-tree만) | 김 (전체) |
| 일상 사용 | ✅ 매일 | ❌ 월 1회 audit / 풀스택 변경 시 |

#### 운영 권장

- 일상 작업 → 분리 그래프 사용
- 풀스택 변경·API 계약 검토 → 통합 그래프
- `.gitignore` 에 모든 graphify-out 의 cache/manifest/cost 처리:
  ```
  graphify-out/cache/
  graphify-out/manifest.json
  graphify-out/cost.json
  src/backend/graphify-out/cache/
  src/backend/graphify-out/manifest.json
  src/backend/graphify-out/cost.json
  src/frontend/graphify-out/cache/
  src/frontend/graphify-out/manifest.json
  src/frontend/graphify-out/cost.json
  ```

#### Cross-graph 통합 (선택, 5,000+ 노드 시)

분리 그래프를 *하나의 graph.json* 으로 합치려면:

```bash
graphify merge-graphs src/frontend/graphify-out/graph.json \
                      src/backend/graphify-out/graph.json \
                      --out cross-package-graph.json
```

5,000+ 노드 환경에서 HTML viz 부담을 줄이려면 `cluster-only --no-viz` 로 HTML 생성 skip 후 JSON/report 만 사용.

### 4.7 보안·기밀 코드

| 시나리오 | 권장 |
|---|---|
| 사내 코드 (외부 LLM 호출 차단) | **옵션 A 만 사용** (`graphify update .`) — AST-only, LLM 호출 없음 |
| 공개 가능 코드 | 옵션 B/C OK. LLM 시멘틱 추출이 docs 풍부도 ↑ |
| 환경변수·API key 포함 | graphify가 sensitive 파일 자동 skip. 로그·CI에서도 graph 산출물 검토 |

graphify는 LLM에 *시멘틱 컨텐츠*만 보냄, 원본 코드 X. 그래도 사내 정책상 LLM 호출 차단이면 옵션 A 운영 가능.

---

## 5. 일상 워크플로 (시나리오별)

### 5.1 새 프로젝트 인수인계 받았을 때

```bash
cd inherited-project
cp /path/to/graphify_pkg/templates/graphifyignore.template .graphifyignore
graphify update .              # AST-only 첫 빌드 (무비용)
# 또는 docs 풍부 시:
# /graphify .                  # Claude Code 옵션 B

# 5분 통독:
cat graphify-out/GRAPH_REPORT.md | less
open graphify-out/graph.html

# AI에 질문:
# "이 코드베이스의 god nodes 5개를 한 줄씩 설명해줘"
# "어떤 모듈부터 읽으면 전체 흐름이 잡혀?"
# "Suggested Questions 중에 가장 중요한 거 골라서 답변해줘"
```

→ 1시간 안에 코드베이스 *지도* 확보.

### 5.2 리팩토링 우선순위 결정

```bash
graphify update .   # 최신 상태 보장
cat graphify-out/GRAPH_REPORT.md
```

읽기 순서:
1. **God nodes** — 의도된 코어인가? 예상 외면 표적
2. **약한 커뮤니티 (cohesion < 0.1)** — 분할 가능 = 리팩토링 후보
3. **Knowledge Gaps - 고립 노드** — 미사용 모듈 = 제거 후보

### 5.3 변경 영향 분석 (PR 리뷰)

```bash
graphify update .                                # PR 변경 반영
graphify path "변경된함수명" "API_endpoint"       # 영향 경로
graphify explain "변경된함수명"                   # 인접 컨텍스트
```

→ 단순 grep으로 못 찾는 *간접 영향* 발견.

### 5.4 새 기능 추가 전 설계 검토

```bash
graphify query "기능 X와 가장 관련 깊은 모듈은?"
graphify path "기존모듈A" "기존모듈B"  # 새 기능이 어디 끼어들지
```

### 5.5 좋은 답변을 그래프에 환류 (선택)

```bash
graphify save-result \
  --question "How does X relate to Y?" \
  --answer "X calls Y via the Z interface ..." \
  --type query \
  --nodes "X" "Y" "Z"
```

→ Q&A가 `graphify-out/memory/`에 저장. 다음 `graphify update`에서 그래프에 노드로 흡수.

---

## 6. FAQ

### Q1. LLM Wiki / PKM 시스템이 함께 필요한가?

A: **코드 워크스페이스에선 X**. graphify 단독으로 충분. LLM Wiki는 *PKM*용 별도 시스템 (raw/wiki/Output 3계층, ingest·query·lint 모드 등). 코드 분석에는 과한 운영 부담.

[Karpathy LLM Wiki 패턴](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f)이 흥미롭다면 별도 wiki 볼트 부트스트랩 권장.

### Q2. 토큰 절감 효과는 실제로 얼마인가?

코퍼스 크기에 비례:
- ~50 파일 / ~90k 단어: **71.5×** (graphify 공식 벤치마크)
- ~110 파일 / ~70k 단어: **4~38×** (실측)
- ~10 파일: ~1× (그래프 가치는 *구조 명확성*)

코퍼스가 커야 절감 효과 ↑. 작은 코드도 *이해 도구*로는 가치 있음.

### Q3. AST 추출은 어떤 언어 지원하나?

22+ 언어 (Tree-sitter 기반). graphify v0.7.5+ 기준:
- Python, TypeScript, JavaScript, Go, Rust, Java, C, C++, Ruby, Swift, Kotlin, C#, Scala, PHP, Lua, Fortran, R, Bash, SQL 등

미지원 언어는 LLM 시멘틱 추출에 의존 (옵션 B/C 사용).

### Q4. `graphify-out/`을 git에 commit할까?

| 파일 | 권장 |
|---|---|
| `graph.json` | (선택) commit OK — 다른 사람과 공유. 큼 (수 MB) |
| `graph.html` | (선택) commit OK |
| `GRAPH_REPORT.md` | **권장**. 작고 사람용 readme로 가치 |
| `manifest.json` | 절대경로 포함 — **gitignore 권장** |
| `cost.json` | 로컬 토큰 트래킹 — gitignore |
| `cache/` | (선택) commit 시 다른 머신에서 cache hit, repo 사이즈 ↑ — 트레이드오프 |

`.gitignore` 권장:
```
graphify-out/cache/
graphify-out/manifest.json
graphify-out/cost.json
```

### Q5. 큰 변경 후 그래프가 갑자기 작아짐 — 정상?

graphify가 안전 가드 발동:
```
WARNING: new graph has N nodes but existing graph.json has M.
Refusing to overwrite — you may be missing chunk files from a previous session.
```

의도된 corpus 축소 (rename·archive·삭제) 시 발생.

해결:
```bash
graphify update . --force
# 또는
GRAPHIFY_FORCE=1 graphify update .
```

### Q6. AI 호출이 너무 많이 됨 — 비용 우려

```bash
# 코드 변경만이면 AST-only (LLM 무호출)
graphify update .

# git hook이면 자동으로 AST-only (코드만 변경 시)
graphify hook install
```

LLM 호출은 docs·papers·images 추출 또는 옵션 B/C 풀 빌드 시에만 발생.

### Q7. 다른 AI 도구도 사용 가능?

17개 통합 지원 (graphify v0.7.5+):

| 카테고리 | 지원 도구 |
|---|---|
| Claude 계열 | Claude Code, Claude for Chrome (browser) |
| OpenAI 계열 | Codex CLI, GitHub Copilot CLI, VS Code Copilot Chat |
| 그 외 IDE/CLI | Cursor, Gemini CLI, OpenCode, Aider, Kiro IDE/CLI, Trae, Trae CN, Antigravity (Google), Hermes, Pi, OpenClaw, Factory Droid |

각 `graphify <tool> install/uninstall` ([INSTALL.md §3.2](INSTALL.md) 표 참조).

### Q8. MCP 서버는 언제 켜나?

여러 AI 도구·세션이 *같은 그래프*를 쿼리할 때. Claude Desktop·다른 AI 도구가 stdio MCP로 graphify를 호출 → 항상 최신 graph 참조.

단일 사용자·단일 도구면 always-on hook으로 충분.

### Q9. 첫 빌드에 API key가 필요한가?

**아니오**. 옵션 A (`graphify update .`)는 API key 없이 first-build부터 정상 작동.
- AST-only 추출 — LLM 무호출
- 빈 `graphify-out/`에서 시작 가능
- 코드 위주 프로젝트의 default 진입점

옵션 B (`/graphify .`)도 별도 API key 불필요 — Claude Code 세션이 처리.

옵션 C (`graphify extract .`)만 API key 필수.

### Q10. graphify와 다른 도구 (CodeQL, Sourcegraph 등) 차이는?

| 도구 | 강점 | 약점 |
|---|---|---|
| graphify | knowledge graph 시각화, AI-friendly, 무료, 작은 코퍼스에서도 가치 | 정적 분석 깊이 (CodeQL이 우세) |
| CodeQL | 보안 분석, 정적 분석 정밀 | 학습 곡선, 시각화 X |
| Sourcegraph | 대규모 검색, 인덱싱 | 비용, 셋업 복잡 |
| ctags / cscope | 단순·빠른 코드 네비게이션 | 시맨틱 추출 X |

graphify는 *AI와 함께 쓸 때* 진가. graph가 AI에 컨텍스트로 주입됨.

---

## 7. 한계 — 알아두면 좋은 것

| 한계 | 영향 | 우회 |
|---|---|---|
| 5,000+ 노드 시 HTML viz 무거움 | 시각화 느림 | `cluster-only --no-viz` 또는 디렉토리 분할 빌드 |
| `manifest.json` 절대경로 | 머신 간 incremental 불가 | 풀 빌드 1회로 재생성 |
| Windows native PreToolUse hook 미지원 | always-on 부분 작동 | WSL 권장 |
| 비-AST 언어 (Verilog, Tcl) | LLM 시멘틱만으로 추출 | 옵션 B/C 사용 |
| 1만 줄 단일 파일 | LLM 시멘틱 추출 시 chunk 분할 | 자동 분할되나 컨텍스트 단편화 가능 |
| 폐쇄망 (LLM 호출 차단) | 시멘틱 추출 불가 | 옵션 A만 운영 (`graphify update .`) |
| `graphify extract` API key 필수 | 헤드리스 풀 추출 시 | 옵션 A·B로 우회 |

---

## 8. 참고 자료

- 공식 GitHub: [github.com/safishamsi/graphify](https://github.com/safishamsi/graphify)
- 한국어 랜딩: [graphify.net/kr](https://graphify.net/kr/)
- [graphify 71.5× 토큰 절감 영상 (Working AI)](https://www.youtube.com/watch?v=Ma8e25AOtao)
- [Medium: How to Use Graphify](https://medium.com/agentic-builders/how-to-use-graphify-turn-any-folder-into-a-knowledge-graph-d51b38eb60b6)
- [Karpathy LLM Wiki 패턴](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f) — 코드 외 *지식 누적* 시스템 검토 시
- 본 패키지 [`INSTALL.md`](INSTALL.md) — 설치 단계
- 본 패키지 [`templates/`](templates/) — `.graphifyignore`, CLAUDE.md 섹션, settings.json hook
- 본 패키지 [`skills/graphify-bootstrap/`](skills/graphify-bootstrap/) — 한 줄 부트스트랩 스킬

---

## 9. 한 줄 요약

> **코드 워크스페이스에 graphify 깔고 잊어라**. `graphify update .` 한 번 + always-on hook + git hook 켜두면 사용자 행동 변화 없이 *코드 질문 답변 품질 ↑ + 토큰 ↓*. docs/는 *있으면 좋고 없어도 됨*. PKM이나 wiki 시스템 만들 필요 없음.
