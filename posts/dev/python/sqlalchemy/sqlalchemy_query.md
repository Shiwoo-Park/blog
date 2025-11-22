---
layout: post
title: "SQLAlchemy 2.x 의 쿼리(Select) 객체 알아보기"
date: 2025-06-07
categories: [python, sqlalchemy]
---
- `stmt = select(User.name, User.age)`에서 `stmt`는
- **SQLAlchemy 2.x 기준의 SQL 표현 객체**로, 타입은 `sqlalchemy.sql.selectable.Select`이고,
- SQLModel과 SQLAlchemy에서 핵심적으로 다루는 객체야.
- 이 객체는 이후 다양한 체이닝 메서드로 **쿼리 조합 가능** (ex. `.where()`, `.order_by()`)

```python
from sqlalchemy.sql.selectable import Select

type(stmt)  # sqlalchemy.sql.selectable.Select
```

## ✅ `select(...)` 의 주요 체이닝 메서드

| 메서드              | 설명                                                | 예제 코드                                                         |
| ------------------- | --------------------------------------------------- | ----------------------------------------------------------------- |
| `.where(...)`       | 필터 조건 추가 (`AND`, `==`, `in_()` 등)            | `select(User).where(User.age > 20)`                               |
| `.select_from(...)` | 쿼리의 기준이 되는 FROM 테이블(또는 서브쿼리) 지정  | `select(User).select_from(Order).join(User)`                      |
| `.order_by(...)`    | 정렬 기준 지정                                      | `select(User).order_by(User.created_at.desc())`                   |
| `.limit(...)`       | limit 절 지정                                       | `select(User).limit(10)`                                          |
| `.offset(...)`      | offset 절 지정                                      | `select(User).offset(20)`                                         |
| `.distinct()`       | `DISTINCT` 적용                                     | `select(User.name).distinct()`                                    |
| `.join(...)`        | 조인 (첫 번째 테이블 기준)                          | `select(Order).join(User)`                                        |
| `.join_from(...)`   | 조인 방향 커스터마이징 (기준 테이블 명시)           | `select(User).join_from(Order, User)`                             |
| `.outerjoin(...)`   | LEFT OUTER JOIN 등                                  | `select(User).outerjoin(Order)`                                   |
| `.group_by(...)`    | 그룹핑 지정 (`GROUP BY`)                            | `select(User.city, func.count()).group_by(User.city)`             |
| `.having(...)`      | 그룹핑 후 조건 필터링 (`HAVING`)                    | `select(User.city).group_by(User.city).having(func.count() > 10)` |
| `.options(...)`     | ORM 로딩 전략 지정 (`selectinload`, `load_only` 등) | `select(User).options(selectinload(User.posts))`                  |

## ✅ SQLAlchemy where() 조건 표현식 요약표

| 표현식 유형          | 예시 코드                         | 의미 / SQL 변환            |
| -------------------- | --------------------------------- | -------------------------- |
| `==`                 | `User.name == "홍길동"`           | `name = '홍길동'`          |
| `!=`                 | `User.age != 30`                  | `age <> 30`                |
| `<`, `<=`, `>`, `>=` | `User.age >= 18`                  | `age >= 18`                |
| `in_()`              | `User.city.in_(["서울", "부산"])` | `city IN ('서울', '부산')` |
| `notin_()`           | `~User.city.in_(["서울"])`        | `city NOT IN ('서울')`     |
| `is_()`              | `User.deleted_at.is_(None)`       | `deleted_at IS NULL`       |
| `is_not()`           | `User.deleted_at.is_not(None)`    | `deleted_at IS NOT NULL`   |
| `like()`             | `User.name.like("김%")`           | `name LIKE '김%'`          |
| `ilike()`            | `User.name.ilike("%kim%")`        | `name ILIKE '%kim%'`       |
| `startswith()`       | `User.name.startswith("이")`      | `name LIKE '이%'`          |
| `contains()`         | `User.bio.contains("개발")`       | `bio LIKE '%개발%'`        |
| `between()`          | `User.age.between(20, 30)`        | `age BETWEEN 20 AND 30`    |

## ✅ 자주 쓰이는 종류별 `join` 요약표

| 구문                        | SQL 관점                   | 기준 테이블 | 조인 방식    | 결과            |
| --------------------------- | -------------------------- | ----------- | ------------ | --------------- |
| `select(A).join(B)`         | `FROM A JOIN B`            | A           | `INNER JOIN` | A의 컬럼만      |
| `select(A, B).join(B)`      | `FROM A JOIN B`            | A           | `INNER JOIN` | A, B 컬럼(튜플) |
| `select(A).join_from(B, A)` | `FROM B JOIN A`            | B           | `INNER JOIN` | A의 컬럼만      |
| `select(A).outerjoin(B)`    | `FROM A LEFT OUTER JOIN B` | A           | `LEFT JOIN`  | A의 컬럼만      |

## ✅ `select(...).options(...)` 주요 옵션 정리

| 옵션             | 설명                                                     | 사용 상황                           | 예제                                         |
| ---------------- | -------------------------------------------------------- | ----------------------------------- | -------------------------------------------- |
| `selectinload()` | 관계된 데이터를 별도 쿼리로 **in 조건**으로 한 번에 로딩 | 다대일, 일대다 관계 효율적으로 로딩 | `select(A).options(selectinload(A.b_list))`  |
| `joinedload()`   | 관계된 데이터를 **JOIN**으로 한 번에 로딩                | 조인해도 데이터 중복 적고 빠를 때   | `select(A).options(joinedload(A.b))`         |
| `subqueryload()` | 관계된 데이터를 **서브쿼리**로 로딩                      | 중첩 관계가 많을 때                 | `select(A).options(subqueryload(A.b_list))`  |
| `lazyload()`     | 해당 필드를 **lazy 로딩**으로 명시                       | 기본 eager 로딩을 비활성화          | `select(A).options(lazyload(A.b))`           |
| `raiseload()`    | 접근 시 **예외 발생** (안 쓰게 차단)                     | 보안/성능 이슈로 로딩 원천 차단     | `select(A).options(raiseload(A.b))`          |
| `defer()`        | 지정된 컬럼 **지연 로딩** (필요할 때만 로딩)             | 특정 큰 컬럼을 기본 쿼리에서 제외   | `select(A).options(defer(A.large_column))`   |
| `undefer()`      | `defer()`된 컬럼을 **즉시 로딩**                         | 원래 지연되던 필드를 강제로 로딩    | `select(A).options(undefer(A.large_column))` |
| `load_only()`    | 특정 컬럼만 **선택 로딩**                                | 쿼리 성능 최적화                    | `select(A).options(load_only(A.id, A.name))` |

## ✅ 활용 팁

### 1. 조건부 필터 체이닝

```python
if name:
    stmt = stmt.where(User.name == name)

if age:
    stmt = stmt.where(User.age == age)
```

→ 조건적으로 필터를 추가할 수 있어 실용적

### 2. SQL 보기 (`print(stmt)`)

```python
print(stmt)  # 출력: SELECT user.name, user.age FROM user ...
```

→ 실제 SQL 쿼리문 확인 가능 (`compile()`도 가능)

```python
print(stmt.compile(compile_kwargs={"literal_binds": True}))
```

### 3. `distinct(), group_by()` 사용법

```python
stmt = select(User.name).distinct()
stmt = select(User.name, func.count()).group_by(User.name)
```

### 4. `select_from()`으로 기준 테이블 명시

```python
stmt = select(User.name, UserGroup.name).select_from(
    join(User, UserGroup, User.group_id == UserGroup.id)
)
```

### 5. 2개 테이블 join 하여 둘다 조회 시,

```python
result = session.exec(select(A, B).join(B)).all()

# 결과는 (A, B) 튜플 형태로 리턴됨
# 즉, [(<A 객체>, <B 객체>), ...] 식으로 결과를 받아볼 수 있음
for a, b in result:
    print(a.title, b.name)
```

### 6. where 구문 복합 조건 예제 (or, and 섞어서)

```python
from sqlalchemy import select, and_, or_

# 복합 논리식
# WHERE (age >= 18 AND age <= 30) OR (city = '서울' AND is_active = true)

stmt = select(User).where(
    or_(
        and_(User.age >= 18, User.age <= 30),
        and_(User.city == "서울", User.is_active == True)
    )
)


# 다양한 조건문 조합 예시 (in_, is_not, like 등)

stmt = select(User).where(
    and_(
        User.status.in_(["active", "pending"]),
        User.email.ilike("%@baropharm.co.kr"),
        User.deleted_at.is_(None),
        ~User.name.like("테스트%")
    )
)
```

## ✅ 주의사항

| 항목                        | 설명                                         |
| --------------------------- | -------------------------------------------- |
| `.where()`는 체이닝 가능    | `.where(...).where(...)` 형태로 여러 개 가능 |
| `stmt` 자체는 **실행 불가** | 반드시 `session.exec(stmt)`로 실행해야 함    |
| SQLModel 사용 시            | 필드 선택은 `User.field`, 전체는 `User` 전달 |
