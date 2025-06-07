# 나만의 파이썬 개발을 위한 Pycharm 세팅

> 날짜: 2024-06-22

[목록으로](https://shiwoo-park.github.io/blog)

---

나는 파이썬 개발할때 무조건 pycharm 을 쓴다.

PC 를 바꾸게 되거나 파이참을 통째로 다시 설치하게되면 종종 다시 세팅을 해야하는상황이 생기는데 매번 기억해내기 귀찮아서 일단 리스트업 ㅎㅎ

## 설정

`File > Settings` 화면에서 적용하는 것들

- 모든 공백 문자열 표시: `Editor > General > Appearance > Show whitespaces` 하위 전부 체크
- black 자동 코드 포매터 적용: `Tools > Black > On save` 체크 (패키지 미설치 시 설치 필요)

## 단축키(keymap) 설정

플러그인으로 일단 `Eclipse Keymap` 을 설치한 다음 해당 키맵을 복제(Duplicate) 한뒤, 아래의 단축키 설정을 덮어씌운다.

- Git fetch : `Ctrl + Alt + \`
- Git pull : `Ctrl + Alt + [`
- Git push : `Ctrl + Alt + ]`
- Find - Replace in Files : `Ctrl + Shift + H`


## 편집기 세팅

코드 편집하는 윈도우 관련 설정

- 편집기 하단에 현재 커서위치에 따른 코드 계층 표시 (Breadcrumbs)
  - 편집기 좌측 라인넘버쪽에서 우클릭
  - `Appearance > Breadcrumbs > Bottom` 클릭
- Git blame 시 유저 Full name 으로 표시
  - 편집기 좌측 라인넘버쪽에서 우클릭
  - `Annotate with Git Blame` 클릭 (이렇게 하면 수정한 유저가 일단 보임)
  - 이 상태에서 한번더, 편집기 좌측 유저 이름에서 우클릭
  - `View > Names > Full Name` 클릭



---

[목록으로](https://shiwoo-park.github.io/blog)
