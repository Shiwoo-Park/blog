---
layout: post
title: "Pydantic v2 의 BaseModel 파헤치기"
date: 2025-05-14
categories: [python, pydantic]
---
ydantic은 Python 데이터 유효성 검증 및 직렬화/역직렬화를 도와주는 라이브러리야.


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


# ✅ 3. 기본값, Optional 필드

```python
from typing import Optional

class Item(BaseModel):
    title: str
    description: Optional[str] = None
    price: float = 0.0
```


# ✅ 4. 중첩 모델

```python
class Address(BaseModel):
    city: str
    zip_code: str

class Customer(BaseModel):
    name: str
    address: Address
```


# ✅ 5. 리스트, 유니언

```python
from typing import Union

class Data(BaseModel):
    items: list[int]
    result: Union[int, str]
```


# ✅ 6. 필드 메타 정보: `Field`

```python
from pydantic import Field

class User(BaseModel):
    name: str = Field(..., min_length=2, max_length=50, description="이름")
    age: int = Field(default=0, ge=0, le=120)
```


# ✅ 7. 필드 alias 및 변환

```python
class User(BaseModel):
    full_name: str = Field(alias="fullName")

    model_config = {
        "populate_by_name": True
    }

User.model_validate({"fullName": "홍길동"})
```


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
