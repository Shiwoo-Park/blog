# AI 프롬프트 엔지니어링에 활용할 프로젝트 파일 자동생성 스크립트

> 날짜: 2025-05-14

[목록으로](https://shiwoo-park.github.io/blog)

---

## 특정폴더 path 지정하여 모든 하위 파일들을 하나의 md 파일로 생성

````shell
#!/bin/bash

# 특정 폴더 하위 특정 파일들을 읽어들여서 하나의 결과 md 파일로 출력해주는 스크립트
# - 실행 경로: $PROJECT_HOME
# - 읽어들여야 하는 tsx 파일들의 폴더 리스트 입력
# - 결과 파일: $PROJECT_HOME/docs/prompt_engineering/cms_components.md

# 입력 경로와 출력 파일 정의
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_HOME="$(dirname "$SCRIPT_DIR")"

# ✅ 입력 디렉토리 배열로 정의
INPUT_DIRS=(
  "$PROJECT_HOME/src/components/common"
  "$PROJECT_HOME/src/components/ui"
  "$PROJECT_HOME/src/components/v2"
)

OUTPUT_FILE="$PROJECT_HOME/docs/prompt_engineering/cms_components.md"

# 출력 디렉토리가 없다면 생성
mkdir -p "$(dirname "$OUTPUT_FILE")"

# 출력 파일 초기화
> "$OUTPUT_FILE"

# 파일 합치기 함수
merge_files() {
  local input_dir=$1

  for tsx_file in "$input_dir"/*.tsx; do
    # 파일 경로를 프로젝트 루트 기준으로 상대경로로 표시
    relative_path="${tsx_file#$PROJECT_HOME/}"

    echo "## $relative_path" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    echo '```tsx' >> "$OUTPUT_FILE"
    cat "$tsx_file" >> "$OUTPUT_FILE"
    echo '```' >> "$OUTPUT_FILE"
    echo -e "\n\n" >> "$OUTPUT_FILE"
  done
}

# ✅ 배열 순회하며 각 폴더 처리
for dir in "${INPUT_DIRS[@]}"; do
  merge_files "$dir"
done

echo "✅ AI 프로젝트 파일 등록용 [components.md] 파일이 생성 되었습니다:\n- 리소스 폴더 리스트:"
for dir in "${INPUT_DIRS[@]}"; do
  echo "  - $dir"
done
echo "- 결과 파일:\n  - $OUTPUT_FILE"


````

## 특정파일 직접 지정하여 하나의 md 파일로 생성

````shell
#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_HOME="$(dirname "$SCRIPT_DIR")"
OUTPUT_FILE="$PROJECT_HOME/docs/prompt_engineering/cms_base_codes.md"

# === [ChatGPT 에 집어넣고 싶은 기본코드 파일 path 를 입력] ===
FILES=(
    "src/hooks/useAuth.tsx"
    "src/services/aws/AwsService.ts"
    "src/enums/base.tsx"
)
# =====================

# 파일 생성 시작
echo "# Base Codes" > "$OUTPUT_FILE"

for FILE in "${FILES[@]}"
do
    if [ -f "$FILE" ]; then
        echo "" >> "$OUTPUT_FILE"
        echo "## PROJECT_HOME/$FILE" >> "$OUTPUT_FILE"
        echo '```tsx' >> "$OUTPUT_FILE"
        cat "$PROJECT_HOME/$FILE" >> "$OUTPUT_FILE"
        echo '```' >> "$OUTPUT_FILE"
    else
        echo "[경고] 파일이 존재하지 않아서 스킵합니다: $FILE"
    fi
done

echo "✅ AI 프로젝트 파일 등록용 [base_code.md] 파일이 생성되었습니다: $OUTPUT_FILE"
````

## 일괄 성성 스크립트

```shell
#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
sh $SCRIPT_DIR/make_doc_base_code_md.sh
sh $SCRIPT_DIR/make_doc_components_md.sh
sh $SCRIPT_DIR/make_doc_sample_code.sh
```

---

[목록으로](https://shiwoo-park.github.io/blog)
