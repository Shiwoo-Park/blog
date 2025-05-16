# iconv 를 이용한 텍스트 파일 인코딩 변환

> 날짜: 2025-05-16

[목록으로](https://shiwoo-park.github.io/blog)

---

`iconv`는 **텍스트 파일의 문자 인코딩을 변환**하는 데 사용하는 **명령줄 도구**입니다. Linux와 macOS에 기본 설치되어 있으며, 한글 파일 인코딩 문제를 해결할 때 매우 유용합니다.

---

## 🛠️ iconv란?

* **의미**: *International Conversion*의 줄임말
* **기능**: 파일이나 스트림의 \*\*문자 인코딩(encoding)\*\*을 **한 형식에서 다른 형식으로 변환**
* **지원 인코딩**: UTF-8, EUC-KR, CP949, ISO-8859-1, Shift\_JIS 등 매우 다양

---

## 📌 기본 사용법

```bash
iconv -f <원본인코딩> -t <변환할인코딩> <입력파일> > <출력파일>
```

### 예시: CP949 → UTF-8

```bash
iconv -f cp949 -t utf-8 korean.txt > korean_utf8.txt
```

* `-f`: from (원본 인코딩)
* `-t`: to (변환할 인코딩)

---

## 💡 자주 쓰는 인코딩 이름

| 용도     | 인코딩 명칭              |
| ------ | ------------------- |
| 윈도우 한글 | `cp949` 또는 `euc-kr` |
| 웹 표준   | `utf-8`             |
| 일본어    | `shift_jis`         |

---

## 📎 변환 없이 확인만 하고 싶을 때

```bash
file -I korean.txt
```

출력 예:

```
korean.txt: text/plain; charset=iso-8859-1
```

---

## ✅ 요약

* `iconv`는 텍스트 파일의 **문자 인코딩을 바꾸는 도구**
* 한글 깨짐 문제 해결에 탁월
* 간단한 명령으로 CP949, EUC-KR → UTF-8 변환 가능

---

## 샘플 사용법 예시

```bash
# 1. CP949 (EUC-KR) → UTF-8로 변환 (한글 깨짐 방지)
iconv -f cp949 -t utf-8 input.txt > output.txt

# 2. UTF-8 → CP949로 변환 (윈도우 메모장에서 읽히게)
iconv -f utf-8 -t cp949 input.txt > output_windows.txt

# 3. 파일 인코딩을 유지하면서 내용 출력만 보기 (터미널 확인용)
iconv -f euc-kr -t utf-8 input.txt

# 4. 변환하면서 기존 파일 덮어쓰기 (주의 필요!)
iconv -f cp949 -t utf-8 input.txt -o input.txt

# 또는 safer 방법:
iconv -f cp949 -t utf-8 input.txt > temp.txt && mv temp.txt input.txt

# 5. 디렉토리 내 모든 .txt 파일을 UTF-8로 일괄 변환
for file in *.txt; do
  iconv -f cp949 -t utf-8 "$file" > "utf8_$file"
done

# 6. 인코딩 확인 (정확하진 않지만 참고용)
file -I input.txt
# 예: input.txt: text/plain; charset=iso-8859-1

# 7. iconv 지원 인코딩 리스트 보기
iconv -l
```

---

[목록으로](https://shiwoo-park.github.io/blog)
