---
layout: post
title: "AI 프롬프트 엔지니어링에 활용할 프로젝트 파일 자동생성 스크립트"
date: 2025-05-14
categories: [ai, automation, tools]
---
## 특정폴더 path 지정하여 모든 하위 파일들을 하나의 md 파일로 생성

````shell
#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_HOME="$(dirname "$SCRIPT_DIR")"
OUTPUT_FILE="$PROJECT_HOME/docs/prompt_engineering/cms_base_codes.md"

# === [ChatGPT 에 집어넣고 싶은 기본코드 파일 path 를 입력] ===
FILES=(
    "src/app/globals.ts"
    "src/hooks/useAuth.tsx"
    "src/services/api/ApiController.ts"
    "src/services/aws/AwsService.ts"
    "src/enums/base.tsx"
    "src/app/layout.tsx"
    "src/lib/paramUtil.ts"
    "src/lib/strUtil.ts"
    "src/lib/typeUtil.ts"
)

get_highlight_lang() {
  local ext="${1##*.}"
  case "$ext" in
    js)   echo "javascript" ;;
    ts)   echo "typescript" ;;
    jsx)  echo "jsx" ;;
    tsx)  echo "tsx" ;;
    py)   echo "python" ;;
    sh)   echo "bash" ;;
    json) echo "json" ;;
    css)  echo "css" ;;
    scss) echo "scss" ;;
    html) echo "html" ;;
    yml|yaml) echo "yaml" ;;
    md)   echo "markdown" ;;
    *)    echo "" ;;
  esac
}

# =====================

# 파일 생성 시작
echo "# Base Codes" > "$OUTPUT_FILE"

for FILE in "${FILES[@]}"
do
    FULL_PATH="$PROJECT_HOME/$FILE"
    if [ -f "$FULL_PATH" ]; then
        echo "" >> "$OUTPUT_FILE"
        echo "## PROJECT_HOME/$FILE" >> "$OUTPUT_FILE"
        LANG=$(get_highlight_lang "$FILE")
        echo "\`\`\`${LANG}" >> "$OUTPUT_FILE"
        cat "$FULL_PATH" >> "$OUTPUT_FILE"
        echo '```' >> "$OUTPUT_FILE"
    else
        echo "[경고] 파일이 존재하지 않아서 스킵합니다: $FILE"
    fi
done

echo "✅ AI 프로젝트 파일 등록용 [base_code.md] 파일이 생성되었습니다: $OUTPUT_FILE"
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
