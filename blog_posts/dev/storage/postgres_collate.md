---
layout: post
title: "PostgreSQL - 문자열 필드 COLLATE 와 정렬"
date: 2024-10-29
categories: [database, postgresql, i18n]
---

# PostgreSQL - 문자열 필드 COLLATE 와 정렬

> 날짜: 2024-10-29

[목록으로](https://shiwoo-park.github.io/blog)

---

PostgreSQL에서 `COLLATE`는 **문자열의 정렬 및 비교 방식**을 정의하는 데 사용됩니다. 이는 데이터베이스, 테이블, 컬럼, 또는 쿼리 수준에서 적용할 수 있으며, 각 언어의 고유한 정렬 규칙을 지원하여 다국어 데이터 처리에 유용합니다. 주요 개념과 사용법은 다음과 같습니다.

### 1. `COLLATE`의 개념
- **정렬 순서**: `COLLATE`는 문자열이 저장되거나 쿼리될 때, 어떤 기준으로 정렬하고 비교할지 결정합니다. 언어마다 특수 문자가 다르고, 일부 언어에서는 대문자와 소문자를 구분하지 않거나 정렬이 달라질 수 있기 때문에 `COLLATE` 설정이 중요합니다.
- **비교 규칙**: 예를 들어, 한글이나 영어의 경우 `a, A`가 같은 위치로 간주될지 아니면 다른 위치로 간주될지를 `COLLATE` 설정에 따라 제어할 수 있습니다.

### 2. `COLLATE` 사용 위치
- **데이터베이스 수준**: 데이터베이스를 생성할 때 기본 `COLLATE`를 설정하여, 데이터베이스 내 모든 텍스트 필드에 적용되는 기본 정렬 규칙을 설정할 수 있습니다.
  
  ```sql
  CREATE DATABASE mydb WITH LC_COLLATE = 'ko_KR.utf8';
  ```

- **테이블 또는 컬럼 수준**: 테이블이나 컬럼을 정의할 때 특정 `COLLATE`를 적용할 수 있습니다.

  ```sql
  CREATE TABLE example (
      name VARCHAR(100) COLLATE "ko_KR.utf8"
  );
  ```

- **쿼리 수준**: 쿼리 내에서만 임시로 다른 `COLLATE`를 적용할 수 있습니다. 예를 들어, 한글로 정렬하려는 경우 다음과 같이 쿼리에 적용할 수 있습니다.

  ```sql
  SELECT name FROM example ORDER BY name COLLATE "ko_KR.utf8";
  ```

### 3. 주요 Collation 예시
- **C Collation**: ASCII 기반으로 빠르게 정렬하는 방식입니다. 다국어 지원 없이 단순하게 코드 순으로 정렬하며, 영어 알파벳과 숫자에 대해서만 제대로 정렬이 가능합니다.
- **ko_KR.utf8**: 한국어 기준으로 정렬하고 비교합니다. 한글 데이터를 사용하는 경우, 이 설정으로 대소문자 구분 없이 유사한 발음으로 정렬됩니다.

### 4. `COLLATE` 변경 시 주의사항
- **성능**: `COLLATE "C"`는 다국어 처리 없이 단순한 코드 순 정렬을 하므로 빠르게 동작하지만, 언어별 고유 정렬이 필요할 때는 적합하지 않습니다.
- **인덱스와 충돌**: 특정 `COLLATE`로 생성된 인덱스는 다른 `COLLATE`로 설정된 컬럼에는 재사용할 수 없습니다.
  
### 5. 사용 예시
한글 문자열을 저장하는 컬럼에 `COLLATE "ko_KR.utf8"`을 적용한 후, 쿼리 시에 그 기준으로 정렬이 이루어지도록 할 수 있습니다.

```sql
-- 특정 collation 으로 정렬하여 select
SELECT name FROM example ORDER BY name COLLATE "ko_KR.utf8";

-- 한글 정렬 (ansii 키값 기준으로 정렬)
ALTER TABLE my_inventories ALTER COLUMN "name" SET DATA TYPE character varying(100) COLLATE "C";
```

### 6. 한글 문자열 필드 정렬 `COLLATE "C"`

```sql
-- 한글 정렬 (ansii 키값 기준으로 정렬)
ALTER TABLE my_inventories ALTER COLUMN "name" SET DATA TYPE character varying(100) COLLATE "C";
```

- COLLATE "C"는 문자열 비교 및 정렬 기준을 POSIX 기본 정렬 순서로 설정합니다.
- 이 설정은 특수 문자나 한글을 포함한 다국어에 대해 특별한 정렬을 하지 않고, 단순히 ASCII 코드 값 순서대로 비교합니다.
- 따라서 한글이나 특수 문자가 포함된 문자열은 예상치 못한 순서로 정렬될 수 있으며, 주로 성능을 위해 사용하는 경우가 많습니다.
- 이 설정으로 인해 다국어가 아닌 문자열에서는 빠른 비교와 정렬이 가능하지만, 한글이나 특수 문자를 포함한 경우 정렬이 어색할 수 있습니다.


---

[목록으로](https://shiwoo-park.github.io/blog)
