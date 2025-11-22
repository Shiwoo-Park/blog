---
layout: post
title: "Pydantic 2.x 모델 필드: 유효성 검사 + 전처리 + 후처리"
date: 2025-06-07
categories: [python, pydantic, validation]
---
## ✅ 사용할 수 있는 주요 Pydantic v2 Validator / Hook 종류

| 데코레이터                             | 용도                    | 실행 시점            |
| --------------------------------- | --------------------- | ---------------- |
| `@field_validator`                | 개별 필드 단위 유효성 검사 / 후처리 | 입력 후 유효성 검사 시    |
| `@model_validator(mode="before")` | 전체 모델 단위 전처리          | 모델 생성 직전         |
| `@model_validator(mode="after")`  | 전체 모델 단위 후처리          | 모델 생성 후          |
| `@field_serializer`               | 직렬화 커스터마이징 (응답용)      | 출력 시 (dict/json) |
| `@computed_field`                 | 계산 필드 (저장 안됨)         | 응답 시 계산          |


## 1. `@field_validator`

필드 단위 유효성 검사 및 값 가공 (예: 반올림, 길이 체크 등)

```python
from pydantic import field_validator

class User(SQLModel):
    score: float

    @field_validator("score")
    def round_score(cls, v):
        return round(v, 2)
```

## 2. `@model_validator`

### `@model_validator(mode="before")`

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

### `@model_validator(mode="after")`

모델 인스턴스 생성 **후**, 종속 필드 간 논리 검사

```python
@model_validator(mode="after")
def validate_name_email(self):
    if self.name in self.email:
        raise ValueError("이름이 이메일에 포함되어 있으면 안 됩니다")
    return self
```

### 3. `@field_serializer`

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

### 4. `@computed_field`

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


### 📌 참고 정리

* `@field_validator`: 단일 필드 값 조작 (clean/normalize)
* `@model_validator`: 복수 필드 간의 관계 검증, 전후처리
* `@field_serializer`: API 응답에서 출력값 제어
* `@computed_field`: 동적 계산된 필드 제공 (DB 컬럼 아님)


## 모델 직렬화 / 역직렬화

- Serialization (=직렬화): Python 객체(Pydantic 모델) → dict, JSON 같은 primitive 데이터로 변환
- Deserialization (=역직렬화) :dict, JSON 같은 primitive 데이터 → 모델 객체로 복원

```python
user = User(name="길동")

# 직렬화
user.model_dump()               # dict 출력
user.model_dump_json()          # JSON 문자열

# 역직렬화
User.model_validate(data)       # dict → 모델
User.model_validate_json(json)  # JSON → 모델
```


# 🧾 요약 표: Pydantic v2 기준 주요 기능

| 항목               | 사용법 / 예시                               |          
| ------------------ | ------------------------------------------- |
| 기본 필드 정의     | `name: str`                                 |          
| Optional 필드      | `desc: str &#124; None = None`              |
| 중첩 모델          | `address: Address`                          |          
| Field 옵션         | `Field(..., min_length=3)`                  |          
| 유효성 검사        | `@field_validator / @model_validator`       |          
| 모델 설정          | `model_config = { "extra": "forbid", ... }` |          
| Enum `.value` 사용 | `model_config = {"use_enum_values": True}`  |          
| 직렬화             | `.model_dump()`, `.model_dump_json()`       |          
