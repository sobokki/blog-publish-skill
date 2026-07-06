#!/usr/bin/env bash
set -euo pipefail

# blog-publish-skill installer
# Claude Code(~/.claude/skills/blog) 와 Codex(~/.codex/prompts/blog.md) 양쪽에 설치한다.
# 단일 소스: instructions.md

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BODY="$SCRIPT_DIR/instructions.md"

if [[ ! -f "$BODY" ]]; then
  echo "✗ instructions.md 를 찾을 수 없습니다: $BODY" >&2
  exit 1
fi

echo "▶ blog-publish-skill 설치 시작"

# ── 1. Claude Code skill ─────────────────────────────────────────
CLAUDE_DIR="$HOME/.claude/skills/blog"
mkdir -p "$CLAUDE_DIR"
{
  cat <<'FRONTMATTER'
---
name: blog
description: 개발하다 배운 것을 블로그 글로 발행할 때 사용. "블로그에 올려줘", "이거 블로그 글로 써줘", "TIL로 기록해줘", "방금 배운 거 블로그에 정리해줘" 같은 요청에 발동. 현재 대화 맥락에서 학습 포인트를 뽑아 포스트 초안을 만들고, 확인받은 뒤 GitHub Pages 블로그에 커밋·push 해서 발행한다. 블로그 경로/URL은 ~/.config/blog-publish/config.env 에서 읽는다.
---

# 블로그 발행 스킬

FRONTMATTER
  cat "$BODY"
} > "$CLAUDE_DIR/SKILL.md"
echo "  ✓ Claude Code: $CLAUDE_DIR/SKILL.md"

# ── 2. Codex prompt ──────────────────────────────────────────────
CODEX_DIR="$HOME/.codex/prompts"
mkdir -p "$CODEX_DIR"
{
  echo "# 블로그 발행 (/blog)"
  echo
  echo "개발하다 배운 것을 GitHub Pages 블로그에 발행한다. 아래 절차를 따른다."
  echo
  cat "$BODY"
} > "$CODEX_DIR/blog.md"
echo "  ✓ Codex: $CODEX_DIR/blog.md  (사용: /blog)"

# ── 3. 설정파일 ──────────────────────────────────────────────────
CONFIG_DIR="$HOME/.config/blog-publish"
CONFIG="$CONFIG_DIR/config.env"
if [[ -f "$CONFIG" ]]; then
  echo "  ✓ 설정파일 이미 존재: $CONFIG (유지)"
else
  mkdir -p "$CONFIG_DIR"
  if [[ -t 0 ]]; then
    echo
    echo "블로그 설정을 입력하세요 (나중에 $CONFIG 에서 수정 가능):"
    read -r -p "  블로그 레포 로컬 경로 (예: $HOME/username.github.io): " BLOG_REPO
    read -r -p "  사이트 URL (예: https://username.github.io): " BLOG_URL
  else
    echo "  ⚠ 비대화형 환경 — 설정파일을 placeholder로 생성합니다. 나중에 값을 채우세요."
    BLOG_REPO=""
    BLOG_URL=""
  fi
  cat > "$CONFIG" <<EOF
# blog-publish-skill 설정
BLOG_REPO="${BLOG_REPO}"
BLOG_URL="${BLOG_URL}"
EOF
  echo "  ✓ 설정파일 생성: $CONFIG"
fi

echo
echo "✅ 설치 완료"
echo "   Claude Code: \"블로그에 올려줘\" 라고 말하면 발동"
echo "   Codex:       /blog 입력"
