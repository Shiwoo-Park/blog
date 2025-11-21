---
layout: post
title: "서버 디스크 정리 가이드"
date: 2024-07-12
categories: [devops, linux, maintenance]
---

# 서버 디스크 정리 가이드

> 날짜: 2024-07-12

[목록으로](https://shiwoo-park.github.io/blog)

---

## 디스크 정리용 linux commands

```shell
# 대용량 파일 및 디렉토리 찾기 (Top 20)
sudo du -h / | sort -rh | head -n 20

# 패키지 캐시 정리
sudo yum clean all

# 저널로그 삭제 (7일 이상된)
sudo journalctl --vacuum-time=7d

# === 도커 ===
# 1달간 미사용 이미지 삭제
docker image prune -a -f --filter "until=720h"
# 1달간 미사용 컨테이터 삭제
docker container prune -f  --filter "until=720h"

# 디스크 사용량 분석도구 설치 & 활용
sudo yum install ncdu
sudo ncdu /
```

## 저널로그 (Journal Log):

저널로그는 systemd 시스템에서 사용되는 중앙집중식 로깅 시스템입니다. systemd-journald 서비스에 의해 관리되며, 다음과 같은 특징을 가집니다:

- 구조화된 로그 데이터를 저장합니다.
- 시스템 부팅부터 종료까지의 모든 로그를 포함합니다.
- 커널 로그, 시스템 로그, 애플리케이션 로그 등 다양한 소스의 로그를 통합 관리합니다.
- 바이너리 형식으로 저장되어 효율적인 저장 및 검색이 가능합니다.
- `journalctl` 명령어를 통해 로그를 조회하고 관리할 수 있습니다.

주요 사용 예:
```shell
journalctl                     # 모든 로그 보기
journalctl -u service-name     # 특정 서비스의 로그 보기
journalctl --since today       # 오늘의 로그만 보기
journalctl -f                  # 실시간 로그 모니터링 (tail -f와 유사)

# 7일 이상 된 로그 삭제
sudo journalctl --vacuum-time=7d

# 500M 로 로그 크기 제한
sudo journalctl --vacuum-size=500M

# 데몬 재시작 (설정 리로드)
sudo systemctl restart systemd-journald

# 데몬 상태 확인
sudo systemctl status systemd-journald

# 변경된 설정의 적용 확인
sudo journalctl --verify

# 저널 사용량 확인
journalctl --disk-usage
```

`/etc/systemd/journald.conf` 로 자동관리 설정

- 총 로그크기를 1G 로 제한하고
- 1개월 or 15일 이상 된 로그를 자동 삭제

```conf
SystemMaxUse=1G
MaxRetentionSec=1month
MaxRetentionSec=15d
```

## ncdu (NCurses Disk Usage):

ncdu는 "NCurses Disk Usage"의 약자로, 디스크 사용량을 분석하고 시각화하는 커맨드라인 도구입니다.

특징 및 활용 방법:
- 대화형 인터페이스를 제공하여 디렉토리 구조를 탐색하며 디스크 사용량을 확인할 수 있습니다.
- 디스크 공간을 많이 차지하는 파일이나 디렉토리를 쉽게 식별할 수 있습니다.
- 커맨드라인 환경에서 작동하므로, GUI가 없는 서버 환경에서도 유용합니다.

사용 방법:
1. 설치 후 다음과 같이 실행합니다:
   ```
   sudo yum install ncdu
   sudo ncdu /
   ncdu /path/to/directory
   ```

2. 실행하면 대화형 인터페이스가 나타납니다:
   - 화살표 키로 디렉토리를 탐색합니다.
   - Enter 키로 하위 디렉토리로 들어갑니다.
   - 'q' 키를 눌러 종료합니다.

3. 각 디렉토리와 파일의 크기가 시각적으로 표시되며, 크기순으로 정렬됩니다.

4. 특정 디렉토리나 파일에 커서를 올리면 상세 정보가 표시됩니다.

활용 예:
- 대용량 파일이나 불필요한 파일을 찾아 삭제하여 디스크 공간을 확보할 때
- 특정 애플리케이션이나 사용자가 사용하는 디스크 공간을 분석할 때
- 시스템의 전반적인 디스크 사용 패턴을 파악할 때

ncdu는 특히 서버 환경에서 디스크 공간 관리에 매우 유용한 도구입니다.