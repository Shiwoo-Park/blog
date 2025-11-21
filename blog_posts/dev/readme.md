---
layout: post
title: 실바의 개발 블로그에 오신것을 환영합니다
---

[블로그](https://shiwoo-park.github.io/blog/) | [Git-Repo](https://github.com/Shiwoo-Park/blog) | [즐겨찾기](favorite.md) | [Code Snippets](https://github.com/Shiwoo-Park/blog/tree/master/code_snippets)

<!-- ### 준비중 -->

<!-- - [ECS-EC2 에서 도커 stop 시, 그 안에 celery warm shutdown 처리](devops/ecs_celery_warm_exit.md) -->
<!-- - [FastAPI 에서 APScheduler 로 Batch 작업 처리하기 (+ Redis Lock 기반 동시성 제어)]() -->

<!-- ### 2025.09 -->

<!-- - [대용량 트래픽 환경에서의 백엔드 대응 전략]() -->

### 2025.11

- [Git Worktree: 여러 브랜치를 동시에 작업하는 방법](ai/git_worktree.md)
- [개발자에게 유용한 AI 프롬프트](ai/useful_prompts.md)
- [Python + Django + DRF 레거시 거대 프로젝트에 Cursor 를 최대한 잘 활용하는 방법](ai/cursor_tips_drf.md)

### 2025.08

- [Postgre SQL - 초당 1000번 업데이트 발생 + 유니크 필드에 대한 정렬 전략](storage/postgres_example2.md)
- [Postgre SQL - 테이블 설계 Tip: 업데이트가 잦은 필드 + 그 필드로 정렬 + 유니크 보장까지 해야 하는 경우](storage/postgres_example1.md)
- [Postgres SQL - 실무에서 쓰기 좋은 실행계획 분석 및 활용법 + CBO](storage/postgres_explain.md)

### 2025.07

- [Postgres MVCC, Fillfactor, HOT, SPC 개념잡기](storage/postgres_mvcc.md)
- [PostgreSQL: Lock 에 대하여](storage/postgres_lock.md)
- [Redis Timeout 으로 인한 서비스 전체 장애 대응 로그](history/redis_mget.md)
- [Redis 연결 상태 통계 분석 명령어](devops/redis_check.md)

### 2025.06

- [PostgreSQL 사용자가 꼭 알아야 할 핵심 개념](storage/postgres_tips.md)
- [PostgreSQL 구조](storage/postgres_architecture.md)
- [Django ORM VS SQLAlchemy 무엇이 다를까?](python/sqlalchemy/sqlalchemy_vs_django_orm.md)
- [자체제작 - DRF 기반 CSV 다운로드 모듈 (Django + DRF + Celery)](python/mywork/drf_csv_downloader.md)
- [자체제작 - 동시성 제어를 위한 컨텍스트 매니저 (Django + Redis)](python/mywork/concurrency_safe_context_manager.md)
- [간단하면서도 안전한 인증 토큰 만들기 (Python, HMAC, ID/SECRET 기반)](python/simple_auth_hmac.md)
- [SQLAlchemy 2.x + sqlmodel 기반 모델 및 CRUD 쿼리 작성 가이드](python/sqlalchemy/sqlalchemy_basic.md)
- [SQLAlchemy 2.x 의 쿼리결과(Result) 객체 파헤치기](python/sqlalchemy/sqlalchemy_result.md)
- [SQLAlchemy 2.x 의 쿼리(Select) 객체 알아보기](python/sqlalchemy/sqlalchemy_query.md)
- [Pydantic 2 모델 필드: 유효성 검사 + 전처리 + 후처리](python/pydantic/pydantic_model_advanced.md)
- [Pydantic 2 기반 풀스펙 모델 코드 (FastAPI + SQLModel + SQLAlchemy 2)](python/pydantic/pydantic_model_full_spec.md)

### 2025.05

- [Pydantic 2 의 BaseModel 파헤치기](python/pydantic/pydantic_model_basic.md)

### 2025.03

- [Self-hosted Gitlab 관리](devops/self_hosted_gitlab.md)

### 2025.02

- [분산 트레이싱 도구 Jaeger (feat. OpenTelemetry)](devops/jaeger.md)
- [MSA 환경에서의 버그 트래킹](devops/msa_bug_tracking.md)
- [서비스 모니터링 도구 -Prometheus](devops/prometheus.md)
- [서비스 모니터링 지표에 대하여](devops/monitoring_values.md)
- [pull, push 아키텍쳐](backend/push_pull.md)
- [데이터 쏠림현상 Data skew](storage/data_skew.md)
- [Postgres - GIN index](devops/postgres_gin_index.md)
- [분산 로깅에 대하여](devops/distributed_logging.md)
- [Sentry - 에러 모니터링](devops/sentry.md)
- [파이썬으로 로깅 Best Practice](python/logging_best_practice.md)
- [파이썬으로 로깅 잘하기](python/logging.md)

### 2024.12

- [AWS - EC2 인스턴스 유형별 용도](aws/ec2_instance_type.md)
- [DevOps 업무 - 나만의 꿀팁](devops/my_tips.md)
- [Terraform 기본지식](devops/terraform.md)
- [Docker 환경에서 `ENTRYPOINT`와 `CMD`의 차이점](devops/docker_entrypoint_vs_cmd.md)
- [Docker: ARG,ENV, RUN, CMD 를 사용한 서비스 다중환경 지원](devops/docker_multi_env_setup.md)
- [파이썬 - Generator 와 yield](python/generator_yield.md)
- [파이썬 - Dataclass](python/dataclass.md)
- [파이썬 - Dunder(double underscore) method](python/dunder_method.md)
- [파이썬 - 함수 오버로딩과 singledispatch 데코레이터](python/overload_singledispatch.md)

### 2024.11

- [파이썬 - Property](python/property.md)
- [파이썬 - 클래스 속성 vs 인스턴스 속성](python/class_instance_attr.md)
- [파이썬 - Descriptor 알아보기](python/descriptor.md)
- [Celery 워커 구동 명령어 옵션 살펴보기](python/celery_commands.md)
- [Celery 운용 Tips](python/celery_tips.md)

### 2024.10

- [당신이 몰랐던 파이썬 이야기들](python/mywork/hidden_story.md)
- [파이썬 연산자: `2 is 2` 와 `2 == 2`의 차이점](python/is_vs_equal.md)
- [PostgreSQL - 문자열 필드 COLLATE 와 정렬](storage/postgres_collate.md)
- [Jenkins를 사용하여 AWS ECS Fargate 에 배포하기 (ECR, CodeDeploy, HTTPS, 로드 밸런서)](aws/jenkins_ecs_codedeploy.md)

### 2024.09

- [Python `3.7 -> 3.12 버전업` 을 통해 얻을 수 있는것들](python/mywork/version_up_7_to_12.md)
- [AWS - EC2 인스턴스 템플릿 교체](aws/update_ec2_template.md)
- [Linux 서버 상태진단](devops/linux_status.md)

### 2024.08

- [AWS - Code Deploy 에서 ApplicationStop 오류 해결](aws/code_deploy_error2.md)
- [Gitlab - CI/CD pipeline 최적화 및 코드품질관리기능](git/gitlab_cicd_tips.md)
- [Gitlab - 각종 꿀팁 및 모범사례](git/gitlab.tips.md)
- [AWS - ALB 여러 도메인 하나로 서비스 하기](aws/multiple_domain.md)
- [AWS - EKS vs ECS](aws/eks_vs_ecs.md)
- [AWS - RDS 관리 Tips](aws/rds_manage.md)

### 2024.07

- [AWS - 배포환경 구분하기](aws/manage_env_var.md)
- [AWS - Code Deploy 오류 해결: appspec.yml 을 찾을 수 없음](aws/code_deploy_error1.md)
- [AWS - ECR 에 이미지 푸시](aws/aws_ecr_push.md)
- [서버 디스크 정리](devops/server_disk_clean.md)
- [js - ?? (nullish) 연산자](frontend/js_nullish_operator.md)

### 2024.06

- [React hook - `useForm()` 간단 사용법](frontend/react_use_form.md)
- [node 프로세스 관리 - pm2](frontend/pm2_guide.md)
- [쉘 스크립트 - 꿀팁 모음](devops/shell_script_2.md)
- [Windows 에서 nano 설치하고 사용하기](etc/win_nano.md)

### 2024.05

- [Linux 에서 유저 전환하는 방법](devops/linux_user_change.md)
- [Redis tip 모음](storage/redis_tips.md)
- [루트 권한을 획득하는 명령어들의 차이점(sudo -s, -i, su)](devops/sudo_cmds.md)

### 2024.04

- [factoryboy - @post_generation 사용법](python/factoryboy_post_gen.md)
- [나만의 개발환경 설정방법](etc/my_keymap.md)
- [git squash](git/git_squash.md)
- [Slack 시스템 메시지에서 그룹 멘션하기](etc/slack_user_group_mention.md)
- [git rebase](git/git_rebase.md)
- [테크스펙- 기능적/비기능적 요구사항의 차이](etc/functional_requirement.md)

### 2024.03

- [JWT 토큰의 발급, 사용, 관리 방식 총정리](backend/jwt_token.md)
- [PostgreSQL 유용한 쿼리 모음](storage/postgres_query.md)
- [프로젝트의 미사용 pip 패키지 찾아내기](python/pip_cleanup.md)
- [특정 pip 패키지의 다른 패키지 의존성 확인하기](python/pip_dependency.md)
- [Git hook 으로 커밋메시지 prefix 자동화하기](git/git_hook_1.md)
- [SSR, SPA, SSG, ISR 개념 잡기](frontend/ssr_spa_ssg_isr.md)
- [파이썬 자동 코드포매터 black 적용하기](python/apply_black.md)

### 2023.04

- [Flutter App 출시 Tips](etc/flutter_release_tips.md)
- [Django ORM Tips](python/django/django_orm_tips.md)

### 2022.03

- [MySQL Tips](storage/mysql_tips.md)
- [DRF 활용, 최적화 Tip 모음](python/django/drf_tips.md)

### 2021.10

- [pytest Django 예제 모음](python/unittest/pytest_3_django_examples.md)
- [pytest VS unittest](python/unittest/pytest_2_compare.md)
- [pytest 소개 및 기능](python/unittest/pytest_1_intro.md)

### 2021.9

- [Linux 의 init 시스템: systemd 와 systemctl 간단 사용법](devops/systemd_ctl_basic.md)

### 2021.8

- [SSH 활용 tips](devops/ssh_tips.md)
- [pipenv 기능 및 명령어](python/pipenv_cmds.md)

### 2021.2

- [Django + Pytest tips](python/django/django_pytest_tips.md)

### 2021.1

- [쉘 스크립트 - 기본 문법](devops/shell_script_1.md)
- [쉘 스크립트 - 명령어 모음](devops/useful_bash_cmds.md)

### 2020.12

- [내가 자주쓰는 기술스택: 유용한 웹문서 모음](python/mywork/study_links.md)
- [Docker - 명령어 모음](devops/docker_cmds.md)

### 2020.11

- [React.js - 입문을 위한 배경지식](frontend/react_backgrounds.md)

### 2020.08

- [Django - Group By 쿼리 작성하기](python/django/django_groupby.md)
- [Git - 명령어 모음](git/git_cmds.md)

### 2020.07

- [Git - 서버에 deploy key 활용가능하도록 등록하기](git/git_deploy_key.md)
- [Git - 헤깔리는 gitignore 의 directory 설정](git/gitignore_dir.md)
- [Django or DRF 의 View 에 Custom Decorator 를 달아보자](python/django/django_view_decorator.md)

### 기타 참고링크

- [Markdown Cheatsheet](https://github.com/adam-p/markdown-here/wiki/Markdown-Cheatsheet)
