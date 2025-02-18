# Postgres - GIN index 에 대여

> 날짜: 2025-02-18

[목록으로](https://shiwoo-park.github.io/blog)

---

### **1. GIN (Generalized Inverted Index) 인덱스란?**
**GIN (Generalized Inverted Index)**는 **PostgreSQL**에서 `JSONB`, `ARRAY`, `hstore`, `tsvector` 등의 복합 데이터 타입을 효율적으로 검색하기 위한 특수한 인덱스입니다.  
특히 배열(`ArrayField`)이나 `JSONB` 필드에서 특정 값의 포함 여부를 검색할 때 매우 유용합니다.

---

### **2. GIN 인덱스의 동작 방식**
일반적인 B-Tree 인덱스는 개별 행(row)을 정렬하여 검색 속도를 높이지만, **GIN 인덱스는 각 요소(값)에 대한 역색인**(inverted index)을 생성합니다.

예를 들어, `target_user_group_id_white_list` 필드에 `[1, 2, 3]`이 저장된 경우, GIN 인덱스는 다음과 같은 구조를 가집니다:

| 값   | 행 ID |
|------|------|
| 1    | 1, 2, 5 |
| 2    | 1, 3 |
| 3    | 1, 4 |
| 4    | 2, 4 |
| 5    | 3 |

즉, 개별 값(요소) 자체가 인덱싱되므로 특정 값이 포함된 행을 매우 빠르게 찾을 수 있습니다.

---

### **3. GIN 인덱스의 장점**
✔ **빠른 검색 속도**  
  - `ARRAY` 또는 `JSONB` 필드에서 특정 값이 포함된 데이터를 조회할 때 성능이 우수함
  - `@>` (contains), `?`, `?|`, `?&` 연산자를 사용하는 경우 매우 효율적

✔ **비교적 작은 크기의 인덱스**  
  - 각 요소(값)를 개별적으로 인덱싱하므로 중복된 값이 많은 경우 효율적

✔ **배열(`ArrayField`) 및 `JSONB` 필드에 적합**  
  - 다대다(M:N) 관계 데이터를 저장할 때 쿼리 최적화 가능

---

### **4. GIN 인덱스의 단점 & 주의사항**
❌ **쓰기(INSERT/UPDATE) 성능 저하**  
  - **B-Tree 인덱스보다 업데이트 비용이 훨씬 큼**
  - 하나의 값만 변경되어도 모든 요소를 다시 인덱싱해야 하기 때문

❌ **많은 작은 트랜잭션이 있는 경우 비효율적**  
  - 트랜잭션마다 GIN 인덱스가 업데이트되어 Lock이 걸릴 수 있음

❌ **정렬(`ORDER BY`)에는 적절하지 않음**  
  - `ORDER BY`와 함께 사용할 경우 B-Tree보다 비효율적

❌ **최적의 조건에서만 활용해야 함**  
  - 전체 테이블 스캔이 필요한 경우 성능 개선 효과가 적음

---

### **5. GIN 인덱스를 활용한 적절한 사용법**
**📌 (1) 특정 값이 포함된 배열 검색 (빠른 조회 가능)**
```sql
SELECT * FROM benefit_collections WHERE target_user_group_id_white_list @> ARRAY[1];
```
**→ `GIN INDEX` 적용 시, 빠르게 결과 반환**

---

**📌 (2) `GIN INDEX`는 삽입/수정이 잦은 경우 사용하지 않는 것이 좋음**
예를 들어, 하루에도 수천 건 이상의 데이터가 업데이트되는 경우 GIN 인덱스는 과부하를 유발할 수 있음.

이런 경우:
1. **인덱스를 삭제하고 테이블 스캔 활용**
   ```sql
   DROP INDEX IF EXISTS idx_benefit_collections__target_user_group_id_white_list;
   ```
2. **B-Tree + Partial Index 활용 (자주 조회되는 값만 인덱싱)**
   ```sql
   CREATE INDEX idx_benefit_collections_partial 
   ON benefit_collections (id)
   WHERE array_length(target_user_group_id_white_list, 1) > 0;
   ```
---

**📌 (3) `GIN INDEX`를 사용할 때 `fastupdate=off` 옵션 고려**
기본적으로 GIN 인덱스는 **"Fast Update Buffer"**를 사용하여 데이터를 빠르게 추가하지만, 자주 업데이트되는 경우 오히려 성능이 저하될 수 있음.
```sql
ALTER INDEX idx_benefit_collections__target_user_group_id_white_list SET (fastupdate = off);
```
이렇게 설정하면 쓰기 성능이 향상될 수 있음.

---

### **6. GIN 인덱스 vs B-Tree 인덱스 비교**
| 비교 항목 | GIN 인덱스 | B-Tree 인덱스 |
|----------|----------|----------|
| 최적 데이터 타입 | `ARRAY`, `JSONB`, `hstore`, `tsvector` | `INTEGER`, `VARCHAR`, `TIMESTAMP` 등 일반 필드 |
| 주요 활용 쿼리 | `@>`, `?`, `?|`, `?&` | `=`, `>`, `<`, `BETWEEN` |
| 검색 속도 | **빠름** | 보통 |
| `ORDER BY` 성능 | **느림** | **빠름** |
| INSERT/UPDATE 성능 | **느림 (비효율적)** | **빠름 (일반적으로 더 적합)** |
| 적절한 사용 예시 | `WHERE jsonb_column @> '{"key": "value"}'` | `WHERE age > 30 ORDER BY age` |

---

### **7. 결론**
✔ **배열(`ArrayField`) 또는 `JSONB` 검색이 많다면 GIN 인덱스를 적극 활용**  
✔ **삽입/수정이 잦은 경우 GIN 인덱스를 피하고 Partial Index나 B-Tree 사용**  
✔ **빠른 업데이트가 필요한 경우 `fastupdate=off` 설정 고려**  
✔ **정렬(`ORDER BY`)에는 적합하지 않음 → B-Tree를 사용해야 함**  

즉, **"조회 쿼리가 많고 업데이트가 적은 경우 GIN 인덱스를 사용"** 하는 것이 가장 이상적인 활용법입니다. 🚀

---

[목록으로](https://shiwoo-park.github.io/blog)
