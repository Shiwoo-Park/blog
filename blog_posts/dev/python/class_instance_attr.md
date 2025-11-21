---
layout: post
title: "파이썬의 클래스 속성과 인스턴스 속성의 차이 및 관리방식"
date: 2024-11-30
categories: [python, oop]
---

# 파이썬의 클래스 속성과 인스턴스 속성의 차이 및 관리방식

> 날짜: 2024-11-30

[목록으로](https://shiwoo-park.github.io/blog)

---

파이썬에서 객체지향 프로그래밍(OOP)을 사용하다 보면, 클래스 속성과 인스턴스 속성을 올바르게 이해하고 관리하는 것이 중요합니다. 이 글에서는 클래스 속성과 인스턴스 속성의 차이를 간단히 살펴보고, 잘못된 속성 관리로 인해 발생할 수 있는 오류와 이를 방지하는 방법을 소개합니다.

---

## 클래스 속성과 인스턴스 속성의 차이

### 1. 클래스 속성

- **클래스 전체에 공유**되는 속성입니다.
- 클래스 정의 시점에 설정되며, **모든 인스턴스가 동일한 값을 공유**합니다.
- 클래스 속성은 **클래스명.속성명**으로 접근하거나, 인스턴스를 통해 접근할 수 있습니다.

**예제**:
```python
class MyClass:
    class_attribute = "This is a class attribute"

# 클래스 속성에 접근
print(MyClass.class_attribute)  # 출력: This is a class attribute

# 인스턴스를 통해 클래스 속성 접근
instance = MyClass()
print(instance.class_attribute)  # 출력: This is a class attribute
```


### 2. 인스턴스 속성
- **각 인스턴스별로 독립적**으로 존재하는 속성입니다.
- 인스턴스 생성 후, 보통 `__init__` 메서드에서 설정됩니다.
- 인스턴스 속성은 특정 인스턴스에만 적용되며, 다른 인스턴스와 값을 공유하지 않습니다.

**예제**:
```python
class MyClass:
    def __init__(self, value):
        self.instance_attribute = value

# 서로 다른 인스턴스 속성
instance1 = MyClass("Instance 1 value")
instance2 = MyClass("Instance 2 value")

print(instance1.instance_attribute)  # 출력: Instance 1 value
print(instance2.instance_attribute)  # 출력: Instance 2 value
```


## 잘못된 속성 관리로 인한 오류 발생 가능성

### 1. 클래스 속성과 인스턴스 속성을 혼동한 경우
클래스 속성과 인스턴스 속성을 혼동하면, 의도하지 않게 모든 인스턴스가 같은 값을 공유할 수 있습니다.

**예제: 잘못된 속성 관리**
```python
class MyClass:
    shared_list = []  # 클래스 속성

instance1 = MyClass()
instance2 = MyClass()

# 한 인스턴스에서 수정
instance1.shared_list.append("Value")

# 모든 인스턴스에 영향을 미침
print(instance2.shared_list)  # 출력: ['Value']
```

**문제**:
- `shared_list`는 클래스 속성이므로 모든 인스턴스가 이를 공유합니다.
- 한 인스턴스에서 변경한 값이 다른 인스턴스에도 영향을 미칩니다.


### 2. 방지 방법: 클래스 속성과 인스턴스 속성을 명확히 구분
클래스 속성은 변경되지 않는 **공용 데이터**에만 사용하고, 인스턴스별 데이터를 저장하려면 인스턴스 속성을 사용하세요.

**수정된 코드**:
```python
class MyClass:
    def __init__(self):
        self.unique_list = []  # 인스턴스 속성

instance1 = MyClass()
instance2 = MyClass()

# 한 인스턴스에서 수정
instance1.unique_list.append("Value")

# 다른 인스턴스에는 영향을 미치지 않음
print(instance2.unique_list)  # 출력: []
```


## 클래스 속성과 인스턴스 속성의 관리 요령

1. **클래스 속성**:
   - 변경되지 않는 데이터(상수)나 클래스 전역적으로 공유해야 하는 데이터를 저장할 때 사용합니다.
   - 예: `DEFAULT_SETTINGS`, `MAX_LIMIT`.

2. **인스턴스 속성**:
   - 인스턴스별로 고유한 데이터를 저장할 때 사용합니다.
   - 예: `self.name`, `self.age`.

3. **디버깅 팁**:
   - 클래스와 인스턴스 속성을 명확히 구분하기 위해, `클래스명.속성명`과 `self.속성명`의 사용 방식을 일관되게 유지하세요.
   - 클래스 속성을 수정하려면 반드시 클래스명을 사용하세요.

**예제**:
```python
class MyClass:
    class_attribute = "Shared"

    def __init__(self, value):
        self.instance_attribute = value

# 클래스 속성을 수정
MyClass.class_attribute = "Modified Shared"
```

## 결론

클래스 속성과 인스턴스 속성의 차이를 이해하고, 이를 적절히 관리하면 코드의 가독성과 안정성을 높일 수 있습니다. 특히, 잘못된 속성 관리로 인한 공유 데이터 문제를 예방하기 위해 클래스 속성과 인스턴스 속성을 명확히 구분하는 습관을 가지세요.


---

[목록으로](https://shiwoo-park.github.io/blog)
