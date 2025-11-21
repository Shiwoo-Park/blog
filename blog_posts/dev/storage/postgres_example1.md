---
layout: post
title: "Postgre SQL - 테이블 설계 Tip: 업데이트가 잦은 필드 + 그 필드로 정렬 + 유니크 보장까지 해야 하는 경우"
date: 2025-08-23
categories: [database, postgresql, design]
---

# Postgre SQL - 테이블 설계 Tip: 업데이트가 잦은 필드 + 그 필드로 정렬 + 유니크 보장까지 해야 하는 경우

> 날짜: 2025-08-23

[목록으로](https://shiwoo-park.github.io/blog)

---

아래는 실무 위주로, 바꿔야 할 지점만 콕 집어 예제 포함해 설명합니다.

---

# 1) 기본 원칙 (핵심만)

* **잦은 업데이트 컬럼을 인덱스에서 분리**: HOT 업데이트 유도(인덱스 재작성 방지).
* **정렬 + 유니크는 “그룹 선두 컬럼 → 정렬 컬럼” 복합 유니크 인덱스**로 해결.
* **대규모 재배치가 필요한 구조는 피함**: “가변 순서”는 *gap 기반 sort\_key*로 해결.
* **쓰기/읽기 경합 분리**: 파티셔닝, 수직 분할, 커버링 인덱스 활용.
* **경합 구간엔 어드바이저리 락**으로 일관성 유지.

---

# 2) 수직 분할로 HOT 업데이트 확보

“업데이트가 잦은 필드”를 별도 테이블로 분리하면, 메인 테이블 인덱스 재작성 최소화 + HOT 업데이트 확률↑

```sql
-- 메인(변경 적음): 인덱스/조인 대상
CREATE TABLE item (
  id BIGSERIAL PRIMARY KEY,
  list_id BIGINT NOT NULL,           -- 정렬 그룹
  title TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_item__list_id ON item(list_id);

-- 변경 잦음(상태/점수/정렬키 등)
CREATE TABLE item_dyn (
  item_id BIGINT PRIMARY KEY REFERENCES item(id) ON DELETE CASCADE,
  sort_key BIGINT NOT NULL,          -- 정렬용
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
) WITH (fillfactor=80);               -- 여유 공간 확보로 HOT 가능성↑
```

> 포인트
>
> * `item`에는 안정적/자주 조회되는 컬럼만.
> * `item_dyn.sort_key`가 자주 바뀌어도 `item`의 인덱스는 영향 없음.

---

# 3) 정렬 + 유니크 보장 (그룹 내 고유 순서)

**그룹(list\_id) 내에서 sort\_key 유니크 + 정렬 최적화**: 복합 유니크 + 커버링

```sql
-- 그룹별 고유 순서 보장
CREATE UNIQUE INDEX uidx_itemdyn__list__sort
  ON item_dyn(list_id, sort_key);

-- 정렬 최적화(커버링) 예: 목록 조회용
CREATE INDEX idx_itemdyn__list__sort__cover
  ON item_dyn(list_id, sort_key DESC, item_id);
```

조회 예시:

```sql
-- 특정 리스트 상위 50개
SELECT i.id, i.title, d.sort_key
FROM item i
JOIN item_dyn d ON d.item_id = i.id
WHERE d.list_id = 42 AND d.is_active
ORDER BY d.sort_key DESC
LIMIT 50;
```

> 선두 컬럼을 `list_id`로 두고 그 다음 `sort_key` → 정렬 + 필터 동시 최적화

---

# 4) “대량 이동” 없는 정렬: **Gap 기반 sort\_key**

위치 바꿀 때 전체를 밀지 않도록 **간격을 두고 배치**합니다. (예: 초기에 10, 20, 30 …로 부여)

* 사이에 끼워넣기: 기존 (10,20) 사이면 15 부여 → **대량 UPDATE 회피**
* 간격이 고갈되면 **부분 리노멀라이즈**(해당 그룹만, 트랜잭션 짧게)
* 자료형: `BIGINT` 추천(여유 큼). 정렬 역순이면 큰 수→작은 수 방향으로.

초기 부여 예:

```sql
-- 새 아이템: 최대 sort_key + 10,000 간격
INSERT INTO item_dyn(item_id, list_id, sort_key)
SELECT :item_id, :list_id,
       COALESCE(MAX(sort_key), 0) + 10000
FROM item_dyn WHERE list_id = :list_id;
```

끼워넣기 예:

```sql
-- before_key와 after_key 사이 중간값 부여
UPDATE item_dyn
SET sort_key = ((:before_key + :after_key) / 2)
WHERE item_id = :target_item_id AND list_id = :list_id;
```

리노멀라이즈(드물게):

```sql
-- 해당 list_id만 잠깐 정규화 (간격 재부여)
WITH ordered AS (
  SELECT item_id, ROW_NUMBER() OVER (ORDER BY sort_key DESC) AS rn
  FROM item_dyn WHERE list_id = :list_id
)
UPDATE item_dyn d
SET sort_key = (10000 * ordered.rn)
FROM ordered
WHERE d.item_id = ordered.item_id AND d.list_id = :list_id;
```

> 포인트
>
> * 정렬 변경이 잦아도 **대규모 행 이동/충돌**이 없음.
> * 유니크 제약은 그대로 유지(충돌 시 재시도/중간값 조정).

---

# 5) 유니크 충돌/경합 처리 (동시성)

정렬 변경은 보통 “그룹 단위” 직렬화가 안전합니다. **어드바이저리 락**으로 짧게 감싸면 단순+안전.

```sql
-- 그룹 단위 직렬화 (세션 내)
SELECT pg_advisory_xact_lock(hashtext('reorder:' || :list_id::text));

-- 여기서 끼워넣기/교환/리노멀라이즈 실행
-- 유니크 충돌(ON CONFLICT) 시 미세 조정 후 재시도
```

또는 `INSERT ... ON CONFLICT (list_id, sort_key) DO UPDATE` 패턴으로 재시도 로직 구현.

---

# 6) “활성만 유니크”가 필요한 경우 (부분 유니크)

활성 행만 유니크하게 강제하고, 비활성 기록은 중복 허용:

```sql
CREATE UNIQUE INDEX uidx_itemdyn__list__sort__active
  ON item_dyn(list_id, sort_key)
  WHERE is_active;  -- 부분 유니크
```

활성/비활성 전환도 안전해짐(활성으로 바꿀 때만 충돌 체크).

---

# 7) 파티셔닝으로 유지/운영 비용 절감

* **시간/테넌트 기준 파티션**으로 VACUUM/인덱스 관리 부담 분산.
* 최근 파티션만 **autovacuum 강화**, 오래된 파티션은 **READ 최적화**.

```sql
CREATE TABLE item_dyn_p (
  item_id BIGINT,
  list_id BIGINT,
  sort_key BIGINT,
  is_active BOOLEAN,
  updated_at TIMESTAMPTZ
) PARTITION BY HASH (list_id);

CREATE TABLE item_dyn_p0 PARTITION OF item_dyn_p FOR VALUES WITH (MODULUS 8, REMAINDER 0);
-- p1..p7 생성 생략
CREATE UNIQUE INDEX ON item_dyn_p(list_id, sort_key); -- 전파됨
```

> `HASH(list_id)`는 그룹별 재배치를 막고, 특정 그룹 핫스팟을 분산(인서트/업데이트 병렬성↑).

---

# 8) 운영 파라미터/메인터넌스 팁

* **fillfactor 낮추기**(변경 잦은 테이블/인덱스): 페이지 분할·Bloat 완화.
* **autovacuum per-table 설정**: 변경 많은 테이블에 aggressive하게.

  ```sql
  ALTER TABLE item_dyn SET (
    autovacuum_vacuum_scale_factor = 0.05,
    autovacuum_analyze_scale_factor = 0.02
  );
  ```
* **인덱스는 최소화**: 업데이트 잦은 컬럼에 불필요한 인덱스 금지(모든 인덱스가 업데이트 비용).
* **커버링 인덱스(INCLUDE)**: 읽기 경로 최적화하되, 잦은 업데이트 컬럼은 INCLUDE에도 넣지 않기.

---

# 9) Django/DRF 실무 적용 포인트

* 모델 분리: `Item`, `ItemDynamic`(OneToOne).
* 정렬 변경 API:

  * **list\_id 기준 어드바이저리 락**(DB 함수 호출) → gap 재할당 → 저장.
  * 유니크 충돌 시 **재시도**(중간값 재계산).
* 마이그레이션 시 **기존 rank → gap 방식**으로 변환 + 유니크 인덱스 이관.

---

## 요약 체크리스트

* [ ] 잦은 업데이트 컬럼을 **수직 분할**해 HOT 업데이트 확보
* [ ] **(list\_id, sort\_key) 유니크** + 정렬 커버링 인덱스
* [ ] **gap 기반 sort\_key**로 재배치 없이 순서 변경
* [ ] 동시성은 **어드바이저리 락** 또는 재시도 UPSERT
* [ ] 파티셔닝/자체 autovacuum/fillfactor로 **운영 비용 관리**


# 위 내용에 대한 추가 개념 설명

좋은 추가 질문이에요 👍 각각 핵심만 딱 정리해드릴게요.

---

## 1) HOT 업데이트란?

* **Heap Only Tuple** 업데이트.
* 보통 PostgreSQL에서 UPDATE 하면 → 새로운 튜플을 쓰고, **해당 컬럼이 포함된 인덱스 전부 갱신**해야 함.
* 그런데 **변경된 컬럼이 어떤 인덱스에도 포함되지 않으면** 인덱스 갱신을 건너뛰고, 기존 인덱스는 그대로 두고 heap 페이지만 갱신 → 이것을 HOT 업데이트라고 함.
* 효과: **인덱스 재작성 I/O 절약 → 성능↑, Bloat↓**
* 예시:

  ```sql
  -- name은 인덱스 없음, email만 인덱스 있음
  UPDATE users SET name='foo' WHERE id=1;
  -- HOT UPDATE → email 인덱스는 안 건드림
  ```

---

## 2) 그룹 선두 컬럼 → 정렬 컬럼 복합 인덱스

* 의미: **(그룹, 정렬열)** 조합으로 인덱스를 만드는 것.
* 왜?

  * “특정 그룹(list\_id)” 안에서 정렬된 결과를 빠르게 뽑기 위해.
  * 정렬 컬럼만 인덱스 잡으면 그룹 필터링 시 효율↓.
* 예시:

  ```sql
  CREATE UNIQUE INDEX uidx_orders__listid__sortkey
    ON orders(list_id, sort_key);
  ```

  → list\_id 조건을 먼저 타고, 그 안에서 sort\_key 정렬/유니크 보장.

---

## 3) 어드바이저리 락(Advisory Lock)

* **DB 레코드/테이블에 직접 걸리는 락이 아님.**
* 앱이 임의로 숫자/키를 지정해서 “이 키는 지금 점유 중”이라고 DB에 알려두는 락.
* **사용자 정의 락 시스템**이라 충돌 없고 가볍다.
* 트랜잭션 단위/세션 단위 모두 가능.
* 예시:

  ```sql
  -- list_id 단위 정렬 변경 시 직렬화
  SELECT pg_advisory_xact_lock(hashtext('reorder:' || :list_id::text));
  -- 같은 list_id 정렬 요청은 동시에 들어와도 직렬 실행됨
  ```

---

## 4) 커버링 인덱스란? (+ 예제)

* 인덱스만 읽고도 쿼리를 만족시킬 수 있는 인덱스.
* 즉, **필요한 컬럼이 전부 인덱스에 포함된 경우** → 테이블(Heap)을 안 보고 인덱스만으로 결과 반환. (`Index Only Scan`)
* PostgreSQL에서는 `INCLUDE` 문법도 지원 (Postgres 11+).

예시:

```sql
-- 조회 쿼리: status별 최신 id, ordered_at만 뽑기
SELECT id, ordered_at
FROM orders
WHERE status='paid'
ORDER BY ordered_at DESC
LIMIT 20;

-- 커버링 인덱스
CREATE INDEX idx_orders__status__ordered_at_cover
  ON orders(status, ordered_at DESC, id);

-- id, ordered_at, status가 모두 인덱스에 있으므로 Heap 접근 X
-- 실행계획: Index Only Scan
```

---

## 5) sort\_key에 “1초당 천 번” 업데이트, 효율적일까?

* 답: **그냥 단일 테이블+인덱스 구조라면 비효율적** (인덱스 재작성 1,000/s → CPU+I/O 병목).
* **효율적으로 만들 수 있는 조건**:

  1. sort\_key만 별도 테이블(`item_dyn`)로 분리 → 다른 인덱스 영향 최소화.
  2. `fillfactor` 낮춰 HOT UPDATE 확률↑ (sort\_key 자체가 인덱스에 걸려있으니 HOT은 안되지만, is\_active 등 다른 필드라도 HOT 유도).
  3. 정렬 변경 방식을 **gap 기반 sort\_key**로 설계 → 전체 재정렬 UPDATE 방지.
  4. 1초 1,000번 수준이라면:

     * **shard/파티션 분산**(list\_id 해시)
     * **autovacuum aggressive 튜닝**
     * 필요시 **in-memory 캐시(redis)로 임시 정렬 관리 후 배치 sync**도 고려.

즉, **sort\_key가 인덱스에 걸려있으니 업데이트마다 인덱스 재작성은 피할 수 없음.**
→ “많은 업데이트에도 효율적일 수 있다”는 의미는:

* 전체 행을 밀어내는 리빌드가 없는 구조(gap key),
* 인덱스 최소화+분리 설계,
* 파티셔닝/캐싱을 곁들이면 **그 정도 트래픽도 버틸 수 있다**는 뜻입니다.

---

✅ 요약

* HOT 업데이트: 인덱스 영향 없는 컬럼만 바꿀 때 I/O 절약.
* 그룹 선두 컬럼 → 정렬 컬럼: 특정 그룹 내 정렬 최적화 복합 인덱스.
* 어드바이저리 락: 앱 정의 락으로 그룹 단위 직렬화 제어.
* 커버링 인덱스: 인덱스만 보고 쿼리 결과 해결, Heap 접근 없음.
* sort\_key 초당 1천 업데이트 → **단순 구조는 힘듦**, but “수직 분할 + gap key + 파티셔닝/캐시”로 충분히 대응 가능.

---

[목록으로](https://shiwoo-park.github.io/blog)
