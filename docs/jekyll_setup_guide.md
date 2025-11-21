# Jekyll 설정 완료 가이드

## 생성된 파일들

다음 파일들이 생성되었습니다:
- `_config.yml` - Jekyll 설정 파일
- `_layouts/default.html` - 기본 레이아웃 (Google Analytics/AdSense 포함)
- `_layouts/post.html` - 포스트 레이아웃
- `index.html` - 메인 페이지
- `Gemfile` - Ruby 의존성 관리

## 다음 단계

### 1. 마크다운 파일에 Front Matter 추가

각 마크다운 파일 상단에 다음 형식의 Front Matter를 추가해야 합니다:

```markdown
---
layout: post
title: "포스트 제목"
date: 2025-01-15
categories: [dev, python]
---

기존 마크다운 내용...
```

**예시:**
- `blog_posts/dev/python/logging.md` 파일을 열어서
- 첫 줄에 `---` 추가
- Front Matter 작성
- 다시 `---` 추가
- 기존 내용 유지

### 2. Google Analytics 설정

1. https://analytics.google.com 접속
2. 계정 생성 및 속성 생성
3. 측정 ID 받기 (예: `G-XXXXXXXXXX`)
4. `_config.yml` 파일에서 주석 해제하고 ID 입력:
   ```yaml
   google_analytics: G-XXXXXXXXXX
   ```

### 3. Google AdSense 설정

1. https://www.google.com/adsense 접속
2. 계정 생성 및 사이트 승인 대기 (1-2일 소요)
3. 발행자 ID 받기 (예: `ca-pub-XXXXXXXXXX`)
4. `_config.yml` 파일에서 주석 해제하고 ID 입력:
   ```yaml
   google_adsense: ca-pub-XXXXXXXXXX
   ```
5. 광고 단위 생성 후 광고 슬롯 ID 받기
6. `_layouts/post.html`에서 `data-ad-slot` 값 수정

### 4. GitHub에 푸시

```bash
git add .
git commit -m "Add Jekyll configuration"
git push
```

### 5. GitHub Pages 설정 확인

1. GitHub Repository > Settings > Pages
2. Source가 `Deploy from a branch`로 설정되어 있는지 확인
3. Branch가 `master` (또는 `main`)인지 확인
4. 몇 분 후 https://shiwoo-park.github.io/blog 접속하여 확인

## 자동화 스크립트 (선택사항)

모든 마크다운 파일에 Front Matter를 자동으로 추가하는 Python 스크립트:

```python
# add_frontmatter.py
import os
import re
from pathlib import Path
from datetime import datetime

def get_date_from_file(file_path):
    """파일 수정 시간에서 날짜 추출"""
    mtime = os.path.getmtime(file_path)
    return datetime.fromtimestamp(mtime).strftime('%Y-%m-%d')

def extract_title_from_filename(file_path):
    """파일명에서 제목 추출"""
    name = Path(file_path).stem
    # 언더스코어를 공백으로, 각 단어 첫 글자 대문자
    return name.replace('_', ' ').title()

def add_frontmatter_to_md(file_path):
    """마크다운 파일에 Front Matter 추가"""
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # 이미 front matter가 있으면 스킵
    if content.strip().startswith('---'):
        print(f"스킵 (이미 Front Matter 있음): {file_path}")
        return
    
    # 파일명에서 제목 추출
    title = extract_title_from_filename(file_path)
    
    # 날짜 추출
    date = get_date_from_file(file_path)
    
    # 카테고리 추출 (경로에서)
    categories = []
    path_parts = Path(file_path).parts
    if 'dev' in path_parts:
        categories.append('dev')
    # 추가 카테고리 추출 로직...
    
    frontmatter = f"""---
layout: post
title: "{title}"
date: {date}
categories: {categories}
---

"""
    
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(frontmatter + content)
    
    print(f"처리 완료: {file_path}")

# 모든 .md 파일에 적용
exclude_dirs = {'archive', 'node_modules', '.git', 'resources', 'code_snippets', 'docs', 'job_specs'}
exclude_files = {'README.md', 'readme.md', 'favorite.md', 'blog_migration_guide.md', 'jekyll_setup_guide.md', '_post_template.md'}

for root, dirs, files in os.walk('.'):
    # 제외할 디렉토리 필터링
    dirs[:] = [d for d in dirs if d not in exclude_dirs]
    
    for file in files:
        if file.endswith('.md') and file not in exclude_files:
            file_path = os.path.join(root, file)
            try:
                add_frontmatter_to_md(file_path)
            except Exception as e:
                print(f"오류 발생 ({file_path}): {e}")

print("\n모든 파일 처리 완료!")
```

**사용 방법:**
```bash
python add_frontmatter.py
```

## 문제 해결

### Jekyll이 빌드되지 않는 경우

1. GitHub Actions 탭에서 빌드 로그 확인
2. `_config.yml` 문법 오류 확인
3. Front Matter 형식 확인 (YAML 문법)

### Google Analytics가 작동하지 않는 경우

1. `_config.yml`에서 `google_analytics` 값 확인
2. 브라우저 개발자 도구 > Network 탭에서 gtag.js 로드 확인
3. Google Analytics 실시간 보고서에서 확인

### AdSense 광고가 표시되지 않는 경우

1. 사이트 승인 대기 중인지 확인 (1-2일 소요)
2. `_config.yml`에서 `google_adsense` 값 확인
3. 광고 슬롯 ID 확인
4. AdSense 대시보드에서 광고 단위 상태 확인

## 추가 개선 사항

### 테마 적용

인기 있는 테마:
- **Minimal Mistakes**: https://github.com/mmistakes/minimal-mistakes
- **Chirpy**: https://github.com/cotes2020/jekyll-theme-chirpy

### SEO 최적화

`_config.yml`에 이미 `jekyll-seo-tag` 플러그인이 포함되어 있습니다.
각 포스트에 `description` 추가:

```yaml
---
layout: post
title: "포스트 제목"
description: "포스트 설명 (SEO용)"
date: 2025-01-15
---
```

### 검색 기능 추가

- **Simple Jekyll Search**: 클라이언트 사이드 검색
- **Algolia**: 전문 검색 서비스 (무료 플랜 있음)

## 참고 자료

- [Jekyll 공식 문서](https://jekyllrb.com/docs/)
- [GitHub Pages 문서](https://docs.github.com/en/pages)
- [Jekyll 테마 모음](https://jekyllthemes.io/)

