---
layout: post
title: "Python dataclass 정의와 용법"
date: 2024-12-10
categories: [python, dataclass]
---

# Python `dataclass` 정의와 용법

> 날짜: 2024-12-10

[목록으로](https://shiwoo-park.github.io/blog)

---

`dataclass`는 Python 3.7에 도입된 데코레이터로, 데이터 중심의 클래스를 더 간결하고 직관적으로 작성할 수 있도록 도와줍니다. 기본적으로 데이터 저장용 클래스를 만들 때 반복적으로 작성해야 하는 코드를 자동으로 생성해줍니다. 

#### 주요 특징

- 기본 생성자 (`__init__`) 자동 생성
- `__repr__`, `__eq__`, `__hash__` 등의 메서드 자동 생성
- 기본 값 및 타입 힌트를 활용한 명확한 클래스 정의
- 기본값, 타입 힌트, `field()` 및 `__post_init__`으로 다양한 동작을 설정할 수 있습니다.
- 불변 객체를 생성하거나 가변 기본값 문제를 방지하기 위한 옵션을 제공합니다.

---

### 기본 사용법

#### 1. `dataclass` 정의

```python
from dataclasses import dataclass

@dataclass
class Person:
    name: str
    age: int
    city: str = "Seoul"  # 기본값

# 인스턴스 생성
p1 = Person(name="Alice", age=30)
print(p1)  # 출력: Person(name='Alice', age=30, city='Seoul')
```

#### 2. 주요 기능

- **자동 생성자**: 필드에 맞는 `__init__` 메서드를 자동으로 생성.
- **간결한 출력**: 객체를 출력할 때 `__repr__` 메서드 자동 생성.
- **비교 연산 지원**: 두 객체의 필드 값을 비교하는 `__eq__` 메서드 생성.

```python
p2 = Person(name="Alice", age=30)
print(p1 == p2)  # True (name과 age가 같기 때문)
```

---

### 고급 사용법

#### 1. 필드의 세부 설정
`dataclass`는 `field()`를 사용하여 필드의 동작을 세밀하게 제어할 수 있습니다.

```python
from dataclasses import dataclass, field

@dataclass
class Product:
    id: int
    name: str
    price: float = field(default=0.0)  # 기본값 설정
    tags: list = field(default_factory=list)  # 가변 객체를 위한 기본값

p = Product(id=1, name="Laptop")
print(p)  # 출력: Product(id=1, name='Laptop', price=0.0, tags=[])
```

#### 2. `__post_init__` 메서드
생성자가 실행된 후 추가 로직을 수행할 수 있습니다.

```python
@dataclass
class Rectangle:
    width: int
    height: int
    area: int = field(init=False)  # 생성자에서 직접 초기화하지 않음

    def __post_init__(self):
        self.area = self.width * self.height

r = Rectangle(4, 5)
print(r.area)  # 출력: 20
```

#### 3. 불변 객체 만들기

- 불변 객체를 사용하면 의도치 않은 속성 변경으로 인한 오류를 방지할 수 있습니다.
- 예: 설정 값, 구성 정보 등 변경되면 안 되는 데이터를 다룰 때.
- `frozen=True` 옵션을 사용하면 불변 객체를 생성할 수 있습니다.
- `frozen=True` 로 설정하면 객체가 해시 가능(__hash__ 자동 생성)하며, 딕셔너리 키나 집합 원소로 사용할 수 있습니다.

```python
@dataclass(frozen=True)
class ImmutablePoint:
    x: int
    y: int

p = ImmutablePoint(10, 20)
# p.x = 30  # TypeError: cannot assign to field 'x'
```

---

### 주의점

1. **가변 기본값 문제**
   가변 객체를 기본값으로 사용하는 경우 `default_factory`를 사용해야 합니다. 그렇지 않으면 모든 인스턴스가 동일한 객체를 참조합니다.
   ```python
   @dataclass
   class MyClass:
       items: list = []  # 잘못된 사용
   ```

2. **클래스 간 상속**
   `dataclass`는 상속을 지원하지만, 상위 클래스의 동작이 자동으로 상속되지는 않으므로 주의해야 합니다.

---

### dataclass 의 모든 기능을 활용한 클래스 예시

```python
from dataclasses import dataclass, field, asdict, astuple
from typing import List, Dict

@dataclass(frozen=True)  # 객체를 불변으로 설정
class Product:
    # 필드 정의 (타입 힌트와 기본값 포함)
    id: int                     # 반드시 초기화해야 하는 필드
    name: str                   # 반드시 초기화해야 하는 필드
    price: float = 0.0          # 기본값 제공
    tags: List[str] = field(default_factory=list)  # 가변 객체를 위한 기본값
    metadata: Dict[str, str] = field(default_factory=dict)  # 가변 객체
    discount_rate: float = field(init=False)  # 초기화에서 제외된 필드
    total_stock: int = field(default=100, metadata={"unit": "items"})  # 메타데이터 추가

    def __post_init__(self):
        # `__post_init__`에서 추가 초기화 로직 및 validation 수행
        object.__setattr__(self, 'discount_rate', 0.1 if self.price > 100 else 0.0)
        if self.price < 0:
            raise ValueError("Price must be non-negative")
        if not (0 <= self.discount_rate <= 1):
            raise ValueError("Discount must be between 0 and 1")


    def apply_discount(self) -> float:
        # 객체의 값을 활용한 메서드
        return self.price * (1 - self.discount_rate)

# 객체 생성 (초기화)
product = Product(id=1, name="Laptop", price=1500.0, tags=["Electronics", "Portable"])

# 출력 및 사용 예시
print(product)  # __repr__ 자동 생성
# 출력: Product(id=1, name='Laptop', price=1500.0, tags=['Electronics', 'Portable'], metadata={}, discount_rate=0.1, total_stock=100)

# 데이터 구조 변환
print(asdict(product))  # 딕셔너리로 변환
# 출력: {'id': 1, 'name': 'Laptop', 'price': 1500.0, 'tags': ['Electronics', 'Portable'], 'metadata': {}, 'total_stock': 100, 'discount_rate': 0.1}

print(astuple(product))  # 튜플로 변환
# 출력: (1, 'Laptop', 1500.0, ['Electronics', 'Portable'], {}, 0.1, 100)

# 메서드 사용
print(f"Discounted price: {product.apply_discount()}")  # 메서드 실행
# 출력: Discounted price: 1350.0

# 불변 객체 검증
try:
    product.price = 2000  # 수정 시도 (frozen=True로 인해 예외 발생)
except AttributeError as e:
    print(e)
# 출력: cannot assign to field 'price'
```


---

[목록으로](https://shiwoo-park.github.io/blog)
