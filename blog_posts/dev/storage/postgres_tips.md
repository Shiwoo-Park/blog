---
layout: post
title: "PostgreSQL 사용자가 꼭 알아야 할 핵심 개념"
date: 2025-06-29
categories: [database, postgresql]
---

# 🎯 PostgreSQL 사용자가 꼭 알아야 할 핵심 개념

> 날짜: 2025-06-29

[목록으로](https://shiwoo-park.github.io/blog)

---

#### 1. **데이터베이스 구조**
- **클러스터** → **데이터베이스** → **스키마** → **테이블** 순서로 계층 구조
- 기본 스키마: `public` (사용자 데이터), `pg_catalog` (시스템 정보)

#### 2. **성능 최적화 핵심**
- **Shared Buffer**: 자주 사용하는 데이터를 메모리에 캐싱
- **Work Memory**: 정렬, 조인 작업에 사용되는 임시 메모리
- **인덱스**: 검색 성능 향상의 핵심 (B-tree, Hash, GIN 등)

#### 3. **유지보수 필수 작업**
- **VACUUM**: 데드 튜플 정리 (자동 실행되지만 수동 모니터링 필요)
- **ANALYZE**: 통계 정보 업데이트 (쿼리 플래너가 최적 경로 선택)
- **REINDEX**: 인덱스 재구성 (성능 저하 시)

#### 4. **모니터링 필수 지표**
```sql
-- 테이블별 통계 확인
SELECT schemaname, tablename, n_tup_ins, n_tup_upd, n_tup_del, n_dead_tup
FROM pg_stat_user_tables;

-- 인덱스 사용률 확인
SELECT schemaname, tablename, indexname, idx_scan, idx_tup_read, idx_tup_fetch
FROM pg_stat_user_indexes;

-- Wraparound 위험도 확인
SELECT datname, age(datfrozenxid) as xid_age 
FROM pg_database 
WHERE age(datfrozenxid) > 150000000;
```

#### 5. **성능 튜닝 핵심 설정**
```sql
-- postgresql.conf 주요 설정
shared_buffers = 25% of RAM        -- 공유 버퍼 크기
work_mem = 4MB                     -- 작업 메모리
maintenance_work_mem = 64MB        -- 유지보수 작업 메모리
effective_cache_size = 75% of RAM  -- OS 캐시 크기
```

#### 6. **문제 해결 체크리스트**
- **느린 쿼리**: EXPLAIN ANALYZE로 실행 계획 분석
- **메모리 부족**: work_mem, shared_buffers 조정
- **디스크 I/O 많음**: 인덱스 추가, 쿼리 최적화
- **Wraparound 경고**: VACUUM FREEZE 실행

#### 7. **백업과 복구**
- **WAL**: 트랜잭션 로그 (Point-in-Time Recovery 가능)
- **pg_dump**: 논리적 백업
- **pg_basebackup**: 물리적 백업

#### 8. **보안 기본사항**
- **Role**: 사용자 권한 관리
- **SSL**: 암호화 연결
- **pg_hba.conf**: 접근 제어

### 💡 실무 팁
- **정기적인 VACUUM**: 성능 유지의 핵심
- **적절한 인덱스**: 과도한 인덱스는 INSERT/UPDATE 성능 저하
- **통계 정보 최신화**: ANALYZE로 쿼리 최적화
- **모니터링 자동화**: Wraparound, 데드 튜플 비율 등 체크


---

[목록으로](https://shiwoo-park.github.io/blog)
