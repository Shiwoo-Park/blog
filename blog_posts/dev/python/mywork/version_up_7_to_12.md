---
layout: post
title: "Python 3.7 -> 3.12 버전업을 통해 얻을 수 있는것들"
date: 2024-09-07
categories: [python, migration, version-up]
---

# Python 3.7 -> 3.12 버전업을 통해 얻을 수 있는것들

> 날짜: 2024-09-07

[목록으로](https://shiwoo-park.github.io/blog)

---

최근에 회사 아주 오랫동안 숙원 사업이었던 메인 API 프로젝트의 파이썬 + pip 패키지 버전업 작업을 완료했다.

한... 3달쯤? 걸렸나.. 싶다. 뭐 그렇게 오래걸렸냐 한다면... 우선순위가 계속 밀려서 작업을 거의 마무리 해놓고 약 2달간은 다른프로젝트 하느라 그냥 코드 싱크 맞추는 정도... ? 였기 때문

그리고 무엇보다 우리회사 기준에서 다양한 배포 환경과 환경에 따라 달라지는 배포방식, 그리고 하나의 프로젝트로 api 와 celery 2개의 서비스를 하고있는 구조에서 그 모든것들을 챙기기란 쉽지 않은 일이었다.

어찌됫든!!! 해냈다. 배포하고 자잘한 버그들이 좀 있었지만 그래도 지금은 다 해결하고 안정된 상태이다.

주요 버전 변경 사항은 아래와 같음

- python: 3.7.13 -> 3.12.5
- Django: 3.2.18 -> 4.2.11
- DRF: 3.12.4 -> 3.15.1
- celery: 5.2.7 -> 5.3.6

이 변화로 인해 많은혜택을 얻을 수 있었겠지만 그 무엇보다도 가장 근본적인 변화인 파이썬 버전업과 관련하여 한번 그 주요 혜택들을 한번 정리하고 싶었다.

---

Python 3.7.x 에서 3.12로 업데이트하면서 개발자들이 곧바로 적용할 수 있는 예제 코드와 그 혜택을 설명하겠습니다.

### 1. **성능 향상**: 함수 호출 및 반복문 최적화
Python 3.12에서는 내부적으로 함수 호출 및 반복문 처리 속도가 개선되었습니다.

**예제**:
```python
# 대규모 데이터 처리 시 Python 3.12에서 성능 향상을 볼 수 있음
large_list = [i for i in range(1000000)]

# 반복문 성능 개선
def sum_large_list(data):
    total = 0
    for num in data:
        total += num
    return total

# Python 3.12에서는 이 반복문이 더 빠르게 실행됩니다.
print(sum_large_list(large_list))
```

**혜택**:
Python 3.7에 비해 대규모 데이터를 처리할 때 성능 향상을 경험할 수 있습니다. API 서버에서 대용량 데이터를 처리하거나 반복적인 계산을 할 때 유용합니다.

---

### 2. **구조적 패턴 매칭**: 복잡한 조건문을 간결하게 처리
Python 3.10부터 도입된 패턴 매칭이 3.12에서 더욱 강력해졌습니다.

**예제**:
```python
def handle_event(event):
    match event:
        case {"type": "user", "action": "login"}:
            return "User logged in"
        case {"type": "user", "action": "logout"}:
            return "User logged out"
        case {"type": "admin", "action": "login"}:
            return "Admin logged in"
        case _:
            return "Unknown event"

# Python 3.12에서 패턴 매칭을 사용하여 복잡한 조건을 처리할 수 있음
event = {"type": "user", "action": "login"}
print(handle_event(event))  # 출력: User logged in
```

**혜택**:
조건문을 더 깔끔하고 가독성 좋게 작성할 수 있으며, 복잡한 데이터 구조를 쉽게 처리할 수 있습니다. 대규모 애플리케이션에서 데이터 흐름을 처리하는 로직에 유용합니다.

---

### 3. **타입 힌팅의 확장**: 코드 품질과 유지보수 향상
Python 3.12에서는 더 정교한 타입 힌팅과 타입 유추 기능이 제공됩니다.

**예제**:
```python
# Python 3.12에서 정교한 타입 힌팅 사용 가능
from typing import List

def process_data(data: List[int]) -> int:
    return sum(data)

# 이 함수는 명확한 타입을 가지고 있어 IDE에서 오류를 미리 발견할 수 있음
result = process_data([1, 2, 3, 4])
print(result)  # 출력: 10
```

**혜택**:
타입 안정성을 보장하면서도 IDE에서 코드 자동 완성 및 오류 검출 기능을 강화할 수 있습니다. 대규모 프로젝트에서 코드 품질을 높이고, 협업 중에도 타입 오류를 미리 잡아낼 수 있습니다.

---

### 4. **에러 메시지 개선**: 디버깅 시간 단축
Python 3.12에서 더 직관적이고 자세한 에러 메시지가 제공됩니다.

**예제**:
```python
# 일부러 잘못된 코드를 작성해봅니다.
def divide(x, y):
    return x / y

# 이 코드는 ZeroDivisionError를 발생시킴
print(divide(10, 0))
```

**혜택**:
Python 3.12에서는 더 구체적이고 명확한 에러 메시지를 제공하여 디버깅 속도를 높여줍니다. 문제를 쉽게 찾아 수정할 수 있으므로 개발 생산성이 향상됩니다.

---

### 5. **F-string 향상**: 가독성과 디버깅 효율성 증가
Python 3.12에서는 F-string이 더욱 강력해져, 표현식 평가 결과를 쉽게 출력할 수 있습니다.

**예제**:
```python
# Python 3.12에서 F-string을 디버깅용으로 활용
value = 42
print(f"Value is {value=}")  # 출력: Value is value=42

# 복잡한 표현식도 쉽게 출력 가능
result = (lambda x: x ** 2)(value)
print(f"Result of squaring {value}: {result=}")  # 출력: Result of squaring 42: result=1764
```

**혜택**:
디버깅할 때 변수 값과 표현식을 더 간결하게 출력할 수 있어, 개발 중 가독성과 디버깅 효율성이 높아집니다.

---

### 6. **메모리 관리 개선**: 대규모 애플리케이션 성능 최적화
Python 3.12에서는 메모리 할당 최적화가 이루어져, 메모리 사용량을 줄일 수 있습니다.

**예제**:
```python
# Python 3.12에서는 메모리 관리가 최적화되어, 많은 양의 데이터를 처리할 때 유리
import sys

large_list = [i for i in range(1000000)]
print(f"Memory usage: {sys.getsizeof(large_list)} bytes")  # 메모리 사용량 출력
```

**혜택**:
메모리를 많이 사용하는 서버 환경에서 더 효율적으로 자원을 관리할 수 있으며, 특히 EC2 같은 클라우드 환경에서 비용 절감 효과를 볼 수 있습니다.

---

### 결론
Python 3.12로 업데이트하면 성능 향상, 코드 가독성 및 유지보수성 개선, 디버깅 효율성 증가 등의 혜택을 받을 수 있습니다. 위의 예제 코드들은 곧바로 개발에 적용할 수 있으며, 특히 성능이 중요한 백엔드 API 개발에서 효과적으로 활용할 수 있습니다.


---

[목록으로](https://shiwoo-park.github.io/blog)
