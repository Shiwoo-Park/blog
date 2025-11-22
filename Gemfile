source "https://rubygems.org"

# 로컬 개발 환경: 최신 Jekyll 사용
gem "jekyll", "~> 4.3"

# Jekyll plugins (로컬과 운영 모두 사용)
gem "jekyll-feed", "~> 0.12"
gem "jekyll-sitemap"
gem "jekyll-seo-tag"

# GitHub Pages 호환성 (운영 환경에서만 자동 설치)
# GitHub Pages는 bundle install 시 모든 그룹을 설치하므로 production 그룹도 자동 설치됨
# 로컬: bundle install --without production (github-pages 제외, 최신 Jekyll 사용)
# 운영: bundle install (모든 그룹 설치, GitHub Pages에서 자동)
group :production do
  # github-pages gem은 자체 Jekyll 버전을 포함하므로
  # 로컬에서는 제외하여 최신 Jekyll 사용
  gem "github-pages", group: :jekyll_plugins
end

