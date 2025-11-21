---
layout: post
title: "Postgres MVCC, Fillfactor, HOT, SPC 개념잡기"
date: 2025-07-15
categories: [database, postgresql, internals]
---

# Postgres MVCC, Fillfactor, HOT, SPC 개념잡기

> 날짜: 2025-07-15

[목록으로](https://shiwoo-park.github.io/blog)

---

PostgreSQL의 MVCC, fillfactor, HOT update, Single Page Cleanup은 데이터 수정/삭제 시 성능과 공간 효율을 높이기 위해 유기적으로 작동하는 핵심 메커니즘입니다.

이 네 가지는 서로 밀접하게 연결되어 있으므로, 각 개념을 설명하고, 동작 흐름을 따라 상관관계를 정리해드리겠습니다.

⸻

### 1. MVCC (Multi-Version Concurrency Control)

PostgreSQL의 기본적인 동시성 제어 방식으로, 읽기-쓰기 충돌 없이 트랜잭션을 격리하기 위해 데이터의 여러 버전을 유지합니다.

- 동작 방식

  - 테이블의 각 row에는 xmin, xmax라는 숨겨진 시스템 컬럼이 존재
  - 업데이트나 삭제 시 기존 row를 즉시 수정하지 않고, 새로운 row 버전을 생성
  - 기존 row는 이전 트랜잭션을 위한 스냅샷, 새로운 row는 최신 상태

- 결과
  - 데이터 수정이 잦으면 row 버전이 계속 누적되어 디스크 공간 낭비 가능
  - VACUUM이 필요해짐 (불필요한 row 제거)

### 2. fillfactor

PostgreSQL에서 테이블 또는 인덱스를 생성/변경할 때 설정할 수 있는 page 내 row 저장 밀도 설정값입니다. 기본값은 100(즉, 페이지를 가득 채움).

동작 방식
• fillfactor = 70으로 설정 시, 한 페이지의 70%만 row로 채우고 30%는 free space로 남김
• 이 여유 공간은 HOT update와 같이 동일 페이지 내 row update를 가능하게 만들어줌

목적
• 업데이트 성능 향상
• page split이나 불필요한 page 이동 방지

### 3. HOT Update (Heap-Only Tuple Update)

MVCC 기반 업데이트 시 새로운 row를 생성하되, 인덱스 재작성 없이 현재 페이지 내에서만 row version을 교체하는 최적화 기법입니다.

- 조건
  - 업데이트가 인덱스에 영향을 주지 않는 컬럼만 수정될 경우
  - 해당 page 내에 새로운 row를 저장할 충분한 여유 공간이 있을 경우 (fillfactor로 확보)
- 효과
  - 인덱스 성능 유지 (인덱스에 불필요한 row 버전 쌓이지 않음)
  - VACUUM 부하 감소
  - 업데이트 성능 대폭 향상

### 4. Single Page Cleanup (SPC)

PostgreSQL 13부터 도입된 페이지 단위 미니 VACUUM 기능. 필요 시 페이지 단위로만 불필요한 tuple 제거.

- 동작 방식
  - SELECT 또는 UPDATE 수행 중, 해당 page가 많은 dead tuple을 포함하면 자동으로 SPC 실행
  - 기존 autovacuum이 전체 테이블을 스캔하며 cleanup 했다면, SPC는 딱 필요한 페이지만 정리
- 효과
  - VACUUM 딜레이 없이 실시간 공간 회수
  - HOT update 후에도 dead tuple이 많아질 경우 공간 낭비 방지

## 개념 간 상관관계 요약

- 요소 핵심 역할 상호작용 관계
- MVCC 동시성 확보 및 버전 유지 update 시 새로운 row 생성 → 공간 누적
- fillfactor page 내 여유 공간 확보 HOT update 가능성 증가
- HOT update 인덱스 부담 없이 update 최적화 동일 페이지에 여유 공간 필요 (fillfactor 영향)
- SPC dead tuple 실시간 정리 HOT update 이후의 공간 낭비 최소화

### 흐름도 요약

1. MVCC → update 시 row 누적
2. fillfactor → 페이지 내 여유 공간 확보
3. HOT update → 인덱스 무수정 + 같은 page 내 row 교체
4. Single Page Cleanup → dead tuple 실시간 정리

## ✅ 최신 PostgreSQL 기준 유의사항 (2025 기준)

- PostgreSQL 13부터 SPC 기본 활성화됨 (추가 설정 불필요)
- PostgreSQL 14 이상에서 fillfactor는 ALTER TABLE ... SET (fillfactor=...)로 런타임에 설정 가능
- HOT update는 모든 인덱스에 영향을 미치지 않아야만 가능 (하나라도 수정 대상이면 일반 update로 fallback됨)

---

[목록으로](https://shiwoo-park.github.io/blog)
