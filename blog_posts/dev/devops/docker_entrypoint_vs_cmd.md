---
layout: post
title: "Docker 환경에서 ENTRYPOINT와 CMD의 차이점"
date: 2024-12-10
categories: [devops, docker]
---

# Docker 환경에서 `ENTRYPOINT`와 `CMD`의 차이점

> 날짜: 2024-12-10

[목록으로](https://shiwoo-park.github.io/blog)

---

**공통점**: 
- 둘 다 컨테이너 실행 시 실행할 명령어를 정의합니다.

**차이점**:

| **특징**                | **ENTRYPOINT**                                    | **CMD**                                          |
|--------------------------|--------------------------------------------------|-------------------------------------------------|
| **목적**                | 컨테이너의 **기본 실행 동작을 고정**              | 기본 명령어를 지정하지만, **대체 가능**          |
| **동작 방식**           | 항상 실행되며, 컨테이너 실행 시 전달된 인자를 추가로 취급 | 컨테이너 실행 시 대체되거나 무시될 수 있음      |
| **명령어 실행 형식**     | 명령어를 **절대 대체할 수 없음**                  | 명령어를 **사용자 지정 값으로 대체 가능**        |
| **사용 예시**           | 실행 파일이나 스크립트를 **고정 실행**할 때 사용   | 컨테이너에 기본 옵션 제공                       |
| **우선순위**            | `ENTRYPOINT`가 **CMD를 덮어씀**                   | `CMD`는 **ENTRYPOINT와 함께 인자로 사용**        |

**예제 1: `CMD`와 `ENTRYPOINT` 비교**
```dockerfile
# CMD
CMD ["echo", "Default message"]

# 실행
docker run <image>            # 출력: Default message
docker run <image> "Custom"   # 출력: Custom

# ENTRYPOINT
ENTRYPOINT ["echo"]
CMD ["Default message"]

# 실행
docker run <image>            # 출력: Default message
docker run <image> "Custom"   # 출력: Custom
```

**예제 2: ENTRYPOINT와 CMD 조합**
```dockerfile
ENTRYPOINT ["python3", "app.py"]
CMD ["--help"]

# 실행
docker run <image>            # python3 app.py --help
docker run <image> --version  # python3 app.py --version
```

---

[목록으로](https://shiwoo-park.github.io/blog)
