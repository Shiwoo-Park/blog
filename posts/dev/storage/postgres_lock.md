---
layout: post
title: "PostgreSQL: Lock 에 대하여"
date: 2025-07-30
categories: [database, postgresql, concurrency]
---
## Lock의 개념과 목적

PostgreSQL에서 **Lock**은 동시성 제어를 위한 핵심 메커니즘입니다. 

여러 트랜잭션이 동시에 같은 데이터에 접근할 때 데이터의 일관성과 무결성을 보장하기 위해 사용됩니다.

### Lock이 필요한 이유
- **동시성**: 여러 사용자가 동시에 데이터에 접근할 때 발생하는 문제 해결
- **일관성**: 데이터의 ACID 속성 중 Consistency 보장
- **무결성**: 데이터가 손상되지 않도록 보호

## 객체 레벨 락 (Object-Level Locks)

### 객체란?

PostgreSQL에서 객체는 다음과 같은 것들을 의미합니다:
- **테이블** (Tables)
- **인덱스** (Indexes) 
- **시퀀스** (Sequences)
- **뷰** (Views)
- **함수** (Functions)

### 객체 락 모드

PostgreSQL은 다양한 객체 락 모드를 제공합니다:

```sql
-- 테이블에 대한 ACCESS SHARE 락 (기본 SELECT)
SELECT * FROM users WHERE id = 1;

-- 테이블에 대한 ROW SHARE 락 (SELECT FOR UPDATE)
SELECT * FROM users WHERE id = 1 FOR UPDATE;

-- 테이블에 대한 ROW EXCLUSIVE 락 (INSERT, UPDATE, DELETE)
UPDATE users SET name = 'John' WHERE id = 1;

-- 테이블에 대한 SHARE 락 (CREATE INDEX)
CREATE INDEX idx_users_name ON users(name);

-- 테이블에 대한 SHARE ROW EXCLUSIVE 락 (VACUUM FULL, REINDEX)
VACUUM FULL users;

-- 테이블에 대한 SHARE UPDATE EXCLUSIVE 락 (CREATE INDEX CONCURRENTLY)
CREATE INDEX CONCURRENTLY idx_users_email ON users(email);

-- 테이블에 대한 EXCLUSIVE 락 (ALTER TABLE)
ALTER TABLE users ADD COLUMN email VARCHAR(255);

-- 테이블에 대한 ACCESS EXCLUSIVE 락 (DROP, TRUNCATE)
TRUNCATE TABLE users;
```

### 각 락 모드의 상세 설명

| 락 모드 | 사용 사례 | 호환성 | 설명 |
|---------|-----------|--------|------|
| **ACCESS SHARE** | SELECT | 높음 | 기본 읽기 작업, 가장 호환성이 높음 |
| **ROW SHARE** | SELECT FOR UPDATE | 높음 | 행 수정을 위한 락, 다른 읽기와 호환 |
| **ROW EXCLUSIVE** | INSERT, UPDATE, DELETE | 낮음 | 데이터 수정 작업, 다른 수정과 호환되지 않음 |
| **SHARE** | CREATE INDEX | 낮음 | 인덱스 생성, 다른 SHARE와 호환 |
| **SHARE ROW EXCLUSIVE** | VACUUM FULL, REINDEX | 낮음 | 테이블 재구성, 다른 작업과 호환되지 않음 |
| **SHARE UPDATE EXCLUSIVE** | CREATE INDEX CONCURRENTLY | 낮음 | 동시 인덱스 생성, 다른 업데이트와 호환되지 않음 |
| **EXCLUSIVE** | ALTER TABLE | 매우 낮음 | 스키마 변경, 다른 모든 작업과 호환되지 않음 |
| **ACCESS EXCLUSIVE** | DROP, TRUNCATE | 없음 | 테이블 삭제/재생성, 완전 배타적 |

### SHARE ROW EXCLUSIVE vs SHARE UPDATE EXCLUSIVE 비교

- `SHARE ROW EXCLUSIVE` 는 해당 테이블에 대해 자기 자신과도 충돌하며 다른 작업도 차단 
- `SHARE UPDATE EXCLUSIVE` 는 공유 업데이트 용 유지되며 읽기·쓰기 허용, 일부 DDL/VACUUM 작업만 차단

#### SHARE ROW EXCLUSIVE 락 예시
```sql
-- VACUUM FULL은 SHARE ROW EXCLUSIVE 락 사용
-- 다른 모든 작업을 차단함
VACUUM FULL users;

-- 동시에 실행 불가능한 작업들:
-- UPDATE users SET name = 'John' WHERE id = 1;  -- 대기
-- CREATE INDEX idx_users_name ON users(name);    -- 대기
-- ALTER TABLE users ADD COLUMN email VARCHAR(255); -- 대기
```

#### SHARE UPDATE EXCLUSIVE 락 예시
```sql
-- CREATE INDEX CONCURRENTLY는 SHARE UPDATE EXCLUSIVE 락 사용
-- 다른 업데이트 작업은 차단하지만 읽기는 허용
CREATE INDEX CONCURRENTLY idx_users_email ON users(email);

-- 동시에 실행 가능한 작업:
SELECT * FROM users WHERE id = 1;  -- 가능

-- 동시에 실행 불가능한 작업들:
-- UPDATE users SET name = 'John' WHERE id = 1;  -- 대기
-- INSERT INTO users (name) VALUES ('Alice');    -- 대기
-- DELETE FROM users WHERE id = 1;               -- 대기
```


### 락 호환성 매트릭스

| 요청 락 ↓ \ 기존 락 →            | ACCESS SHARE | ROW SHARE | ROW EXCLUSIVE | SHARE | SHARE ROW EXCLUSIVE | SHARE UPDATE EXCLUSIVE | EXCLUSIVE | ACCESS EXCLUSIVE |
| -------------------------- | ------------ | --------- | ------------- | ----- | ------------------- | ---------------------- | --------- | ---------------- |
| **ACCESS SHARE**           | O            | O         | O             | O     | O                   | O                      | O         | X                |
| **ROW SHARE**              | O            | O         | O             | O     | O                   | O                      | X         | X                |
| **ROW EXCLUSIVE**          | O            | O         | O             | X     | X                   | X                      | X         | X                |
| **SHARE**                  | O            | O         | X             | O     | X                   | X                      | X         | X                |
| **SHARE ROW EXCLUSIVE**    | O            | O         | X             | X     | X                   | X                      | X         | X                |
| **SHARE UPDATE EXCLUSIVE** | O            | O         | X             | X     | X                   | X                      | X         | X                |
| **EXCLUSIVE**              | X            | X         | X             | X     | X                   | X                      | X         | X                |
| **ACCESS EXCLUSIVE**       | X            | X         | X             | X     | X                   | X                      | X         | X                |


## 행 레벨 락 (Row-Level Locks)

### 행 레벨 락 모드

행 레벨 락은 특정 행에만 적용되는 락입니다. PostgreSQL에서는 **MVCC(Multi-Version Concurrency Control)** 를 사용하여 락 정보를 페이지 내부의 튜플 버전에 저장합니다.

```sql
-- FOR UPDATE: 행을 수정하기 위한 배타적 락
SELECT * FROM users WHERE id = 1 FOR UPDATE;

-- FOR NO KEY UPDATE: 키가 아닌 컬럼만 수정할 때 사용
SELECT * FROM users WHERE name = 'John' FOR NO KEY UPDATE;

-- FOR SHARE: 행을 읽기 위한 공유 락
SELECT * FROM users WHERE id = 1 FOR SHARE;

-- FOR KEY SHARE: 키 컬럼만 보호하는 공유 락
SELECT * FROM users WHERE id = 1 FOR KEY SHARE;
```

### MVCC와 락 정보 저장 방식

PostgreSQL은 **MVCC (Multi-Version Concurrency Control)** 방식을 사용하여 데이터의 일관성과 동시성을 보장합니다. 각 행(튜플)은 다음과 같은 시스템 컬럼을 통해 트랜잭션 상태를 추적합니다:

| 필드     | 설명                   |
| ------ | -------------------- |
| `xmin` | 튜플을 생성한 트랜잭션 ID      |
| `xmax` | 튜플을 삭제하거나 잠근 트랜잭션 ID |

> `xmax`는 **DELETE/UPDATE** 또는 행 락(`FOR UPDATE`, `FOR SHARE` 등) 이 걸렸을 때 사용됩니다.

락은 새로운 튜플을 생성하지 않고, 기존 튜플의 `xmax` 필드에 **락을 획득한 트랜잭션 ID**를 기록하는 방식으로 관리됩니다. 실제 데이터 변경이 없는 단순 락(`FOR UPDATE`)만으로는 튜플 복사(copy-on-write)는 발생하지 않습니다.

| 판단 요소               | 설명                                                   |
| ------------------- | ---------------------------------------------------- |
| `xmax` 있음           | "무언가에 의해 잠깐 변경/잠금됐음"을 의미하지만 **그 자체로는 유효성 판단 불가**     |
| `xmax` + 트랜잭션 상태 확인 | 이 트랜잭션이 커밋됐다면: 삭제 or 락 확정<br>롤백됐다면: 락 무효 (튜플 여전히 유효) |
| → MVCC 처리           | PostgreSQL은 이 판단을 통해 클라이언트에 보여줄 튜플을 결정함 (가시성 판단)     |

```sql
-- 현재 튜플의 트랜잭션 정보 확인 예시
SELECT ctid, xmin, xmax
FROM users
WHERE id = 1;
```

### 특징 요약

* **락은 튜플의 `xmax` 필드로 표현된다.**
* **`FOR UPDATE`, `FOR SHARE` 등은 `xmax` 에 트랜잭션 ID를 기록하여 잠금만 표시합니다.**
* **튜플 복사는 오직 `UPDATE`나 `DELETE` 같은 데이터 변경 작업 시 발생한다.**
* **동시 락이 허용되는 경우(`FOR SHARE`, `FOR KEY SHARE`)는 여러 트랜잭션이 동일 튜플에 호환 락을 잡을 수 있다.**
* **락 해제는 트랜잭션 종료 시 자동 처리되며, 별도 튜플 버전 생성은 없다.**

### 페이지 저장의 장점

MVCC 정보(`xmin`, `xmax`)와 락 정보는 모두 **디스크의 튜플 헤더에 직접 저장**되므로 다음과 같은 이점이 있습니다:

* 서버 재시작 이후에도 락/트랜잭션 정보 일관성 유지
* 메모리 의존도 없이 튜플 상태 복원 가능
* 트랜잭션 충돌이나 정합성 검사 시 빠른 판단 가능


### 다중 트랜잭션과 호환가능한 락

```sql
-- 세션 1: 공유 락 획득
BEGIN;
SELECT * FROM users WHERE id = 1 FOR SHARE;
-- 다른 세션에서 같은 행에 FOR SHARE 가능

-- 세션 2: 같은 행에 공유 락 획득 가능
BEGIN;
SELECT * FROM users WHERE id = 1 FOR SHARE;
-- 세션 1과 호환됨
```

### 튜플 락 대기

#### Lock Timeout

```sql
-- 락 대기 시간 설정 (기본값: 0 = 무한대기)
SET lock_timeout = '5s';

-- 5초 후에도 락을 얻지 못하면 에러 발생
SELECT * FROM users WHERE id = 1 FOR UPDATE;
-- ERROR: canceling statement due to lock timeout
```

#### NOWAIT Lock

```sql
-- 락을 즉시 얻을 수 없으면 바로 에러 발생
SELECT * FROM users WHERE id = 1 FOR UPDATE NOWAIT;
-- ERROR: could not obtain lock on row in relation "users"
```

### Deadlock

#### 데드락 개념 및 발생 원인

데드락은 두 개 이상의 트랜잭션이 서로가 가진 락을 기다리면서 무한 대기하는 상황입니다.

**데드락 발생 시나리오:**
```sql
-- 세션 1
BEGIN;
UPDATE users SET name = 'Alice' WHERE id = 1;  -- users 테이블의 행 1 락
-- 잠시 대기...

-- 세션 2  
BEGIN;
UPDATE users SET name = 'Bob' WHERE id = 2;    -- users 테이블의 행 2 락
UPDATE users SET name = 'Charlie' WHERE id = 1; -- 행 1 락 대기 (세션 1이 가짐)

-- 세션 1
UPDATE users SET name = 'David' WHERE id = 2;   -- 행 2 락 대기 (세션 2가 가짐)
-- DEADLOCK 발생!
```

#### 탐지 및 해소 방법

PostgreSQL은 자동으로 데드락을 탐지하고 해소합니다:

```sql
-- 데드락 발생 시 로그 확인
SELECT * FROM pg_stat_activity WHERE state = 'active';

-- 현재 락 상태 확인
SELECT 
    l.pid,
    l.mode,
    l.granted,
    a.query
FROM pg_locks l
JOIN pg_stat_activity a ON l.pid = a.pid
WHERE l.relation::regclass::text = 'users';
```

**데드락 방지 방법:**
```sql
-- 1. 일관된 순서로 락 획득
-- 항상 ID 순서대로 업데이트
UPDATE users SET name = 'Alice' WHERE id = 1;
UPDATE users SET name = 'Bob' WHERE id = 2;

-- 2. 트랜잭션 크기 최소화
BEGIN;
-- 필요한 작업만 수행
UPDATE users SET name = 'Alice' WHERE id = 1;
COMMIT;

-- 3. 락 타임아웃 설정
SET lock_timeout = '10s';
```

## 메모리 레벨 락 (Memory-Level Locks)

메모리 레벨 락은 PostgreSQL 내부에서 메모리 구조를 보호하기 위한 락들입니다. 각각 독립적인 목적과 특성을 가집니다.

### LWLocks (Lightweight Locks)

LWLocks는 **메모리 내 공유 데이터 구조**를 보호하는 경량 락입니다. 매우 짧은 시간 동안만 보유하며, PostgreSQL 내부 동기화에 사용됩니다.

**보호 대상:**
- **공유 메모리 세그먼트**: 프로세스 간 공유되는 메모리 영역
- **WAL 버퍼**: Write-Ahead Log 버퍼 영역
- **통계 정보**: 데이터베이스 통계 및 카운터
- **백그라운드 프로세스 상태**: autovacuum, checkpoint 등


### Spinlocks

Spinlocks는 **CPU 레벨의 최저 수준 동기화**를 위한 락입니다. CPU에서 직접 처리되며, 매우 짧은 시간 동안만 사용됩니다.

**보호 대상:**
- **카운터 변수**: 트랜잭션 ID, OID 생성기 등
- **플래그 변수**: 시스템 상태 플래그
- **링크드 리스트**: 메모리 할당/해제 관리
- **해시 테이블**: 내부 해시 구조체
- **세마포어**: 프로세스 간 신호 전달


### Buffer Pin Lock

Buffer Pin Lock은 **공유 버퍼의 특정 페이지**를 보호하는 락입니다. 페이지가 메모리에 고정되어 있는 동안 다른 프로세스가 해당 페이지를 수정하지 못하도록 합니다.

**보호 대상:**
- **데이터 페이지**: 테이블의 실제 데이터가 저장된 페이지
- **인덱스 페이지**: 인덱스 구조가 저장된 페이지
- **TOAST 페이지**: 큰 객체 데이터가 저장된 페이지
- **시스템 카탈로그 페이지**: 메타데이터 페이지
- **프리징된 페이지**: vacuum이나 analyze 중인 페이지

**동작 방식:**
1. 프로세스가 페이지를 읽을 때 **pin** (고정)
2. 다른 프로세스는 **pinned** 페이지에 쓰기 불가
3. 작업 완료 후 **unpin** (고정 해제)

```sql
-- 버퍼 사용량 확인
SELECT 
    schemaname,
    tablename,
    attname,
    n_distinct,
    correlation
FROM pg_stats 
WHERE tablename = 'users';
```

### WAL Buffer Lock

WAL Buffer Lock은 **Write-Ahead Log 버퍼**를 보호하는 락입니다. 트랜잭션의 안전성을 보장하기 위해 WAL 레코드가 디스크에 쓰이기 전까지 버퍼를 보호합니다.

**보호 대상:**
- **WAL 레코드**: 트랜잭션의 모든 변경사항
- **체크포인트 정보**: 시스템 복구를 위한 체크포인트
- **커밋 로그**: 트랜잭션 커밋/롤백 정보
- **시스템 카탈로그 변경**: DDL 작업의 로그
- **인덱스 변경**: 인덱스 생성/삭제 로그

**동작 방식:**
1. 트랜잭션이 데이터 변경 시 WAL 레코드 생성
2. WAL 버퍼에 레코드 저장 (락으로 보호)
3. 커밋 시 디스크에 WAL 파일 쓰기
4. 쓰기 완료 후 락 해제

```sql
-- WAL 통계 확인
SELECT 
    name,
    setting,
    unit
FROM pg_settings 
WHERE name LIKE '%wal%';
```

### 메모리 락 모니터링 방법 by pg_stat_activity

```sql
-- 현재 활성 세션과 락 상태 확인
SELECT 
    a.pid,
    a.usename,
    a.application_name,
    a.client_addr,
    a.state,
    a.query_start,
    a.query,
    l.mode,
    l.granted,
    l.relation::regclass::text as table_name
FROM pg_stat_activity a
LEFT JOIN pg_locks l ON a.pid = l.pid
WHERE a.state = 'active'
ORDER BY a.query_start;
```

## Lock 종류와 차이점 비교도표

| 락 종류 | 보호 대상 | 범위 | 지속시간 | 성능 영향 | 사용 사례 |
|---------|-----------|------|----------|-----------|-----------|
| **객체 락** | 테이블/인덱스 구조 | 테이블/인덱스 전체 | 트랜잭션 | 중간 | DDL 작업 |
| **행 락** | 특정 데이터 행 | 특정 행 | 트랜잭션 | 낮음 | DML 작업 |
| **LWLocks** | 공유 메모리 구조 | 메모리 세그먼트 | 짧음 | 매우 낮음 | 내부 동기화 |
| **Spinlocks** | CPU 레벨 변수 | 메모리 단위 | 매우 짧음 | 없음 | 최저 수준 동기화 |
| **Buffer Pin** | 공유 버퍼 페이지 | 페이지 단위 | 짧음 | 낮음 | 버퍼 관리 |
| **WAL Lock** | WAL 버퍼 영역 | 로그 버퍼 | 짧음 | 낮음 | 로그 쓰기 |

## pg_locks를 이용한 Lock 모니터링

### 기본 락 정보 조회

```sql
-- 현재 모든 락 상태 확인
SELECT 
    l.pid,
    l.mode,
    l.granted,
    l.relation::regclass::text as table_name,
    l.page,
    l.tuple,
    l.virtualxid,
    l.transactionid,
    l.classid,
    l.objid,
    l.objsubid
FROM pg_locks l
WHERE l.relation IS NOT NULL
ORDER BY l.pid, l.mode;
```

### 락 대기 상황 확인

```sql
-- 락을 기다리는 세션들 확인
SELECT 
    w.pid as waiting_pid,
    w.mode as waiting_mode,
    b.pid as blocking_pid,
    b.mode as blocking_mode,
    w.relation::regclass::text as table_name
FROM pg_locks w
JOIN pg_locks b ON w.relation = b.relation 
    AND w.mode != b.mode
WHERE NOT w.granted 
    AND b.granted
    AND w.relation IS NOT NULL;
```

### 데드락 위험 상황 확인

```sql
-- 데드락 가능성이 있는 세션들
WITH lock_chains AS (
    SELECT 
        pid,
        mode,
        relation,
        granted,
        -- 각 테이블별로 락을 기다리는 순서를 매김
        ROW_NUMBER() OVER (PARTITION BY relation ORDER BY pid) as rn
    FROM pg_locks 
    WHERE relation IS NOT NULL AND NOT granted
)
SELECT 
    l1.pid as first_waiting_pid,
    l1.mode as first_mode,
    l2.pid as second_waiting_pid,
    l2.mode as second_mode,
    l1.relation::regclass::text as table_name,
    '데드락 위험: 같은 테이블에서 서로 다른 락을 기다리는 세션들' as risk_description
FROM lock_chains l1
JOIN lock_chains l2 ON l1.relation = l2.relation 
    AND l1.pid < l2.pid
WHERE l1.rn = 1 AND l2.rn = 2;  -- 첫 번째와 두 번째 대기 세션만 조합
```


### 실용적인 락 모니터링 스크립트

```sql
-- 락 상황을 한눈에 보는 종합 쿼리
SELECT 
    'LOCK SUMMARY' as info,
    COUNT(*) as total_locks,
    COUNT(*) FILTER (WHERE granted) as granted_locks,
    COUNT(*) FILTER (WHERE NOT granted) as waiting_locks,
    COUNT(DISTINCT pid) as sessions_with_locks
FROM pg_locks
WHERE relation IS NOT NULL

UNION ALL

SELECT 
    'DEADLOCK INFO' as info,
    COUNT(*) as total_deadlocks,
    0 as granted_locks,
    0 as waiting_locks,
    0 as sessions_with_locks
FROM pg_stat_database
WHERE deadlocks > 0;
```

## 실무 팁

### 1. 락 최소화 전략

```sql
-- ❌ 나쁜 예: 긴 트랜잭션
BEGIN;
UPDATE users SET last_login = NOW() WHERE id = 1;
-- 다른 복잡한 작업들...
COMMIT;

-- ✅ 좋은 예: 짧은 트랜잭션
UPDATE users SET last_login = NOW() WHERE id = 1;
```

### 2. 인덱스 활용

```sql
-- 인덱스가 있으면 락 범위가 줄어듦
CREATE INDEX idx_users_email ON users(email);
UPDATE users SET name = 'John' WHERE email = 'john@example.com';
```


## 실무 설정 가이드

### 1. 락 타임아웃 설정

#### PostgreSQL 기본값
```sql
-- PostgreSQL의 실제 기본값
lock_timeout = 0               -- 무한대기 (타임아웃 없음)
```

#### 권장 기본 설정 (postgresql.conf)
```sql
-- 실무에서 권장하는 기본값
lock_timeout = '30s'           -- 30초 타임아웃 (무한대기 방지)
```

#### 세션별 동적 설정
```sql
-- 특정 세션에서만 다른 값 사용
SET lock_timeout = '10s';      -- 이 세션만 10초로 변경

-- 트랜잭션별 설정
BEGIN;
SET lock_timeout = '5s';       -- 이 트랜잭션만 5초로 변경
UPDATE users SET name = 'John' WHERE id = 1;
COMMIT;
```

#### 환경별 권장값
```sql
-- 웹 애플리케이션 환경
SET lock_timeout = '5s';       -- 빠른 응답 필요

-- 배치 작업 환경  
SET lock_timeout = '30m';      -- 긴 처리 시간 허용

-- 데이터 마이그레이션 환경
SET lock_timeout = '2h';       -- 매우 긴 처리 시간 허용
```

### 2. 데드락 타임아웃 설정

#### 기본 설정 (postgresql.conf)
```sql
-- 서버 전체 기본값 설정
deadlock_timeout = '1s'        -- PostgreSQL 기본값
```

#### 환경별 권장값
```sql
-- 높은 동시성 환경 (빠른 데드락 탐지)
deadlock_timeout = '500ms';

-- 복잡한 트랜잭션 환경 (여유 시간 필요)
deadlock_timeout = '5s';

-- 배치 처리 환경 (긴 트랜잭션 허용)
deadlock_timeout = '10s';
```

### 3. 최대 락 수 (max_locks_per_transaction)

- 하나의 트랜잭션이 동시에 락을 보유할 수 있는 객체 수를 설정합니다. 
- 테이블, 인덱스 등 락이 필요한 객체마다 슬롯을 소비하며, shared_buffers와 함께 관리됩니다.



#### 기본 설정 (postgresql.conf)
```sql
-- 서버 전체 기본값 설정
max_locks_per_transaction = 64     -- PostgreSQL 기본값
```

#### 환경별 권장값
```sql
-- 작은 테이블, 단순한 쿼리 환경
max_locks_per_transaction = 32;

-- 복잡한 조인, 많은 테이블 환경
max_locks_per_transaction = 128;

-- 대용량 데이터 마이그레이션 환경
max_locks_per_transaction = 512;
```

### 4. 락 모니터링 설정

#### 로그 설정 (postgresql.conf)
```sql
-- 락 타임아웃 로그
log_lock_waits = on

-- 데드락 로그
log_statement = 'all'  -- 모든 SQL 로그 (데드락 포함)

-- 락 대기 시간 임계값
log_min_duration_statement = 1000  -- 1초 이상 쿼리 로그
```

#### 모니터링 쿼리

- pg_stat_database의 deadlocks 컬럼은 해당 DB 전체 누적 데드락 횟수이며, 정기 모니터링 시에는 delta 증가 값 추적 필요
- 설정 단위는 '5s', '30min', '1h' 등 공식 문서 기준 단위로 통일 권장

```sql
-- 현재 락 대기 중인 세션만 필터링
SELECT 
    pid,
    usename,
    application_name,
    client_addr,
    state,
    wait_event_type,
    wait_event,
    query_start,
    query
FROM pg_stat_activity 
WHERE wait_event_type = 'Lock'
ORDER BY query_start;

-- 데드락 발생 횟수 및 블록 I/O 대기 시간 (누적 기준)
SELECT 
    datname,
    deadlocks,           -- 누적된 데드락 발생 횟수
    blk_read_time,       -- 디스크에서 읽기 대기로 소비된 시간(ms)
    blk_write_time       -- 디스크로 쓰기 대기로 소비된 시간(ms)
FROM pg_stat_database;
```

### 5. 성능 최적화 설정

#### 공유 버퍼 설정
```sql
-- 기본값: 128MB
shared_buffers = '256MB'       -- 작은 DB
shared_buffers = '1GB'         -- 중간 DB
shared_buffers = '4GB'         -- 대용량 DB (메모리의 25%)
```

#### 락 관련 메모리 설정
```sql
-- 락 테이블 크기
max_connections = 100          -- 기본값: 100
max_connections = 200          -- 높은 동시성 환경

-- 락 해시 테이블 크기
hash_mem_multiplier = 1.0      -- 기본값: 1.0
hash_mem_multiplier = 2.0      -- 복잡한 조인 환경
```

### 6. 케이스별 실무 설정 예시

#### 웹 애플리케이션 환경
```sql
-- postgresql.conf
lock_timeout = '5s'
deadlock_timeout = '1s'
max_locks_per_transaction = 64
log_lock_waits = on
shared_buffers = '256MB'
```

#### 배치 처리 환경
```sql
-- postgresql.conf
lock_timeout = '30m'
deadlock_timeout = '10s'
max_locks_per_transaction = 256
log_lock_waits = on
shared_buffers = '1GB'
```

#### 데이터 웨어하우스 환경
```sql
-- postgresql.conf
lock_timeout = '1h'
deadlock_timeout = '30s'
max_locks_per_transaction = 512
log_lock_waits = on
shared_buffers = '4GB'
hash_mem_multiplier = 2.0
```

### 7. 설정 변경 후 확인 방법

```sql
-- 현재 설정 확인
SHOW lock_timeout;
SHOW deadlock_timeout;
SHOW max_locks_per_transaction;

-- 설정 변경 후 재시작 필요 여부
SELECT name, setting, context 
FROM pg_settings 
WHERE name IN ('lock_timeout', 'deadlock_timeout', 'max_locks_per_transaction');
-- context가 'user'면 재시작 불필요
-- context가 'postmaster'면 재시작 필요
```















