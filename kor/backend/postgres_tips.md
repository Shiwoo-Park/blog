# PostgreSQL tip 모음

> 날짜: 2024-03-20

## 주요 개념

- 스키마
  - 데이터베이스 내에서 테이블을 논리적으로 그룹화하는 방법
  - 기본 스키마 = `public`
  - 스키마는 데이터베이스 객체(테이블, 뷰, 인덱스, 함수 등)의 컬렉션으로, 데이터베이스 내에서 별도의 네임스페이스를 제공하여, 이름이 같은 다른 스키마의 객체와 구분할 수 있게 합니다. 
  - 이를 통해 데이터베이스의 조직화 및 접근 제어를 용이하게 하며, 다중 사용자 환경에서 객체 이름 충돌을 방지할 수 있습니다.
- 데이터베이스간 정보조회
  - A DB로 접속하여 B DB 테이블 정보를 쿼리로 얻어오는 것은 불가능함.

## 쿼리

```sql
-- 데이터베이스 목록 조회
SELECT datname FROM pg_database;

-- 특정 테이블의 구조(컬럼 정보) 조회
SELECT
    column_name,
    data_type,
    character_maximum_length,
    is_nullable,
    column_default
FROM
    information_schema.columns
WHERE
    table_name = 'your_table_name';

-- 스키마 까지 명시할 필요가 있다면 조건 추가
    AND table_schema = 'your_schema_name';

-- table 삭제
DROP TABLE my_table;

-- DB 삭제
DROP DATABASE IF EXISTS 데이터베이스명;
```

---

[목록으로](https://shiwoo-park.github.io/blog/kor)
