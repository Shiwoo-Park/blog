---
layout: post
title: "Pydantic 2 기반 풀스펙 모델 코드 (FastAPI + SQLModel + SQLAlchemy 2)"
date: 2025-06-15
categories: [python, pydantic, fastapi]
---
## 입출력 스키마 용 모델: Only Pydantic 2.x

```python
from pydantic import BaseModel, Field, field_validator, model_validator, field_serializer, computed_field
from enum import Enum
from datetime import datetime, date
from typing import Any

class TypeEnum(str, Enum):
    def __new__(cls, value: str, label: str):
        obj = str.__new__(cls)
        obj._value_ = value
        obj.label = label

        return obj

class UserType(TypeEnum):
    NORMAL = "NORMAL", "일반 회원"
    ADMIN = "ADMIN", "관리자"
    GUEST = "GUEST", "비회원"

class Role(str, Enum):
    USER = "user"
    ADMIN = "admin"


class User(BaseModel):
    id: int = Field(..., title="사용자 ID", description="정수형 고유 ID")
    name: str = Field(..., title="이름", description="사용자 이름")
    age: int = Field(..., title="나이", description="0 이상", ge=0)
    role: Role = Field(default=Role.USER, title="역할", description="사용자 역할 (Enum)")
    email: str | None = Field(
        default=None,
        alias="email_address",
        title="이메일",
        description="nullable 이메일 주소"
    )
    bio: str | None = Field(default=None, title="소개", description="nullable 자기소개")
    score: float = Field(default=1.0, title="점수", description="0보다 커야 함", gt=0)
    created_at: datetime = Field(default_factory=datetime.utcnow)
    birthday: date | None = Field(default=None, title="생일")
    misc: Any | None = Field(default=None, title="기타 정보")
    user_type: UserType = Field(default=UserType.NORMAL)

    # -------------------------
    # ✅ 필드 유효성 검사기
    @field_validator("name")
    def strip_and_capitalize_name(cls, v: str) -> str:
        return v.strip().title()

    @field_validator("score")
    def round_score(cls, v: float) -> float:
        return round(v, 2)

    # -------------------------
    # ✅ 모델 전처리
    @model_validator(mode="before")
    @classmethod
    def preprocess_input(cls, data: dict) -> dict:
        data["name"] = data.get("name", "").replace("  ", " ")
        return data

    # -------------------------
    # ✅ 모델 후처리
    @model_validator(mode="after")
    def validate_logic(self) -> "User":
        if self.role == Role.ADMIN and self.age < 18:
            raise ValueError("관리자는 18세 이상이어야 합니다")
        return self

    # -------------------------
    # ✅ 응답 직렬화
    @field_serializer("created_at")
    def format_created_at(self, value: datetime, _info) -> str:
        return value.strftime("%Y-%m-%d %H:%M")

    # -------------------------
    # ✅ 계산 필드 (출력 전용)
    @computed_field
    @property
    def is_adult(self) -> bool:
        return self.age >= 18

    @computed_field
    @property
    def user_type_label(self) -> str:
        return self.user_type.label

    # -------------------------
    # ✅ 모델 전역 설정
    model_config = {
        "use_enum_values": True,
        "populate_by_name": True,
        "str_strip_whitespace": True,
        "coerce_numbers_to_str": False,  # 예시: string 필드에 123 들어오면 에러 발생
        "extra": "forbid",               # 모델 정의 외 필드는 허용 안 함
        "frozen": False,                 # True로 하면 인스턴스 수정 불가
        "json_schema_extra": {
            "examples": [
                {
                    "id": 1,
                    "name": "홍길동",
                    "age": 30,
                    "role": "user",
                    "email_address": "hong@example.com",
                    "score": 3.14,
                    "birthday": "1990-01-01"
                }
            ]
        }
    }
```

## DB 테이블용 모델: SQLModel(SQLAlchemy 2 + Pydantic 2) 기반

```python
from sqlmodel import SQLModel, Field
from datetime import datetime, date
from typing import Any
from enum import Enum

class TypeEnum(str, Enum):
    def __new__(cls, value: str, label: str):
        obj = str.__new__(cls)
        obj._value_ = value
        obj.label = label

        return obj

class UserType(TypeEnum):
    NORMAL = "NORMAL", "일반 회원"
    ADMIN = "ADMIN", "관리자"
    GUEST = "GUEST", "비회원"


class Role(str, Enum):
    USER = "user"
    ADMIN = "admin"


class User(SQLModel, table=True):
    __tablename__ = "user"

    id: int | None = Field(default=None, primary_key=True, title="사용자 ID")
    name: str = Field(title="이름", max_length=100)
    age: int = Field(ge=0, title="나이")
    role: Role = Field(default=Role.USER, title="역할")

    email: str | None = Field(default=None, title="이메일", max_length=255)
    bio: str | None = Field(default=None, title="소개")
    score: float = Field(default=1.0, gt=0, title="점수")

    created_at: datetime = Field(default_factory=datetime.utcnow)
    birthday: date | None = Field(default=None)
    misc: Any | None = Field(default=None)

    user_type: UserType = Field(default=UserType.NORMAL, title="회원 유형")

    # ✅ Enum label 프로퍼티
    @property
    def user_type_label(self) -> str:
        return self.user_type.label
```
