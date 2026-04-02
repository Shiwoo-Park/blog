---
layout: post
title: "Postgres의 unnest로 일괄 업데이트 하기"
date: 2026-02-26
categories: [database, postgresql, optimization]
description: "여러 행을 한 번에 갱신할 때 루프 대신 unnest로 배열을 행으로 풀어 UPDATE ... FROM으로 처리하는 방법과 예시를 정리합니다."
keywords: "PostgreSQL, unnest, 일괄업데이트, bulk update, 배열"
image: "/resources/og-dev.png"
---

여러 행을 한 번에 업데이트해야 할 때, 애플리케이션에서 반복문으로 `UPDATE`를 호출하면 round-trip과 lock 비용이 늘어납니다. PostgreSQL의 **unnest**로 배열을 행 집합으로 풀어 한 번의 `UPDATE ... FROM`으로 처리하는 방법을 정리합니다.

---

## 1. unnest란?

**unnest**는 PostgreSQL에서 배열을 **행(row) 집합**으로 바꿔 주는 함수입니다.

```sql
SELECT * FROM unnest(ARRAY[1, 2, 3]) AS t(id);
```

결과는 세 행입니다: `1`, `2`, `3`.  
여러 배열을 같이 넘기면 **같은 위치끼리 한 행**으로 묶입니다.

```sql
SELECT * FROM unnest(ARRAY[1, 2, 3]) AS id,
             unnest(ARRAY['A', 'B', 'C']) AS val;
-- (1,'A'), (2,'B'), (3,'C')
```

이렇게 “id 배열 + 갱신할 값 배열”을 행 집합으로 만든 뒤, `UPDATE ... FROM`에 넣어 쓰면 됩니다.

---

## 2. unnest로 일괄 업데이트 패턴

한 번에 여러 행을 갱신하려면, **서브쿼리에서 unnest로 (id, 값) 행들을 만들고**, 그걸 `FROM`에 두고 조인해서 `UPDATE`합니다.

- **WHERE**에만 unnest를 쓰면 set-returning function이라 에러가 나므로, **FROM 서브쿼리**에서 unnest한 결과를 쓰는 것이 맞습니다.

기본 형태는 다음과 같습니다.

```sql
UPDATE 대상테이블 t
SET   갱신할컬럼 = sub.값
FROM (
  SELECT * FROM unnest(ARRAY[1, 2, 3]) AS id,
               unnest(ARRAY['값1', '값2', '값3']) AS val
) sub
WHERE t.id = sub.id;
```

동일한 위치의 id와 값이 한 행으로 짝을 이루므로, “어떤 id에 어떤 값”을 넣을지 명확합니다.

---

## 3. 실전 예시

예: `items` 테이블에서 여러 id의 `status`를 한 번에 바꾸는 경우.

```sql
UPDATE items i
SET   status = sub.status,
      updated_at = now()
FROM (
  SELECT * FROM unnest(ARRAY[101, 102, 103]) AS id,
               unnest(ARRAY['active', 'active', 'pending']) AS status
) sub
WHERE i.id = sub.id;
```

- id `101` → `active`, `102` → `active`, `103` → `pending`으로 한 번에 갱신됩니다.
- 배열은 애플리케이션에서 바인딩하기 쉽고, 건수가 많으면 500~1000건 단위로 나눠서 여러 번 실행하는 식으로 부하를 조절할 수 있습니다.

---

## 4. 주의사항

- **배열 길이**: 여러 배열을 함께 unnest할 때는 **길이가 같아야** 합니다. 길이가 다르면 짧은 쪽에 맞춰 잘리고, 의도치 않은 매칭이 될 수 있습니다.
- **동시성**: 한 트랜잭션 안에서 많은 행을 갱신하면 lock이 길어질 수 있으므로, 배치 크기와 트랜잭션 시간을 고려하는 것이 좋습니다.
- **복합 키**: (col1, col2)처럼 복합 키로 매칭하려면, col1 배열과 col2 배열을 각각 unnest해서 `WHERE t.col1 = sub.col1 AND t.col2 = sub.col2`로 연결하면 됩니다.

---

## 5. 핵심요약

- **unnest**는 배열을 행 집합으로 바꿔 주는 함수이며, 여러 배열을 같이 쓰면 같은 인덱스끼리 한 행으로 묶입니다.
- 루프로 여러 번 `UPDATE`하는 대신, **unnest로 (id, 값) 행들을 만든 뒤 `UPDATE ... FROM`**으로 한 번에 처리하면 round-trip과 lock을 줄일 수 있습니다.
- unnest는 **FROM 서브쿼리**에서 사용하고, 배열 길이를 맞추고, 필요하면 배치 크기를 나눠서 실행하면 실무에서 안정적으로 쓸 수 있습니다.
