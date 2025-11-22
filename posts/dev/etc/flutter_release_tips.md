---
layout: post
title: "Flutter 앱 출시 Tips"
date: 2023-04-21
categories: [mobile, flutter, deployment]
---
## Apple App Store


- [Apple Developer](https://developer.apple.com/kr/) 쪽에서 Identifier 및 Certificate 등 발급을 받은뒤
  - 개발자 등록을 위해 돈이 든다 (1년에 약 13만원....ㄷㄷ)
  - 앱 하나당 하나의 Bundle Identifier 가 사용되는데 앱에서 사용할 기능들을 미리 지정함
- Apple [App Store Connect](https://appstoreconnect.apple.com/) 를 통해서 앱을등록하고 출시 및 모니터링을 진행하게 됨.
- 앱 릴리즈 후, 사용통계 정보등을 얻고 싶다면 [Firebase](https://firebase.google.com/) 를 활용
- 앱 아이콘이나 launch image 등을 공짜로 만들고 싶다면 AI 이미지 생성기 등을 활용
  - [App Icon 생성기](https://www.appicon.co/)
  - [Bing Image 생성기](https://www.bing.com/images/create)
  - [각종 프로모션 이미지 생성기](https://previewed.app/)
- 앱 스크린샷 찍는것은 PC 에서 iOS 시뮬레이터로 앱 띄운다음 `Cmd + s` 누르면 됨.
- 스크린샷 리사이징은 무료 온라인 도구 찾아보면 많이 있음
  - [온라인 이미지 프로세싱 도구](https://www.iloveimg.com/ko)
- 개인정보 처리방침, 지원 URL 등의 입력방법
  - 내용 작성의 기본 틀은 `Chat GPT` 같은걸로 만들어달라고 하거나 국가별 official 포맷 찾은뒤 커스터마이징
  - 페이지 제공은 `Git Page, Notion Web Page` 등을 활용. (블로그도 된다고 함)
- 기본적으로는 Flutter 와 Apple 에서 제공되는 공식문서들을 잘 읽어보고 따라하면 됨.
  - Minimum OS Version 세팅을 xcode 쪽 설정과 flutter 쪽 설정 동기화 해주는거 중요.
- Transport 라는 앱으로 빌드한 앱 코드를 업로드 했었는데 Apple Cloud 를 통해서 코드를 올리는 방법도 있는듯 함. -> 이건 잘 모름ㅋ

## Android Google Play Store

- TBD...
