# Django or DRF 의 View 에 Custom Decorator 를 달아보자

> 날짜: 2020-07-17

이 글은 독자가 `파이썬의 Decorator` 라는 개념을 이미 알고 있다는 것을 전제하고 작성되었습니다.

아직 데커레이터를 모르시는 분들은 먼저 한번 그게 무엇인지 구글링을 해보고 오심을 추천드립니다.

간단하게 설명 드리자면 `특정 함수에 추가기능을 골뱅이(@) 를 사용하여 손쉽게 넣을 수 있는 파이썬 기능` 입니다.

---

어쩃든, 그럼 본론으로 들어가서 !!!

Django 에서 제공되는 일반적인 View, 그리고 DRF(Django REST Framework)에서 제공되는 APIView 를 살펴보면

최초 HTTP Request 가 진입하는 메서드별 매핑 함수 argument 포맷이 모두 동일하게 아래와 같은 기본 형태를 가지고 있습니다.

```python
def dispatch(self, request, *args, **kwargs):
    pass

def get(self, request, *args, **kwargs):
    pass
```

그래서 우리는 입력되는 request 를 가지고 어떤 원하는 비즈니스 로직을 처리할 수 있는 Decorator 를 만들어서 활용할 수 있지요

저 같은경우는 아래와같은 데커레이터를 만들어서 써봤습니다.

1. Django Auth 프레임웤을 사용 할 수 없었던 사정이 있어, 메서드별로 권한 코드의 보유여부 등을 체크하는 Access 인증용 데커레이터
2. 입력 시, 필수 param, data 의 키값 보유 여부를 검증하여 없을 시 자동으로 400 응답을 돌려주는 데커레이터
3. 특정 IP 로만 접속되어야 하는 view 함수의 경우, IP 차단을 검증해주는 데커레이터

그럼 커스텀 Decorator 를 만들기 위해 이미 Django 에서 제공하는 Built-in Decorator 를 한번 살펴봅시다

사실 아래의 코드를 이해할 수 있다면, 커스텀 데커레이터 만들기는 식은죽 먹기입니다.

일단 코드를 한번 보시죠

```python
from functools import wraps

from django.http import HttpResponseNotAllowed
from django.middleware.http import ConditionalGetMiddleware
from django.utils.decorators import decorator_from_middleware
from django.utils.log import log_response


def require_http_methods(request_method_list):
    """
    Decorator to make a view only accept particular request methods.  Usage::

        @require_http_methods(["GET", "POST"])
        def my_view(request):
            # I can assume now that only GET or POST requests make it this far
            # ...

    Note that request methods should be in uppercase.
    """
    def decorator(func):
        @wraps(func)
        def inner(request, *args, **kwargs):
            if request.method not in request_method_list:
                response = HttpResponseNotAllowed(request_method_list)
                log_response(
                    'Method Not Allowed (%s): %s', request.method, request.path,
                    response=response,
                    request=request,
                )
                return response
            return func(request, *args, **kwargs)
        return inner
    return decorator
```

(계속 작성 예정 ...)

---

[목록으로](https://github.com/Shiwoo-Park/blog/tree/master/kor)
