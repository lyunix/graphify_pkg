#!/usr/bin/env bash
# graphify_pkg bootstrap helper
# 사용:
#   ~/dev/graphify_pkg/bootstrap.sh
#
# 효과:
#   1. ~/.claude/skills/graphify-bootstrap/ 에 SKILL.md 등록 → /graphify-bootstrap 슬래시 활성화
#   2. 등록 결과 검증 + 다음 행동 안내
#
# graphify CLI 자체 설치는 본 스크립트에서 다루지 않음.
# 부트스트랩 첫 단계에서 글로벌 vs .venv 선택 후 설치.

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
SKILL_SRC="$SCRIPT_DIR/skills/graphify-bootstrap"
SKILL_DST="$HOME/.claude/skills/graphify-bootstrap"

if [ ! -d "$SKILL_SRC" ]; then
  echo "ERROR: $SKILL_SRC 가 없습니다. graphify_pkg root 에서 실행하세요." >&2
  exit 1
fi

mkdir -p "$HOME/.claude/skills"

if [ -d "$SKILL_DST" ]; then
  echo "ℹ  기존 스킬 발견 — 갱신: $SKILL_DST"
  rm -rf "$SKILL_DST"
fi

cp -R "$SKILL_SRC" "$SKILL_DST"

# 검증
if [ ! -f "$SKILL_DST/SKILL.md" ]; then
  echo "ERROR: 복사 후 $SKILL_DST/SKILL.md 가 없습니다." >&2
  exit 1
fi

echo "✓ graphify-bootstrap 스킬 등록됨: $SKILL_DST"
echo
echo "다음 행동:"
echo "  1. 새 워크스페이스에서 Claude Code 세션 시작"
echo "  2. /graphify-bootstrap 호출 → 자동 부트스트랩"
echo
echo "수동 트리거 (slash command 미인식 시):"
echo "  \"이 워크스페이스에 graphify 부트스트랩해줘. graphify_pkg/INSTALL.md §1·§2·§3.1·§4 순서.\""
echo
echo "graphify CLI 미설치 상태면 부트스트랩 첫 단계에서 설치 옵션 (글로벌 vs .venv) 을 안내합니다."
