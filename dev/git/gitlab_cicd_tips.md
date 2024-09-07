# Gitlab - CI/CD pipeline 최적화, 코드품질관리 기능

> 날짜: 2024-08-15

[목록으로](https://shiwoo-park.github.io/blog)

---

### 1. **GitLab의 CI/CD 설정에서 파이프라인 최적화 팁**

GitLab CI/CD 파이프라인을 최적화하는 방법은 여러 가지가 있지만, 주요 팁을 몇 가지 소개합니다.

- **캐싱(Cache) 활용**: 동일한 의존성을 사용하는 작업이 반복될 경우, 이를 캐시로 설정해 빌드 시간을 단축할 수 있습니다. 예를 들어, Node.js 프로젝트에서는 `node_modules` 디렉토리를 캐시하여 다음 빌드 시 다운로드 시간을 줄일 수 있습니다.

  ```yaml
  cache:
    paths:
      - node_modules/
  ```

- **병렬 작업(Parallel Jobs) 설정**: 독립적인 작업은 병렬로 실행해 전체 파이프라인 시간을 줄입니다. 예를 들어, 테스트와 빌드를 동시에 수행할 수 있습니다.

  ```yaml
  test:
    stage: test
    script:
      - npm test

  build:
    stage: build
    script:
      - npm run build
  ```

- **`only`와 `except` 키워드 사용**: 특정 브랜치나 태그에서만 작업을 실행하도록 설정해 불필요한 작업 실행을 방지합니다.

  ```yaml
  deploy:
    stage: deploy
    script:
      - ./deploy.sh
    only:
      - main
  ```

- **Artifacts 최소화**: 필요한 아티팩트만 저장하도록 설정해 스토리지 비용을 줄이고, 파이프라인 성능을 향상시킵니다. 큰 파일은 가능한 한 줄이고, 필요한 파일만 업로드하세요.

  ```yaml
  artifacts:
    paths:
      - dist/
    expire_in: 1 week
  ```

- **Dynamic Pipelines**: `rules`를 활용해 조건에 따라 특정 파이프라인 단계가 실행되도록 설정할 수 있습니다. 예를 들어, 특정 파일이 변경되었을 때만 특정 작업을 실행할 수 있습니다.

  ```yaml
  job:
    script: echo "Run this job"
    rules:
      - changes:
          - "src/**/*"
  ```

### 2. **GitLab의 코드 품질 관리 기능 활용**

GitLab은 코드 품질을 유지하고 향상시키기 위한 다양한 기능을 제공합니다. 주요 기능을 효과적으로 활용하는 방법은 다음과 같습니다.

- **Code Quality Reports**: GitLab은 코드 품질 보고서를 제공하며, CI 파이프라인에 이를 포함시켜 코드 변경 시 품질 저하를 미리 감지할 수 있습니다. 파이프라인 설정에서 `code_quality` 스테이지를 추가해 코드 분석을 수행하세요.

  ```yaml
  code_quality:
    stage: test
    image: docker.io/gongzhang/codequality:latest
    script:
      - codeclimate analyze
    artifacts:
      paths: [gl-code-quality-report.json]
  ```

- **Static Application Security Testing (SAST)**: GitLab의 보안 기능을 활용해 코드에서 보안 취약점을 자동으로 탐지할 수 있습니다. SAST를 파이프라인에 포함시키면 코드에서 보안 취약점이 발생하는 것을 미리 방지할 수 있습니다.

  ```yaml
  sast:
    stage: test
    artifacts:
      reports:
        sast: gl-sast-report.json
  ```

- **Code Owners 설정**: 코드의 특정 디렉토리나 파일에 대해 자동으로 리뷰어를 지정할 수 있습니다. 이를 통해 코드 리뷰의 책임성을 높이고, 코드 품질을 유지할 수 있습니다. `.gitlab/CODEOWNERS` 파일에 소유자를 지정하세요.

  ```
  # All files in the `src/` directory require review from @frontend_team
  src/ @frontend_team
  ```

- **Merge Request Approval Rules**: 중요한 코드에 대해 추가적인 승인 규칙을 설정할 수 있습니다. 특정 파일이나 디렉토리에 대한 변경은 반드시 특정 팀의 승인을 받도록 설정하여 코드 품질을 보장할 수 있습니다.

  ```yaml
  approval_rules:
    approvals:
      - name: "Security Review"
        approvals_required: 2
        users:
          - @security_team
  ```

---

[목록으로](https://shiwoo-park.github.io/blog)
