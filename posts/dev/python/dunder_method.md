---
layout: post
title: "파이썬 - Dunder(double underscore) method"
date: 2024-12-02
categories: [python, oop]
---
# 파이썬 - Dunder(double underscore) method (`__foo__`)

> 날짜: 2024-12-02

[목록으로](https://shiwoo-park.github.io/blog)

---

파이썬의 **던더 메서드(Dunder Methods)**(Double Underscore Methods, `__method__`)는 특정 작업에 대해 객체의 동작을 정의하는 특별한 메서드입니다. 이들은 주로 클래스에 특별한 동작을 부여하거나 기본 동작을 재정의하는 데 사용됩니다.

다음은 주요 던더 메서드의 종류와 용도를 정리한 내용입니다.

---

## **1. 객체 초기화 및 소멸 관련 메서드**

### **`__init__(self, ...)`**
- **용도**: 객체가 생성될 때 호출되는 생성자 메서드.
- **예제**:
  ```python
  class MyClass:
      def __init__(self, name):
          self.name = name

  obj = MyClass("Python")
  print(obj.name)  # 출력: Python
  ```

### **`__new__(cls, ...)`**
- **용도**: 객체의 인스턴스를 생성할 때 호출되는 메서드. 주로 메타클래스에서 사용.
- **예제**:
  ```python
  class MyClass:
      def __new__(cls, *args, **kwargs):
          print("Creating instance")
          return super().__new__(cls)
  ```

### **`__del__(self)`**
- **용도**: 객체가 삭제될 때 호출되는 소멸자 메서드.
- **예제**:
  ```python
  class MyClass:
      def __del__(self):
          print("Instance is being deleted")
  ```

---

## **2. 연산자 오버로딩 관련 메서드**

### 산술 연산자
- **`__add__(self, other)`**: `+` 연산자.
- **`__sub__(self, other)`**: `-` 연산자.
- **`__mul__(self, other)`**: `*` 연산자.
- **예제**:
  ```python
  class Vector:
      def __init__(self, x, y):
          self.x = x
          self.y = y

      def __add__(self, other):
          return Vector(self.x + other.x, self.y + other.y)

      def __repr__(self):
          return f"Vector({self.x}, {self.y})"

  v1 = Vector(1, 2)
  v2 = Vector(3, 4)
  print(v1 + v2)  # 출력: Vector(4, 6)
  ```

### 비교 연산자
- **`__eq__(self, other)`**: `==` 연산자.
- **`__lt__(self, other)`**: `<` 연산자.
- **예제**:
  ```python
  class Person:
      def __init__(self, age):
          self.age = age

      def __eq__(self, other):
          return self.age == other.age

  p1 = Person(30)
  p2 = Person(30)
  print(p1 == p2)  # 출력: True
  ```

### 논리 연산자
- **`__and__(self, other)`**: `&` 연산자.
- **`__or__(self, other)`**: `|` 연산자.

---

## **3. 문자열 표현 관련 메서드**

### **`__str__(self)`**
- **용도**: `print()` 함수나 `str()` 호출 시 객체의 문자열 표현을 반환.
- **예제**:
  ```python
  class MyClass:
      def __str__(self):
          return "This is MyClass instance"

  obj = MyClass()
  print(obj)  # 출력: This is MyClass instance
  ```

### **`__repr__(self)`**
- **용도**: 객체의 개발자 친화적인 표현을 반환. 주로 디버깅 목적.
- **예제**:
  ```python
  class MyClass:
      def __repr__(self):
          return "MyClass()"

  obj = MyClass()
  print(repr(obj))  # 출력: MyClass()
  ```

---

## **4. 컨테이너 관련 메서드**

### **`__getitem__(self, key)`**
- **용도**: 객체가 인덱싱될 때 호출.
- **예제**:
  ```python
  class MyList:
      def __init__(self, data):
          self.data = data

      def __getitem__(self, index):
          return self.data[index]

  obj = MyList([1, 2, 3])
  print(obj[1])  # 출력: 2
  ```

### **`__setitem__(self, key, value)`**
- **용도**: 객체의 특정 요소를 설정할 때 호출.
- **예제**:
  ```python
  class MyList:
      def __init__(self, data):
          self.data = data

      def __setitem__(self, index, value):
          self.data[index] = value

  obj = MyList([1, 2, 3])
  obj[1] = 10
  print(obj.data)  # 출력: [1, 10, 3]
  ```

### **`__len__(self)`**
- **용도**: `len()` 호출 시 객체의 길이를 반환.
- **예제**:
  ```python
  class MyList:
      def __init__(self, data):
          self.data = data

      def __len__(self):
          return len(self.data)

  obj = MyList([1, 2, 3])
  print(len(obj))  # 출력: 3
  ```

---

## **5. 호출 가능 객체 관련 메서드**

### **`__call__(self, ...)`**
- **용도**: 객체를 함수처럼 호출할 때 동작 정의.
- **예제**:
  ```python
  class MyCallable:
      def __call__(self, x):
          return x * 2

  obj = MyCallable()
  print(obj(5))  # 출력: 10
  ```

---

## **6. 컨텍스트 매니저 관련 메서드**

### **`__enter__(self)`**
- **용도**: `with` 문 진입 시 실행되는 코드 정의.
### **`__exit__(self, exc_type, exc_value, traceback)`**
- **용도**: `with` 문 종료 시 실행되는 코드 정의.
- **예제**:
  ```python
  class MyContextManager:
      def __enter__(self):
          print("Entering context")
          return self

      def __exit__(self, exc_type, exc_value, traceback):
          print("Exiting context")

  with MyContextManager():
      print("Inside context")
  ```

---

## **7. 기타 메서드**

### **`__iter__(self)`**
- **용도**: 객체를 반복 가능하게 만듦.
- **예제**:
  ```python
  class MyIterator:
      def __init__(self, data):
          self.data = data
          self.index = 0

      def __iter__(self):
          return self

      def __next__(self):
          if self.index >= len(self.data):
              raise StopIteration
          result = self.data[self.index]
          self.index += 1
          return result

  obj = MyIterator([1, 2, 3])
  for item in obj:
      print(item)
  ```

---

### **요약**

던더 메서드는 파이썬의 객체 동작을 사용자 정의할 수 있는 강력한 도구입니다. 이를 적절히 활용하면 코드의 가독성과 재사용성을 크게 높일 수 있습니다. 하지만 남용할 경우 코드의 복잡도가 증가할 수 있으니, 필요한 경우에만 적절히 사용하는 것이 중요합니다.
