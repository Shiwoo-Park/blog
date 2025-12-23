# SEO 개선 가이드

검색 엔진 최적화를 통해 블로그 조회수를 높이기 위한 가이드입니다.

## 이미 적용된 조치

1. ✅ **jekyll-seo-tag 플러그인**: 기본 SEO 태그 자동 생성
2. ✅ **jekyll-sitemap 플러그인**: 사이트맵 자동 생성
3. ✅ **Google Analytics & Tag Manager**: 트래픽 분석
4. ✅ **robots.txt**: 검색 엔진 크롤링 설정
5. ✅ **구조화된 데이터 (JSON-LD)**: BlogPosting, WebSite 스키마 추가
6. ✅ **포스트 템플릿 개선**: description, keywords 필드 추가

## 추가로 적용 가능한 조치

### 1. 각 포스트에 메타데이터 추가

**현재 상태**: 포스트에 description이 없으면 site.description이 사용됨

**개선 방법**: 각 포스트의 frontmatter에 description과 keywords 추가

```yaml
---
layout: post
title: "금리에 대하여"
date: 2025-12-22
categories: [invest, basic]
description: "금리의 개념부터 다양한 금리 종류, 그리고 경제에 미치는 영향까지 쉽게 이해할 수 있는 가이드"
keywords: "금리, 기준금리, 채권금리, 예금금리, 대출금리, 인플레이션, 경제지표"
---
```

**권장사항**:
- description: 150-160자 (검색 결과에 표시되는 길이)
- keywords: 5-10개, 쉼표로 구분
- 포스트 내용의 핵심을 간결하게 요약

### 2. Open Graph 이미지 추가

**개선 방법**: 각 포스트에 og:image 추가

```yaml
---
image: "/resources/og-image.png"  # 또는 포스트별 이미지
---
```

**권장사항**:
- 이미지 크기: 1200x630px (Facebook, Twitter 권장)
- 각 카테고리별 대표 이미지 생성
- 포스트 제목이 포함된 이미지 사용

### 3. 내부 링크 구조 개선

**개선 방법**:
- 관련 포스트 간 상호 링크 추가
- 카테고리 페이지에서 관련 포스트 링크
- "관련 글" 섹션 추가

**예시**: 포스트 하단에 관련 글 섹션 추가

### 4. 포스트 URL 최적화

**현재**: `/:categories/:title/`

**개선 가능**:
- 제목에 검색 키워드 포함
- URL이 너무 길지 않도록 (50자 이하 권장)
- 한글 URL은 인코딩되므로 영어 키워드 포함 고려

### 5. Breadcrumb 추가

**개선 방법**: 포스트 상단에 breadcrumb 네비게이션 추가

```
홈 > 투자 > 기본 > 금리에 대하여
```

### 6. 포스트 업데이트 날짜 추가

**개선 방법**: 포스트에 last_modified_at 필드 추가

```yaml
---
last_modified_at: 2025-12-23
---
```

### 7. 이미지 최적화

**개선 방법**:
- 이미지에 alt 텍스트 추가
- 이미지 파일명을 의미있게 (예: `interest-rate-chart.png`)
- 이미지 크기 최적화 (WebP 형식 사용 고려)

### 8. 콘텐츠 품질 개선

**개선 방법**:
- 포스트 길이: 최소 1000자 이상 권장
- 제목에 검색 키워드 포함
- H1, H2, H3 태그 적절히 사용
- 목차 추가 (Table of Contents)

### 9. 모바일 최적화

**현재**: viewport 메타 태그 있음

**추가 확인사항**:
- 모바일에서 읽기 쉬운 폰트 크기
- 터치하기 쉬운 버튼 크기
- 빠른 로딩 속도

### 10. 페이지 속도 최적화

**개선 방법**:
- 이미지 lazy loading
- CSS/JS 최소화
- CDN 사용 고려

### 11. Google Search Console 등록

**조치**:
1. Google Search Console에 사이트 등록
2. sitemap.xml 제출
3. 검색 성능 모니터링
4. 인덱싱 상태 확인

### 12. 소셜 미디어 공유 최적화

**개선 방법**:
- Twitter Card 태그 추가
- Facebook Open Graph 태그 확인
- 카카오톡 공유 최적화 (한국 특화)

## 우선순위별 적용 가이드

### 즉시 적용 (High Priority)
1. ✅ 구조화된 데이터 추가 (완료)
2. ✅ 포스트 템플릿에 description, keywords 필드 추가 (완료)
3. 각 포스트에 description 추가
4. Google Search Console 등록

### 단기 적용 (Medium Priority)
5. Open Graph 이미지 생성 및 추가
6. 내부 링크 구조 개선
7. Breadcrumb 추가
8. 포스트 업데이트 날짜 추가

### 장기 적용 (Low Priority)
9. 이미지 최적화
10. 페이지 속도 최적화
11. 소셜 미디어 공유 최적화

## 체크리스트

각 포스트 작성 시 확인사항:

- [ ] 제목에 검색 키워드 포함
- [ ] description 필드 작성 (150-160자)
- [ ] keywords 필드 작성 (5-10개)
- [ ] 포스트 내용 1000자 이상
- [ ] H1, H2, H3 태그 적절히 사용
- [ ] 이미지에 alt 텍스트 추가
- [ ] 관련 포스트 링크 추가
- [ ] 카테고리 정확히 지정

## 참고 자료

- [Google Search Central](https://developers.google.com/search)
- [Schema.org](https://schema.org/)
- [Open Graph Protocol](https://ogp.me/)
- [Jekyll SEO Tag](https://github.com/jekyll/jekyll-seo-tag)

