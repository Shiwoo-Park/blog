# sqlalchemy v2 + sqlmodel 기반 모델 및 CRUD 작성 기본 가이드

> 날짜: 2025-06-06

[목록으로](https://shiwoo-park.github.io/blog)

---

## ✅ SQLAlchemy 2.x & SQLModel 소개

* **SQLAlchemy 2.x**는 `async/await` 지원, **Declarative ORM**과 **Core SQL**를 명확히 분리
* **SQLModel**은 **Pydantic 2 + SQLAlchemy 2 ORM** 기반의 상위 추상화로 FastAPI에 적합

---

## 🧱 모델 정의 예시 (Pydantic v2 + SQLModel 기준)

## 1:N 관계

```python
from sqlmodel import SQLModel, Field, Relationship
from datetime import date, datetime, time
from enum import Enum
from typing import List


class UserGroup(SQLModel, table=True):
    id: int | None = Field(default=None, primary_key=True)
    name: str = Field(index=True)

    users: List["User"] = Relationship(back_populates="group")

class UserStatus(str, Enum):
    ACTIVE = "active"
    INACTIVE = "inactive"
    SUSPENDED = "suspended"


class User(SQLModel, table=True):
    id: int | None = Field(default=None, primary_key=True, description="PK (auto increment)")
    name: str = Field(title="이름", description="사용자의 전체 이름", max_length=100)
    email: str | None = Field(default=None, title="이메일", description="이메일 주소, nullable", max_length=255)

    age: int | None = Field(default=None, ge=0, lt=200, description="나이, nullable")
    score: float = Field(
        default=0.01,
        description="기본 점수 (0보다 커야 하며 소숫점 둘째자리까지 반올림)",
        gt=0
    )

    is_active: bool = Field(default=True, description="활성 상태 여부")

    birth_date: date | None = Field(default=None, title="생년월일", description="nullable")
    last_login_at: datetime | None = Field(default=None, description="마지막 로그인 시간")
    preferred_login_time: time | None = Field(default=None, description="선호 로그인 시간")

    big_id: int | None = Field(
        default=None,
        sa_column_kwargs={"bigint": True},
        description="bigint 컬럼 예시"
    )

    status: UserStatus = Field(
        default=UserStatus.ACTIVE,
        title="상태",
        description="사용자 상태 (Enum: active, inactive, suspended)"
    )

    # Relationship (ForeignKey)
    group_id: int | None = Field(default=None, foreign_key="usergroup.id")
    group: UserGroup | None = Relationship(back_populates="users")

    @field_validator("score")
    def round_score(cls, v: float) -> float:
        return round(v, 2)
```

## N:N 관계

```python
class PostTagLink(SQLModel, table=True):
    post_id: int = Field(foreign_key="post.id", primary_key=True)
    tag_id: int = Field(foreign_key="tag.id", primary_key=True)


class Post(SQLModel, table=True):
    id: int | None = Field(default=None, primary_key=True)
    title: str = Field(title="제목", description="게시글 제목", max_length=255)
    content: str | None = Field(
        default="",
        title="본문 내용",
        description="게시글의 본문 텍스트 (nullable, 기본값은 빈 문자열)",
        sa_column_kwargs={"nullable": True}
    )

    tags: List["Tag"] = Relationship(back_populates="posts", link_model="PostTagLink")



class Tag(SQLModel, table=True):
    id: int | None = Field(default=None, primary_key=True)
    name: str

    posts: List["Post"] = Relationship(back_populates="tags", link_model=PostTagLink)
```

---

## ⚙️ Async DB 세션 구성

```python
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker

DATABASE_URL = "postgresql+asyncpg://user:pass@host/dbname"

engine = create_async_engine(DATABASE_URL, echo=True)
async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
```

---

## 🔁 Dependency (FastAPI 기준)

```python
from fastapi import Depends
from contextlib import asynccontextmanager

@asynccontextmanager
async def get_session():
    async with async_session() as session:
        yield session
```

---

## 🛠️ 기본 쿼리 예시 (AsyncSession 사용)

### 1. Insert

```python
async with async_session() as session:
    user = User(name="홍길동", email="hong@example.com")
    session.add(user)
    await session.commit()
```

---

### 2. Select

```python
# 단일 row
stmt = select(User).where(User.name == "홍길동")
result = await session.exec(stmt)
user = result.first()

# 전체 row
stmt = select(User)
result = await session.exec(stmt)
users = result.all()
```

---

### 3. Update

```python
stmt = select(User).where(User.id == 1)
result = await session.exec(stmt)
user = result.one()
user.email = "new@example.com"
await session.commit()
```

---

### 4. Delete

```python
stmt = select(User).where(User.id == 1)
result = await session.exec(stmt)
user = result.one()
await session.delete(user)
await session.commit()
```

---

### 5. 정렬, 필터, 페이징

```python
stmt = select(User).where(User.name.like("홍%")).order_by(User.id.desc()).offset(0).limit(10)
result = await session.exec(stmt)
users = result.all()
```

---

## 📌 참고

* SQLAlchemy 2.x는 **statement-first 방식** (`select(User)`)이 기본
* `session.exec()`은 **SQLModel 전용** (SQLAlchemy는 `session.execute()`)

---

---

[목록으로](https://shiwoo-park.github.io/blog)
