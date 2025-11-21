---
layout: post
title: "PostgreSQL 구조"
date: 2025-06-29
categories: [database, postgresql]
---

# PostgreSQL 구조

> 날짜: 2025-06-29

[목록으로](https://shiwoo-park.github.io/blog)

---

## 프로세스 구조

### 주요 프로세스
- **Postmaster (메인 프로세스)**
  - 클라이언트 연결 요청 처리
  - 백엔드 프로세스 생성 및 관리
  - 시스템 종료 시그널 처리

- **Backend Process (백엔드 프로세스)**
  - 클라이언트 요청 처리
  - SQL 쿼리 실행
  - 트랜잭션 관리

- **Background Process (백그라운드 프로세스)**
  - **WAL Writer**: WAL 버퍼를 디스크에 쓰기
  - **Checkpointer**: 체크포인트 수행
  - **Background Writer**: 더티 페이지를 디스크에 쓰기
  - **Autovacuum Launcher**: Autovacuum 워커 프로세스 관리
  - **Autovacuum Worker**: 테이블 정리 작업 수행
  - **Archiver**: WAL 파일 아카이빙
  - **Statistics Collector**: 통계 정보 수집

## 메모리 구조

### Shared Memory (공유 메모리)
- **Shared Buffer**: 테이블과 인덱스 데이터 캐싱
- **WAL Buffer**: WAL 레코드 임시 저장
- **Commit Log**: 트랜잭션 커밋 상태
- **Lock Space**: 락 정보 저장
- **Shared Memory Context**: 공유 데이터 구조

### Local Memory (로컬 메모리)
- **Work Memory**: 정렬, 해시 조인 등에 사용
- **Maintenance Work Memory**: VACUUM, CREATE INDEX 등에 사용
- **Temp Buffer**: 임시 테이블 데이터
- **Local Memory Context**: 세션별 데이터

## 논리적 구조

### 클러스터 (Cluster)
- PostgreSQL 인스턴스 전체
- 여러 데이터베이스 포함

### 데이터베이스 (Database)
- 논리적 데이터 컨테이너
- 독립적인 네임스페이스

### 스키마 (Schema)
- 데이터베이스 내 논리적 네임스페이스
- 기본 스키마: `public`, `information_schema`, `pg_catalog`
- 롤(Role): DB 관련 권한

### 데이터베이스 객체 (Database Objects)
- **테이블 (Table)**: 데이터 저장
- **인덱스 (Index)**: 검색 성능 향상
- **뷰 (View)**: 가상 테이블
- **시퀀스 (Sequence)**: 자동 증가 값
- **함수 (Function)**: 저장 프로시저
- **트리거 (Trigger)**: 이벤트 기반 동작
- **테이블스페이스 (Tablespace)**: 물리적 저장 위치 지정

### 릴레이션 (Relation)
- 테이블, 인덱스, 뷰의 통칭
- 시스템 카탈로그에서 관리

### 튜플 (Tuple)
- 테이블의 행(Row)
- 실제 데이터 값

### 페이지 (Page)
- 디스크 I/O의 기본 단위 (8KB)
- 튜플과 메타데이터 포함

## 물리적 구조

### 디렉토리 구조
```
$PGDATA/
├── base/           # 데이터베이스 파일
├── global/         # 글로벌 시스템 카탈로그
├── pg_wal/         # WAL 파일
├── pg_xact/        # 커밋 로그
├── pg_stat_tmp/    # 통계 정보
└── postgresql.conf # 설정 파일
```

### 포크 (Fork)
PostgreSQL 테이블은 여러 포크로 구성:

- **Main Fork**: 실제 데이터 (튜플)
- **Free Space Map (FSM)**: 사용 가능한 공간 정보
- **Visibility Map (VM)**: 튜플 가시성 정보
- **Initialization Fork**: 언로그 테이블의 초기 데이터

### OID (Object Identifier)
- 데이터베이스 객체의 고유 식별자
- 시스템 카탈로그에서 관리
- 32비트 정수형

### 파일 구조
- **Heap File**: 테이블 데이터
- **Index File**: 인덱스 데이터
- **TOAST File**: 큰 값 저장
- **WAL File**: 트랜잭션 로그

## FSM, VM 과 Vacuum의 관계

### Vacuum이란?

**Vacuum**은 PostgreSQL에서 테이블의 **데드 튜플(Dead Tuple)**을 정리하고 **저장 공간을 회수**하는 중요한 유지보수 작업입니다.

#### Vacuum의 주요 목적:
- **데드 튜플 제거**: DELETE나 UPDATE로 인해 더 이상 사용되지 않는 튜플 정리
- **저장 공간 회수**: 삭제된 튜플이 차지하던 공간을 재사용 가능하게 만듦
- **통계 정보 업데이트**: 테이블과 인덱스의 통계 정보 갱신
- **트랜잭션 ID 래핑 방지**: XID 래핑 문제 해결

#### Vacuum의 종류:
- **VACUUM**: 데드 튜플만 제거 (공간 회수 안함)
- **VACUUM FULL**: 테이블 재구성하여 공간 회수
- **VACUUM ANALYZE**: 통계 정보도 함께 업데이트
- **AUTOVACUUM**: 자동으로 실행되는 백그라운드 Vacuum

### FSM, VM이 Vacuum 작업과 어떤 관련이 있는지?

#### Free Space Map (FSM)과 Vacuum

**FSM**은 테이블의 각 페이지에서 **사용 가능한 공간**을 추적하는 데이터 구조입니다.

```sql
-- FSM 정보 확인
SELECT schemaname, tablename, attname, n_distinct, correlation 
FROM pg_stats 
WHERE tablename = 'your_table_name';
```

**FSM과 Vacuum의 관계:**
- **Vacuum 전**: FSM은 데드 튜플이 차지하는 공간을 "사용 중"으로 표시
- **Vacuum 중**: 데드 튜플을 제거하면서 FSM을 업데이트
- **Vacuum 후**: FSM이 새로운 사용 가능한 공간을 정확히 반영

**FSM의 역할:**
- 새로운 튜플 삽입 시 **적절한 페이지 선택** 도움
- **공간 효율성** 향상
- **페이지 분할** 최소화

#### Visibility Map (VM)과 Vacuum

**VM**은 각 페이지의 **모든 튜플이 모든 트랜잭션에서 보이는지**를 추적합니다.

```sql
-- VM 정보 확인 (PostgreSQL 내부 뷰)
SELECT * FROM pg_stat_all_tables 
WHERE schemaname = 'public' AND relname = 'your_table_name';
```

**VM과 Vacuum의 관계:**
- **VM 비트가 1인 페이지**: 모든 튜플이 모든 트랜잭션에서 보임 → Vacuum 스킵 가능
- **VM 비트가 0인 페이지**: 일부 튜플이 일부 트랜잭션에서 안 보임 → Vacuum 필요

**VM의 장점:**
- **Vacuum 성능 향상**: 스킵할 수 있는 페이지 식별
- **Index-Only Scan 최적화**: 인덱스만으로 쿼리 실행 가능
- **트랜잭션 격리 수준** 유지

### Wraparound 문제란 무엇이고 VACUUM FREEZE로 이를 해결하는 방법

#### Wraparound 문제

PostgreSQL의 **트랜잭션 ID (XID)**는 32비트 정수로 제한되어 있습니다.

```sql
-- 현재 XID 확인
SELECT txid_current();

-- 데이터베이스별 XID 사용량 확인
SELECT datname, age(datfrozenxid) as xid_age 
FROM pg_database 
ORDER BY xid_age DESC;
```

**문제 발생 과정:**
1. XID는 0부터 시작하여 증가
2. 약 21억 개의 트랜잭션 후 **최대값 도달**
3. XID가 다시 0부터 시작 → **Wraparound 발생**
4. 이전 트랜잭션과 현재 트랜잭션의 **순서 구분 불가**

**Wraparound의 위험성:**
- **데이터 무결성** 손상 가능
- **데이터베이스 접근 불가** (Emergency Mode)
- **복구 불가능한 상황** 발생

#### VACUUM FREEZE로 해결하는 방법

**VACUUM FREEZE**는 모든 튜플의 **XID를 특별한 값으로 고정**하여 Wraparound를 방지합니다.

```sql
-- VACUUM FREEZE 실행
VACUUM FREEZE table_name;

-- 전체 데이터베이스에 대해 실행
VACUUM FREEZE;

-- 강제로 실행 (트랜잭션 ID 고정)
VACUUM FREEZE VERBOSE table_name;
```

**VACUUM FREEZE의 동작:**
1. **모든 튜플의 XID를 FrozenXID로 설정**
2. **FrozenXID는 항상 모든 트랜잭션보다 이전**으로 간주
3. **Wraparound 문제 완전 해결**

**자동 FREEZE 설정:**
```sql
-- postgresql.conf 설정
autovacuum_freeze_max_age = 200000000  -- 기본값
vacuum_freeze_min_age = 50000000       -- 기본값
```

**모니터링 쿼리:**
```sql
-- Wraparound 위험도 확인
SELECT 
    schemaname,
    tablename,
    age(relfrozenxid) as xid_age,
    CASE 
        WHEN age(relfrozenxid) > 200000000 THEN 'CRITICAL'
        WHEN age(relfrozenxid) > 150000000 THEN 'WARNING'
        ELSE 'OK'
    END as status
FROM pg_stat_user_tables 
ORDER BY xid_age DESC;
```

**FSM, VM과 FREEZE의 관계:**
- **FSM**: FREEZE 후 공간 재사용 가능성 업데이트
- **VM**: FREEZE된 튜플은 모든 트랜잭션에서 보이므로 VM 비트 1로 설정
- **성능 향상**: FREEZE 후 Index-Only Scan 최적화 가능

## 핵심 요약

1. **PostgreSQL은 Postmaster(메인), Backend(쿼리처리), Background(유지보수) 프로세스로 구성되며, Shared Memory(공유)와 Local Memory(세션별)로 메모리를 관리한다.**

2. **논리적 구조는 클러스터 → 데이터베이스 → 스키마 → 객체(테이블, 인덱스 등)의 계층으로, 물리적으로는 디렉토리와 포크(Main, FSM, VM)로 데이터를 저장한다.**

3. **FSM(Free Space Map)은 페이지별 사용 가능한 공간을, VM(Visibility Map)은 튜플 가시성을 추적하여 Vacuum 성능을 최적화한다.**

4. **Vacuum은 데드 튜플 제거, 공간 회수, 통계 업데이트를 수행하며, VACUUM FREEZE는 32비트 XID 제한으로 인한 Wraparound 문제를 해결한다.**

5. **정기적인 모니터링(`age(datfrozenxid)`)과 VACUUM 작업이 데이터 무결성과 성능 유지의 핵심이다.**


---

[목록으로](https://shiwoo-park.github.io/blog)
