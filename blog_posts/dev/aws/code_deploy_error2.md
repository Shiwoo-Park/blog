---
layout: post
title: "Code Deploy 배포루틴 오류 수정 - ApplicationStop 에러"
date: 2024-08-28
categories: [aws, codedeploy, troubleshooting]
---

# Code Deploy 배포루틴 오류 수정 - ApplicationStop 에러

> 날짜: 2024-08-28

[목록으로](https://shiwoo-park.github.io/blog)

---

## 사건 요약

- 기존 Code Deploy 로 배포하던 잘 돌아가던 프로젝트의 appspec.yml 파일 과 관련 스크립트들을 수정을 좀 했음
- 배포를 했더니 `ApplicationStop` 단계 에서 계속 오류남
- 아예 새로 코드 다운로드 받아서 실행하라고 프로젝트 폴더를 통째로 지워버렸더니 `No such file or directory` 에러
- 결국 인터넷을 뒤지다가 [Code Deploy AppSpec EC2 관련 AWS 공식문서 링크](https://docs.aws.amazon.com/ko_kr/codedeploy/latest/userguide/reference-appspec-file-structure-hooks.html#appspec-hooks-server) 를 발견하고 읽어봄
- Code Deploy 콘솔 해당 배포그룹의 가장 최근에 성공한 배포 ID 를 복사
- 배포 서버로 가서 아래 명령어를 날림
  ```bash
  cd /opt/codedeploy-agent/deployment-root/deployment-instructions
  # 만약 마지막 성공한 배포 ID 가 d-ABCD12345 라고 할 경우
  grep -l d-ABCD12345 *_last_successful_install
  ```
- 이때 응답되는 파일을 `cat` 하면 무슨 폴더 path 가 나오는데 이 `{마지막_배포성공_PATH}/deployment-archive` 로 이동
- 이곳의 `appspec.yml` 이 신규 배포할때 참고하는 파일이임을 알고 이것을 에러 안나도록 수정.
- 오류 해결됨

## 중요 ApplicationStop 관련 AWS 공식문서 내용

- `ApplicationStop` : 이 배포 수명 주기 이벤트는 애플리케이션 수정이 다운로드되기 전에도 발생합니다. 이 이벤트에 대해서는 애플리케이션을 안전하게 종료하거나 배포 준비 중에 현재 설치된 패키지를 제거하도록 스크립트를 지정할 수 있습니다. 이 배포 수명 주기 이벤트에 사용된 AppSpec 파일 및 스크립트는 이전에 성공적으로 배포된 애플리케이션 수정 버전에서 가져온 것입니다.

### 참고

- 최초 배포하기 전에는 인스턴스에 AppSpec 파일이 존재하지 않습니다. 이러한 이유로, 인스턴스에 처음으로 배포할 때는 ApplicationStop 후크가 실행되지 않습니다. 인스턴스에 두 번째로 배포할 때는 ApplicationStop 후크를 사용할 수 있습니다.
- 마지막으로 성공적으로 배포된 애플리케이션 수정 버전의 위치를 확인하기 위해 CodeDeploy 에이전트는 `deployment-group-id_last_successful_install` 파일에 나열된 위치를 조회합니다. 

이 파일의 위치는 다음과 같습니다.
- Amazon Linux, Ubuntu Server 및 RHEL Amazon EC2의 `/opt/codedeploy-agent/deployment-root/deployment-instructions` 폴더
- Windows Server Amazon EC2 인스턴스에 대한 `C:\ProgramData\Amazon\CodeDeploy\deployment-instructions` 폴더.

---

[목록으로](https://shiwoo-park.github.io/blog)
