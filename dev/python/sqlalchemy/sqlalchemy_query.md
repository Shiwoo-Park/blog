# SQLAlchemy 2.x 의 쿼리(Select) 객체 알아보기

> 날짜: 2025-06-07

[목록으로](https://shiwoo-park.github.io/blog)

---

- `stmt = select(User.name, User.age)`에서 `stmt`는 
- **SQLAlchemy 2.x 기준의 SQL 표현 객체**로, 타입은 `sqlalchemy.sql.selectable.Select`이고, 
- SQLModel과 SQLAlchemy에서 핵심적으로 다루는 객체야.


## ✅ 객체 타입

```python
from sqlalchemy.sql.selectable import Select

type(stmt)  # sqlalchemy.sql.selectable.Select
```

* `select()` 함수는 `Select` 객체를 반환하고,
* 이 객체는 이후 `.where()`, `.order_by()` 등으로 **쿼리 조합 가능**


## ✅ 주요 체이닝 메서드

| 메서드               | 설명                                                      |
| ----------------- | ------------------------------------------------------- |
| `.where(...)`     | 필터 조건 추가 (`AND`, `==`, `in_()` 등)                       |
| `.order_by(...)`  | 정렬 기준 지정                                                |
| `.limit(...)`     | limit 절 지정                                              |
| `.offset(...)`    | offset 절 지정                                             |
| `.distinct()`     | `DISTINCT` 적용                                           |
| `.join(...)`      | 다른 테이블 조인                                               |
| `.outerjoin(...)` | LEFT OUTER JOIN 등 조인                                    |
| `.group_by(...)`  | 그룹핑 지정 (`GROUP BY`)                                     |
| `.having(...)`    | 그룹핑 조건 필터링 (`HAVING`)                                   |
| `.options(...)`   | eager-loading 등 ORM 옵션 설정 (`load_only`, `selectinload`) |


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


### 3. `distinct()` or `group_by()`와 함께 쓰기

```python
stmt = select(User.name).distinct()
```

```python
stmt = select(User.name, func.count()).group_by(User.name)
```


### 4. `select_from()`으로 기준 테이블 명시

```python
stmt = select(User.name, UserGroup.name).select_from(
    join(User, UserGroup, User.group_id == UserGroup.id)
)
```


## ✅ 주의사항

| 항목                   | 설명                                   |
| -------------------- | ------------------------------------ |
| `.where()`는 체이닝 가능   | `.where(...).where(...)` 형태로 여러 개 가능 |
| `stmt` 자체는 **실행 불가** | 반드시 `session.exec(stmt)`로 실행해야 함     |
| SQLModel 사용 시        | 필드 선택은 `User.field`, 전체는 `User` 전달   |

---

[목록으로](https://shiwoo-park.github.io/blog)
