# 블로그 마이그레이션 및 Google Analytics/AdSense 통합 가이드

## 현재 상황 분석

현재 블로그는:
- 마크다운 파일 기반
- `archive/index.html`에서 클라이언트 사이드로 marked.js를 사용해 렌더링
- GitHub Pages로 서비스 중 (`https://shiwoo-park.github.io/blog/`)
- 간단한 배포 프로세스 (`scripts/commit.sh`)
- 블로그 포스트는 `blog_posts/` 디렉토리에 구조화되어 있음
- 코드 스니펫은 `code_snippets/` 디렉토리에 있음

## 추천 솔루션 비교

### 1. Jekyll (가장 추천 ⭐⭐⭐⭐⭐)

**장점:**
- GitHub Pages 네이티브 지원 (별도 빌드 설정 불필요)
- 전세계적으로 가장 널리 사용되는 정적 사이트 생성기
- 마크다운 파일 구조 그대로 유지 가능
- Google Analytics/AdSense 통합 매우 쉬움
- 수천 개의 무료 테마 제공
- Ruby 기반이지만 설정만 하면 자동 빌드

**단점:**
- Ruby 의존성 (하지만 GitHub Pages에서 자동 처리)
- 빌드 속도가 Hugo보다 느림 (하지만 블로그 규모에서는 무시 가능)

**마이그레이션 난이도:** ⭐⭐ (쉬움)

---

### 2. Hugo (빌드 속도 최고 ⭐⭐⭐⭐)

**장점:**
- 매우 빠른 빌드 속도 (초 단위)
- Go 기반, 단일 바이너리로 간단
- 마크다운 파일 구조 그대로 유지 가능
- Google Analytics/AdSense 통합 쉬움
- GitHub Actions로 자동 빌드/배포 가능

**단점:**
- GitHub Pages에서 자동 빌드 지원 안 함 (GitHub Actions 필요)
- Jekyll보다 사용자 수 적음 (하지만 충분히 많음)

**마이그레이션 난이도:** ⭐⭐⭐ (보통)

---

### 3. Astro (최신 기술 ⭐⭐⭐⭐)

**장점:**
- 매우 빠른 성능 (거의 0KB JavaScript)
- React/Vue/Svelte 등 다양한 프레임워크 지원
- 마크다운 네이티브 지원
- Google Analytics/AdSense 통합 쉬움
- Vercel/Netlify에서 무료 호스팅 가능

**단점:**
- 상대적으로 새로운 기술 (커뮤니티는 빠르게 성장 중)
- Node.js 기반

**마이그레이션 난이도:** ⭐⭐⭐ (보통)

---

### 4. Next.js (React 기반 ⭐⭐⭐)

**장점:**
- React 생태계 활용 가능
- Vercel에서 무료 호스팅 (자동 배포)
- 매우 강력한 기능들
- Google Analytics/AdSense 통합 쉬움

**단점:**
- 마크다운 파일 구조 변경 필요
- React 학습 곡선
- 오버엔지니어링일 수 있음 (블로그용으로는)

**마이그레이션 난이도:** ⭐⭐⭐⭐ (어려움)

---

## 최종 추천: Jekyll

**이유:**
1. GitHub Pages 네이티브 지원으로 설정 최소화
2. 전세계적으로 가장 많이 사용 (커뮤니티, 문서, 테마 풍부)
3. 마크다운 파일 구조 거의 그대로 유지
4. Google Analytics/AdSense 통합 매우 간단
5. 유지보수 최소화 (GitHub에서 자동 빌드)

---

## Jekyll 마이그레이션 단계별 가이드

### Step 1: 기본 Jekyll 설정

1. **`_config.yml` 파일 생성** (블로그 루트에)

```yaml
# Site settings
title: 실바의 블로그
description: 개발 블로그
url: https://shiwoo-park.github.io
baseurl: /blog

# Google Analytics
google_analytics: G-XXXXXXXXXX  # 나중에 추가

# Google AdSense
google_adsense: ca-pub-XXXXXXXXXX  # 나중에 추가

# Build settings
markdown: kramdown
plugins:
  - jekyll-feed
  - jekyll-sitemap

# Exclude from processing
exclude:
  - README.md
  - readme.md
  - scripts/
  - .gitignore
  - archive/
  - docs/
  - job_specs/
  - code_snippets/
```

2. **`Gemfile` 생성** (선택사항, 로컬 테스트용)

```ruby
source "https://rubygems.org"

gem "jekyll", "~> 4.3"
gem "github-pages", group: :jekyll_plugins
```

3. **`_layouts/default.html` 생성** (기본 레이아웃)

```html
<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>{% if page.title %}{{ page.title }} | {% endif %}{{ site.title }}</title>
  <link rel="stylesheet" href="{{ '/assets/css/main.css' | relative_url }}">
  
  <!-- Google Analytics -->
  {% if site.google_analytics %}
  <!-- Google tag (gtag.js) -->
  <script async src="https://www.googletagmanager.com/gtag/js?id={{ site.google_analytics }}"></script>
  <script>
    window.dataLayer = window.dataLayer || [];
    function gtag(){dataLayer.push(arguments);}
    gtag('js', new Date());
    gtag('config', '{{ site.google_analytics }}');
  </script>
  {% endif %}
  
  <!-- Google AdSense -->
  {% if site.google_adsense %}
  <script async src="https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client={{ site.google_adsense }}"
     crossorigin="anonymous"></script>
  {% endif %}
</head>
<body>
  <header>
    <h1><a href="{{ '/' | relative_url }}">{{ site.title }}</a></h1>
  </header>
  
  <main>
    {{ content }}
  </main>
  
  <footer>
    <p>&copy; {{ site.time | date: "%Y" }} {{ site.title }}</p>
  </footer>
</body>
</html>
```

4. **`_layouts/post.html` 생성** (포스트 레이아웃)

```html
---
layout: default
---
<article>
  <header>
    <h1>{{ page.title }}</h1>
    {% if page.date %}
    <time datetime="{{ page.date | date: '%Y-%m-%d' }}">
      {{ page.date | date: "%Y년 %m월 %d일" }}
    </time>
    {% endif %}
  </header>
  
  <div class="content">
    {{ content }}
  </div>
  
  <!-- AdSense 광고 (선택사항) -->
  {% if site.google_adsense %}
  <div class="adsense-container">
    <ins class="adsbygoogle"
         style="display:block"
         data-ad-client="{{ site.google_adsense }}"
         data-ad-slot="1234567890"
         data-ad-format="auto"
         data-full-width-responsive="true"></ins>
    <script>
         (adsbygoogle = window.adsbygoogle || []).push({});
    </script>
  </div>
  {% endif %}
</article>
```

5. **`index.html` 생성** (메인 페이지)

```html
---
layout: default
---
<h2>최근 포스트</h2>
<ul>
  {% for post in site.posts limit: 10 %}
  <li>
    <a href="{{ post.url | relative_url }}">{{ post.title }}</a>
    <span class="date">{{ post.date | date: "%Y-%m-%d" }}</span>
  </li>
  {% endfor %}
</ul>
```

### Step 2: 마크다운 파일에 Front Matter 추가

각 마크다운 파일 상단에 YAML Front Matter 추가:

```markdown
---
layout: post
title: "포스트 제목"
date: 2025-01-15
categories: [dev, python]
---

기존 마크다운 내용...
```

**자동화 스크립트 예시:**

```python
# add_frontmatter.py
import os
import re
from pathlib import Path

def add_frontmatter_to_md(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # 이미 front matter가 있으면 스킵
    if content.startswith('---'):
        return
    
    # 파일명에서 제목 추출
    title = Path(file_path).stem.replace('_', ' ').title()
    
    # 날짜는 파일 수정 시간에서 추출 (또는 수동 입력)
    frontmatter = f"""---
layout: post
title: "{title}"
date: 2025-01-15
---

"""
    
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(frontmatter + content)

# 모든 .md 파일에 적용 (README.md, docs/, code_snippets/ 제외)
exclude_dirs = {'archive', 'node_modules', '.git', 'resources', 'code_snippets', 'docs', 'job_specs'}
exclude_files = {'README.md', 'readme.md', 'favorite.md', '_post_template.md'}

for root, dirs, files in os.walk('.'):
    # 제외할 디렉토리 필터링
    dirs[:] = [d for d in dirs if d not in exclude_dirs]
    
    for file in files:
        if file.endswith('.md') and file not in exclude_files:
            file_path = os.path.join(root, file)
            add_frontmatter_to_md(file_path)
```

### Step 3: Google Analytics 설정

1. **Google Analytics 계정 생성**
   - https://analytics.google.com 접속
   - 계정 생성 및 속성(Property) 생성
   - 측정 ID 받기 (예: `G-XXXXXXXXXX`)

2. **`_config.yml`에 추가**
   ```yaml
   google_analytics: G-XXXXXXXXXX
   ```

3. **레이아웃 파일에 이미 추가됨** (Step 1의 `_layouts/default.html`)

### Step 4: Google AdSense 설정

1. **Google AdSense 계정 생성**
   - https://www.google.com/adsense 접속
   - 계정 생성 및 사이트 승인 대기 (보통 1-2일)
   - 발행자 ID 받기 (예: `ca-pub-XXXXXXXXXX`)

2. **`_config.yml`에 추가**
   ```yaml
   google_adsense: ca-pub-XXXXXXXXXX
   ```

3. **광고 배치 위치 결정**
   - 포스트 상단/하단
   - 사이드바
   - 인라인 광고

4. **광고 코드 추가** (레이아웃 파일에 이미 포함됨)

### Step 5: 테마 적용 (선택사항)

인기 있는 Jekyll 테마:
- **Minima** (Jekyll 기본 테마)
- **Minimal Mistakes** (가장 인기)
- **Chirpy** (현대적, 다크모드 지원)
- **TeXt** (깔끔한 한국어 지원)

테마 적용 방법:
```bash
# Gemfile에 추가
gem "minimal-mistakes-jekyll"

# _config.yml에 추가
theme: minimal-mistakes-jekyll
```

### Step 6: GitHub Pages 설정

1. **Repository Settings > Pages**
   - Source: `Deploy from a branch`
   - Branch: `master` (또는 `main`)
   - Folder: `/ (root)`

2. **자동 빌드 확인**
   - GitHub Actions 탭에서 빌드 로그 확인
   - 빌드 성공 시 자동으로 사이트 업데이트

### Step 7: 배포 및 테스트

1. **로컬 테스트** (선택사항)
   ```bash
   bundle install
   bundle exec jekyll serve
   # http://localhost:4000/blog 접속
   ```

2. **GitHub에 푸시**
   ```bash
   git add .
   git commit -m "Migrate to Jekyll"
   git push
   ```

3. **사이트 확인**
   - https://shiwoo-park.github.io/blog 접속
   - Google Analytics에서 실시간 방문자 확인
   - AdSense에서 광고 표시 확인

---

## 대안: Hugo 마이그레이션 (빌드 속도 중시 시)

### 기본 설정

1. **`config.yaml` 생성**
```yaml
baseURL: 'https://shiwoo-park.github.io/blog'
languageCode: 'ko'
title: '실바의 블로그'

params:
  googleAnalytics: 'G-XXXXXXXXXX'
  googleAdsense: 'ca-pub-XXXXXXXXXX'
```

2. **`layouts/_default/baseof.html` 생성**
```html
<!DOCTYPE html>
<html>
<head>
  <title>{{ .Title }}</title>
  
  <!-- Google Analytics -->
  {{ if .Site.Params.googleAnalytics }}
  <script async src="https://www.googletagmanager.com/gtag/js?id={{ .Site.Params.googleAnalytics }}"></script>
  <script>
    window.dataLayer = window.dataLayer || [];
    function gtag(){dataLayer.push(arguments);}
    gtag('js', new Date());
    gtag('config', '{{ .Site.Params.googleAnalytics }}');
  </script>
  {{ end }}
</head>
<body>
  {{ block "main" . }}{{ end }}
</body>
</html>
```

3. **GitHub Actions 워크플로우** (`.github/workflows/deploy.yml`)
```yaml
name: Deploy Hugo

on:
  push:
    branches: [ master ]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./public
```

---

## 비교 요약

| 항목 | Jekyll | Hugo | Astro |
|------|--------|------|-------|
| GitHub Pages 네이티브 | ✅ | ❌ (Actions 필요) | ❌ (Actions 필요) |
| 빌드 속도 | 보통 | 매우 빠름 | 빠름 |
| 설정 난이도 | 쉬움 | 보통 | 보통 |
| 커뮤니티 | 매우 큼 | 큼 | 성장 중 |
| 테마 수 | 매우 많음 | 많음 | 적음 |
| 마이그레이션 | 쉬움 | 보통 | 보통 |

---

## 다음 단계

1. **Jekyll 선택 시:**
   - `_config.yml` 생성
   - 기본 레이아웃 파일 생성
   - 마크다운 파일에 Front Matter 추가
   - Google Analytics/AdSense ID 설정

2. **테마 선택:**
   - Minimal Mistakes 추천 (가장 인기, 문서 풍부)

3. **SEO 최적화:**
   - `jekyll-sitemap` 플러그인
   - `jekyll-seo-tag` 플러그인

4. **성능 최적화:**
   - 이미지 최적화
   - CSS/JS 압축

---

## 참고 자료

- [Jekyll 공식 문서](https://jekyllrb.com/)
- [GitHub Pages 문서](https://docs.github.com/en/pages)
- [Google Analytics 설정](https://support.google.com/analytics/answer/9304153)
- [Google AdSense 설정](https://support.google.com/adsense/answer/7183212)
- [Jekyll 테마 모음](https://jekyllthemes.io/)

