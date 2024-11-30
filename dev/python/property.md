# 파이썬의 Property 사용법

> 날짜: 2024-11-30

[목록으로](https://shiwoo-park.github.io/blog)

---

파이썬에서 **`property`**는 일반적으로 **`property()` 함수** 또는 **`@property` 데코레이터**를 가리킵니다. 둘은 같은 기능을 제공하며, 클래스에서 **getter, setter, deleter를 정의하여 속성 접근 방식을 제어**하는 데 사용됩니다.

즉, **`property`**라는 용어는 **데코레이터 그 자체만을 뜻하는 것이 아니라**, **파이썬에서 속성을 정의하고 관리하는 데 사용하는 메커니즘**을 의미합니다. 

---

### **1. `property()` 함수**
- **`property()`**는 파이썬에서 제공하는 내장 함수로, 클래스 속성의 **getter, setter, deleter**를 정의할 수 있습니다.
- 인수를 통해 속성 접근을 제어하는 메서드를 설정합니다:
  - `fget`: getter 메서드.
  - `fset`: setter 메서드.
  - `fdel`: deleter 메서드.
  - `doc`: 속성의 문서화 문자열.

#### **예제: `property()` 함수**
```python
class MyClass:
    def __init__(self, value):
        self._value = value

    def get_value(self):  # getter
        return self._value

    def set_value(self, new_value):  # setter
        if new_value < 0:
            raise ValueError("Value must be non-negative")
        self._value = new_value

    def del_value(self):  # deleter
        del self._value

    value = property(get_value, set_value, del_value, "This is a managed property")

obj = MyClass(10)
print(obj.value)  # getter 호출: 10
obj.value = 20    # setter 호출
print(obj.value)  # 출력: 20
del obj.value     # deleter 호출
```

---

### **2. `@property` 데코레이터**
- **`@property` 데코레이터**는 `property()` 함수를 간소화한 문법입니다.
- `@property`를 사용해 **getter 메서드를 정의**하고, `@<property_name>.setter`와 `@<property_name>.deleter`를 사용해 **setter 및 deleter**를 정의할 수 있습니다.

#### **예제: `@property` 데코레이터**
```python
class MyClass:
    def __init__(self, value):
        self._value = value

    @property
    def value(self):  # getter
        return self._value

    @value.setter
    def value(self, new_value):  # setter
        if new_value < 0:
            raise ValueError("Value must be non-negative")
        self._value = new_value

    @value.deleter
    def value(self):  # deleter
        del self._value

obj = MyClass(10)
print(obj.value)  # getter 호출: 10
obj.value = 20    # setter 호출
print(obj.value)  # 출력: 20
del obj.value     # deleter 호출
```

---

### **3. `property()`와 `@property`의 차이점**
| **`property()`**                    | **`@property` 데코레이터**                     |
|--------------------------------------|-----------------------------------------------|
| 함수 호출을 통해 getter, setter, deleter를 설정 | 데코레이터로 간결한 문법 제공                   |
| 명시적으로 `property(fget, fset, fdel)` 사용 | `@property`, `@<name>.setter`, `@<name>.deleter` 사용 |
| 문서 문자열을 인수로 전달 가능        | `__doc__`에 문자열을 추가하면 동일한 효과        |

---

### **4. `property`를 사용하는 이유**
- **캡슐화**: 외부에서 속성에 직접 접근하지 못하게 하고, getter와 setter를 통해 제어합니다.
- **동작 추가**: 속성 값을 읽거나 쓸 때, 추가적인 동작(유효성 검사, 계산 등)을 수행할 수 있습니다.
- **코드 가독성**: 속성처럼 사용되는 간결한 인터페이스 제공.

#### **예제: 속성 값 검증**
```python
class Temperature:
    def __init__(self, celsius):
        self._celsius = celsius

    @property
    def celsius(self):  # getter
        return self._celsius

    @celsius.setter
    def celsius(self, value):  # setter
        if value < -273.15:
            raise ValueError("Temperature below -273.15°C is not possible")
        self._celsius = value

temp = Temperature(25)
print(temp.celsius)  # 출력: 25
temp.celsius = -300  # ValueError: Temperature below -273.15°C is not possible
```

---

### **5. 잘못된 이해 방지**
- **`property`라는 단어 자체**는 파이썬의 속성 관리 메커니즘 전체를 지칭할 수 있습니다.
- **`@property` 데코레이터**는 `property()` 함수의 간소화된 문법으로, 속성을 정의할 때 자주 사용됩니다.

---

### **6. 요약**
- **`property()`**는 파이썬 내장 함수로, getter, setter, deleter를 설정할 수 있습니다.
- **`@property`** 데코레이터는 `property()`를 간소화한 문법으로 더 직관적으로 사용 가능합니다.
- `property`는 캡슐화를 통해 속성 접근을 제어하고, 가독성과 유지보수성을 향상시키는 데 사용됩니다.

---

[목록으로](https://shiwoo-park.github.io/blog)
