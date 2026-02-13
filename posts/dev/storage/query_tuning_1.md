---
layout: post
title: "PostgreSQL 쿼리 튜닝 실전: 실행계획과 pg_stat_user_indexes로 병목 잡기"
date: 2026-02-13
categories: [database, postgresql, optimization]
description: "메인홈 150ms 쿼리를 실행계획과 pg_stat_user_indexes로 분석해 복합 인덱스로 개선한 실무 사례. LATERAL+LIMIT, Top-N 최적화, 인덱스 설계 의사결정 과정을 정리합니다."
keywords: "PostgreSQL, 쿼리튜닝, 실행계획, pg_stat_user_indexes, 인덱스, LATERAL, Top-N"
image: "/resources/og-dev.png"
---

실무에서 “이 쿼리가 정상인가?”부터 시작해, 실행계획과 `pg_stat_user_indexes`를 함께 보며 병목을 찾고 인덱스를 정리한 과정을 정리한 글입니다.

---

## 1. 문제 상황

- **증상**: 메인홈 첫 진입 시 특정 쿼리가 약 **150ms** 소요
- **데이터 규모**: topic 13개, posts 약 22만 건 (전체 229,229건 중 필터 조건 통과 약 196,736건)
- **의문**: “이 정도면 느린 건가?” → 원인 분석으로 이어짐

### 1-1. 기존 쿼리

요구사항은 “선택한 topic별로 최신 글 4개씩”을 가져오는 것이고, 기존에는 **ROW_NUMBER() + PARTITION BY** 로 구현되어 있었습니다.

```sql
SELECT
  id
FROM
  (
    SELECT
      ROW_NUMBER() OVER (
        PARTITION BY topic_id
        ORDER BY id DESC
      ) AS no,
      *
    FROM posts
    WHERE is_notice = false
      AND is_deleted = false
      AND is_blinded = false
      AND is_use = true
      AND topic_id IN (2, 34, 265, 1, 595, 3, 5, 694, 100)
  ) posts
WHERE posts.no <= 4
ORDER BY id DESC;
```

### 1-2. 기존 쿼리 실행계획

```text
Sort  (cost=61811.91..62277.57 rows=186265 width=4)
  Sort Key: posts.id DESC
  ->  Subquery Scan on posts  (cost=37371.26..42959.21 rows=186265 width=4)
        ->  WindowAgg  (cost=37371.26..41096.56 rows=186265 width=743)
              Run Condition: (row_number() OVER (?) <= 4)
              ->  Sort  (cost=37371.26..37836.92 rows=186265 width=8)
                    Sort Key: posts_1.topic_id, posts_1.id DESC
                    ->  Seq Scan on posts posts_1  (cost=0.02..18518.55 rows=186265 width=8)
                          Filter: ((NOT is_notice) AND (NOT is_deleted) AND (NOT is_blinded) AND is_use AND (topic_id = ANY ('{2,34,265,1,595,3,5,694,100}'::integer[])))
```

- **Seq Scan** → 조건에 맞는 약 18만 행 스캔 후 **Sort(topic_id, id DESC)** → **WindowAgg** → 다시 **Sort(id DESC)** 까지 두 번의 정렬이 발생합니다.

---

## 2. 실행계획으로 병목 찾기

### 2-1. 기존 실행계획에서 보인 점

위 실행계획에서 드러나는 문제는 다음과 같습니다.

- **Seq Scan**: `topic_id IN (...)` 와 4개의 boolean 조건으로만 필터하므로, 옵티마이저가 전체 스캔을 선택함. `topic_id` 단일 인덱스가 있어도 정렬을 못 맡기 때문에 비용상 불리할 수 있음.
- **이중 Sort**: (1) `topic_id, id DESC` 로 정렬 후 WindowAgg, (2) 최종 결과를 다시 `id DESC` 로 정렬 → 대량 행에 대한 정렬이 두 번 발생.
- **WindowAgg**: topic별 상위 4개를 구하기 위해 파티션 전체를 읽고 정렬한 뒤 잘라내는 구조라, “topic당 4개만 읽으면 되는” 최적화가 되지 않음.

정리하면, **“topic으로 필터만 하고, 정렬·Top-N은 인덱스가 도와주지 못하는”** 구조였습니다.

### 2-2. 개선 방향: 쿼리 변경 + 복합 인덱스

동일 요구사항(topic별 최신 4개)을 **LATERAL + LIMIT** 로 바꾸면, topic마다 “해당 topic에서 id DESC 순 4개만” 읽으면 됩니다. 이때 `(topic_id, id DESC)` 복합 인덱스가 있으면 정렬 없이 Top-N만 스캔할 수 있습니다.

**개선한 쿼리**

```sql
SELECT p.id
FROM topics t
JOIN LATERAL (
  SELECT id
  FROM posts
  WHERE topic_id = t.id
    AND is_notice = false
    AND is_deleted = false
    AND is_blinded = false
    AND is_use = true
  ORDER BY id DESC
  LIMIT 4
) p ON true
WHERE t.id IN (2, 34, 265, 1, 595, 3, 5, 694, 100)
ORDER BY id DESC;
```

**개선한 쿼리 실행계획**

```text
Sort  (cost=126.88..126.97 rows=36 width=4)
  Sort Key: posts.id DESC
  ->  Nested Loop  (cost=0.44..125.94 rows=36 width=4)
        ->  Seq Scan on topics t  (cost=0.02..3.43 rows=9 width=4)
              Filter: (id = ANY ('{2,34,265,1,595,3,5,694,100}'::integer[]))
        ->  Limit  (cost=0.42..13.53 rows=4 width=4)
              ->  Index Scan using idx_posts__topic_id__id_desc on posts  (cost=0.42..37126.71 rows=11325 width=4)
                    Index Cond: (topic_id = t.id)
                    Filter: ((NOT is_notice) AND (NOT is_deleted) AND (NOT is_blinded) AND is_use)
```

- **비용 비교**: 기존 계획 총 cost가 6만 대였던 것에 비해, 개선 후 **126 수준**으로 급감.
- **Sort**: 최상단 Sort는 **36행**에 대한 정렬뿐이라 비용(126.88..126.97)이 무시 가능.
- **Nested Loop**: 바깥쪽은 `topics`를 **Seq Scan**으로 9행만 읽고, 안쪽은 topic당 **Limit 4**로 4행만 가져옴.
- **Index Scan** using `idx_posts__topic_id__id_desc`: `Index Cond: (topic_id = t.id)` 로 구간 접근 후, 이미 `id DESC` 순이므로 **정렬 없이** 상위 4개만 읽음. `Filter`는 인덱스에 없는 boolean 컬럼들(is_notice, is_deleted 등)을 적용하는 단계.

**추가한 인덱스**

```sql
CREATE INDEX idx_posts__topic_id__id_desc
ON posts (topic_id, id DESC);
```

**정리**: 실행계획상 **“정렬 제거”가 핵심**이었고, 쿼리를 LATERAL+LIMIT로 바꾼 뒤 `(topic_id, id DESC)` 복합 인덱스를 추가해 Nested Loop + Index Scan + Limit으로 전환했습니다.

---

## 3. pg_stat_user_indexes로 인덱스 사용 현황 분석

실행계획만으로는 “어떤 인덱스가 실제로 잘 쓰이는지 / 안 쓰이는지”를 보기 어렵습니다. `pg_stat_user_indexes`로 사용량을 확인했습니다.

```sql
SELECT *
FROM pg_stat_user_indexes
WHERE relname = 'posts';
```

### 3-1. 주요 컬럼 해석

| 컬럼              | 의미                                                       |
| ----------------- | ---------------------------------------------------------- |
| **idx_scan**      | 이 인덱스로 시도된 인덱스 스캔 횟수 (쿼리당 1회씩 카운트)  |
| **idx_tup_read**  | 인덱스에서 읽은 (엔트리) 튜플 수                           |
| **idx_tup_fetch** | 인덱스를 통해 테이블에서 실제로 가져온 **살아 있는** 행 수 |

- `idx_scan`이 낮으면: 그 인덱스를 쓰는 쿼리가 적다는 뜻
- `idx_tup_read` 대비 `idx_tup_fetch`가 너무 작으면: 인덱스로 많이 읽지만 실제 반환/사용 행은 적어서 비효율일 수 있음

### 3-2. 실제 데이터 해석

- **posts_topic_index**(예: `topic_id` 단일) 의 **idx_scan**이 매우 낮았음
- topic이 13개뿐이라 **선택성(카디널리티)** 이 낮고, 옵티마이저가 다른 경로를 택하거나 스캔당 비용이 커서 “인덱스는 쓰이지만 효과는 미미”한 상황
- **idx_scan만 높다고 “좋은 인덱스”가 아님** → `idx_tup_read`, `idx_tup_fetch`와 실행계획을 함께 봐야 함

이 과정으로 “사실상 역할이 약한 인덱스 후보”를 식별할 수 있었습니다.

---

## 4. 인덱스 설계 의사결정 과정

### 4-1. 왜 topic 단일 인덱스는 효과가 약했는가

- **카디널리티가 낮음**: topic 13개 → 한 topic당 평균 약 1.7만 행
- “topic으로만 자르기”는 되지만, **정렬(id DESC)** 은 인덱스가 도와주지 못함
- 그래서 topic으로 필터한 뒤 **대량 행을 읽고 Sort** 하는 구조가 됨

### 4-2. 왜 복합 인덱스 `(topic_id, id DESC)` 가 정답에 가까웠는가

```sql
CREATE INDEX idx_posts__topic_id__id_desc ON posts (topic_id, id DESC);
```

- **정렬 제거**: `topic_id`로 잘라낸 구간이 이미 `id DESC` 순이라 **Sort 노드 제거** 가능
- **Top-N 최적화**: “topic별 최신 N개”를 인덱스에서만 읽고 끝낼 수 있음
- **Nested Loop** 와 잘 맞음: 바깥쪽에서 topic을 돌면서, 안쪽에서 이 인덱스로 Limit N만 스캔

즉, “필터용”이 아니라 **“정렬 제거 + Top-N”용**으로 인덱스를 설계한 케이스입니다.

---

## 5. Partial Index는 왜 쓰지 않았는가

- `is_notice = false AND is_deleted = false AND ...` 같은 조건으로 **Partial Index**를 고려할 수 있었음
- 실제로 해당 조건을 만족하는 행이 **전체 229,229건 중 196,736건(약 86%)** 이라, “일부만 걸러내는” 효과가 크지 않음
- Partial Index는 조건 변경 시 인덱스 정의도 같이 바꿔야 해서 **유지보수 부담**이 커짐
- 위 복합 인덱스만으로도 목표 성능을 달성할 수 있어, 복잡도 대비 이득이 적다고 판단해 사용하지 않음

---

## 6. 인덱스 삭제 판단 방법

불필요해 보이는 기존 인덱스를 제거할 때 참고한 절차입니다.

1. **1차 필터**: `pg_stat_user_indexes.idx_scan`으로 거의 사용되지 않는 인덱스 후보 선정
2. **실행계획 검증**: 중요한 쿼리들이 새 복합 인덱스(또는 다른 인덱스)를 쓰는지 `EXPLAIN (ANALYZE, BUFFERS)` 로 확인
3. **대체 가능 여부**: 해당 인덱스의 역할(필터/정렬)을 다른 인덱스가 이미 커버하는지 확인
4. **운영 모니터링**: 삭제 후 짧은 기간 트래픽·지연 시간을 보면서 이상 유무 확인

“idx_scan이 낮다 → 무조건 삭제”가 아니라, **실행계획으로 대체 여부를 검증한 뒤** 단계적으로 제거하는 것이 안전합니다.

---

## 7. 성능 개선 결과

- **Before**: 해당 쿼리 약 **150ms**
- **After**: 복합 인덱스 적용 후 **수 ms ~ 10ms대** 수준으로 단축 (환경에 따라 상이)
- 실행계획에서 **Seq Scan / 무거운 Sort** 가 사라지고 **Index Scan + Limit** 위주로 바뀜
- 메인홈 첫 진입 체감 속도가 개선됨 (추가로 캐시 적용 시 더 안정적)

---

## 8. 실무에서 얻은 인사이트

- **카디널리티가 낮은 컬럼의 단일 인덱스**는 “쓸 수는 있지만 효과가 작은” 경우가 많다. 정렬·Top-N까지 고려해 **복합 인덱스**를 설계하는 편이 낫다.
- **idx_scan만 보고 판단하면 안 된다.** 사용 횟수와 함께 `idx_tup_read`, `idx_tup_fetch`와 실행계획을 같이 봐야 “진짜 쓰이는 인덱스”와 “유명무실한 인덱스”를 구분할 수 있다.
- **메인홈처럼 자주 hit 되는 구간**은 결국 **캐시**가 정답에 가깝다. DB는 “캐시 미스일 때 부담을 줄이는” 수준으로 튜닝하는 것이 현실적이다.
- 인덱스는 **“필터용”** 만이 아니라 **“정렬 제거·Top-N”** 용으로 설계해야 할 때가 많다. `(topic_id, id DESC)` 같은 조합이 그 예시다.

---

## 핵심요약

- **문제**: 메인홈 진입 시 “topic별 최신 4개” 조회 쿼리가 약 150ms 소요. posts 약 22만 건, 필터 통과 약 19.7만 건.
- **기존 방식**: ROW_NUMBER() OVER (PARTITION BY topic_id ORDER BY id DESC) + no ≤ 4 → Seq Scan → 이중 Sort → WindowAgg.
- **원인**: 정렬·Top-N을 인덱스가 담당하지 못해 대량 스캔과 정렬 비용 발생.
- **해결**: 쿼리를 **LATERAL + LIMIT 4** 로 변경하고 **복합 인덱스 `idx_posts__topic_id__id_desc (topic_id, id DESC)`** 추가 → Nested Loop + Index Scan으로 정렬 제거, 쿼리 시간 수 ms~10ms대 수준으로 단축.
- **인사이트**: 실행계획과 **pg_stat_user_indexes** 를 함께 보면 병목과 불필요한 인덱스를 구분할 수 있고, 인덱스는 “필터”뿐 아니라 **“정렬 제거·Top-N”** 용으로 설계할 필요가 많다.
