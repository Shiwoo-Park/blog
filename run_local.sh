#!/bin/bash
set -e

PORT=4001
IMAGE="jekyll/jekyll:4"
NAME="blog-local"

cd "$(dirname "$0")"

if ! docker info > /dev/null 2>&1; then
  echo "[run_local] Docker가 실행되지 않았습니다. Docker Desktop을 먼저 실행하세요."
  exit 1
fi

docker rm -f "$NAME" > /dev/null 2>&1 || true

if [ ! -d vendor/bundle ]; then
  echo "[run_local] gem 설치 중 (최초 1회, 수 분 소요)..."
  docker run --rm -u root \
    -v "$PWD:/srv/jekyll" \
    -e BUNDLE_PATH=/srv/jekyll/vendor/bundle \
    "$IMAGE" bundle install
fi

echo "[run_local] http://localhost:$PORT/blog/ 에서 확인하세요 (종료: Ctrl+C)"

docker run --rm -it -u root \
  --name "$NAME" \
  -p "$PORT:$PORT" \
  -v "$PWD:/srv/jekyll" \
  -e BUNDLE_PATH=/srv/jekyll/vendor/bundle \
  "$IMAGE" \
  bundle exec jekyll serve --port "$PORT" --host 0.0.0.0 --force_polling
