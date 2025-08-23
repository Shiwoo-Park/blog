# Postgres SQL - 실무에서 쓰기 좋은 실행계획 분석 및 활용법

> 날짜: 2025-08-23

[목록으로](https://shiwoo-park.github.io/blog)

---

## 예제 스키마 (공통)

```sql
-- 주문/고객 간단 스키마
CREATE TABLE users (
  id BIGSERIAL PRIMARY KEY,
  email TEXT UNIQUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE orders (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users(id),
  status TEXT NOT NULL,                 -- 'paid', 'refund', ...
  total_amount NUMERIC(12,2) NOT NULL,  -- 합계 금액
  ordered_at TIMESTAMPTZ NOT NULL
);

-- 인덱스
CREATE INDEX idx_orders__user_id ON orders(user_id);
CREATE INDEX idx_orders__status__ordered_at ON orders(status, ordered_at DESC);
CREATE INDEX idx_orders__ordered_at ON orders(ordered_at DESC);
```


## 1) 들어가며: 실행계획이 왜 중요한가

* 느린 쿼리는 대부분 **잘못된 접근 경로(Scan/Join/Sort)** 또는 **부정확한 통계**에서 시작합니다.
* 실행계획은 “왜 이렇게 느린가?”를 **수치와 경로로** 보여줍니다.


## 2) EXPLAIN / EXPLAIN ANALYZE 기본기

* `EXPLAIN` = 계획만 추정, `EXPLAIN ANALYZE` = 실제 실행 + 시간/행수 포함.
* 실무에선 보통:

```sql
EXPLAIN (ANALYZE, BUFFERS) 
SELECT * FROM orders WHERE status='paid' ORDER BY ordered_at DESC LIMIT 20;
```

**포인트**

* `Actual Rows` vs `Plan Rows` 차이(카디널리티 오차)
* `Buffers: shared hit/read`(캐시 적중/디스크 I/O)
* 상단 노드가 전체 시간의 대부분을 먹는지 확인


## 3) 자주 등장하는 노드 빠르게 읽기

* **Seq Scan**: 전체 테이블 훑기. 조건 선택도가 낮거나 인덱스 없을 때.
* **Index Scan**: 조건 컬럼 인덱스 활용. 랜덤 I/O 증가 가능.
* **Index Only Scan**: 필요한 컬럼이 모두 인덱스에 있으면 테이블 접근 생략(커버링).
* **Nested Loop**: 소량 + 인덱스 적합 시 유리.
* **Hash Join**: 중간 규모 이상 JOIN 기본기. 해시 빌드 메모리/디스크 확인.
* **Merge Join**: 양쪽이 정렬(또는 정렬 가능)일 때 강력.


## 4) 실무 사례별 분석

### 4-1) WHERE 조건 최적화

문제 쿼리:

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM orders WHERE user_id = 123 AND status='paid';
```

개선 팁:

* 다중 조건 빈도가 높다면 **복합 인덱스** 고려:

```sql
CREATE INDEX idx_orders__user_id__status ON orders(user_id, status);
```

체크포인트:

* Index Scan으로 바뀌고 `Actual Rows`가 조건에 맞는 소수로 줄었는지 확인.

### 4-2) ORDER BY/LIMIT 최적화

문제 쿼리:

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, ordered_at FROM orders
WHERE status='paid'
ORDER BY ordered_at DESC
LIMIT 20;
```

개선 인덱스(커버링 지향):

```sql
-- 정렬열이 선두가 되도록 설계하면 Top-N 빠름
CREATE INDEX idx_orders__status__ordered_at__cover
  ON orders(status, ordered_at DESC, id);
```

효과:

* `Index Scan Backward` 또는 `Index Only Scan`으로 `Sort` 제거/축소.
* `LIMIT`과 잘 맞아 I/O 급감.

### 4-3) JOIN 순서/방법

문제 쿼리:

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT u.email, o.total_amount
FROM users u
JOIN orders o ON o.user_id = u.id
WHERE o.status='paid' AND o.ordered_at >= now() - interval '7 days';
```

체크:

* `Hash Join`이 일반적. `Hash` 빌드가 어느 테이블에서 일어나는지, `Hash Batches`/`Disk` 발생 확인.
  개선:

```sql
-- 조인에 자주 쓰이는 조건 인덱스 강화
CREATE INDEX idx_orders__status__ordered_at__user_id
  ON orders(status, ordered_at DESC, user_id);
```

효과:

* `Hash Build` 대상이 작아지고, `Rows Removed by Filter` 감소.

### 4-4) GROUP BY/COUNT

문제 쿼리:

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT date_trunc('day', ordered_at) d, count(*)
FROM orders
WHERE status='paid'
GROUP BY 1
ORDER BY 1 DESC
LIMIT 7;
```

개선 후보:

* 시간 파티셔닝(대용량), `status, ordered_at` 복합 인덱스,
* 상시 조회라면 **물질화 뷰**로 일일 집계 캐시.



## 5) 실행계획에서 꼭 볼 지표

* **Cost (startup/total)**: 플래너의 상대적 추정치. 절대시간 아님.
* **Rows (예상 vs 실제)**: 큰 차이면 **통계 갱신/히스토그램** 문제 가능.
* **Width**: 평균 행 크기. 폭이 클수록 I/O 증가.
* **Buffers**: `read`(디스크) 비중이 높으면 I/O 병목 신호.
* **Timing**: 어느 노드가 전체의 병목인지 상단에서부터 확인.


## 6) 자주 하는 실수

* Cost만 보고 좋다/나쁘다 판단.
* `ANALYZE` 소홀 → 카디널리티 오차로 잘못된 플랜 선택.
* 다중 컬럼 인덱스 **선두 컬럼 순서**를 사용 패턴과 다르게 설계.


## 7) 실무 최적화 전략 체크리스트

* **인덱스 설계**
  * 조건/정렬/조인을 함께 고려해 **선두 컬럼 순서** 결정.
  * 읽는 컬럼까지 포함해 **커버링**(Index Only Scan) 노리기.
  * 광범위 범위 스캔은 **BRIN**(시간축/단조 증가 id)에 유리.

* **통계 관리**
  * 주기적 `VACUUM (ANALYZE)` 또는 `auto_analyze` 확인.
  * 분포 불균형 컬럼은 `ALTER TABLE ... ALTER COLUMN ... SET STATISTICS N;`로 샘플 업.

* **파티셔닝**
  * 기간 기준 대용량 테이블에 유효. **pruning**으로 불필요 스캔 제거.

* **Parallel Query**
  * 전체 스캔/해시 집계가 큰 경우 `max_parallel_workers_per_gather`/`parallel_tuple_cost` 등 점검.


## 8) 도구 활용

* **pg\_stat\_statements**: 상위 느린/빈번 쿼리 식별

```sql
SELECT query, calls, total_time, mean_time
FROM pg_stat_statements
ORDER BY total_time DESC
LIMIT 20;
```

* **auto\_explain**: 느린 쿼리 자동 계획 로깅

```sql
-- postgresql.conf 예시
shared_preload_libraries = 'pg_stat_statements,auto_explain'
auto_explain.log_min_duration = '200ms'
auto_explain.log_analyze = on
auto_explain.log_buffers = on
```

* **시각화**: EXPLAIN.depesz, Dalibo PEV로 노드/비용 트리 가독성↑


## 9) 마무리: 루틴화 팁

1. `pg_stat_statements`로 후보 찾기 →
2. `EXPLAIN (ANALYZE, BUFFERS)`로 병목 노드 확인 →
3. **인덱스/쿼리/통계** 순으로 개선 →
4. 전/후 수치(시간, Buffers, Rows) 기록 및 공유.


## 부록) 미니 튜닝 전/후 예시

### 전: 느린 Top-N

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT id, ordered_at 
FROM orders 
WHERE status='paid'
ORDER BY ordered_at DESC
LIMIT 20;
/*
Sort (cost: 높음) -> Seq Scan orders
Actual ... Buffers: read 다수, time 수백 ms
*/
```

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
/*
Index Only Scan using idx_orders__status__ordered_at__cover
Actual time: 수 ms, Buffers hit 위주, Sort 제거
*/
```



### 실무 점검 체크리스트 (요약)

* [ ] WHERE/JOIN/ORDER BY 패턴과 인덱스 선두 컬럼 일치
* [ ] LIMIT Top-N은 **정렬열 선두 + 커버링**
* [ ] Rows(예상 vs 실제) 큰 차이면 ANALYZE/통계 조정
* [ ] Buffers read 비율↑ = I/O 병목 의심
* [ ] 상위 느린 쿼리: `pg_stat_statements`로 상시 추적
* [ ] 재발 방지: 전/후 지표 남기고 회고

---


## CBO(Cost Based Optimizer)가 Cost를 계산하는 기준

### 🔎 CBO가 Cost를 판단하는 핵심 개념

Postgres는 쿼리를 실행할 때 여러 **실행계획 후보**를 만들어두고, 각각의 비용(Cost)을 계산한 후 **가장 저렴한 플랜**을 고릅니다.
여기서 Cost는 절대값이 아니라 **상대값**이에요. 즉, “플랜 A가 B보다 몇 배 빠르다” 정도로만 쓰입니다.


### 1. Cost 판단 기준 (실무 포인트)

#### (1) **통계 정보 (Statistics)**

* `ANALYZE`로 테이블/컬럼 통계 수집 → 옵티마이저는 **행 개수(rows), 데이터 분포, null 비율, 상관관계** 등을 추정합니다.
* 통계가 오래되면 → 잘못된 rows 추정 → 잘못된 실행계획 선택.
* **실무 팁**: 대용량 insert/update 이후엔 `ANALYZE` 실행 필수.
  (autovacuum만 믿지 말고 batch 작업 후 수동으로 돌려주기)

#### (2) **플래너 비용 파라미터 (GUC 설정)**

Postgres는 CPU와 I/O 비용을 아래 값으로 단순화해서 계산합니다:

* `seq_page_cost`: 순차 페이지 읽기 비용 (기본 1.0)
* `random_page_cost`: 랜덤 페이지 읽기 비용 (기본 4.0 → SSD 환경이면 1.1\~1.5 권장)
* `cpu_tuple_cost`: 튜플 처리 비용
* `cpu_index_tuple_cost`: 인덱스 튜플 처리 비용
* `effective_cache_size`: OS 캐시 메모리 크기 추정치 (커야 인덱스 플랜 선호↑)

👉 **실무 팁**:

* SSD 환경이라면 `random_page_cost` 낮추면 인덱스 스캔을 더 잘 씁니다.
* `effective_cache_size`는 실제 서버 RAM의 50\~75% 정도로 설정.
* CPU 비용은 보통 손대지 않고, I/O 관련 값만 조정하는 경우가 많음.

#### (3) **행 개수 추정 (Cardinality)**

* `조건(selectivity)` × `총 행 수` = 예상 반환 row 수
* 조인 시: `(outer_rows × inner_rows) × 선택도`
* rows 추정이 빗나가면 → 해시 조인 대신 중첩 루프 선택 같은 문제 발생.

👉 **실무 팁**:

* `EXPLAIN (ANALYZE)`로 **예상 rows vs 실제 rows** 비교 → 오차 크면 통계 개선 필요.

### 2. Cost 계산 과정 (간단하게)

플랜 노드별로 다음을 합산합니다:

```
(읽어야 할 페이지 수 × 페이지 비용)
+ (처리할 튜플 수 × CPU 비용)
+ (정렬/해시/병렬 등 추가 비용)
```

모든 후보 플랜 중 **total cost가 가장 낮은 것** 선택.


### 3. 실무 적용 체크리스트 ✅

1. **통계 최신화**

   * 대규모 DML 후 `ANALYZE` → 쿼리 성능 급변 방지.
2. **환경 반영한 비용 조정**

   * SSD라면 `random_page_cost = 1.1~1.5`
   * 메모리 크기에 맞게 `effective_cache_size` 튜닝.
3. **실행계획 검증 루틴**

   * `EXPLAIN (ANALYZE, BUFFERS)`로 예상 vs 실제 rows 오차 확인.
   * rows 예측 실패 → `CREATE STATISTICS` (다중 컬럼 상관, distinct 값 등) 고려.
4. **Prepared Statement 주의**

   * 반복 쿼리는 `PREPARE`로 빠르게.
   * 단, 조건 값에 따라 rows 편차가 큰 쿼리는 *custom plan 강제* 필요할 수도 있음 (`plan_cache_mode=force_custom_plan`).

## 🔑 요약

* **CBO는 통계 + 비용 파라미터(GUC) + 선택도**를 바탕으로 실행계획 비용을 계산.
* **SSD, 캐시 환경 반영** → `random_page_cost`, `effective_cache_size`를 꼭 조정.
* **실행계획 검증 루틴**을 두고 rows 오차가 크면 `ANALYZE`·`CREATE STATISTICS`로 보정.
* Cost 값은 절대 성능이 아니라 “비교 기준”일 뿐. **EXPLAIN ANALYZE가 최종 진실**.





[목록으로](https://shiwoo-park.github.io/blog)
