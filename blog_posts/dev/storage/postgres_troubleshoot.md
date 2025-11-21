---
layout: post
title: "PostgreSQL 트러블슈팅 실전 가이드"
date: 2025-11-18
categories: [database, postgresql, troubleshooting]
---

# PostgreSQL 트러블슈팅 실전 가이드

> 날짜: 2025-11-18

[목록으로](https://shiwoo-park.github.io/blog)

---

## 1. 🚨 긴급 조치: 문제 세션 종료

### 특정 PID 단건 종료

```sql
-- 쿼리만 취소 (안전, 트랜잭션 롤백하고 연결 유지)
SELECT pg_cancel_backend(12345);

-- 연결 강제 종료 (즉시 종료)
SELECT pg_terminate_backend(12345);
```

**결과 해석**: `t` (true) 반환 시 성공, `f` (false) 반환 시 해당 PID가 없거나 이미 종료됨.

### 여러 PID 한번에 종료

```sql
-- 예1: 오래 실행되는 쿼리들 일괄 종료
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE state != 'idle'
  AND NOW() - query_start > INTERVAL '10 minutes'
  AND pid != pg_backend_pid();  -- 현재 세션 제외

-- 예2: idle in transaction 세션들 일괄 종료
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE state = 'idle in transaction'
  AND NOW() - state_change > INTERVAL '5 minutes'
  AND pid != pg_backend_pid();

-- 예3: 특정 사용자의 모든 세션 종료
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE usename = 'problem_user'
  AND pid != pg_backend_pid();

-- 예4: 특정 데이터베이스의 모든 세션 종료
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = 'target_db'
  AND pid != pg_backend_pid();
```

**결과 해석**: 각 행마다 `t` 또는 `f` 반환. 종료된 PID 개수만큼 `t` 행이 출력됨.

**핵심**:

- `pg_cancel_backend`: 쿼리만 취소 (안전)
- `pg_terminate_backend`: 연결 강제 종료 (즉시 효과)
- 여러 건 종료 시 `pg_backend_pid()`로 **현재 세션은 반드시 제외**
- 프로덕션 환경에서는 신중하게 사용

---

## 2. 오래 실행 중인 쿼리 파악

### 오래 실행 중인 쿼리 목록 (5분 이상)

```sql
SELECT
  pid,
  usename,
  application_name,
  client_addr,
  state,
  query_start,
  NOW() - query_start as duration,
  query
FROM pg_stat_activity
WHERE state != 'idle'
  AND NOW() - query_start > INTERVAL '5 minutes'
ORDER BY query_start;
```

**결과 해석**:

- `pid`: 종료가 필요한 경우 이 값을 사용
- `duration`: `00:30:00` 형식으로 표시됨. 시간이 길수록 위험
- `state`: `active` (실행중), `idle in transaction` (트랜잭션 유지) 등
- `query`: 실제 실행 중인 SQL. 느린 쿼리 원인 파악 가능
- 결과가 없으면 문제 없음

### 현재 실행 중인 모든 활성 쿼리

```sql
SELECT
  pid,
  usename,
  datname,
  state,
  NOW() - query_start as duration,
  query
FROM pg_stat_activity
WHERE state = 'active'
  AND pid != pg_backend_pid()
ORDER BY query_start;
```

**결과 해석**:

- 실행 중인 모든 쿼리가 시간순으로 정렬됨
- `duration`이 큰 것부터 확인하여 비정상적으로 오래 걸리는 쿼리 파악
- 평소 빠른 쿼리가 오래 걸린다면 Lock 대기 중일 가능성

**핵심**: 오래 실행되는 쿼리는 성능 저하의 주범. duration이 비정상적으로 긴 쿼리는 조사 후 종료 검토.

---

## 3. Lock 및 블로킹 상황 진단

### 블로킹 관계 파악 (누가 누구를 블로킹하는지)

```sql
SELECT
  blocked.pid     AS blocked_pid,
  blocked.query   AS blocked_query,
  blocking.pid    AS blocking_pid,
  blocking.query  AS blocking_query,
  blocking.state  AS blocking_state,
  blocking.query_start
FROM pg_locks blocked_locks
JOIN pg_stat_activity blocked ON blocked_locks.pid = blocked.pid
JOIN pg_locks blocking_locks
  ON blocking_locks.locktype = blocked_locks.locktype
  AND blocking_locks.DATABASE IS NOT DISTINCT FROM blocked_locks.DATABASE
  AND blocking_locks.relation IS NOT DISTINCT FROM blocked_locks.relation
  AND blocking_locks.page IS NOT DISTINCT FROM blocked_locks.page
  AND blocking_locks.tuple IS NOT DISTINCT FROM blocked_locks.tuple
  AND blocking_locks.virtualxid IS NOT DISTINCT FROM blocked_locks.virtualxid
  AND blocking_locks.transactionid IS NOT DISTINCT FROM blocked_locks.transactionid
  AND blocking_locks.classid IS NOT DISTINCT FROM blocked_locks.classid
  AND blocking_locks.objid IS NOT DISTINCT FROM blocked_locks.objid
  AND blocking_locks.objsubid IS NOT DISTINCT FROM blocked_locks.objsubid
JOIN pg_stat_activity blocking ON blocking_locks.pid = blocking.pid
WHERE NOT blocked_locks.GRANTED;
```

**결과 해석**:

- `blocked_pid`: 대기 중인 세션 (피해자)
- `blocking_pid`: Lock을 잡고 있는 세션 (원인) → **이것을 종료해야 함**
- `blocking_query`: 원인 쿼리. 트랜잭션을 길게 유지하는 쿼리인지 확인
- `blocking_state`: `idle in transaction`이면 작업 없이 Lock만 유지 중 (즉시 종료 필요)
- 결과가 없으면 현재 블로킹 없음 (정상)

### Exclusive Lock 보유 중인 세션

```sql
SELECT
  a.pid,
  a.usename,
  a.query,
  a.query_start,
  l.relation::regclass AS locked_table,
  l.mode,
  a.state
FROM pg_locks l
JOIN pg_stat_activity a ON l.pid = a.pid
WHERE l.mode LIKE '%ExclusiveLock%'
  AND a.state != 'idle'
ORDER BY a.query_start;
```

**결과 해석**:

- `locked_table`: Lock이 걸린 테이블명
- `mode`: Lock 종류 (RowExclusiveLock, AccessExclusiveLock 등)
- `AccessExclusiveLock`은 가장 강력한 Lock으로 모든 작업 블로킹 (DDL 작업 시 발생)
- 오래 유지되는 Exclusive Lock은 서비스 장애 원인

### Lock 대기 중인 쿼리 조회

```sql
SELECT
  l.pid,
  l.mode,
  l.locktype,
  l.relation::regclass as table_name,
  a.query,
  a.state,
  NOW() - a.query_start as wait_time
FROM pg_locks l
JOIN pg_stat_activity a ON l.pid = a.pid
WHERE NOT l.GRANTED
ORDER BY a.query_start;
```

**결과 해석**:

- `GRANTED = false`: Lock을 얻지 못하고 대기 중인 쿼리들
- `wait_time`: 얼마나 오래 대기 중인지 확인
- `table_name`: 어느 테이블의 Lock을 기다리는지 확인
- 이 PID들은 피해자이므로 종료하지 말고, 블로킹 관계 쿼리로 원인 찾기

**핵심**: 블로킹 상황은 서비스 중단의 직접적 원인. **blocking_pid를 찾아 즉시 종료 조치**.

---

## 4. Idle in Transaction (위험!)

### Idle in Transaction 상태의 세션

```sql
SELECT
  pid,
  usename,
  application_name,
  client_addr,
  state,
  query_start,
  state_change,
  NOW() - state_change as idle_duration,
  query
FROM pg_stat_activity
WHERE state = 'idle in transaction'
ORDER BY state_change;
```

**결과 해석**:

- `idle in transaction`: 트랜잭션은 시작했지만 아무 작업도 하지 않는 상태
- `idle_duration`: 이 시간이 길수록 위험 (5분 이상이면 즉시 종료 검토)
- `query`: 마지막으로 실행한 쿼리 (이 쿼리의 Lock을 아직 보유 중)
- `application_name`: 어느 애플리케이션이 원인인지 파악 (코드 수정 필요)
- 결과가 많다면 애플리케이션의 트랜잭션 관리 문제

### 5분 이상 idle in transaction 세션 일괄 종료

```sql
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE state = 'idle in transaction'
  AND NOW() - state_change > INTERVAL '5 minutes'
  AND pid != pg_backend_pid();
```

**결과 해석**: 종료된 세션 수만큼 `t` 행이 출력됨.

**핵심**: 'idle in transaction' 상태가 오래 지속되면 Lock을 계속 보유하여 다른 쿼리 블로킹. **즉시 종료 검토**.

---

## 5. 빠른 체크리스트 ⚡

문제 발생 시 순차적으로 확인:

1. **오래 실행되는 쿼리** (섹션 2) → 5분 이상 실행 쿼리 확인 → PID 확인 후 종료 검토
2. **Lock 및 블로킹** (섹션 3) → 블로킹 관계 파악 → blocking_pid 종료
3. **Idle in transaction** (섹션 4) → 5분 이상 idle 세션 즉시 종료
4. **연결 수 확인** (섹션 6) → 최대치 근접 시 불필요한 연결 종료
5. **VACUUM 상태** (섹션 7) → dead tuple 비율 확인, 필요 시 수동 VACUUM
6. **캐시 히트율** (섹션 9) → 90% 미만이면 메모리 설정 검토
7. **디스크 공간** (섹션 8) → 80% 이상이면 로그/테이블 정리

---

## 6. 현재 연결 상태 확인

### 전체 연결 수 및 상태별 분류

```sql
SELECT
  state,
  COUNT(*) as connection_count
FROM pg_stat_activity
GROUP BY state
ORDER BY connection_count DESC;
```

**결과 해석**:

- `active`: 현재 쿼리 실행 중 (정상)
- `idle`: 대기 중 (정상)
- `idle in transaction`: 트랜잭션 유지 중 (많으면 문제)
- `idle in transaction (aborted)`: 실패한 트랜잭션 유지 중 (정리 필요)
- 각 상태의 정상 범위를 평소 모니터링으로 파악해두기

### 최대 연결 수 대비 현재 사용률

```sql
SELECT
  COUNT(*) as current_connections,
  (SELECT setting::int FROM pg_settings WHERE name = 'max_connections') as max_connections,
  ROUND(COUNT(*)::numeric / (SELECT setting::int FROM pg_settings WHERE name = 'max_connections') * 100, 2) as usage_percent
FROM pg_stat_activity;
```

**결과 해석**:

- `usage_percent`: 80% 이상이면 위험 (새 연결 실패 가능)
- 90% 이상이면 즉시 불필요한 연결 정리 필요
- 지속적으로 높다면 애플리케이션의 커넥션 풀 설정 검토

### 연결 수가 많은 사용자/데이터베이스

```sql
SELECT
  usename,
  datname,
  COUNT(*) as connection_count
FROM pg_stat_activity
WHERE state != 'idle'
GROUP BY usename, datname
ORDER BY connection_count DESC;
```

**결과 해석**:

- 어느 사용자/DB가 연결을 많이 사용하는지 확인
- 특정 애플리케이션이 비정상적으로 많은 연결 생성 중인지 파악
- 불필요한 연결이 많다면 해당 애플리케이션 재시작 검토

**핵심**: 연결 수가 max_connections에 근접하면 새 연결이 거부됨. 80% 이상이면 주의 필요.

---

## 7. VACUUM 및 테이블 상태 확인

### 테이블별 VACUUM/ANALYZE 상태

```sql
SELECT
  schemaname,
  relname,
  last_vacuum,
  last_autovacuum,
  last_analyze,
  last_autoanalyze,
  n_dead_tup,
  n_live_tup,
  ROUND(n_dead_tup::numeric / NULLIF(n_live_tup, 0) * 100, 2) as dead_tuple_ratio
FROM pg_stat_all_tables
WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
  AND n_dead_tup > 0
ORDER BY n_dead_tup DESC
LIMIT 20;
```

**결과 해석**:

- `n_dead_tup`: 삭제/업데이트로 생긴 dead tuple 수 (많을수록 성능 저하)
- `dead_tuple_ratio`: 20% 이상이면 VACUUM 필요
- `last_autovacuum`: 마지막 자동 VACUUM 시간. NULL이면 한번도 안됨 (문제)
- dead tuple이 많고 autovacuum이 오래 전이면 수동 VACUUM 실행

### VACUUM이 오래되거나 dead tuple이 많은 테이블

```sql
SELECT
  schemaname,
  relname,
  last_autovacuum,
  n_dead_tup,
  n_live_tup
FROM pg_stat_all_tables
WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
  AND (
    last_autovacuum < NOW() - INTERVAL '7 days'
    OR n_dead_tup > 10000
  )
ORDER BY n_dead_tup DESC;
```

**결과 해석**:

- 7일 이상 VACUUM이 안된 테이블 또는 dead tuple이 10000개 이상인 테이블
- 이런 테이블들은 수동 VACUUM 대상
- 결과가 많다면 autovacuum 설정 조정 필요

### 수동 VACUUM 실행

```sql
-- 일반 VACUUM (상세 로그 출력)
VACUUM VERBOSE ANALYZE table_name;

-- VACUUM FULL (테이블 재구성, 시간 오래 걸림)
VACUUM FULL VERBOSE ANALYZE table_name;
```

**결과 해석**:

- 실행 시간과 정리된 dead tuple 수가 출력됨
- VACUUM FULL은 테이블 Lock이 걸리므로 서비스 시간 외 실행 권장
- 실행 후 테이블 크기와 성능 개선 확인

**핵심**: dead tuple 비율이 20% 이상이면 성능 저하. VACUUM 실행 필요.

---

## 8. 데이터베이스 크기 및 테이블 크기

### 데이터베이스별 크기

```sql
SELECT
  datname,
  pg_size_pretty(pg_database_size(datname)) as size
FROM pg_database
ORDER BY pg_database_size(datname) DESC;
```

**결과 해석**:

- 크기가 큰 DB부터 정렬됨
- 급격한 증가가 있다면 어느 테이블이 커졌는지 확인 필요
- 디스크 여유 공간과 비교하여 용량 계획 수립

### 테이블별 크기 (인덱스 포함)

```sql
SELECT
  schemaname,
  tablename,
  pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as total_size,
  pg_size_pretty(pg_relation_size(schemaname||'.'||tablename)) as table_size,
  pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename) - pg_relation_size(schemaname||'.'||tablename)) as index_size
FROM pg_tables
WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC
LIMIT 20;
```

**결과 해석**:

- `total_size`: 테이블 + 인덱스 전체 크기
- `table_size`: 실제 데이터 크기
- `index_size`: 인덱스 크기
- index_size가 table_size보다 크면 인덱스 재검토 필요
- 큰 테이블들은 파티셔닝이나 아카이빙 검토

**핵심**: 디스크 공간 부족은 DB 장애의 주요 원인. 급격한 크기 증가 시 원인 파악 필요.

---

## 9. 캐시 히트율 확인

### 전체 캐시 히트율

```sql
SELECT
  'cache hit rate' as metric,
  ROUND(
    sum(blks_hit)::numeric / NULLIF(sum(blks_hit) + sum(blks_read), 0) * 100,
    2
  ) as percentage
FROM pg_stat_database;
```

**결과 해석**:

- `percentage`: 99% 이상이면 이상적
- 90-95%: 정상 범위
- 90% 미만: 메모리 부족 또는 쿼리 비효율
- 낮다면 `shared_buffers` 설정 증가 검토

### 테이블별 캐시 히트율

```sql
SELECT
  schemaname,
  relname,
  heap_blks_read + idx_blks_read as total_reads,
  heap_blks_hit + idx_blks_hit as total_hits,
  ROUND(
    (heap_blks_hit + idx_blks_hit)::numeric /
    NULLIF(heap_blks_hit + idx_blks_hit + heap_blks_read + idx_blks_read, 0) * 100,
    2
  ) as cache_hit_ratio
FROM pg_statio_user_tables
WHERE (heap_blks_read + idx_blks_read) > 0
ORDER BY cache_hit_ratio
LIMIT 20;
```

**결과 해석**:

- 캐시 히트율이 낮은 테이블부터 정렬됨
- 자주 조회되는 테이블의 히트율이 낮다면 문제
- 큰 테이블의 full scan이 원인일 수 있음 (인덱스 추가 검토)

**핵심**: 캐시 히트율이 90% 미만이면 shared_buffers 증가 또는 쿼리 최적화 검토.

---

## 10. 인덱스 사용률 및 효율성

### 사용되지 않는 인덱스 찾기

```sql
SELECT
  schemaname,
  tablename,
  indexname,
  idx_scan,
  idx_tup_read,
  idx_tup_fetch,
  pg_size_pretty(pg_relation_size(indexrelid)) as index_size
FROM pg_stat_user_indexes
WHERE idx_scan = 0
  AND schemaname NOT IN ('pg_catalog', 'information_schema')
ORDER BY pg_relation_size(indexrelid) DESC;
```

**결과 해석**:

- `idx_scan = 0`: 한번도 사용되지 않은 인덱스
- `index_size`: 불필요한 인덱스가 차지하는 공간
- 크기가 큰 미사용 인덱스부터 삭제 검토
- Primary Key, Unique 제약은 제외하고 판단
- 통계 초기화 후 시간이 지나지 않았다면 결과 신뢰도 낮음

### 인덱스 효율성 분석

```sql
SELECT
  schemaname,
  tablename,
  indexname,
  idx_scan,
  idx_tup_read,
  idx_tup_fetch,
  CASE
    WHEN idx_tup_read = 0 THEN 0
    ELSE ROUND((idx_tup_fetch::numeric / idx_tup_read) * 100, 2)
  END as fetch_ratio
FROM pg_stat_user_indexes
WHERE schemaname NOT IN ('pg_catalog', 'information_schema')
  AND idx_scan > 0
ORDER BY idx_scan DESC
LIMIT 20;
```

**결과 해석**:

- `idx_scan`: 인덱스가 사용된 횟수 (많을수록 중요한 인덱스)
- `fetch_ratio`: 인덱스 효율성 (높을수록 좋음)
- ratio가 낮으면 인덱스를 읽었지만 실제 데이터는 적게 가져온 것 (비효율)
- 자주 사용되지만 효율이 낮은 인덱스는 재설계 검토

**핵심**: 사용되지 않는 인덱스는 쓰기 성능 저하 원인. fetch_ratio가 낮으면 인덱스 효율성 검토 필요.

---

## 11. 복제(Replication) 상태 확인

### 복제 지연 확인 (Primary 서버)

```sql
SELECT
  client_addr,
  state,
  sync_state,
  pg_wal_lsn_diff(pg_current_wal_lsn(), sent_lsn) as send_lag_bytes,
  pg_wal_lsn_diff(sent_lsn, write_lsn) as write_lag_bytes,
  pg_wal_lsn_diff(write_lsn, flush_lsn) as flush_lag_bytes,
  pg_wal_lsn_diff(flush_lsn, replay_lsn) as replay_lag_bytes
FROM pg_stat_replication;
```

**결과 해석**:

- `client_addr`: Replica 서버 주소
- `state`: `streaming`이면 정상, `catchup`이면 따라잡는 중
- `sync_state`: `async` (비동기), `sync` (동기), `potential` (동기 대기)
- 각 `lag_bytes`: 바이트 단위 지연량
  - 모두 0이면 완벽한 동기화 상태
  - 수 MB 이하면 정상 범위
  - 수십 MB 이상이면 네트워크 또는 Replica 성능 문제
- Replica가 보이지 않으면 복제가 끊어진 상태 (긴급)

### Replication Slot 상태

```sql
SELECT
  slot_name,
  slot_type,
  database,
  active,
  pg_wal_lsn_diff(pg_current_wal_lsn(), restart_lsn) as lag_bytes,
  pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), restart_lsn)) as lag_size
FROM pg_replication_slots
ORDER BY lag_bytes DESC;
```

**결과 해석**:

- `active = false`: 연결되지 않은 Slot (WAL 파일 계속 쌓임, 위험)
- `lag_bytes`: Slot이 소비하지 못한 WAL 크기
- 비활성 Slot이 있고 lag가 크면 디스크 가득 찰 수 있음
- 불필요한 Slot은 `SELECT pg_drop_replication_slot('slot_name')` 로 삭제

**핵심**: 복제 지연이 크면 failover 시 데이터 손실 위험. 비활성 slot은 WAL 파일 증가 원인.

---

## 12. 기타 유용한 명령어

### 준비된 트랜잭션 확인

```sql
SELECT
  gid,
  prepared,
  owner,
  database,
  NOW() - prepared as age
FROM pg_prepared_xacts
ORDER BY prepared;
```

**결과 해석**:

- 2PC (Two-Phase Commit)로 준비된 트랜잭션 목록
- `age`: 준비된 후 경과 시간
- 오래된 준비 트랜잭션은 Lock을 유지하므로 문제
- 수동으로 `COMMIT PREPARED` 또는 `ROLLBACK PREPARED` 필요
- 일반적으로 결과가 없어야 정상

### 통계 정보 초기화 (필요 시)

```sql
-- 전체 통계 초기화
SELECT pg_stat_reset();

-- 특정 테이블 통계 초기화
SELECT pg_stat_reset_single_table_counters('table_name'::regclass);
```

**결과 해석**:

- 성공 시 아무 값도 반환하지 않음
- 초기화 후 통계는 다시 누적되기 시작
- 성능 측정 전 기준점으로 사용
- 프로덕션에서는 신중하게 (기존 통계 손실)

**핵심**: 성능 측정 전 기준점 설정 시 사용. 프로덕션에서는 주의.

---

[목록으로](https://shiwoo-park.github.io/blog)
