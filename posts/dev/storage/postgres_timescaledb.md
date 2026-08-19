---
layout: post
title: "TimescaleDB 실전 활용 가이드: 개념부터 압축·보존 정책까지"
date: 2026-08-19
categories: [database, postgresql, timescaledb]
description: "TimescaleDB의 핵심 개념(Hypertable, Chunk)부터 설치, 압축·보존 정책 설정, time_bucket·Continuous Aggregate 쿼리, 실전 활용사례까지 바로 써먹는 실무 가이드입니다."
keywords: "TimescaleDB, PostgreSQL, 시계열 데이터베이스, Hypertable, Chunk, Compression, Continuous Aggregate, Retention Policy"
image: "/resources/og-dev.png"
---

[TimescaleDB 개요](postgres_timescaledb.md)에서 다룬 특징을 바탕으로, 실제로 설치하고 운영하는 데 필요한 개념과 명령어를 정리합니다.

---

## 1. 시작 전 핵심 개념 잡기

### 1-1. 시계열 데이터가 뭐가 다른가

시계열(Time-series) 데이터는 시간이 지나면서 계속 쌓이는 데이터입니다. 센서 값, 서버 CPU 사용량, 주가, 클릭 로그가 모두 여기에 속합니다. 이런 데이터는 공통적으로 아래와 같은 패턴을 보입니다.

- **쓰기(INSERT)가 압도적으로 많다** — 새 row가 계속 추가됨
- **과거 데이터는 거의 수정(UPDATE)하지 않는다** — 한번 쓰이면 값이 바뀔 일이 없음
- **최신 데이터 조회 빈도가 높다** — "최근 1시간", "오늘 하루" 같은 조회가 대부분

### 1-2. 일반 PostgreSQL 테이블로 쌓으면 왜 느려지는가

일반 테이블 하나에 수억 건을 계속 INSERT 하면 다음 문제가 생깁니다.

- 테이블과 인덱스가 계속 커지면서, 인덱스가 메모리에 다 올라가지 못해 디스크 I/O가 늘어남
- `VACUUM`, 인덱스 재구성 같은 유지보수 작업의 대상 범위가 테이블 전체라 오래 걸림
- 오래된 데이터를 지우려면 대량 `DELETE`가 필요한데, 이 역시 테이블 전체에 부담을 줌

### 1-3. TimescaleDB가 푸는 방식: 안 보이게 쪼갠다

TimescaleDB의 해법은 단순합니다. **겉으로는 하나의 테이블처럼 보이지만, 내부적으로는 시간 구간별로 여러 개의 작은 테이블로 쪼개서 관리**합니다.

```
Hypertable (사용자가 쿼리하는 테이블, 논리적으로 1개)
 ├─ Chunk 1 (2026-08-01 ~ 2026-08-02 데이터)
 ├─ Chunk 2 (2026-08-02 ~ 2026-08-03 데이터)
 └─ Chunk 3 (2026-08-03 ~ 2026-08-04 데이터, 현재 쓰기 중)
```

- **Hypertable**: 사용자가 실제로 `SELECT`/`INSERT` 하는 대상. 일반 테이블처럼 다루면 됩니다.
- **Chunk**: Hypertable 내부에서 시간 구간별로 나뉜 물리적 테이블. 쿼리에 시간 조건이 있으면 관련 없는 Chunk는 아예 건너뛰어(Chunk pruning) 조회 범위를 좁힙니다.

이 구조 덕분에 데이터가 아무리 쌓여도 최근 데이터가 들어 있는 Chunk만 활발하게 쓰이고, 나머지 오래된 Chunk는 압축하거나 통째로 삭제하기 쉬워집니다.

### 1-4. 뒤에 나올 세 가지 용어, 먼저 한 줄로

| 용어 | 한 줄 정의 |
| --- | --- |
| **압축(Compression)** | 더 이상 잘 안 바뀌는 오래된 Chunk를 열 기반으로 다시 저장해 용량을 줄이는 것 |
| **보존(Retention)** | 일정 기간이 지난 오래된 Chunk를 통째로 자동 삭제하는 정책 |
| **연속 집계(Continuous Aggregate)** | "시간대별 평균/합계" 같은 집계 결과를 미리 계산해 캐싱해두는 뷰 |

이 세 가지가 TimescaleDB 실무 활용의 핵심이며, 3장부터 순서대로 다룹니다.

---

## 2. 설치 및 환경 구성

### 2-1. Docker Compose로 설치하기

가장 빠른 방법은 공식 이미지를 사용하는 것입니다.

```yaml
# docker-compose.yml
services:
  timescaledb:
    image: timescale/timescaledb:latest-pg16
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
      POSTGRES_DB: mydb
    ports:
      - "5432:5432"
    volumes:
      - timescale_data:/var/lib/postgresql/data

volumes:
  timescale_data:
```

```bash
docker compose up -d
```

### 2-2. Extension 활성화 확인

컨테이너 접속 후 DB에 Extension이 설치돼 있는지 확인합니다.

```sql
CREATE EXTENSION IF NOT EXISTS timescaledb;

-- 설치 확인
SELECT extname, extversion FROM pg_extension WHERE extname = 'timescaledb';
```

이미 운영 중인 RDS/자체 호스팅 PostgreSQL이 있다면, 해당 인스턴스가 `timescaledb` Extension을 지원하는지 먼저 확인해야 합니다. AWS RDS는 특정 파라미터 그룹 설정이 필요하므로 사전 확인이 필요합니다.

---

## 3. Hypertable 생성

### 3-1. 일반 테이블 → Hypertable 전환

기존 테이블 스키마를 그대로 만들고, `create_hypertable()`로 전환합니다.

```sql
CREATE TABLE sensor_data (
    time        TIMESTAMPTZ NOT NULL,
    sensor_id   INTEGER NOT NULL,
    temperature DOUBLE PRECISION,
    humidity    DOUBLE PRECISION
);

SELECT create_hypertable('sensor_data', by_range('time'));
```

전환 이후에도 `INSERT`/`SELECT` 문법은 일반 테이블과 동일합니다.

### 3-2. chunk_time_interval 설정 기준

Chunk 크기는 성능에 직접적인 영향을 줍니다. 기본값은 7일이지만, 대부분의 운영 환경에는 맞지 않습니다.

- **너무 작으면**: Chunk 개수가 수천 개로 늘어나고, 쿼리 플래너가 단순한 조회에도 매번 모든 Chunk의 제약조건을 검사해 오히려 느려집니다.
- **너무 크면**: 압축·해제 작업이 오래 걸리고, 하나의 Chunk를 처리할 때 필요한 메모리(work_mem)가 커집니다.

실무에서 참고할 만한 기준은 **Chunk 하나당 약 2,500만 row**, 그리고 **현재 쓰기 중인 Chunk의 인덱스가 전체 메모리의 25% 이내**에 들어오도록 산정하는 것입니다. 예를 들어 초당 1,000건씩 쌓이는 테이블이라면 하루 약 8,640만 건이 쌓이므로, 1일보다 짧은 간격(예: 6~12시간)이 적절할 수 있습니다.

```sql
SELECT create_hypertable(
    'sensor_data',
    by_range('time', INTERVAL '12 hours')
);

-- 이미 만든 Hypertable의 간격 변경
SELECT set_chunk_time_interval('sensor_data', INTERVAL '1 day');
```

### 3-3. 기존 데이터 마이그레이션 시 주의점

이미 데이터가 쌓인 일반 테이블을 Hypertable로 바꿀 때는 `migrate_data => true` 옵션을 쓸 수 있지만, 데이터량이 크면 락이 오래 걸립니다. 운영 중인 테이블이라면 신규 테이블로 Hypertable을 만들고 배치로 데이터를 옮긴 뒤 전환하는 방식이 더 안전합니다.

---

## 4. 압축(Compression) 정책

### 4-1. 압축 활성화 및 컬럼 설정

압축을 켜기 전에, 압축 효율을 높이기 위한 두 가지 컬럼을 지정합니다.

```sql
ALTER TABLE sensor_data SET (
    timescaledb.compress,
    timescaledb.compress_segmentby = 'sensor_id',
    timescaledb.compress_orderby = 'time DESC'
);
```

- `segmentby`: 같은 값끼리 묶어서 압축할 컬럼. 조회 시 자주 `WHERE`로 필터링하는 컬럼(예: `sensor_id`, `device_id`)을 지정하면 압축된 상태에서도 해당 그룹만 빠르게 찾을 수 있습니다.
- `orderby`: 그룹 내에서 정렬 기준이 되는 컬럼. 보통 `time DESC`를 사용합니다.

### 4-2. 압축 정책 자동화

특정 시점이 지난 Chunk를 자동으로 압축하도록 정책을 등록합니다.

```sql
SELECT add_compression_policy('sensor_data', compress_after => INTERVAL '7 days');
```

이후로는 백그라운드 작업이 주기적으로 실행되어, 생성 후 7일이 지난 Chunk를 자동 압축합니다.

### 4-3. 압축 효과 확인

```sql
SELECT
    chunk_name,
    before_compression_total_bytes,
    after_compression_total_bytes,
    round(
        100.0 * (1 - after_compression_total_bytes::numeric / before_compression_total_bytes),
        1
    ) AS compression_ratio_pct
FROM chunk_compression_stats('sensor_data');
```

---

## 5. 데이터 보존(Retention) 정책

### 5-1. 오래된 Chunk 자동 삭제

보존 기간이 지난 데이터는 `DELETE` 대신 Chunk 단위로 통째로 드롭하는 것이 훨씬 빠릅니다.

```sql
SELECT add_retention_policy('sensor_data', drop_after => INTERVAL '90 days');
```

### 5-2. 압축과 보존을 함께 쓸 때 원칙

실무에서 검증된 원칙은 **"압축은 빠르게, 보존은 길게"**입니다.

- 압축은 되도록 일찍 적용(예: 생성 1시간~1일 후)해서 디스크 사용량을 조기에 줄입니다.
- 보존 기간은 비즈니스 요구사항에 맞춰 길게 유지(예: 30~90일)합니다.
- 이렇게 하면 Chunk가 삭제되는 시점에는 이미 압축된 상태라, 데이터 생명주기 전체에서 디스크 사용량이 최소화됩니다.

```sql
-- 1일 후 압축, 90일 후 삭제
SELECT add_compression_policy('sensor_data', compress_after => INTERVAL '1 day');
SELECT add_retention_policy('sensor_data', drop_after => INTERVAL '90 days');
```

---

## 6. 실무 쿼리 패턴

### 6-1. time_bucket()으로 시간 단위 집계

`GROUP BY`에 시간 함수를 직접 쓰는 대신, TimescaleDB가 제공하는 `time_bucket()`을 사용합니다.

```sql
SELECT
    time_bucket('1 hour', time) AS bucket,
    sensor_id,
    avg(temperature) AS avg_temp
FROM sensor_data
WHERE time > now() - INTERVAL '1 day'
GROUP BY bucket, sensor_id
ORDER BY bucket;
```

### 6-2. Continuous Aggregate로 미리 계산해두기

대시보드처럼 반복 조회되는 집계 쿼리는 매번 원본 데이터를 스캔하는 대신, 결과를 미리 계산해두는 Continuous Aggregate를 사용합니다.

```sql
CREATE MATERIALIZED VIEW sensor_hourly
WITH (timescaledb.continuous) AS
SELECT
    time_bucket('1 hour', time) AS bucket,
    sensor_id,
    avg(temperature) AS avg_temp,
    max(temperature) AS max_temp
FROM sensor_data
GROUP BY bucket, sensor_id;

-- 새 데이터가 들어올 때마다 자동 갱신되도록 정책 등록
SELECT add_continuous_aggregate_policy('sensor_hourly',
    start_offset => INTERVAL '3 hours',
    end_offset => INTERVAL '1 hour',
    schedule_interval => INTERVAL '1 hour'
);
```

이렇게 하면 대시보드 쿼리는 원본 데이터량과 무관하게 `sensor_hourly` 뷰 하나만 조회하면 되므로 응답 속도가 거의 일정하게 유지됩니다. TimescaleDB 2.6 이상부터는 Continuous Aggregate 자체에도 압축 정책을 적용할 수 있어, 오래된 집계 결과도 추가로 용량을 줄일 수 있습니다.

---

## 7. 실전 활용사례 & Best Practice

### 7-1. IoT/모니터링: 다운샘플링 파이프라인

1초 단위로 쏟아지는 원본 센서 데이터를 그대로 장기 보관하는 대신, Continuous Aggregate로 1분 평균을 미리 계산해두고, 원본 데이터는 짧은 보존 기간(예: 7일) 후 삭제하는 구조가 일반적입니다. 조회는 대부분 집계 테이블만 보면 되고, 원본은 최근 이슈 추적용으로만 짧게 유지합니다.

### 7-2. 이커머스 이벤트 로그: 압축으로 비용 절감

페이지뷰·클릭 로그처럼 2~3년치를 분석해야 하는 경우, Continuous Aggregate로 일별/시간별 집계를 만들어 분석 쿼리 성능을 확보하고, 원본 로그는 압축 정책을 적용해 스토리지 비용을 30~40% 수준까지 절감한 사례가 있습니다.

### 7-3. 설계 원칙: 나중에 바꾸기 어렵다

Ingest rate(초당 쓰기량), 보존 기간, 조회 패턴은 테이블을 만들 때 함께 설계해야 합니다. Chunk 크기나 압축 컬럼 구성은 이미 데이터가 쌓인 뒤에 바꾸려면 비용이 크므로, 서비스 초기에 예상 쓰기량 기준으로 먼저 정하고 시작하는 것이 안전합니다.

### 7-4. 흔한 안티패턴

- **chunk_time_interval을 기본값(7일) 그대로 사용**: 쓰기량이 많은 서비스라면 Chunk 하나가 지나치게 커져 압축·조회 성능이 떨어집니다.
- **segmentby 없이 압축**: 자주 필터링하는 컬럼을 segmentby로 지정하지 않으면, 압축된 상태에서도 불필요한 데이터를 더 많이 읽게 됩니다.
- **보존 정책만 걸고 압축 정책은 생략**: 삭제 직전까지 원본 크기 그대로 유지되어 디스크 비용이 계속 높게 유지됩니다.

---

## 8. 운영 체크리스트

### 8-1. 모니터링 쿼리

```sql
-- Hypertable별 Chunk 개수 확인
SELECT hypertable_name, count(*) AS chunk_count
FROM timescaledb_information.chunks
GROUP BY hypertable_name;

-- 압축 안 된 Chunk 확인
SELECT chunk_name, is_compressed
FROM timescaledb_information.chunks
WHERE hypertable_name = 'sensor_data' AND is_compressed = false;
```

### 8-2. 흔한 실수 체크

- [ ] `chunk_time_interval`을 쓰기량 기준으로 산정했는가 (기본 7일을 그대로 쓰고 있지 않은가)
- [ ] 압축 정책의 `segmentby`가 실제 조회 시 필터링하는 컬럼과 일치하는가
- [ ] 압축 정책과 보존 정책이 함께 등록되어 있는가 (압축 없이 보존만 있는지 확인)
- [ ] Continuous Aggregate의 갱신 정책(`add_continuous_aggregate_policy`)이 등록되어 있는가

---

## 핵심요약

- TimescaleDB는 하나의 논리적 테이블(**Hypertable**)을 시간 구간별 여러 물리적 테이블(**Chunk**)로 쪼개 관리해 대량 시계열 데이터를 빠르게 처리합니다.
- `chunk_time_interval`은 기본값(7일) 그대로 쓰지 말고, 쓰기량 기준(Chunk당 약 2,500만 row)으로 산정합니다.
- **압축은 빠르게(1일 이내), 보존은 길게(수십~수백일)** 조합이 실무 기본 원칙입니다.
- 반복 집계 쿼리는 `time_bucket()` + **Continuous Aggregate**로 미리 계산해두면 원본 데이터량과 무관하게 빠른 응답을 유지할 수 있습니다.
- Ingest rate, 보존 기간, 조회 패턴은 서비스 초기 설계 단계에서 함께 정해야 나중에 비용을 줄일 수 있습니다.

**참고 자료**
- [TimescaleDB Hypertables, Continuous Aggregates & Compression (2026 Production Guide)](https://www.jusdb.com/blog/timescaledb-hypertables-continuous-aggregates-guide)
- [Increase Your Storage Savings With TimescaleDB | Tiger Data](https://www.tigerdata.com/blog/increase-your-storage-savings-with-timescaledb-2-6-introducing-compression-for-continuous-aggregates)
- [Choosing the right chunk_time_interval value for TimescaleDB Hypertables](https://forum.tigerdata.com/forum/t/choosing-the-right-chunk-time-interval-value-for-timescaledb-hypertables/116)
- [How TimescaleDB Chunks Actually Work (And Why Size Matters)](https://dev.to/philip_mcclarence_2ef9475/how-timescaledb-chunks-actually-work-and-why-size-matters-3hl5)
- [How to Configure Data Retention Policies in TimescaleDB](https://oneuptime.com/blog/post/2026-02-02-timescaledb-data-retention/view)
