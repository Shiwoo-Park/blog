---
layout: post
title: "SQLAlchemy 2.x 의 쿼리결과(Result) 객체 파헤치기"
date: 2025-06-07
categories: [python, sqlalchemy]
---
## 쿼리 결과 추출 메서드 목록

- `result = await session.exec(stmt)` 에서 가져온 result 객체
- 객체 타입: `sqlalchemy.engine.Result`


| 메서드              | 설명                              | 예시                             |
| ---------------- | ------------------------------- | ------------------------------ |
| `.first()`       | 첫 번째 row만 반환 (`None` 가능)        | `user = result.first()`        |
| `.one()`         | row 1개 반환, 없거나 여러 개면 **예외 발생**  | `user = result.one()`          |
| `.one_or_none()` | row 1개 반환, 없으면 `None`, 여러 개면 예외 | `user = result.one_or_none()`  |
| `.scalar()`      | 첫 row의 첫 컬럼값만 반환                | `id = result.scalar()`         |
| `.scalars()`     | 첫 컬럼 값만 리스트로 추출 (단일 컬럼 쿼리에 주로 사용) | `ids = result.scalars().all()` |
| `.all()`         | 모든 row 반환 (list of row/tuple)   | `rows = result.all()`          |
| `.fetchall()`    | `.all()`과 동일 (동의어)              | `result.fetchall()`            |
| `.fetchone()`    | `.first()`와 유사 (동의어)            | `result.fetchone()`            |

## 메서드 사용 예시

```python
# .scalars() 예시
# - 한 개 컬럼만 select 했을 때 매우 유용

stmt = select(User.id)
result = await session.exec(stmt)
user_ids = result.scalars().all()  # [1, 2, 3, ...]


# ----------------------
# .one() / .one_or_none() 사용시 주의사항
# - 응답 레코드가 1개가 아니면 에러

stmt = select(User).where(User.id == 1)
user = await session.exec(stmt)
one_user = user.one()  # 없으면 NoResultFound, 2개 이상이면 MultipleResultsFound 예외 발생
```

## unique() 로 결과데이터 중복 제거

### ✅ `unique()`는 **전체 row 기준으로 유일성**을 판단해

즉, 여러 필드를 select 했을 때:

```python
stmt = select(User.name, User.age)
result = await session.exec(stmt)
rows = result.unique().all()
```

이때 `.unique()`는 `(name, age)` **튜플 전체가 동일한 경우**만 중복으로 간주해서 제거해.


### 예시

```python
[
  ("홍길동", 30),
  ("홍길동", 30),
  ("홍길동", 31),
]
```

→ `unique()` 적용 시 결과:

```python
[
  ("홍길동", 30),
  ("홍길동", 31),
]
```

즉, **(name, age)** 전체 조합이 같아야 중복으로 판단돼.


### ✅ `.scalars()`와 `.unique()` 같이 쓰면?

```python
stmt = select(User.name)
result = await session.exec(stmt)
names = result.unique().scalars().all()
```

이건 **단일 필드 (`name`) 기준 중복 제거**가 되는 형태.


## 요약

### 결과 추출 메서드

| 함수                | 반환 결과           | 특징                   |
| ----------------- | --------------- | -------------------- |
| `first()`         | 첫 row 또는 `None` | 가장 많이 사용됨            |
| `all()`           | 전체 row 리스트      | 튜플 또는 모델 객체 리스트      |
| `scalars().all()` | 첫 컬럼 리스트        | 값만 추출 (단일 컬럼 select) |
| `one()`           | row 1개          | 없거나 여러 개 → **예외**    |
| `one_or_none()`   | row 1개 or None  | 여러 개 → **예외**        |

### unique()

| 상황                                 | `unique()` 기준          |
| ---------------------------------- | ---------------------- |
| `select(User.name, User.age)`      | `(name, age)` 튜플 전체 데이터 기준 중복 제거 |
| `select(User.name)` + `.scalars()` | `name` 값 기준으로 중복 제거    |
