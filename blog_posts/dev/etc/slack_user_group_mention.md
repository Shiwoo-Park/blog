---
layout: post
title: "Slack 시스템 메시지 보낼때 @XXX팀 멘션 걸기"
date: 2024-04-19
categories: [tools, slack, automation]
---

# Slack 시스템 메시지 보낼때 @XXX팀 멘션 걸기

> 날짜: 2024-04-19

슬랙 알림을 API 를 통해서 보내야 하는경우가 종종 있다.
배포 상태 관련, 오류 알림 관련, 작업 상태 관련 등... 다양한 시스템에서 플러그인 또는 코딩을 통해 알림메시지를 보내야 한다.

## 젠킨스 슬랙 메시지에서 팀 멘션하기

문법이 조금씩 다를 수는 있지만 일단 나 같은경우 jenkins 에서 이 알림을 보내야 하는 경우가 있었다.
아래와 같이 메시지를 작성했다.

```
<!subteam^{TEAM_ID}>
:white_check_mark: `${JOB_NAME}` 배포가 완료되었습니다.
```

## 슬랙 그룹 ID 알아내는 법

자, 그럼 위와 같은 경우 TEAM_ID 를 어떻게 알아내야하느냐가 관건이다.
Slack 앱에서는 이 ID 를 바로 알아내기 어려운 부분이 있다. 

- 일단 브라우저로 슬랙을 접속한다.
- 그룹멘션이 있는 채널로 이동한뒤, 개발자 도구를 열고 좌상단에 화살표 버튼을 클릭한다
- 브라우저 슬랙에서 그룹멘션 텍스트 를 클릭하면 개발자도구-Elements 에서 아래와 같은 해당 요소 속성을 확인할 수 있다.
- 이 요소 중 `data-user-group-id` 의 value 에 해당하는 것이 그룹 ID 이다.

![slack_user_group_id](../../resources/slack_user_group_id.png)

위 그림과 같은 경우 그룹 ID 는 `S04T047L90D` 이다.

## 설정값 예제

```
[배포 시작]
`${JOB_NAME}` 배포를 시작합니다.
- 브랜치: `${GIT_BRANCH}`
- 로그확인: `${BUILD_URL}console`

[배포 완료]
@channel
또는
<!subteam^GROUP1_ID> <!subteam^GROUP2_ID>
:white_check_mark: `${JOB_NAME}` 배포가 완료되었습니다.
```

---

[목록으로](https://shiwoo-park.github.io/blog)


