# 파이썬 - 함수 오버로딩과 singledispatch 데코레이터

> 날짜: 2024-12-02

[목록으로](https://shiwoo-park.github.io/blog)

---

파이썬에서 **함수 오버로딩**과 **`singledispatch` 데코레이터**는 서로 관련이 있으면서도, 다른 맥락에서 이해할 수 있습니다. 여기서는 두 개념을 비교하고, `singledispatch` 데코레이터를 활용하여 파이썬에서 함수 오버로딩을 구현하는 방법을 설명하겠습니다.

---

## **1. 함수 오버로딩이란?**
함수 오버로딩은 **같은 이름을 가진 함수가 매개변수의 개수나 타입에 따라 다르게 동작하는 기능**을 말합니다. C++, Java와 같은 언어에서는 기본적으로 함수 오버로딩을 지원합니다.

### **타 언어의 함수 오버로딩 예 (C++)**
```cpp
int add(int a, int b) {
    return a + b;
}

float add(float a, float b) {
    return a + b;
}
```
위 예시에서 함수 이름은 같지만, 매개변수의 타입에 따라 다른 구현이 호출됩니다.

---

## **2. 파이썬에서의 함수 오버로딩**
파이썬은 함수 오버로딩을 **기본적으로 지원하지 않습니다.**

### **왜 파이썬은 함수 오버로딩을 지원하지 않을까?**
파이썬은 동적 타이핑(dynamic typing)을 기반으로 하기 때문에, 함수 호출 시점에 매개변수의 타입을 체크하여 서로 다른 구현을 선택하는 기능이 기본적으로 없습니다. 동일한 이름의 함수를 두 번 이상 정의하면, 이전 정의가 덮어쓰여집니다.

**예제: 덮어쓰기**
```python
def add(a, b):
    return a + b

def add(a, b, c):
    return a + b + c

print(add(1, 2))  # TypeError: add() missing 1 required positional argument
```

---

## **3. `singledispatch` 데코레이터를 활용한 함수 오버로딩**

파이썬에서는 `functools` 모듈의 **`singledispatch` 데코레이터**를 사용하여 함수 오버로딩과 유사한 동작을 구현할 수 있습니다. `singledispatch`는 **매개변수의 타입에 따라 다른 구현을 선택**하는 **제네릭 함수(generic function)**를 제공합니다.

### **`singledispatch`의 기본 개념**
1. 기본 구현을 작성하고 `@singledispatch`로 데코레이트합니다.
2. 각 데이터 타입별 동작을 `@<함수명>.register(타입)`으로 정의합니다.
3. 호출 시 첫 번째 매개변수의 타입에 따라 알맞은 구현이 호출됩니다.

---

### **4. `singledispatch` 사용법**

#### **예제: 타입별 함수 처리**
```python
from functools import singledispatch

@singledispatch
def process(data):
    raise NotImplementedError("Unsupported type")

@process.register(int)
def _(data):
    return f"Processing integer: {data}"

@process.register(str)
def _(data):
    return f"Processing string: {data}"

@process.register(list)
def _(data):
    return f"Processing list of length {len(data)}"

# 함수 호출
print(process(42))           # 출력: Processing integer: 42
print(process("hello"))      # 출력: Processing string: hello
print(process([1, 2, 3]))    # 출력: Processing list of length 3
```

---

### **5. 클래스 메서드에서 `singledispatch` 사용**

파이썬 3.8부터는 **`singledispatchmethod`**를 사용하여 클래스 메서드에서도 함수 오버로딩을 구현할 수 있습니다.

#### **예제: 클래스 메서드 오버로딩**
```python
from functools import singledispatchmethod

class Processor:
    @singledispatchmethod
    def process(self, data):
        raise NotImplementedError("Unsupported type")

    @process.register(int)
    def _(self, data):
        return f"Processing integer: {data}"

    @process.register(str)
    def _(self, data):
        return f"Processing string: {data}"

processor = Processor()
print(processor.process(42))       # 출력: Processing integer: 42
print(processor.process("hello"))  # 출력: Processing string: hello
```

---

### **6. `singledispatch`의 장점과 한계**

#### **장점**
1. **코드 가독성**: 타입별 동작을 분리하여 가독성을 높입니다.
2. **확장성**: 새로운 타입을 지원하려면 단순히 구현을 추가하면 됩니다.
3. **동적 디스패치**: 타입에 따라 적절한 구현을 선택합니다.

#### **한계**
1. **첫 번째 매개변수만 기준**:
   - `singledispatch`는 함수의 첫 번째 매개변수의 타입만을 기준으로 동작을 결정합니다.
   - 두 번째 매개변수 이상을 기준으로 오버로딩하려면 커스텀 디스패처를 구현해야 합니다.
   
2. **매개변수의 타입이 복잡한 경우**:
   - 복잡한 타입 조합에 대한 처리가 어렵습니다.

---

### **7. 함수 오버로딩이 필요한 경우의 대안**

#### **방법 1: 조건문으로 처리**
가장 간단한 방법은 매개변수의 타입을 확인하고 적절한 로직을 선택하는 것입니다.
```python
def process(data):
    if isinstance(data, int):
        return f"Processing integer: {data}"
    elif isinstance(data, str):
        return f"Processing string: {data}"
    elif isinstance(data, list):
        return f"Processing list of length {len(data)}"
    else:
        raise NotImplementedError("Unsupported type")
```

#### **방법 2: 다중 디스패처 사용**
`singledispatch`를 확장하여 다중 매개변수를 처리하는 디스패처를 구현할 수도 있습니다.

---

## **8. 결론**
- 파이썬은 C++이나 Java처럼 기본적인 함수 오버로딩을 지원하지 않지만, **`singledispatch` 데코레이터**를 사용하면 타입별로 다른 동작을 수행하는 함수를 쉽게 작성할 수 있습니다.
- `singledispatch`는 첫 번째 매개변수의 타입을 기준으로 동작하며, 간결하고 확장 가능한 코드를 작성하는 데 유용합니다.
- 복잡한 로직이 필요한 경우 조건문이나 커스텀 디스패처와 같은 대안도 검토할 수 있습니다.


---

[목록으로](https://shiwoo-park.github.io/blog)
