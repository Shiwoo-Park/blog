# Docker: ARG,ENV, RUN, CMD 를 사용한 서비스 다중환경 지원

> 날짜: 2024-12-10

[목록으로](https://shiwoo-park.github.io/blog)

---

Dockerfile의 주요 명령어인 `ARG`, `ENV`, `CMD`, `RUN`의 상관관계는 Docker 이미지를 빌드하고 실행하는 단계에서 어떻게 상호작용하는지에 따라 달라집니다. 각 명령어의 역할과 상관관계를 아래에 자세히 설명합니다.

---

## ARG, ENV, RUN, CMD 명령어 소개

### 1. **`ARG` (Build-time Arguments)**

- **역할:** 이미지를 **빌드할 때** 사용할 값을 정의합니다.
- **특징:** 
  - `docker build` 명령에서 `--build-arg` 옵션으로 값을 전달할 수 있습니다.
  - 빌드가 완료되면 `ARG` 변수는 더 이상 사용할 수 없습니다.
- **예:**
  ```dockerfile
  ARG APP_ENV=production
  RUN echo "App environment is $APP_ENV"
  ```
  빌드 시 `docker build --build-arg APP_ENV=development .`로 값을 변경할 수 있음.

---

### 2. **`ENV` (Environment Variables)**

- **역할:** **컨테이너 런타임**과 **빌드 과정** 모두에서 사용할 환경 변수를 설정합니다.
- **특징:**
  - `ENV`로 설정된 변수는 `RUN`, `CMD` 등 다른 명령어에서도 사용할 수 있습니다.
  - 컨테이너 실행 시 환경 변수로 자동 노출됩니다.
- **예:**
  ```dockerfile
  ENV APP_ENV=production
  RUN echo "App environment is $APP_ENV"
  ```

---

### 3. **`RUN` (Build-time Commands)**

- **역할:** 이미지를 빌드할 때 실행될 명령어를 정의합니다.
- **특징:**
  - Dockerfile의 명령어 중 **이미지 레이어를 생성**하는 역할.
  - 보통 패키지 설치, 파일 복사, 설정 작업에 사용됩니다.
  - `ARG`와 `ENV`에서 설정된 변수를 참조할 수 있음.
- **예:**
  ```dockerfile
  ARG APP_ENV
  RUN echo "App environment is $APP_ENV"
  ```

---

### 4. **`CMD` (Container Runtime Defaults)**

- **역할:** **컨테이너 실행 시** 기본적으로 실행할 명령어를 정의합니다.
- **특징:**
  - `CMD`는 빌드된 이미지를 컨테이너로 실행할 때 적용됩니다.
  - 한 Dockerfile에 하나만 정의할 수 있습니다.
  - 컨테이너 실행 시 명령어를 명시적으로 지정하면 `CMD`는 무시됩니다.
- **예:**
  ```dockerfile
  CMD ["python", "app.py"]
  ```

---

## **상관관계 및 주요 차이점**

1. **빌드 시점 vs 실행 시점**
   - `ARG`와 `RUN`: **이미지 빌드 과정**에서만 사용됩니다.
   - `ENV`와 `CMD`: **컨테이너 실행 시점**에서 작동합니다.

2. **변수 상속**
   - `ARG`는 빌드 시점에서만 접근 가능하지만, `ARG` 값을 `ENV`로 전달하여 런타임에서도 사용할 수 있습니다.
   - 예:
     ```dockerfile
     ARG APP_ENV
     ENV APP_ENV=$APP_ENV
     RUN echo "App environment in build: $APP_ENV"
     CMD echo "App environment in runtime: $APP_ENV"
     ```

3. **이미지 레이어**
   - `RUN`은 레이어를 생성하고, 변경된 파일/설정을 이미지에 포함합니다.
   - `CMD`는 실행 시점의 기본 동작을 정의하므로 레이어와 무관합니다.

4. **유연성**
   - `ARG`는 빌드 시점의 동적 설정에 유용합니다.
   - `ENV`는 런타임의 동적 환경 설정에 사용됩니다.
   - `CMD`는 컨테이너 실행 시 기본 명령어를 설정합니다.

---

## **TIP: 조합 활용 예시**
```dockerfile
# 빌드 타임 변수 정의
ARG APP_ENV=development

# 런타임 변수 설정
ENV APP_ENV=$APP_ENV

# 패키지 설치 (빌드 시점 명령어)
RUN apt-get update && apt-get install -y python3

# 실행 시 기본 명령어
CMD ["python3", "-m", "http.server"]
```

- 빌드 시: `docker build --build-arg APP_ENV=production .`
- 실행 시: `docker run -e APP_ENV=staging <image>`


## `ARG`와 `ENV`를 활용한 다중 환경별 Docker 이미지 구성

**목표**: 빌드 시점과 실행 시점의 변수를 조합하여, 개발, 스테이징, 프로덕션 환경을 각각 구성.

**Dockerfile**
```dockerfile
# 빌드 타임 변수 정의
ARG APP_ENV=development
ARG APP_PORT=5000

# 런타임 환경 변수 설정
ENV APP_ENV=$APP_ENV
ENV APP_PORT=$APP_PORT

# 빌드 작업
RUN echo "Building for $APP_ENV environment"

# 실행 시 기본 동작
CMD ["sh", "-c", "echo Running on $APP_ENV environment with port $APP_PORT"]
```

**빌드 및 실행**
1. **개발 환경**
   ```bash
   docker build --build-arg APP_ENV=development --build-arg APP_PORT=5000 -t myapp:dev .
   docker run myapp:dev
   ```
   출력: `Running on development environment with port 5000`

2. **스테이징 환경**
   ```bash
   docker build --build-arg APP_ENV=staging --build-arg APP_PORT=8000 -t myapp:staging .
   docker run myapp:staging
   ```
   출력: `Running on staging environment with port 8000`

3. **프로덕션 환경**
   ```bash
   docker build --build-arg APP_ENV=production --build-arg APP_PORT=80 -t myapp:prod .
   docker run myapp:prod
   ```
   출력: `Running on production environment with port 80`

---

**환경별 실행 옵션 제어**
컨테이너 실행 시 환경변수를 직접 오버라이드:
```bash
docker run -e APP_ENV=testing -e APP_PORT=9000 myapp:dev
# 출력: Running on testing environment with port 9000
```

---

**Best Practices:**
1. 빌드 시: `ARG`로 빌드 시점의 환경별 설정을 전달.
2. 런타임: `ENV`로 컨테이너 내부에서 필요한 기본값을 설정하고, 필요 시 오버라이드 가능.

---

[목록으로](https://shiwoo-park.github.io/blog)
