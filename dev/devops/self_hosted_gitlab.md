# Self-hosted Gitlab 관리

> 날짜: 2025-03-07

[목록으로](https://shiwoo-park.github.io/blog)

---

## 상태점검

- 로그조회
  - `sudo gitlab-ctl tail`
  - 주요 로그파일 경로: `/var/log/gitlab/`
- 서비스 상태 조회
  - `sudo gitlab-ctl status`
  - `sudo gitlab-rake gitlab:check SANITIZE=true`

## 버전업

- 버전업 작업 시작전 반드시 데이터를 백업할것
- 일반적으로 단계적으로 버전을 올리는것이 좋음.
  - 버전관리방식의 버전이 `{major}.{minor}.{hotfix}` 라고 했을때
  - hotfix 버전은 맘대로 업데이트 가능하지만
  - major 또는 minor 버전을 올릴때는 동일 이전 버전에서 최신 hotfix 버전이어야 함
    - `17.7.1  -> 17.8.1` -> 불가
    - `17.7.1 -> 17.7.6 -> 17.8.1` -> 가능
    - `17.7.6` 은 `17.7.x` 기준 최고 버전

## Gitlab Runner 설정

- 서버에 gitlab-runner 를 별도 설치해야 함.
- 러너를 구동하는 서버는 반드시 gitlab 서비스가 구동중인 서버와 같은 필요가 없음
- executor 로 docker 를 사용하고 싶으면
  - 서버에 docker 를 미리 설치해야함
  - Docker를 사용하는 경우 Linux의 gitlab-runner 유저가 docker 그룹에 속해야 정상 실행 가능
    ```bash
    sudo usermod -aG docker gitlab-runner
    sudo systemctl restart gitlab-runner
    ```
- runner 를 등록하고 구동할때 `sudo` 또는 `gitlab-runner` 유저를 사용해야함.


## 백업 및 복구

- 백업하는 Gitlab 의 버전과 복구하는 Gitlab 의 버전이 동일해야함.

### 백업 Tips

- 백업할 때 **데이터 정합성을 유지하기 위해 GitLab을 중지**
  - `sudo gitlab-ctl stop`
- 하지만 **DB(PostgreSQL), Redis, Gitaly(Git 저장소 관리 서비스)는 유지**
  ```shell
  sudo gitlab-ctl start postgresql
  sudo gitlab-ctl start redis
  sudo gitlab-ctl start gitaly
  ```
- 자체 백업기능 실행
  - `sudo gitlab-backup create SKIP=uploads,builds,artifacts,lfs,registry,pages`
- 기타 주요 파일 수동 백업
  - 2FA, PAT, 인증정보 등까지 완전히 동일하게 백업하고 싶으면 반드시 해야함
  ```shell
  sudo tar -czvf "$BACKUP_DIR/gitlab_config_backup.tar.gz" /etc/gitlab
  sudo tar -czvf "$BACKUP_DIR/gitlab_secrets_backup.tar.gz" /var/opt/gitlab/gitlab-rails/etc
  ```

### 복구 Tips

- 복구시에도 마찬가지로 모든 서비스를 중지하되 **DB(PostgreSQL), Redis, Gitaly(Git 저장소 관리 서비스)는 구동**
- gitlab 설정파일에서 서비스 URL 설정 (`/etc/gitlab/gitlab.rb` 파일의 `external_url` 변경)
- 복구 시 지정하는 백업파일은
  - 반드시 백업폴더(`/var/opt/gitlab/backups`)에 위치해 있어야 하며
  - 파일명 뒤쪽에 `_gitlab_backup.tar` 부분을 제외한 앞부분만 사용하면 됨
  - (ex) `sudo gitlab-backup restore BACKUP=1739361192_2025_02_12_17.7.3`

---

[목록으로](https://shiwoo-park.github.io/blog)
