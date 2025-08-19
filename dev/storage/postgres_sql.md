# Postgres SQL - SQL 실행계획, CBO, 처리과정, 스캔방식

> 날짜: 2025-08-19

[목록으로](https://shiwoo-park.github.io/blog)

---

## 실행계획
### 정의 및 예시
### 실행계획 확인 및 쿼리 튜닝 방법

## PostgreSQL CBO(Cost Based Optimizer)가 Cost를 계산하는 기준

### 🔎 CBO가 Cost를 판단하는 핵심 개념

Postgres는 쿼리를 실행할 때 여러 **실행계획 후보**를 만들어두고, 각각의 비용(Cost)을 계산한 후 **가장 저렴한 플랜**을 고릅니다.
여기서 Cost는 절대값이 아니라 **상대값**이에요. 즉, “플랜 A가 B보다 몇 배 빠르다” 정도로만 쓰입니다.

---

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

---

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



---

[목록으로](https://shiwoo-park.github.io/blog)
