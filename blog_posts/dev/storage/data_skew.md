---
layout: post
title: "데이터 쏠림 현상 Data skew 에 대하여"
date: 2025-02-18
categories: [database, performance, partitioning]
---

# 데이터 쏠림 현상 Data skew 에 대하여

> 날짜: 2025-02-18

[목록으로](https://shiwoo-park.github.io/blog)

---

데이터 파티셔닝 시 특정 유저의 데이터 비중이 너무 커서 균형이 무너지는 현상을 **"데이터 스큐(Data Skew)"** 문제라고 합니다.

### **1. 데이터 스큐(Data Skew)란?**
- 데이터가 파티션에 **균등하게 분배되지 않고** 특정 파티션에 데이터가 **편중**되는 현상
- 특정 키(예: 특정 유저 ID)에 **너무 많은 데이터가 집중**되어 일부 파티션의 크기가 커지고, 읽기/쓰기 성능이 불균형해짐

---

### **2. 데이터 스큐가 발생하는 주요 원인**
1. **편향된 키(Hot Key) 문제**
   - 특정 유저(ID)나 특정 값이 너무 많은 데이터를 포함하는 경우
   - 예: **"VIP 고객"** 한 명이 전체 트랜잭션의 80%를 차지하는 경우

2. **잘못된 파티셔닝 키 선택**
   - 데이터가 고르게 분포되지 않는 파티션 키를 사용한 경우
   - 예: 날짜 기반 파티셔닝을 했는데, 특정 날짜(예: 블랙 프라이데이) 데이터가 급증하는 경우

3. **동적 파티셔닝 오버로드**
   - 새로운 파티션이 자주 생성되면서 특정 파티션이 급격히 커지는 문제
   - 예: 매일 새로운 유저 ID로 파티션을 만들었는데, 몇몇 유저만 지속적으로 데이터를 생성하는 경우

4. **노드 불균형 (Distributed Systems)**
   - 클러스터형 DB에서 일부 노드가 과부하되고 다른 노드는 가벼운 상태가 되는 문제
   - 예: **Shard A**가 트래픽을 90% 가져가고 **Shard B**는 10%만 처리하는 경우

---

### **3. 데이터 스큐가 초래하는 문제점**
- **성능 저하**: 특정 파티션에 **쓰기 부하**가 집중되어 트랜잭션 속도가 느려짐
- **쿼리 불균형**: 특정 노드 또는 파티션에서만 **I/O 부하**가 발생하여 조회 성능 저하
- **스토리지 불균형**: 일부 파티션의 크기가 너무 커져 디스크 공간 낭비
- **운영 비용 증가**: 클러스터형 DB에서는 특정 노드가 과부하되면서 전체적인 확장 비용이 증가

---

### **4. 데이터 스큐 해결 방법**
✅ **1. 더 나은 파티션 키 선택**
   - 균등한 분포를 가지는 **해시 기반 파티셔닝(Hash Partitioning)** 사용  
     → `user_id % N` 방식으로 적절한 `N`을 선택하여 고르게 분배
   - `user_id` 대신, **고유한 트랜잭션 ID** 또는 **범용적인 시간 기반 키** 활용

✅ **2. Hot Key 감지 및 해결**
   - 특정 유저(ID) 쏠림이 심한 경우, **해시를 추가한 가짜 ID**를 생성하여 분산  
     ```sql
     SELECT * FROM logs WHERE hash(user_id) % 4 = 2;
     ```
   - 가짜 샤드 ID를 이용하여 데이터 분산
     ```sql
     shard_id = user_id % 10
     ```

✅ **3. 동적 파티셔닝 제한**
   - 너무 많은 파티션이 생기는 경우, **범위를 재설정**하거나 **로테이션 방식**으로 변경  
   - 예: `일별 파티션` 대신 `월별 파티션`으로 전환

✅ **4. Read-Only 노드 활용**
   - 특정 핫 유저 데이터만 **Replica**에서 처리하여 읽기 부하 분산

✅ **5. Adaptive Load Balancing**
   - **기계 학습 기반 Auto-Sharding** 시스템을 구축하여 특정 파티션이 과부하되면 자동으로 분할

---

### **5. 예제: 해시 파티셔닝 적용**
```sql
CREATE TABLE user_logs (
    user_id BIGINT NOT NULL,
    log_data TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
) PARTITION BY HASH (user_id);

CREATE TABLE user_logs_0 PARTITION OF user_logs FOR VALUES WITH (MODULUS 4, REMAINDER 0);
CREATE TABLE user_logs_1 PARTITION OF user_logs FOR VALUES WITH (MODULUS 4, REMAINDER 1);
CREATE TABLE user_logs_2 PARTITION OF user_logs FOR VALUES WITH (MODULUS 4, REMAINDER 2);
CREATE TABLE user_logs_3 PARTITION OF user_logs FOR VALUES WITH (MODULUS 4, REMAINDER 3);
```
- `user_id % 4` 방식으로 데이터를 4개의 파티션에 균등하게 분배

---

### **결론**
- **데이터 스큐 문제**는 **Hot Key 문제**와 **잘못된 파티셔닝 전략**으로 인해 발생
- **해시 파티셔닝**, **Hot Key 감지**, **Adaptive Load Balancing** 등의 방법으로 해결 가능
- **PostgreSQL에서는 해시 파티셔닝 및 GIN 인덱스 활용**이 유용할 수 있음

이제, **데이터가 균형 있게 분산**되도록 최적화할 수 있습니다! 🚀

---

[목록으로](https://shiwoo-park.github.io/blog)
