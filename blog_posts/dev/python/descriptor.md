---
layout: post
title: "파이썬 디스크립터"
date: 2024-11-30
categories: [python, oop, advanced]
---

# 파이썬 디스크립터

> 날짜: 2024-11-30

[목록으로](https://shiwoo-park.github.io/blog)

---


파이썬에서 **디스크립터(Descriptor)**는 객체 속성에 대한 접근 방식을 사용자 정의할 수 있는 방법을 제공합니다. 디스크립터는 적어도 하나의 특별 메서드(`__get__`, `__set__`, `__delete__`)를 구현한 클래스를 말합니다. 이를 통해 속성에 접근할 때의 동작을 재정의할 수 있습니다.

## 디스크립터의 핵심 메서드
1. **`__get__(self, instance, owner)`**:
   - 속성 값을 가져올 때 호출됩니다.
   - `instance`: 디스크립터가 속한 객체입니다. 클래스에서 호출될 경우 `None`이 전달됩니다.
   - `owner`: 소유 클래스입니다.
   - 반환값이 속성의 값을 결정합니다.

2. **`__set__(self, instance, value)`**:
   - 속성 값을 설정할 때 호출됩니다.
   - `value`: 설정할 값입니다.

3. **`__delete__(self, instance)`**:
   - 속성을 삭제할 때 호출됩니다.

## 디스크립터 종류
1. **데이터 디스크립터**:
   - `__get__`과 `__set__` 또는 `__delete__`를 모두 구현한 경우.
   - 인스턴스의 `__dict__`보다 높은 우선순위를 가집니다.

2. **비데이터 디스크립터**:
   - `__get__`만 구현한 경우.
   - 인스턴스의 `__dict__`에 값이 있을 경우 이를 우선 사용합니다.

---

## `__dict__`와 디스크립터의 관계
1. **인스턴스의 `__dict__`**:
   - 인스턴스 속성은 기본적으로 인스턴스의 `__dict__`에 저장됩니다.
   - 디스크립터가 정의되지 않은 속성에 접근하면, Python은 우선적으로 인스턴스의 `__dict__`를 확인합니다.

2. **클래스의 `__dict__`**:
   - 클래스 속성은 클래스의 `__dict__`에 저장됩니다.
   - 디스크립터는 클래스의 `__dict__`에 정의됩니다. 디스크립터가 정의된 속성에 접근하면, Python은 디스크립터를 먼저 확인합니다.

---

## 디스크립터 동작 순서
파이썬의 속성 접근 순서는 다음과 같습니다:

1. **속성 접근 (`obj.attr`)**:
   - 먼저, 클래스에서 해당 속성이 디스크립터인지 확인합니다.
   - **데이터 디스크립터**가 존재하면, `__get__` 메서드가 호출됩니다. 인스턴스의 `__dict__`보다 우선합니다.
   - 데이터 디스크립터가 없으면, 인스턴스의 `__dict__`를 확인합니다.
   - 비데이터 디스크립터는 인스턴스의 `__dict__`에 값이 없을 때 호출됩니다.

2. **속성 설정 (`obj.attr = value`)**:
   - **데이터 디스크립터**가 정의되어 있으면, `__set__` 메서드가 호출됩니다.
   - 데이터 디스크립터가 없다면, 속성은 인스턴스의 `__dict__`에 저장됩니다.

3. **속성 삭제 (`del obj.attr`)**:
   - **데이터 디스크립터**가 `__delete__`를 구현했다면, 해당 메서드가 호출됩니다.
   - 그렇지 않으면, 인스턴스의 `__dict__`에서 속성을 삭제합니다.


## 디스크립터 예제

### 1. 읽기 전용 디스크립터
```python
class ReadOnlyDescriptor:
    def __get__(self, instance, owner):
        return "읽기 전용 값"

class MyClass:
    attr = ReadOnlyDescriptor()

obj = MyClass()
print(obj.attr)  # 출력: 읽기 전용 값
```

### 2. 데이터 디스크립터 (속성 값 유효성 검사)
```python
class PositiveNumber:
    def __get__(self, instance, owner):
        return instance.__dict__.get('_value', 0)
    
    def __set__(self, instance, value):
        if value < 0:
            raise ValueError("값은 양수여야 합니다.")
        instance.__dict__['_value'] = value

class MyClass:
    value = PositiveNumber()

obj = MyClass()
obj.value = 10  # 올바른 값
print(obj.value)  # 출력: 10
obj.value = -5   # ValueError: 값은 양수여야 합니다.
```

### 3. 데이터 디스크립터가 인스턴스 `__dict__`보다 우선
```python
class DataDescriptor:
    def __get__(self, instance, owner):
        return "데이터 디스크립터 값"
    
    def __set__(self, instance, value):
        instance.__dict__['attr'] = value

class MyClass:
    attr = DataDescriptor()

obj = MyClass()
obj.attr = "인스턴스 값"
print(obj.attr)  # 출력: 데이터 디스크립터 값
print(obj.__dict__)  # 출력: {'attr': '인스턴스 값'}
```
- 데이터 디스크립터가 우선되어 `__get__` 메서드가 호출됩니다.
- 인스턴스의 `__dict__`에 값이 있어도 무시됩니다.

---

### 4. 비데이터 디스크립터는 인스턴스 `__dict__`보다 나중에 호출
```python
class NonDataDescriptor:
    def __get__(self, instance, owner):
        return "비데이터 디스크립터 값"

class MyClass:
    attr = NonDataDescriptor()

obj = MyClass()
obj.__dict__['attr'] = "인스턴스 값"
print(obj.attr)  # 출력: 인스턴스 값
```
- 비데이터 디스크립터는 인스턴스의 `__dict__`에 값이 있을 경우 이를 우선 사용합니다.

---

### 5. 속성 삭제 동작 확인
```python
class DeletableDescriptor:
    def __get__(self, instance, owner):
        return instance.__dict__.get('attr', None)

    def __set__(self, instance, value):
        instance.__dict__['attr'] = value

    def __delete__(self, instance):
        print("속성 삭제됨")
        del instance.__dict__['attr']

class MyClass:
    attr = DeletableDescriptor()

obj = MyClass()
obj.attr = "값 설정"
print(obj.attr)  # 출력: 값 설정
del obj.attr      # 출력: 속성 삭제됨
print(obj.__dict__)  # 출력: {}
```
- 데이터 디스크립터는 `__delete__`를 구현하여 속성 삭제를 제어할 수 있습니다.

---

## 디스크립터 사용 사례
- **프로퍼티**: `property()`는 디스크립터의 한 구현입니다.
- **ORM**: Django와 같은 ORM은 디스크립터를 활용해 모델 필드 접근을 제어합니다.
- **캐싱**: 속성 값을 캐싱하거나 동적으로 계산할 때 사용됩니다.

## 정리
1. **데이터 디스크립터**: 항상 인스턴스 `__dict__`보다 우선합니다.
2. **비데이터 디스크립터**: 인스턴스 `__dict__`에 속성이 없을 때만 동작합니다.
3. **속성 설정/삭제**: 디스크립터가 관련 메서드를 구현한 경우, `__dict__`를 우회합니다.

---

[목록으로](https://shiwoo-park.github.io/blog)
