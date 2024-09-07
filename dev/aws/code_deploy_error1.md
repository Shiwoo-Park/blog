# Code Deploy 배포루틴 오류 수정 - appspec.yml 을 못찾는 현상

> 날짜: 2024-07-24

[목록으로](https://shiwoo-park.github.io/blog)

---

## 사건 요약

- 직장동료가 배포가 안된다고 함
- Jenkins + AWS Code deploy 를 사용해서 배포를 하는 시스템이라 젠킨스 로그부터 봄.
- 젠킨스쪽 작업은 잘 완료 되었는데 Code Deploy 쪽에서 문제가 난것으로 확인되어
- AWS Code Deploy 에서 오류가 난 배포를 일단 찾아서 이벤트 로그를 확인
- 자세한 내용이 확인이 안되어서 배포 대상 서버의 Code Deploy agent log 를 확인
- appspec.yml 을 못찾는다고 하길래 원래 그 파일이 있어야할 배포정보를 저장하는 폴더위치를 따라가봄 -> 폴더 없음
  - 아마도 이때 폴더가 없었던 이유는 최근 서버 용량 부족으로 디스크를 정리할때 잘못하여 Code Deploy 배포그룹용 폴더까지 지워버려서 그렇게 된것으로 보임.
- 여기서 가능해보이는 조치는 아래의 2가지 였음
  - 없어진 폴더를 임의로 만들어주기
  - 기존 배포그룹을 제거 후 다시 생성해 주기
- 내가 선택한것은 그냥 배포그룹 삭제 후 새로생성 이었음
- 오류 해결됨

## 당시 Jenkins log

`ERROR: Step ‘Deploy an application to AWS CodeDeploy’ failed: null`

## 당시 AWS 콘솔 - Code Deploy log

`CodeDeploy agent was not able to receive the lifecycle event. Check the CodeDeploy agent logs on your host and make sure the agent is running and can connect to the CodeDeploy server`

## 당시 Code Deploy Agent log

```
"message\":\"The CodeDeploy agent did not find an AppSpec file within the unpacked revision directory at revision-relative path \\\"appspec.yml\\\". The revision was unpacked to directory \\\"/opt/codedeploy-agent/deployment-root/071ec243-42c7-4ecc-b489-f4829c35c3f3/d-SVEDXQTU5/deployment-archive\\\", and the AppSpec file was expected but not found at path \\\"/opt/codedeploy-agent/deployment-root/071ec243-42c7-4ecc-b489-f4829c35c3f3/d-SVEDXQTU5/deployment-archive/appspec.yml\\\". Consult the AWS CodeDeploy Appspec documentation for more information at http://docs.aws.amazon.com/codedeploy/latest/userguide/reference-appspec-file.html\"
```

---

[목록으로](https://shiwoo-park.github.io/blog)
