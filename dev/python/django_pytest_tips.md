# Django + Pytest 활용 Tip

> 날짜: 2021-02-02

## Global mocking 하기

- 모든 test 에 대하여 특정 함수를 mocking 하는 방법
- 프로젝트 홈폴더에 `conftest.py` 라는 파일을 만들어 아래 내용을 추가한다.

```python
import mock
import pytest

GLOBAL_MOCKING_REFERENCES = [
    "app.util.my_func",
]


@pytest.fixture(scope="session", autouse=True)
def default_session_fixture(request):
    """
    Fixture would affect throughout all tests
    """
    for mocking_ref in GLOBAL_MOCKING_REFERENCES:
        patched = mock.patch(mocking_ref)
        patched.__enter__()

        def unpatch():
            patched.__exit__()

        request.addfinalizer(unpatch)

```

---

[목록으로](https://shiwoo-park.github.io/blog)
