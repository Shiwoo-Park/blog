---
layout: post
title: "Postgres SQL 실행계획 분석 - 1부: 기본기"
date: 2025-08-23
categories: [database, postgresql, optimization]
---

> **시리즈 목차**
> - **1부: 기본기** (현재 문서)
> - [2부: 실전 최적화](/blog/posts/dev/storage/postgres_explain_optimization/)
> - [3부: 고급 주제](/blog/posts/dev/storage/postgres_explain_advanced/)

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

느린 쿼리의 원인은 대부분:
- **잘못된 접근 경로**: 전체 테이블 스캔, 비효율적인 조인 순서
- **부정확한 통계**: 옵티마이저가 잘못된 판단을 내림

실행계획은 "왜 느린가?"를 **수치와 경로로** 보여줍니다.

## 2) EXPLAIN / EXPLAIN ANALYZE 기본기

### 차이점
- `EXPLAIN`: 계획만 추정 (실제 실행 안 함)
- `EXPLAIN ANALYZE`: 실제 실행 + 시간/행수 포함 (실무 필수)

### 기본 사용법

```sql
EXPLAIN (ANALYZE, BUFFERS) 
SELECT * FROM orders WHERE status='paid' ORDER BY ordered_at DESC LIMIT 20;
```

**옵션 설명**
- `ANALYZE`: 실제 실행하여 정확한 시간 측정
- `BUFFERS`: 캐시/디스크 I/O 정보 표시

### 읽는 포인트

1. **Actual Rows vs Plan Rows**
   - Plan Rows: 옵티마이저 예상 행 수
   - Actual Rows: 실제 반환된 행 수
   - 차이가 크면 → 통계 정보 문제 (ANALYZE 필요)

2. **Buffers**
   - `shared hit`: 메모리 캐시에서 읽음 (빠름)
   - `shared read`: 디스크에서 읽음 (느림)
   - read 비율이 높으면 → I/O 병목

3. **Timing**
   - 상단 노드(들여쓰기 적은 부분)가 전체 시간의 대부분을 차지하는지 확인
   - 병목 지점을 찾는 핵심


## 3) 자주 등장하는 노드 빠르게 읽기

### Scan 종류

**Seq Scan (Sequential Scan)**
- 전체 테이블을 처음부터 끝까지 읽음
- 인덱스가 없거나, 조건이 너무 넓어서 인덱스보다 전체 스캔이 빠를 때 사용
- 대용량 테이블에서는 느림

**Index Scan**
- 인덱스를 먼저 찾고, 해당하는 테이블 행을 읽음
- 조건에 맞는 행이 적을 때 유리
- 랜덤 I/O 발생 (인덱스 → 테이블 이동)

**Index Only Scan** ⭐ (가장 빠름)
- 필요한 컬럼이 모두 인덱스에 포함되어 있으면 테이블 접근 생략
- "커버링 인덱스"라고도 함
- I/O가 가장 적음

### Join 종류

**Nested Loop**
- 작은 테이블 × 인덱스가 잘 갖춰진 경우 유리
- 외부 테이블이 작고, 내부 테이블에 인덱스가 있을 때

**Hash Join**
- 중간 규모 이상 JOIN의 기본
- 한쪽 테이블을 해시 테이블로 만들어서 조인
- `Hash Batches`나 `Disk` 발생 시 메모리 부족 신호

**Merge Join**
- 양쪽 테이블이 정렬되어 있을 때 사용
- 정렬된 상태에서 병합하듯이 조인



## 4) 실행계획에서 꼭 볼 지표

### Cost (비용)
- **startup cost**: 첫 번째 행을 반환하기까지의 비용
- **total cost**: 전체 실행 비용
- ⚠️ **주의**: 절대 시간이 아님. 상대적 비교용. `EXPLAIN ANALYZE`의 실제 시간이 더 중요

### Rows (행 수)
- **Plan Rows**: 옵티마이저가 예상한 행 수
- **Actual Rows**: 실제 반환된 행 수
- **차이가 크면**: 통계 정보 오래됨 → `ANALYZE` 실행 필요

### Width (행 크기)
- 평균 행 크기 (바이트)
- 클수록 → I/O 증가 → 느림

### Buffers (I/O)
- **shared hit**: 메모리 캐시에서 읽음 (빠름)
- **shared read**: 디스크에서 읽음 (느림)
- **read 비율이 높으면**: I/O 병목 → 인덱스나 메모리 튜닝 필요

### Timing (실행 시간)
- `EXPLAIN ANALYZE`에서만 표시
- 상단 노드(들여쓰기 적은 부분)가 전체 시간의 대부분을 차지하는지 확인
- 병목 지점을 찾는 핵심 지표


---

> **다음**: [2부: 실전 최적화](/blog/posts/dev/storage/postgres_explain_optimization/)에서 실무 쿼리 최적화 사례를 다룹니다.

