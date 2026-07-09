개발하며 AI와 문제를 풀고 배운 것을, 코딩 흐름을 끊지 않고 블로그 글로 발행한다.
GitHub Pages(Jekyll Chirpy 등 마크다운 기반 정적 블로그)에 `.md` 파일을 커밋·push 하는 방식.

## 0. 설정 로드 (먼저 실행)

블로그 레포 경로와 사이트 URL은 하드코딩하지 않고 설정파일에서 읽는다:

```bash
cat ~/.config/blog-publish/config.env
```

- `BLOG_REPO` — 블로그 레포 **로컬 경로** (현재 작업 디렉토리 cwd가 아님)
- `BLOG_URL` — 사이트 URL (끝에 `/` 없이. 예: `https://username.github.io`)

**설정파일이 없거나 값이 비어있으면**, 사용자에게 (1) 블로그 레포 로컬 경로 (2) 사이트 URL 을 물어보고 아래처럼 만든 뒤 진행한다:

```bash
mkdir -p ~/.config/blog-publish
cat > ~/.config/blog-publish/config.env <<'EOF'
BLOG_REPO="/absolute/path/to/your.github.io"
BLOG_URL="https://your.github.io"
EOF
```

이후 모든 경로는 `$BLOG_REPO`, 발행 URL은 `$BLOG_URL` 을 기준으로 쓴다.

## 0.5. 입력 유형 판별 (설정 로드 다음)

요청/맥락에 **YouTube URL** 이 있는지 본다 (`youtube.com/watch?v=`, `youtu.be/`, `youtube.com/shorts/`).

- **YouTube URL 있음** → 아래 **1-Y. YouTube 영상 추출** 로 간다. 이후 2~4단계(초안/검토/발행)는 공통.
- **없음 (대화 맥락 정리)** → 기존 **1. 학습 포인트 추출** 로 간다.

## 절차 (반드시 순서대로)

### 1-Y. YouTube 영상 추출 (YouTube URL 입력 시)

`yt-dlp` 로 메타데이터와 자막을 뽑아 내용을 분석한다.

**전제**: `yt-dlp` 설치 확인. 없으면 사용자에게 알리고 `brew install yt-dlp` 승인받아 설치 (시스템 전역 설치).

```bash
command -v yt-dlp || echo "NEEDS_INSTALL"
```

**1) 메타데이터** (제목·채널·길이·업로드일):

```bash
yt-dlp --skip-download \
  --print "title:%(title)s" --print "channel:%(channel)s" \
  --print "duration:%(duration_string)s" --print "upload:%(upload_date)s" \
  "<URL>"
```

**2) 자막 다운로드** — **한국어(ko) 우선**, 없으면 en → 첫 자동자막 fallback. scratchpad 에 받는다:

```bash
cd <scratchpad>
yt-dlp --skip-download --write-auto-subs --write-subs \
  --sub-langs "ko,en" --sub-format "srt/vtt/best" \
  -o "sub_%(id)s.%(ext)s" "<URL>"
ls sub_*.srt sub_*.vtt 2>/dev/null
```
자막이 아예 없으면(캡션 미제공) 분석 불가 — 사용자에게 알리고, 임베드만 한 글로 갈지 물어본다.

**3) 자막 정제** — 타임스탬프/인덱스/중복 제거해 순수 텍스트로:

```bash
python3 - <<'PY'
import re, glob
f = sorted(glob.glob("sub_*.ko.*") or glob.glob("sub_*.en.*") or glob.glob("sub_*"))[0]
raw = open(f, encoding="utf-8").read()
out = []
for ln in raw.splitlines():
    if re.match(r'^\d+$', ln) or '-->' in ln: continue
    ln = re.sub(r'<[^>]+>', '', ln).strip()
    if ln and (not out or out[-1] != ln): out.append(ln)
text = re.sub(r'\s+', ' ', " ".join(out)).strip()
open("transcript_clean.txt","w",encoding="utf-8").write(text)
print("chars:", len(text)); print(text[:800])
PY
```

**4) 내용 분석** — `transcript_clean.txt` 전체를 읽고, 영상이 무엇을 다루는지 구조화해서 **"내가 이 영상에서 배운 것"** 관점으로 재구성한다. 자막을 그대로 옮기지 않는다 (요약·해석·핵심 정리).

**5) 영상 ID 확보** — 임베드에 쓸 11자 video id (`watch?v=` 뒤, `youtu.be/` 뒤, `shorts/` 뒤).

이후 **2. 초안 작성** 으로 간다. 단, YouTube 글은 본문 구조가 다르다 (2단계 참고).

### 1. 학습 포인트 추출
현재 대화 맥락에서 다음을 뽑는다:
- **상황**: 어떤 문제·과제를 만났는가
- **해결 과정**: AI와 어떻게 접근했고 무엇을 시도했는가
- **배운 것**: 새로 알게 된 개념 / 다음에 써먹을 포인트

대화가 길면 이번 글의 주제를 사용자에게 한 줄로 확인한다. (예: "이번 건 'N+1 쿼리 잡은 과정'으로 잡으면 될까요?")

### 2. 초안 작성
아래 형식의 `.md` 초안을 만든다.

```markdown
---
title: "한국어 제목"
date: {아래 2-1에서 구한 시각}
categories: [상위, 하위]
tags: [tag1, tag2, tag3]
---

## 상황
...

## 해결 과정
...

## 배운 것
...
```

작성 규칙:
- **본문은 한국어** (다국어 블로그면 사용자 선호 언어로).
- **코드/에러 메시지**는 fenced code block(```lang)으로 넣는다.
- 제목은 낚시성 없이, 무엇을 다뤘는지 드러나게.
- 과장·군더더기 없이. 실제로 배운 것에 집중.

#### 2-Y. YouTube 글 형식 (1-Y 로 왔을 때)

본문 뼈대를 상황/해결/배운것 대신 아래로 바꾼다. `title`/`date`/`categories`/`tags` frontmatter 규칙(2-1)은 동일.

```markdown
---
title: "..."
date: {2-1 시각}
categories: [TIL, ...]
tags: [..., youtube]
---

## 왜 이 영상을
{왜 봤는지 / 어떤 맥락. 관련 이전 글 있으면 내부 링크}

{% raw %}{% include embed/youtube.html id='<VIDEO_ID>' %}{% endraw %}

> 채널: {채널명} · 길이 {길이}

## 1. {핵심 주제}
{자막 분석 기반 정리}

## 2. {핵심 주제}
...

## 정리
{내가 남길 것 3가지 안팎 + 후속 계획}
```

- 임베드는 Chirpy 표준 include `{% raw %}{% include embed/youtube.html id='...' %}{% endraw %}` 사용. `<VIDEO_ID>` 는 1-Y 5)에서 확보한 11자 id.
- 첫 문단에 채널명·길이 등 출처를 명시한다 (attribution).
- 자막을 그대로 옮기지 말고 **핵심을 재구성**한다. 한계·주의점 등 실전 포인트가 있으면 별도 섹션으로.
- `tags` 에 `youtube` 를 넣는다.

#### 2-1. frontmatter 값 규칙
- `title`: 큰따옴표로 감싼다.
- `date`: **반드시** 아래 명령으로 현재 시각(로컬 타임존)을 구해 넣는다 (직접 추측 금지). KST 예시:
  ```bash
  date "+%Y-%m-%d %H:%M:%S %z"
  ```
- `categories`: 최대 2단계 (Chirpy 규칙). 사용자 블로그의 택소노미를 따른다. 기본 제안:
  - `TIL` — 그날 배운 단편
  - `삽질기록` — 문제와 씨름한 과정
  - `AI-협업` — AI와 함께 만든 구현 이야기
  - `회고` — 프로젝트/기간 단위 돌아보기
- `tags`: 자유 형식, 영문 소문자 권장 (`claude-code`, `orm`, `nextjs` 등). 3~6개.

### 3. 초안 검토 (발행 전 필수 정지)
- 완성한 `.md` 전체를 사용자에게 보여준다.
- **명시적 확인("좋아"/"올려줘"/"발행")을 받기 전에는 절대 커밋·push 하지 않는다.**
- 수정 요청이 오면 반영 후 다시 보여주고 재확인한다.

### 4. 발행
확인받은 뒤에만 실행한다.

1. **파일명**: `$BLOG_REPO/_posts/YYYY-MM-DD-<slug>.md`
   - 날짜는 `date +%Y-%m-%d` (로컬).
   - `<slug>`는 **영문 소문자 + 하이픈** (예: `nplus1-query`). 한글 파일명 금지 (URL 깨짐).
   - 파일명 형식이 틀리면 Chirpy가 렌더링하지 않는다.
2. **저장**: 초안을 위 경로에 쓴다.
3. **커밋·push**: 블로그 레포에서 실행한다 (cwd 아님).
   ```bash
   cd "$BLOG_REPO"
   git add "_posts/YYYY-MM-DD-<slug>.md"
   git commit -m "post: <제목>"
   git push origin HEAD
   ```
4. **발행 안내**: 배포 URL을 알려준다: `$BLOG_URL/posts/<slug>/` (GitHub Pages는 1~2분 뒤 반영).

## 가드레일

- **확인 없이 발행 금지** — 3단계 정지를 건너뛰지 않는다.
- **비밀 정보 유출 금지** — 대화 맥락의 API 키·토큰·비밀번호·내부 URL·고객 데이터·사내 코드 경로는 글에 넣지 않는다. 애매하면 사용자에게 확인.
- **회사 기밀 주의** — 업무 코드의 구체적 비즈니스 로직이 드러나면 일반화하거나 사용자에게 확인. "무엇을 배웠나"(개념)에 집중하고 "누구의 코드"는 지운다.
- **cwd 아니라 `$BLOG_REPO`** — 다른 프로젝트에서 코딩 중이어도 반드시 블로그 레포 경로에서 커밋한다.
- **이미지는 범위 밖** — 텍스트·코드 위주. 스크린샷 자동 첨부는 하지 않는다.
- **YouTube 출처 명시** — 영상 글은 반드시 임베드 + 채널명을 넣어 원저작자를 밝힌다. 자막 전문을 그대로 붙여넣지 않는다 (핵심 재구성). 영상 파일 자체를 다운로드하지 않는다 (자막·메타데이터만).

## 체크리스트

- [ ] `~/.config/blog-publish/config.env` 로드 (없으면 생성)
- [ ] 입력 유형 판별 (대화 맥락 vs YouTube URL)
- [ ] (YouTube) `yt-dlp` 설치 확인 → 메타데이터·자막(ko 우선) 추출 → 정제 → 분석 → video id 확보
- [ ] 대화에서 상황/해결/배운점 추출 (또는 YouTube 글 형식 2-Y)
- [ ] `date` 명령으로 현재 시각 확보
- [ ] 초안 + Chirpy frontmatter 작성
- [ ] 초안 전체를 보여주고 확인 대기
- [ ] 확인 후에만 `$BLOG_REPO/_posts/YYYY-MM-DD-<slug>.md`(영문 slug)로 저장
- [ ] 블로그 레포 경로에서 commit·push
- [ ] 비밀/기밀 미포함 확인
- [ ] 발행 URL(`$BLOG_URL/posts/<slug>/`) 안내
