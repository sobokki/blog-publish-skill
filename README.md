# blog-publish-skill

개발하다 AI(Claude Code / Codex)와 문제를 풀며 **배운 것**을, 코딩 흐름을 끊지 않고
`"블로그에 올려줘"` 한마디로 GitHub Pages 블로그에 발행하는 스킬.

- **Claude Code** — 자연어로 자동 발동 (`"블로그에 올려줘"`, `"TIL로 기록해줘"`)
- **Codex** — `/blog` 슬래시 커맨드

현재 대화 맥락에서 `상황 → 해결 과정 → 배운 것`을 뽑아 한국어 포스트 초안을 만들고,
**확인을 받은 뒤에만** 블로그 레포에 `.md`를 커밋·push 한다. GitHub Pages가 자동 배포.

**YouTube URL** 을 주면 (`"이 영상 블로그에 올려줘"`) `yt-dlp` 로 자막·메타데이터를 뽑아,
영상을 임베드하고 내용을 분석·정리한 글을 만든다 (한국어 자막 우선).

## 요구사항

- 마크다운 기반 정적 블로그 레포 (Jekyll [Chirpy](https://github.com/cotes2020/chirpy-starter) 권장, `_posts/` 폴더 사용)
- GitHub Pages 배포 설정 (Chirpy는 Pages를 **GitHub Actions 빌드**로 설정)
- Claude Code 또는 Codex CLI
- (YouTube 정리 기능만 해당) [`yt-dlp`](https://github.com/yt-dlp/yt-dlp) — `brew install yt-dlp`. 없으면 스킬이 설치를 안내한다.

## 설치

```bash
git clone https://github.com/sobokki/blog-publish-skill.git
cd blog-publish-skill
./install.sh
```

`install.sh`가 하는 일:

1. `~/.claude/skills/blog/SKILL.md` 생성 (Claude Code)
2. `~/.codex/prompts/blog.md` 생성 (Codex, `/blog`)
3. `~/.config/blog-publish/config.env` 생성 — 블로그 경로/URL 입력받음

두 도구 모두 **단일 소스 `instructions.md`** 에서 생성되므로 내용이 항상 일치한다.

## 설정

`~/.config/blog-publish/config.env`:

```bash
BLOG_REPO="/Users/you/username.github.io"   # 블로그 레포 로컬 경로
BLOG_URL="https://username.github.io"        # 사이트 URL (끝에 / 없이)
```

스킬은 **현재 작업 디렉토리가 아니라** `BLOG_REPO` 경로에서 커밋하므로, 어느 프로젝트에서
코딩하든 자기 블로그로 발행된다.

## 사용

**Claude Code** — 코딩하다가:
```
이거 블로그에 올려줘
```
→ 초안을 보여줌 → `좋아` → 발행.

**Codex**:
```
/blog
```

**YouTube 영상 정리**:
```
이 영상 블로그에 올려줘 https://youtu.be/VIDEO_ID
```
→ 자막·메타데이터 추출 → 분석 → 영상 임베드 + 정리글 초안 → 확인 → 발행.

## 발행 흐름

```
"블로그에 올려줘"
  → 대화 맥락에서 상황/해결/배운점 추출
    (YouTube URL 이면: yt-dlp 로 자막(ko 우선)·메타데이터 추출 → 내용 분석 → 영상 임베드)
  → Chirpy 포스트 초안 작성 (제목/날짜/카테고리/태그)
  → 초안 보여주고 확인 대기 ⏸        ← 확인 없이는 발행 안 함
  → _posts/YYYY-MM-DD-slug.md 저장 → git commit → push
  → https://<blog>/posts/slug/  (1~2분 뒤 배포)
```

## 카테고리 (기본 제안)

`TIL` / `삽질기록` / `AI-협업` / `회고` — 자기 블로그 택소노미로 바꿔 써도 된다.

## 가드레일

- 확인 전 발행 금지
- API 키·토큰·비밀번호·고객 데이터·사내 코드 경로는 글에 넣지 않음
- 업무 코드의 비즈니스 로직은 일반화 (개념 위주, 특정 코드 배제)

## 라이선스

MIT
