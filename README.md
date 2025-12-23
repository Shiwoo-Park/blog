# 실바의 블로그

## 개요

- jekyll 활용
- Google Analytics 적용
- Google Adsense 적용
- md 파일 기반 블로그 포스팅 관리

## 블로그 바로가기

- [홈](https://shiwoo-park.github.io/blog/)
- [즐겨찾기](https://shiwoo-park.github.io/blog/posts/favorite/)
- [개발](https://shiwoo-park.github.io/blog/posts/dev/home/)
- [투자](https://shiwoo-park.github.io/blog/posts/invest/home/)
- [여행](https://shiwoo-park.github.io/blog/posts/travel/home/)
- [코드](https://shiwoo-park.github.io/blog/snippets/home/)
- [RSS Feed](https://shiwoo-park.github.io/blog/feed.xml)
- [사이트맵](https://shiwoo-park.github.io/blog/sitemap.xml)

## 프로젝트 구조

```
blog/
├── posts/          # 블로그 포스트
│   ├── dev/            # 개발 블로그 (AI, AWS, Python, DevOps 등)
│   ├── invest/         # 투자 관련 블로그
│   ├── travel/         # 여행 관련 블로그
│   └── etc/            # 기타 포스팅
├── snippets/      # 코드 스니펫 모음
│   ├── bash/          # Bash 스크립트
│   ├── django/        # Django 코드
│   ├── fastapi/       # FastAPI 코드
│   ├── js/            # JavaScript 코드
│   └── py/            # Python 코드
├── _config.yml         # Jekyll 설정 파일
├── _layouts/           # Jekyll 레이아웃 템플릿
├── index.html          # 메인 페이지
├── resources/          # 이미지 및 리소스 파일
├── scripts/            # 유틸리티 스크립트
├── docs/               # 문서 및 가이드
└── archive/            # 아카이브 파일
```


## 명령어

```bash
# 최초 세팅 (의존성 설치)
bundle install --without production

# 로컬 개발 서버 시작
.\scripts\start_jekyll.bat
# 또는
.\scripts\start_jekyll.ps1

# 사이트 빌드
bundle exec jekyll build --baseurl=''

# 의존성 업데이트
bundle update
```