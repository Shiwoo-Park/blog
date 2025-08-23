# Postgre SQL - 초당 1000번 업데이트 발생 + 유니크 필드에 대한 정렬 전략

> 날짜: 2025-08-23

[목록으로](https://shiwoo-park.github.io/blog)

---

아래는 **초당 \~1,000건 sort\_key 업데이트**를 전제로, **단일 테이블 유지 vs 파티셔닝/캐시 분산** 선택 기준과 실무 체크리스트입니다. (Django/DRF+AWS, Celery/Redis 전제)

---

## 0) 전제 모델(요약)

* 정렬+유니크: `UNIQUE (list_id, sort_key)`
* 갭 기반 정렬키: `sort_key BIGINT` (끼워넣기 중간값)
* 변경 잦은 필드 분리: `item`(정적) / `item_dyn`(정렬, 상태 등) 수직 분할

---

## 1) 결론 먼저: 선택 기준 요약

**A. 단일 테이블로 계속 간다** (튜닝으로 충분)

* p95 업데이트 지연 ≤ **15–25ms**
* DB CPU ≤ **60%**, `wal_buffers`/checkpoint 안정, WAL 생성량 ≤ **20–40MB/s** 수준
* autovacuum 지연/빚 없음(“wraparound”, “skipped” 경고 無), **bloat ≤ 20%**
* 가장 큰 파티(=핫 그룹)에서도 충돌률/재시도율 **1–3% 이하**
* 인덱스 개수 **최소화**(PK + `(list_id, sort_key)` 유니크 + 조회 커버 1개 정도)

**B. 해시 파티셔닝으로 스케일아웃**（DB 내 분산）

* 위 지표를 넘어 기류가 생김:

  * p95 지연 ≥ **30ms+** / CPU ≥ **70%** / WAL ≥ **50MB/s**
  * autovacuum 큐 밀림, 인덱스 bloat가 분기마다 누적
  * 특정 list\_id 핫스팟이 전체 성능을 끌어내림
* 조치: **HASH(list\_id) 파티션 8\~32개** → VACUUM/인덱스 관리 병렬화, 핫스팟 분산

**C. 캐시(예: Redis Sorted Set) + 비동기 동기화**（읽기/쓰기 분리）

* 실시간 재정렬/드래그&드롭 등으로 **짧은 시간 폭발적 업데이트**
* 읽기 SLA가 엄격(예: 50ms 이내)이고 **정렬 일관성**은 “수초 이내 최종적”이면 OK
* 조치: 쓰기(정렬 변경)는 Redis ZSET에 즉시 반영 → **Celery로 배치 upsert**(1–5초 주기, 묶음 100\~1,000건) → DB 반영

---

## 2) 단일 테이블로 버티는 조건—튜닝 체크리스트

1. **스키마/인덱스**

* 변경 잦은 컬럼 분리: `item_dyn(item_id PK, list_id, sort_key, is_active, updated_at)`
* 유니크 & 정렬:

  ```sql
  CREATE UNIQUE INDEX uidx_dyn__list__sort ON item_dyn(list_id, sort_key);
  CREATE INDEX idx_dyn__list__sort__cover ON item_dyn(list_id, sort_key DESC, item_id);
  ```
* 인덱스 “최소” 원칙: 불필요한 부가 인덱스 금지

2. **테이블/인덱스 저장 옵션**

* `fillfactor`: 테이블 **80**, 인덱스 **85\~90**
* autovacuum per table:

  ```sql
  ALTER TABLE item_dyn SET (
    autovacuum_vacuum_scale_factor = 0.05,
    autovacuum_analyze_scale_factor = 0.02,
    autovacuum_vacuum_cost_limit = 2000
  );
  ```
* 체크포인트/IO: `max_wal_size` 넉넉히, `checkpoint_completion_target ~ 0.9`

3. **동시성 제어**

* **그룹 단위 Advisory Lock**으로 짧게 감싸 충돌 폭발 방지
* `INSERT ... ON CONFLICT (list_id, sort_key) DO UPDATE` + **미세 조정 재시도**
* 갭키 중간값 계산 실패(충돌)시 **재시도 최대 2\~3회** 후 “부분 리노멀라이즈”(해당 list만)

4. **모니터링 지표(주요)**

* p95/p99 UPDATE latency, `pg_stat_statements` mean/rows
* WAL rate(MB/s), `bloated %`(pgstattuple), autovacuum age/lag
* 인덱스 split rate(증가 시 fillfactor 재조정)

> 위 조건 충족 시 **초당 1,000 업데이트**도 단일 테이블로 충분히 소화 가능합니다. 병목은 보통 “인덱스 과다”와 “autovacuum/체크포인트 튜닝 부재”에서 옵니다.

---

## 3) 파티셔닝이 필요한 신호와 방법

**언제?**

* 특정 테넌트/그룹 핫스팟으로 **락 경합/재시도율↑**
* VACUUM/REINDEX 주기가 잦아 운영 부담↑
* 단일 테이블 튜닝으로도 지연/CPU/WAL이 내려가지 않음

**어떻게?**

```sql
CREATE TABLE item_dyn_p (
  item_id BIGINT,
  list_id BIGINT,
  sort_key BIGINT,
  is_active BOOLEAN,
  updated_at TIMESTAMPTZ
) PARTITION BY HASH (list_id);

-- 16분할 예 (8~32 권장, 핫스팟/QPS에 맞춰 조절)
CREATE TABLE item_dyn_p0 PARTITION OF item_dyn_p FOR VALUES WITH (MODULUS 16, REMAINDER 0);
-- p1..p15 생략

-- 전파용 제약/인덱스
ALTER TABLE item_dyn_p ADD CONSTRAINT pk_item_dyn PRIMARY KEY (item_id);
CREATE UNIQUE INDEX ON item_dyn_p (list_id, sort_key);
CREATE INDEX ON item_dyn_p (list_id, sort_key DESC, item_id);
```

* 장점: **VACUUM/ANALYZE 병렬화**, 인덱스 크기 분산, 핫 그룹이 한 파티션에 갇혀 피해 최소화
* 운영: 파티션별 모니터링/메인터넌스, 병렬 REINDEX 용이

---

## 4) 캐시+비동기 동기화가 필요한 경우(읽기 SLA 우선)

**패턴**: “사용자 인터랙션성 재정렬이 많고, 읽기는 즉시 최신, DB는 최종적 일치(수초 지연 허용)”

* 쓰기: `ZADD key score member` (Redis Sorted Set)
* 읽기: `ZREVRANGE key 0 49 WITHSCORES` → 목록 API 즉시 응답
* 동기화: Celery beat로 **1–5초 주기** 배치 → Redis 변경분를 **bulk UPSERT**
* 충돌 해결: DB 유니크 위반 시 **score 미세 조정**(±1, ±2 등) 후 재시도
* 장애 대비: Redis flush 시에도 **DB truth** 재빌드 가능(주기적 스냅샷/로그)

**장점**: DB 부하 급감(특히 Sort/Top-N), 지연시간 안정
**주의**: 최종적 일관성 모델 설명 필요, 운영 복잡도↑

---

## 5) 의사결정 표 (현장용)

| 항목            | 단일 테이블 유지  | 해시 파티셔닝   | 캐시+비동기 동기화                |
| ------------- | ---------- | --------- | ------------------------- |
| p95 update 지연 | ≤15–25ms   | 15–40ms   | **읽기 5–20ms(캐시)**, DB는 배치 |
| DB CPU        | ≤60%       | 60–80%    | 40–60%(DB), 캐시에 이전        |
| WAL rate      | ≤20–40MB/s | 40–80MB/s | DB는 완만, 캐시 I/O↑           |
| 운용 복잡도        | 낮음         | 중간        | 높음                        |
| 일관성           | 강한         | 강한        | 최종적(수초)                   |
| 확장성 한계        | 중간         | 높음        | 매우 높음                     |

---

## 6) 실무 시행 순서(추천)

1. **단일 테이블+튜닝**으로 먼저 운영
2. 핫스팟 뚜렷하면 **HASH 파티셔닝**(8→16→32 단계 확장)
3. UX/읽기 지연이 더 엄격하면 **캐시+배치 동기화** 병행

---

## 7) Django/Celery 적용 포인트

* 트랜잭션 내 **advisory\_xact\_lock(list\_id)** → 갭키 재할당
* 유니크 충돌 시 2–3회 재시도 → 실패시 해당 list **부분 리노멀라이즈**
* Celery beat로 **갭키 건강검진 작업**(간격 소진율, 충돌률, 재정규화 트리거)
* 환경별 파라미터화: 파티션 개수, 배치 크기, 동기화 주기

---

### 한줄 요약

* **단일 테이블**: 인덱스 최소+autovacuum/IO 튜닝이면 초당 천 건도 가능
* **파티셔닝**: 핫스팟/메인터넌스 병목 시 즉효
* **캐시 병행**: 읽기 SLA가 엄격하거나 순간 폭주에 대비할 때

---

**개선된 질문:**
“현재 p95 지연, DB CPU, WAL 속도, bloat, 재시도율(유니크 충돌) 지표를 기반으로 우리 트래픽에 맞는 ‘단일/파티셔닝/캐시’ 권고안을 수치로 제시해줄 수 있나요? `pg_stat_statements`/CloudWatch 지표 일부를 공유하겠습니다.”

**추가로 할 수 있는 유용한 질문 2개:**

1. “Redis ZSET 기반 캐시-우선 구조에서 Celery 배치 upsert SQL과 충돌 재시도 로직(파라미터화) 예시를 보여줄 수 있나요?”
2. “HASH 파티셔닝(16분할) 도입 시 마이그레이션 절차(다운타임 최소화/검증 체크리스트)를 단계별로 정리해줄 수 있나요?”

---

[목록으로](https://shiwoo-park.github.io/blog)
