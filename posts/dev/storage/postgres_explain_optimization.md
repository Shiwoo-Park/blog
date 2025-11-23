---
layout: post
title: "Postgres SQL 실행계획 분석 - 2부: 실전 최적화"
date: 2025-08-23
categories: [database, postgresql, optimization]
---

> **시리즈 목차**
> - [1부: 기본기](/blog/posts/dev/storage/postgres_explain_basics/)
> - **2부: 실전 최적화** (현재 문서)
> - [3부: 고급 주제](/blog/posts/dev/storage/postgres_explain_advanced/)

> **참고**: 예제 스키마는 [1부](/blog/posts/dev/storage/postgres_explain_basics/#예제-스키마-공통)를 참조하세요.

## 1) 실무 사례별 분석

### 1-1) WHERE 조건 최적화

**문제 상황**
- 두 개 이상의 조건을 동시에 사용하는 쿼리가 느림

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM orders WHERE user_id = 123 AND status='paid';
```

**예상 결과 (문제)**
```
Seq Scan on orders
  Filter: (user_id = 123 AND status = 'paid')
  Rows Removed by Filter: 99980  -- 대부분의 행을 버림
```

**해결: 복합 인덱스 생성**

```sql
CREATE INDEX idx_orders__user_id__status ON orders(user_id, status);
```

**개선 후 예상 결과**
```
Index Scan using idx_orders__user_id__status
  Index Cond: (user_id = 123 AND status = 'paid')
  Actual Rows: 5  -- 조건에 맞는 행만 빠르게 찾음
```

**체크포인트**
- `Seq Scan` → `Index Scan`으로 변경되었는지
- `Actual Rows`가 조건에 맞는 소수로 줄었는지
- `Rows Removed by Filter`가 사라졌는지

### 1-2) ORDER BY/LIMIT 최적화 (Top-N 쿼리)

**문제 상황**
- 최신 N개만 가져오는 쿼리인데 전체를 정렬함

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, ordered_at FROM orders
WHERE status='paid'
ORDER BY ordered_at DESC
LIMIT 20;
```

**예상 결과 (문제)**
```
Sort (cost=높음)
  Sort Key: ordered_at DESC
  -> Seq Scan on orders
      Filter: (status = 'paid')
```
- 전체를 스캔하고 정렬한 후 20개만 선택 (비효율)

**해결: 커버링 인덱스**

```sql
-- WHERE 조건 + 정렬 컬럼 + SELECT 컬럼을 모두 포함
CREATE INDEX idx_orders__status__ordered_at__cover
  ON orders(status, ordered_at DESC, id);
```

**개선 후 예상 결과**
```
Limit (cost=낮음)
  -> Index Only Scan using idx_orders__status__ordered_at__cover
      Index Cond: (status = 'paid')
```
- 인덱스에서 바로 정렬된 상태로 20개만 읽음
- `Sort` 노드 제거, I/O 급감

**핵심 포인트**
- 인덱스 순서: `WHERE 조건 → ORDER BY 컬럼 → SELECT 컬럼`
- `Index Only Scan`이 나오면 최적 상태

### 1-3) JOIN 최적화

**문제 상황**
- JOIN과 WHERE 조건이 함께 사용될 때

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT u.email, o.total_amount
FROM users u
JOIN orders o ON o.user_id = u.id
WHERE o.status='paid' AND o.ordered_at >= now() - interval '7 days';
```

**예상 결과**
```
Hash Join
  Hash Cond: (o.user_id = u.id)
  -> Seq Scan on orders
      Filter: (status = 'paid' AND ordered_at >= ...)
      Rows Removed by Filter: 99950  -- 대부분 버림
```

**문제점**
- `Hash Batches`나 `Disk` 발생 시 → 메모리 부족으로 디스크 사용 (느림)
- `Rows Removed by Filter`가 많음 → 불필요한 행을 많이 읽음

**해결: 조인 조건 + WHERE 조건을 포함한 인덱스**

```sql
CREATE INDEX idx_orders__status__ordered_at__user_id
  ON orders(status, ordered_at DESC, user_id);
```

**개선 후 효과**
- `Hash Build` 대상이 작아짐 (필터링된 행만 조인)
- `Rows Removed by Filter` 감소
- 메모리 사용량 감소 → `Disk` 발생 가능성 감소

### 1-4) GROUP BY/집계 최적화

**문제 상황**
- 날짜별 집계 쿼리가 느림

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT date_trunc('day', ordered_at) d, count(*)
FROM orders
WHERE status='paid'
GROUP BY 1
ORDER BY 1 DESC
LIMIT 7;
```

**개선 방법**

1. **인덱스 활용**
   ```sql
   CREATE INDEX idx_orders__status__ordered_at 
     ON orders(status, ordered_at DESC);
   ```
   - WHERE 조건과 GROUP BY에 사용되는 컬럼 포함

2. **물질화 뷰 (Materialized View)** - 상시 조회 시
   ```sql
   CREATE MATERIALIZED VIEW daily_order_stats AS
   SELECT date_trunc('day', ordered_at) d, count(*)
   FROM orders
   WHERE status='paid'
   GROUP BY 1;
   
   -- 주기적으로 갱신 (cron 등)
   REFRESH MATERIALIZED VIEW daily_order_stats;
   ```

3. **파티셔닝** - 대용량 테이블
   - 시간 기준으로 테이블 분할
   - 불필요한 파티션 스캔 제거 (pruning)



## 2) 자주 하는 실수

### ❌ Cost만 보고 판단
- Cost는 상대값일 뿐. `EXPLAIN ANALYZE`의 실제 시간을 봐야 함

### ❌ ANALYZE 소홀
- 통계 정보가 오래되면 → 잘못된 실행계획 선택
- 대용량 DML 후에는 수동으로 `ANALYZE` 실행

### ❌ 인덱스 선두 컬럼 순서 잘못 설계
- 인덱스: `(status, ordered_at)` 
- 쿼리: `WHERE ordered_at > ...` (status 없음)
- → 인덱스 사용 불가 (선두 컬럼이 WHERE에 없음)
- **해결**: 사용 패턴에 맞게 선두 컬럼 순서 결정


## 3) 실무 최적화 전략 체크리스트

### 인덱스 설계
1. **선두 컬럼 순서**: WHERE 조건 → ORDER BY → SELECT 컬럼 순서
2. **커버링 인덱스**: SELECT 컬럼까지 포함하면 `Index Only Scan` 가능 (가장 빠름)
3. **BRIN 인덱스**: 시간축이나 단조 증가 ID에 유리 (인덱스 크기 작음)

### 통계 관리
1. **주기적 ANALYZE**: `VACUUM ANALYZE` 또는 `auto_analyze` 설정 확인
2. **불균형 분포 컬럼**: `ALTER TABLE ... ALTER COLUMN ... SET STATISTICS 1000;`로 샘플 수 증가

### 파티셔닝
- 기간 기준 대용량 테이블에 유효
- **Pruning**: 불필요한 파티션 스캔 자동 제거

### 병렬 쿼리
- 전체 스캔이나 해시 집계가 큰 경우
- `max_parallel_workers_per_gather`, `parallel_tuple_cost` 등 튜닝


## 4) 미니 튜닝 전/후 예시

### 전: 느린 Top-N 쿼리

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, ordered_at 
FROM orders 
WHERE status='paid'
ORDER BY ordered_at DESC
LIMIT 20;
```

**실행계획 (문제)**
```
Limit (cost=1234.56..1234.78 rows=20)
  -> Sort (cost=1234.56..5678.90 rows=100000)
      Sort Key: ordered_at DESC
      -> Seq Scan on orders
          Filter: (status = 'paid')
          Rows Removed by Filter: 50000
          Planning Time: 0.123 ms
          Execution Time: 234.56 ms
          Buffers: shared read=1234  -- 디스크에서 많이 읽음
```

**문제점**
- 전체 테이블 스캔 (Seq Scan)
- 전체 정렬 후 20개만 선택
- 디스크 I/O 많음

### 후: 커버링 인덱스 도입

```sql
CREATE INDEX CONCURRENTLY idx_orders__status__ordered_at__cover
  ON orders(status, ordered_at DESC, id);

EXPLAIN (ANALYZE, BUFFERS)
SELECT id, ordered_at 
FROM orders 
WHERE status='paid'
ORDER BY ordered_at DESC
LIMIT 20;
```

**실행계획 (개선)**
```
Limit (cost=0.42..12.34 rows=20)
  -> Index Only Scan using idx_orders__status__ordered_at__cover
      Index Cond: (status = 'paid')
      Planning Time: 0.123 ms
      Execution Time: 2.34 ms  -- 100배 이상 개선!
      Buffers: shared hit=5  -- 메모리 캐시에서 읽음
```

**개선 효과**
- `Seq Scan` → `Index Only Scan` (테이블 접근 없음)
- `Sort` 노드 제거 (인덱스가 이미 정렬됨)
- 실행 시간: 234ms → 2ms (약 100배 개선)
- 디스크 I/O → 메모리 캐시 읽기



### 실무 점검 체크리스트 (요약)

- [ ] **인덱스 설계**: WHERE/JOIN/ORDER BY 패턴과 인덱스 선두 컬럼 일치
- [ ] **Top-N 쿼리**: LIMIT 사용 시 정렬열 선두 + 커버링 인덱스
- [ ] **통계 관리**: Rows(예상 vs 실제) 차이 크면 `ANALYZE` 실행
- [ ] **I/O 확인**: Buffers read 비율 높으면 I/O 병목 의심
- [ ] **모니터링**: `pg_stat_statements`로 상위 느린 쿼리 추적
- [ ] **문서화**: 전/후 지표 기록으로 재발 방지

---

> **이전**: [1부: 기본기](/blog/posts/dev/storage/postgres_explain_basics/)  
> **다음**: [3부: 고급 주제](/blog/posts/dev/storage/postgres_explain_advanced/)에서 CBO 원리와 도구 활용을 다룹니다.

