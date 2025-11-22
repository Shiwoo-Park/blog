---
layout: post
title: "pytest VS 파이썬 unittest"
date: 2021-10-16
categories: [python, pytest, testing]
---
파이썬 기본 test 모듈은 바로 [unittest](https://docs.python.org/3/library/unittest.html) 모듈 이다. <br/>
이와 비교했을때 pytest 가 어떤점이 더 좋은지 한번 알아보고자 한다.

## 간단한 테스트 작성 및 그 결과 비교

- 간단하게 유닛테스트 동작을 체크하기 위하여 Always pass, fail test 작성
- 두가지 서로다른 테스트 양식으로 만들고 그 결과물 비교

### unittest 작성

#### Made by python unittest

```python
# test_with_unittest.py

from unittest import TestCase

class TryTesting(TestCase):
    def test_always_passes(self):
        self.assertTrue(True)

    def test_always_fails(self):
        self.assertTrue(False)
```

#### Made by pytest

```python
# test_with_pytest.py

def test_always_passes():
    assert True

def test_always_fails():
    assert False
```

### 테스트 결과 출력

#### Result by python unittest

참고로 장고 TestCase 는 파이썬의 unittest 를 확장하였다, 즉 출력물이 동일함

```shell
$ python -m unittest discover
F.
============================================================
FAIL: test_always_fails (test_with_unittest.TryTesting)
------------------------------------------------------------
Traceback (most recent call last):
  File "/.../test_with_unittest.py", line 9, in test_always_fails
    self.assertTrue(False)
AssertionError: False is not True

------------------------------------------------------------
Ran 2 tests in 0.001s

FAILED (failures=1)
```

#### Result by pytest

```shell
$ pytest
================== test session starts =============================
platform darwin -- Python 3.7.3, pytest-5.3.0, py-1.8.0, pluggy-0.13.0
rootdir: /.../effective-python-testing-with-pytest
collected 2 items

test_with_pytest.py .F                                          [100%]

======================== FAILURES ==================================
___________________ test_always_fails ______________________________

    def test_always_fails():
>       assert False
E       assert False

test_with_pytest.py:5: AssertionError
============== 1 failed, 1 passed in 0.07s =========================
```

### 결론
- state 정보를 출력해준다: 파이썬, pytest, plugin 등의 버전정보
- rootdir 표시르 해준다: 테스트르 실행하는 최상위 폴더르 명시함으로서 어디 path 를 대상을 테스트 진행했는지 알 수 있음
- 몇개의 테스트가 진행되었는지 알 수 있다.
- 플러그인 등을 사용하며 훨씬 더 다양하고 자세한 설명을 볼 수 있다 (파일별 / 전체 테스트 커버리지 등)


## 상태값과 의존성의 처리

- unittest 의 경우
  - setUp() 함수에서 한꺼번에 테스트에 필요한 정보를 생성하는 형식
  - 테스트 단위별 검증포인트가 다 다름에도 일괄적이고 암묵적인 테스트 데이터의 생성이 테스트 코드 이해를 어렵게 만듦
- pytest 의 경우
  - fixture 를 함수로 제작하여 필요시에만 unittest 에 argument 형식으로 inject
  - 이로인해 유닛테스트 별로 어떤 데이터가 필요한지 명확하게 알아볼 수 있게 되고 코드 이해도 쉬워짐
  - 심지어 fixture 가 다른 fixture 를 활용 가능하기 때문에 재사용성이나 확장성이 훌륭함

## Test 필터링

pytest 는 아래 3가지 형식으로 원하는 테스트만을 실행 할 수 있는 기능을 제공한다

1. Name-based filtering: 실행히 `-k` 옵션을 이용하여 특정한 name 에 매칭되는 테스트만 실행 가능
2. Directory scoping: 기본적으로 pytest 명령어는 실행되는 current dir 하위의 테스트 파일만을 테스트한다. 직접 rootdir 지정도 가능
3. Test categorization: 테스트으 카테로리르 구분해두면 특정 카테고리의 테스트만 실행하 수 있다 (`-m` 옵션 사용)

하지만 반면에 unittest 는...<br/>
여러 테스트르 하나처럼 묶을 수 있으나 테스트 결과에서 또 파일별로 내용을 구분해주지는 못한다<br/>
하나만 실패하고 다 통과 되어도 그룹에서 하나의 실패가 난것으로마 보이기 때문에 정확히 어떤 테스트가 실패했는지 알기 어려움


## Plugin 시스템

파이썬 unittest 와는 달리 pytest 는 plug-in 시스템을 제공하여 유저의 커스터마이징에 대해서 모든 가능성을 열러 두었다.<br/>
그리고 실제로 이를 활용해 유용한 플러그인들이 많이 개발되어 테스트에 도움으 주고 있다

### 유용한 pytest plug-in 7개

- `pytest-cov` : 테스트 결과에 코드 커버리지 report 추가
- `pytest-django` : `django.test.TestCase` 에서 제공되는 모든 fixture, assert 방식들을 제공
  - django_db 커넥션 지원
  - test client object 사용가능
- `pytest-asyncio` : async program 을 테스트하기 좋은 플러그인. 기존 pytest 에 async 형식의 기능을 훌륭히 제공해준다
- `pytest-randomly` : unit-test 를 무작위 순서로 실행해주는 기능 제공. unit-test 간 의존성 검증에 효과적
- `pytest-clarity` : pytest 실패내역에 대한 출력 결과를 한차원 더 또렷하게 보여주는 기능 제공. 결고 가시성이 매우 뛰어남
- `pytest-bdd` : `BDD(=Behavior-driven Development)` 는 `TDD(Test-driven Development)` 의 확장팩이다. 
   어떠한 특정 도메인 또는 흐름(=story)에 따라 테스트를 연결지을 수 있는 기능 제공 (feat. [Gherkin format](https://www.guru99.com/gherkin-test-cucumber.html) )


## 참고자료

- [Effective Python Testing With Pytest](https://realpython.com/pytest-python-testing/)
- [Django - writing unit tests](https://docs.djangoproject.com/en/3.2/topics/testing/overview/)
- [7 pytest Plugins You Must Definitely Use](https://miguendes.me/7-pytest-plugins-you-must-definitely-use)
