# Python의 `generator`와 `yield`에 대한 깊이 있는 설명

> 날짜: 2024-12-10

[목록으로](https://shiwoo-park.github.io/blog)

---

#### **1. Generator란?**
`Generator`는 **반복(iteration)을 관리하는 특별한 함수**입니다. 일반적인 함수는 값을 반환하고 종료되지만, Generator는 값을 `yield` 키워드로 반환한 후 상태를 유지하며 멈춥니다. 다음 호출 시 중단된 지점에서 실행을 이어가게 됩니다.

- 메모리 효율적: 모든 값을 메모리에 저장하지 않고 필요할 때 계산합니다.
- Lazy Evaluation: 값이 필요할 때마다 계산하므로 성능 최적화에 유리합니다.

---

### **2. `yield`의 동작**

#### **2.1. 기본 구조**
`yield`는 값을 반환하고 함수 실행을 일시 중단합니다. 함수는 `next()`가 호출될 때 중단된 지점에서 재개됩니다.

```python
def simple_generator():
    yield 1
    yield 2
    yield 3

gen = simple_generator()
print(next(gen))  # 1
print(next(gen))  # 2
print(next(gen))  # 3
# print(next(gen))  # StopIteration 예외 발생
```

- **`yield`의 동작**:
  1. 처음 호출 시 함수가 실행되고 첫 번째 `yield`에서 멈춥니다.
  2. 이후 `next()` 호출마다 다음 `yield` 지점으로 이동.

---

#### **2.2. 상태 유지**
Generator는 상태를 유지하므로, 이전 상태 정보를 다시 계산할 필요가 없습니다.

```python
def countdown(n):
    while n > 0:
        yield n
        n -= 1

for num in countdown(5):
    print(num)
# 출력: 5, 4, 3, 2, 1
```

---

### **3. 고급 Generator 기능**

#### **3.1. Generator로 무한 시퀀스 생성**
Generator는 필요할 때만 계산하므로 무한 시퀀스를 생성하는 데 적합합니다.

```python
def infinite_counter(start=0):
    while True:
        yield start
        start += 1

counter = infinite_counter()
for _ in range(5):
    print(next(counter))
# 출력: 0, 1, 2, 3, 4
```

---

#### **3.2. `send()`로 데이터 주입**
Generator는 `send()` 메서드를 통해 외부에서 데이터를 주입받을 수 있습니다. 이는 양방향 데이터 교환을 가능하게 합니다.

```python
def echo():
    while True:
        received = yield
        print(f"Received: {received}")

gen = echo()
next(gen)  # Generator를 활성화
gen.send("Hello")  # Received: Hello
gen.send("World")  # Received: World
```

---

#### **3.3. Generator 종료**
`Generator`는 다음 두 가지 방법으로 종료됩니다:
1. 함수 끝에 도달 (`StopIteration` 예외 발생).
2. `close()` 메서드 호출.

```python
gen = (x for x in range(3))
print(next(gen))  # 0
gen.close()  # Generator 종료
# print(next(gen))  # ValueError: generator already closed
```

---

#### **3.4. `yield from`**
`yield from`은 중첩 Generator를 간결하게 호출하기 위한 키워드입니다. 외부 Generator가 내부 Generator의 모든 값을 순차적으로 반환하도록 위임합니다.

```python
def nested_gen():
    yield from range(3)
    yield from "ABC"

for value in nested_gen():
    print(value)
# 출력: 0, 1, 2, A, B, C
```

---

### **4. Generator와 메모리 효율**

#### **4.1. 리스트와 비교**
리스트는 모든 요소를 메모리에 저장하지만, Generator는 값을 필요할 때마다 계산합니다.

```python
# 메모리를 많이 사용하는 리스트
large_list = [x * x for x in range(10**6)]

# 메모리를 아끼는 Generator
large_gen = (x * x for x in range(10**6))
```

#### **4.2. 예시: 파일 읽기**
Generator를 사용하면 파일을 한 줄씩 읽으면서 메모리를 효율적으로 관리할 수 있습니다.

```python
def read_large_file(file_path):
    with open(file_path, 'r') as file:
        for line in file:
            yield line.strip()

for line in read_large_file("large_file.txt"):
    print(line)
```

---

### **5. Generator의 활용 사례**

#### **5.1. 데이터 스트리밍**
대량의 데이터(예: 로그, CSV 파일)를 한 번에 메모리에 로드하지 않고 한 줄씩 처리.

#### **5.2. 네트워크 스트리밍**
서버에서 데이터 패킷을 실시간으로 수신하면서 처리.

#### **5.3. 병렬 처리**
Generator는 `asyncio`와 결합하여 비동기 작업에 사용됩니다.

```python
import asyncio

async def async_gen():
    for i in range(5):
        yield i
        await asyncio.sleep(1)

async def main():
    async for value in async_gen():
        print(value)

asyncio.run(main())
```

---

### **6. Generator의 한계와 주의점**

1. **상태 유지 복잡성**: Generator는 내부 상태를 유지하지만 복잡한 상태를 관리하려면 코드가 어려워질 수 있습니다.
2. **한 번만 소비 가능**: Generator는 한 번만 반복 가능합니다. 필요 시 새로운 Generator를 생성해야 합니다.
   ```python
   gen = (x for x in range(3))
   list(gen)  # [0, 1, 2]
   list(gen)  # []
   ```

---

### **7. Generator와 성능 비교**

#### **리스트와 Generator의 메모리 사용량**
```python
import sys

# 리스트
large_list = [x for x in range(10**6)]
print(f"List size: {sys.getsizeof(large_list)} bytes")

# Generator
large_gen = (x for x in range(10**6))
print(f"Generator size: {sys.getsizeof(large_gen)} bytes")

# 출력
# List size: 8697464 bytes
# Generator size: 120 bytes
```

---

### 요약
- `Generator`는 메모리 효율적이고, Lazy Evaluation으로 값을 필요할 때 계산.
- `yield`는 실행 상태를 유지하며 값을 반환.
- 고급 기능: `send()`, `yield from`, 무한 시퀀스 생성.
- 적절한 사용 사례: 파일 처리, 데이터 스트리밍, 네트워크 스트리밍 등.

---

[목록으로](https://shiwoo-park.github.io/blog)
