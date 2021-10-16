# pytest VS 다른 test 모듈

> 날짜: 2021-10-16

파이썬 기본 test 모듈은 바로 [unittest](https://docs.python.org/3/library/unittest.html) 모듈 이다.<br/>
이와 비교했을때 pytest 가 어떤점이 더 좋은지 한번 알아보고자 한다.

## Always pass, fail test 비교

간단하게 유닛테스트 동작을 체크하기위한 성공, 실패 검증용 test 를 각각의 방식으로 만들고 그 결과 비교

### unittest 작성 결과

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

```
# test_with_pytest.py

def test_always_passes():
    assert True

def test_always_fails():
    assert False
```

### 테스트 결과 출력

#### Result by python unittest

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

To be continued ... [from](https://realpython.com/pytest-python-testing/#state-and-dependency-management)

## 참고자료

- [Effective Python Testing With Pytest](https://realpython.com/pytest-python-testing/)
- [Django - writing unit tests](https://docs.djangoproject.com/en/3.2/topics/testing/overview/)

---

[목록으로](https://shiwoo-park.github.io/blog/kor)
