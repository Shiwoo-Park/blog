---
layout: post
title: "AWS CodeDeploy 배포 기록 정기 클린업 스크립트"
date: 2026-01-15
categories: [bash, aws, codedeploy]
description: "AWS CodeDeploy 기반 배포 서버에서 누적되는 배포 기록을 자동으로 정리하는 스크립트입니다. 최신 배포 기록만 유지하고 오래된 기록은 삭제하여 디스크 공간을 확보합니다."
keywords: "AWS CodeDeploy, 배포 기록 정리, 디스크 클린업, bash 스크립트, crontab"
---

AWS CodeDeploy를 사용하는 서버에서는 배포가 반복될수록 `/opt/codedeploy-agent/deployment-root` 디렉토리에 배포 기록이 누적되어 디스크 공간을 차지하게 됩니다. 이 스크립트는 정기적으로 오래된 배포 기록을 자동으로 삭제하여 디스크 공간을 확보합니다.

---

## 1. 스크립트 주요 기능

- **자동 정리**: 최신 배포 기록 N개만 유지하고 나머지는 삭제
- **안전한 검증**: UUID 형식 검증 및 예약 폴더 제외
- **Dry-run 모드**: 실제 삭제 전 테스트 실행 가능
- **로그 기록**: 모든 작업 내역을 로그 파일에 기록

---

## 2. 사용 방법

### 2-1. 스크립트 저장 및 실행 권한 부여

```bash
sudo mkdir -p /root/scripts
sudo vi /root/scripts/codedeploy_cleanup.sh
# 아래 스크립트 내용 복사

sudo chmod +x /root/scripts/codedeploy_cleanup.sh
```

### 2-2. Dry-run 모드로 테스트

```bash
sudo /root/scripts/codedeploy_cleanup.sh --dry
```

### 2-3. 실제 실행

```bash
sudo /root/scripts/codedeploy_cleanup.sh
```

### 2-4. Crontab 설정 (정기 실행)

```bash
sudo crontab -e
```

다음 내용 추가:

```
# 매주 일요일 오후 10시에 실행
0 22 * * 0 sudo /root/scripts/codedeploy_cleanup.sh
```

---

## 3. 스크립트 코드

```bash
#!/bin/bash

BASE_DIR="/opt/codedeploy-agent/deployment-root"
LOG_FILE="/root/scripts/codedeploy_cleanup.log"
KEEP_COUNT=2
DRY_RUN=false

[[ "$1" == "--dry" ]] && DRY_RUN=true

# 로그 환경 준비
mkdir -p "$(dirname "$LOG_FILE")"
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $1" | tee -a "$LOG_FILE"
}

log "===== CodeDeploy Cleanup Started (Dry-run: $DRY_RUN) ====="

# 1. BASE_DIR 존재 확인
if [ ! -d "$BASE_DIR" ]; then
    log "[ERROR] Base directory $BASE_DIR not found. Exiting."
    exit 1
fi

# 2. 배포 루트 내의 폴더 순회
for deploy_root in "$BASE_DIR"/*; do
    # 디렉토리가 아니면 건너뜀
    [ -d "$deploy_root" ] || continue

    deploy_name=$(basename "$deploy_root")

    # [검증] 명시적인 예약 폴더 제외
    case "$deploy_name" in
        deployment-instructions|deployment-logs|ongoing-deployment)
            log "[SKIP] Internal meta directory: $deploy_name"
            continue
            ;;
    esac

    # [검증] 반드시 UUID(36자리 해시형태) 폴더인 경우만 진행
    # 예: c5acfe79-f695-4f12-b58c-c5122717b09b
    if [[ ! "$deploy_name" =~ ^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$ ]]; then
        log "[SKIP] Not a deployment UUID format: $deploy_name"
        continue
    fi

    log "[PROCESS] target UUID: $deploy_name"

    # 3. 해당 UUID 폴더 내부의 d-* 디렉토리 정렬 (최신순)
    # %T@: 수정시간(timestamp), %p: 경로
    DEPLOY_UNITS=$(find "$deploy_root" -maxdepth 1 -type d -name "d-*" -printf "%T@ %p\n" | sort -nr | awk '{print $2}')

    INDEX=0
    for unit_path in $DEPLOY_UNITS; do
        INDEX=$((INDEX + 1))

        if [ "$INDEX" -le "$KEEP_COUNT" ]; then
            log "  [KEEP] ($INDEX) $(basename "$unit_path")"
            continue
        fi

        # 실제 삭제 로직
        if $DRY_RUN; then
            log "  [DRY-RUN] Would delete: $unit_path"
        else
            log "  [DELETE] Removing: $unit_path"
            rm -rf "$unit_path"
        fi
    done
done

log "===== CodeDeploy Cleanup Finished ====="
```

### 주요 설정 변수

- `BASE_DIR`: CodeDeploy 배포 기록이 저장된 디렉토리 경로
- `LOG_FILE`: 작업 로그가 기록될 파일 경로
- `KEEP_COUNT`: 유지할 최신 배포 기록 개수 (기본값: 2)

---

## 4. 스크립트 동작 방식

1. **디렉토리 검증**: `/opt/codedeploy-agent/deployment-root` 디렉토리 존재 확인
2. **UUID 폴더 탐색**: 배포 루트 내의 UUID 형식 폴더만 처리 (예약 폴더 제외)
3. **배포 단위 정렬**: 각 UUID 폴더 내의 `d-*` 디렉토리를 수정 시간 기준 최신순 정렬
4. **선택적 삭제**: 최신 `KEEP_COUNT`개만 유지하고 나머지 삭제
5. **로그 기록**: 모든 작업 내역을 로그 파일에 기록

---

## 핵심 요약

- **목적**: AWS CodeDeploy 배포 기록 자동 정리로 디스크 공간 확보
- **기능**: 최신 N개 배포 기록만 유지, 나머지 자동 삭제
- **안전장치**: UUID 형식 검증, 예약 폴더 제외, Dry-run 모드 지원
- **사용법**: Crontab으로 정기 실행 설정 (권장: 주 1회)
- **설정**: `KEEP_COUNT` 변수로 유지할 배포 기록 개수 조정 가능
