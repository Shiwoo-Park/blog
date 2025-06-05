# Pydantic v2 의 BaseModel 파헤치기

> 날짜: 2025-05-14

[목록으로](https://shiwoo-park.github.io/blog)

---

# ✅ 1. 기본 사용법

```python
from pydantic import BaseModel

class User(BaseModel):
    id: int
    name: str
    email: str
    is_active: bool = True
```

## 기본 동작

- `User(id=1, name="Alice", email="alice@example.com")` 처럼 객체 생성
- `.model_dump()` → dict 반환
- `.model_validate(data)` → dict → 모델 변환 (역직렬화)

---

# ✅ 2. 타입 유효성 검사 + 변환

```python
class Product(BaseModel):
    name: str
    price: float
    is_available: bool
```

```python
Product(name="Item", price="1000", is_available="true")
# → 자동으로 float/boolean 으로 변환됨
```

> Pydantic v2는 엄격하게 `strict=True` 설정하면 자동 변환 막을 수 있음

---

# ✅ 3. 기본값, Optional 필드

```python
from typing import Optional

class Item(BaseModel):
    title: str
    description: Optional[str] = None
    price: float = 0.0
```

---

# ✅ 4. 중첩 모델

```python
class Address(BaseModel):
    city: str
    zip_code: str

class Customer(BaseModel):
    name: str
    address: Address
```

---

# ✅ 5. 리스트, 유니언

```python
from typing import Union

class Data(BaseModel):
    items: list[int]
    result: Union[int, str]
```

---

# ✅ 6. 필드 메타 정보: `Field`

```python
from pydantic import Field

class User(BaseModel):
    name: str = Field(..., min_length=2, max_length=50, description="이름")
    age: int = Field(default=0, ge=0, le=120)
```

---

# ✅ 7. 필드 alias 및 변환

```python
class User(BaseModel):
    full_name: str = Field(alias="fullName")

    model_config = {
        "populate_by_name": True
    }

User.model_validate({"fullName": "홍길동"})
```

---

# ✅ 8. 모델 설정 옵션 (Pydantic v2: `model_config`)

| 옵션                    | 설명                                                                |
| ----------------------- | ------------------------------------------------------------------- |
| `use_enum_values`       | Enum 객체 대신 `.value`를 사용                                      |
| `populate_by_name`      | alias 사용 시에도 field name 으로 할당 허용                         |
| `str_strip_whitespace`  | 문자열의 앞뒤 공백 제거                                             |
| `coerce_numbers_to_str` | 숫자를 문자열로 강제 변환                                           |
| `extra`                 | 모델 정의에 없는 필드 허용 여부 (`"forbid"`, `"allow"`, `"ignore"`) |
| `frozen`                | 모델을 불변 (immutable) 객체로                                      |
| `json_schema_extra`     | Swagger/OpenAPI 문서용 커스텀 설명 추가                             |

### 예시:

```python
class User(BaseModel):
    name: str

    model_config = {
        "use_enum_values": True,
        "populate_by_name": True,
        "extra": "forbid",  # 허용되지 않은 필드는 에러
        "str_strip_whitespace": True,
        "json_schema_extra": {
            "example": {
                "name": "홍길동"
            }
        }
    }
```

---

# ✅ 9. 유효성 검사 + 전처리 + 후처리

## ✅ 사용할 수 있는 주요 Pydantic v2 Validator / Hook 종류

| 데코레이터                             | 용도                    | 실행 시점            |
| --------------------------------- | --------------------- | ---------------- |
| `@field_validator`                | 개별 필드 단위 유효성 검사 / 후처리 | 입력 후 유효성 검사 시    |
| `@model_validator(mode="before")` | 전체 모델 단위 전처리          | 모델 생성 직전         |
| `@model_validator(mode="after")`  | 전체 모델 단위 후처리          | 모델 생성 후          |
| `@field_serializer`               | 직렬화 커스터마이징 (응답용)      | 출력 시 (dict/json) |
| `@computed_field`                 | 계산 필드 (저장 안됨)         | 응답 시 계산          |

---

## 🧪 각 예시 간단 정리

### 1. `@field_validator`

필드 단위 유효성 검사 및 값 가공 (예: 반올림, 길이 체크 등)

```python
from pydantic import field_validator

class User(SQLModel):
    score: float

    @field_validator("score")
    def round_score(cls, v):
        return round(v, 2)
```

---

### 2. `@model_validator(mode="before")`

모델 생성 전에 **입력 데이터 전체**를 검사하거나 가공

```python
from pydantic import model_validator

class User(SQLModel):
    name: str
    email: str

    @model_validator(mode="before")
    @classmethod
    def merge_name_email(cls, data):
        data["name"] = data["name"].strip().title()
        data["email"] = data["email"].lower()
        return data
```

---

### 3. `@model_validator(mode="after")`

모델 인스턴스 생성 **후**, 종속 필드 간 논리 검사

```python
@model_validator(mode="after")
def validate_name_email(self):
    if self.name in self.email:
        raise ValueError("이름이 이메일에 포함되어 있으면 안 됩니다")
    return self
```

---

### 4. `@field_serializer`

응답용 가공이 필요할 때 사용 (예: 날짜 형식 변경 등)

```python
from pydantic import field_serializer
from datetime import datetime

class User(SQLModel):
    created_at: datetime

    @field_serializer("created_at")
    def serialize_created_at(self, dt: datetime, _info):
        return dt.strftime("%Y-%m-%d %H:%M")
```

---

### 5. `@computed_field`

응답 시 계산용 필드 (DB 저장 안 됨, property 대체용)

```python
from pydantic import computed_field

class User(SQLModel):
    name: str
    email: str

    @computed_field
    @property
    def domain(self) -> str:
        return self.email.split("@")[1]
```

---

## 📌 참고 정리

* `@field_validator`: 단일 필드 값 조작 (clean/normalize)
* `@model_validator`: 복수 필드 간의 관계 검증, 전후처리
* `@field_serializer`: API 응답에서 출력값 제어
* `@computed_field`: 동적 계산된 필드 제공 (DB 컬럼 아님)


---

# ✅ 10. 모델 덤프/로드/직렬화

```python
user = User(name="길동")

user.model_dump()               # dict 출력
user.model_dump_json()          # JSON 문자열
User.model_validate(data)       # dict → 모델
User.model_validate_json(json)  # JSON → 모델
```

---

# ✅ 11. 기타 고급 기능

| 기능                       | 예                                                    |
| -------------------------- | ----------------------------------------------------- |
| immutable model            | `model_config = {"frozen": True}`                     |
| custom json encoder        | `json_encoders = {datetime: lambda v: v.isoformat()}` |
| `@computed_field` (v2.4\~) | 계산된 필드 readonly 노출                             |

---

# 🧾 요약 표: Pydantic v2 기준 주요 기능

| 항목               | 사용법 / 예시                               |               |
| ------------------ | ------------------------------------------- | ------------- |
| 기본 필드 정의     | `name: str`                                 |               |
| Optional 필드      | \`desc: str                                 | None = None\` |
| 중첩 모델          | `address: Address`                          |               |
| Field 옵션         | `Field(..., min_length=3)`                  |               |
| 유효성 검사        | `@field_validator / @model_validator`       |               |
| 모델 설정          | `model_config = { "extra": "forbid", ... }` |               |
| Enum `.value` 사용 | `model_config = {"use_enum_values": True}`  |               |
| 직렬화             | `.model_dump()`, `.model_dump_json()`       |               |

# 모든 기능을 담은 최종 모델 코드 예시

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

---

[목록으로](https://shiwoo-park.github.io/blog)
