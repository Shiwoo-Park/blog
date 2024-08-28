# Code Deploy 배포루틴 오류 수정 - ApplicationStop 에러

> 날짜: 2024-08-28

[목록으로](https://shiwoo-park.github.io/blog/kor)

---

## 사건 요약

- 기존 Code Deploy 로 배포하던 잘 돌아가던 프로젝트의 appspec.yml 파일 과 관련 스크립트들을 수정을 좀 했음
- 배포를 했더니 ApplicationStop에서 계속 오류남
- 배포를 눌렀더니 에러가 남. 
- 배포 서버로 가서 `deployment-group-id_last_successful_install` 파일에 명시된 배포 버전의 폴더로 가서 appspec.yml 을 수정한뒤 배포
- 오류 해결됨

## ApplicationStop 관련 AWS 공식문서

- [Code Deploy AppSpec EC2 관련 AWS 공식문서 링크](https://docs.aws.amazon.com/ko_kr/codedeploy/latest/userguide/reference-appspec-file-structure-hooks.html#appspec-hooks-server)

- `ApplicationStop` : 이 배포 수명 주기 이벤트는 애플리케이션 수정이 다운로드되기 전에도 발생합니다. 이 이벤트에 대해서는 애플리케이션을 안전하게 종료하거나 배포 준비 중에 현재 설치된 패키지를 제거하도록 스크립트를 지정할 수 있습니다. 이 배포 수명 주기 이벤트에 사용된 AppSpec 파일 및 스크립트는 이전에 성공적으로 배포된 애플리케이션 수정 버전에서 가져온 것입니다.

### 참고

- 배포하기 전에는 인스턴스에 AppSpec 파일이 존재하지 않습니다. 이러한 이유로, 인스턴스에 처음으로 배포할 때는 ApplicationStop 후크가 실행되지 않습니다. 인스턴스에 두 번째로 배포할 때는 ApplicationStop 후크를 사용할 수 있습니다.
- 마지막으로 성공적으로 배포된 애플리케이션 수정 버전의 위치를 확인하기 위해 CodeDeploy 에이전트는 `deployment-group-id_last_successful_install` 파일에 나열된 위치를 조회합니다. 

이 파일의 위치는 다음과 같습니다.
- Amazon Linux, Ubuntu Server 및 RHEL Amazon EC2의 `/opt/codedeploy-agent/deployment-root/deployment-instructions` 폴더
- Windows Server Amazon EC2 인스턴스에 대한 `C:\ProgramData\Amazon\CodeDeploy\deployment-instructions` 폴더.

---

[목록으로](https://shiwoo-park.github.io/blog/kor)
