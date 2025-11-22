---
layout: post
title: "Django or DRF 의 View 에 Custom Decorator 를 달아보자"
date: 2020-07-17
categories: [python, django, decorator]
---


이 글은 독자가 `파이썬의 Decorator` 라는 개념을 이미 알고 있다는 것을 전제하고 작성되었습니다.

아직 데커레이터를 모르시는 분들은 먼저 한번 그게 무엇인지 구글링을 해보고 오심을 추천드립니다.

간단하게 설명 드리자면 `특정 함수에 전처리 or 후처리 기능을 골뱅이(@) 를 사용하여 손쉽게 넣을 수 있는 파이썬 기능` 입니다.

데커레이터는 decorated 함수의 입력 값과 리턴값의 구성이 완벽히 동일한 함수를 리턴해줘야 합니다.

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

여기서 유의 하여 보셔야 할 부분은 인자값이 비슷한 패턴이라는 것입니다.

request 라고 쓰여있어서 동일하지 않냐 라고 생각하실 수 있지만, DRF 와 Django 에서의 사용하는 request type 이 다르기 때문에 완전히 동일하지는 않습니다.

그래서 우리는 입력되는 request 를 가지고 어떤 원하는 비즈니스 로직을 처리할 수 있는 Decorator 를 만들어서 활용할 수 있지요

저 같은경우는 아래와같은 데커레이터를 만들어서 써봤습니다.

1. Django Auth 프레임웤을 사용 할 수 없었던 사정이 있어, 메서드별로 권한 코드의 보유여부 등을 체크하는 Access 인증용 데커레이터
2. 입력 시, 필수 param, data 의 키값 보유 여부를 검증하여 없을 시 자동으로 400 응답을 돌려주는 데커레이터
3. 특정 IP 로만 접속되어야 하는 view 함수의 경우, IP 차단을 검증해주는 데커레이터

그럼 커스텀 Decorator 를 만들기 위해, 이미 Django 에서 제공하는 Built-in Decorator 를 한번 살펴봅시다

사실 아래의 코드를 이해할 수 있다면, 커스텀 데커레이터 만들기는 식은죽 먹기입니다.

`require_http_methods` 라는 데커레이터 인데요. 일단 코드를 한번 보시죠

```python
from functools import wraps

from django.http import HttpResponseNotAllowed
from django.utils.log import log_response


def require_http_methods(request_method_list):   # --- 1번
    """
    Decorator to make a view only accept particular request methods.  Usage::

        @require_http_methods(["GET", "POST"])
        def my_view(request):
            # I can assume now that only GET or POST requests make it this far
            # ...

    Note that request methods should be in uppercase.
    """
    def decorator(func):   # --- 2번
        @wraps(func)       # --- 3번
        def inner(request, *args, **kwargs):   # --- 4번
            if request.method not in request_method_list:
                response = HttpResponseNotAllowed(request_method_list)
                log_response(
                    'Method Not Allowed (%s): %s', request.method, request.path,
                    response=response,
                    request=request,
                )
                return response   # --- 5번
            return func(request, *args, **kwargs)  # --- 6번
        return inner  # --- 7번
    return decorator  # --- 8번
```

자, 어떤 일을 하는 decorator 같은가요?

함수명에서부터 알 수 있듯이, 함수형 view 작성 시, 지원되는 http method 를 제한하기위해 사용되는 decorator 입니다.

미리 지정되지 않은 method 의 http request 가 들어오면 HttpResponseNotAllowed 객체를 리턴하는 것이죠.

그럼, 위에 주석으로 번호표를 달아놨는데 그것을 참고하면서 차근차근 코드를 살펴보겠습니다.

- 일단 가장 바깥쪽인 `require_http_methods` 라는 함수는 내부의 `decorator` 라는 함수를 리턴하는 고위 함수 입니다.
- 왜 이렇게 만들었을까요? 그 이유는 1번에서처럼 `request_method_list` 라는 자체 인자값을 가져야 하기 때문입니다. 
- 입력값이 없었더라면 decorator 라는 내부함수를 두어 한번 더 래핑 할 필요가 없었겟지요. 그리고 decorator 를 사용할때 `@require_http_methods(["GET", "POST"])` 와 같은 식으로 call 을 하지도 않았을 겁니다. 인자값이 없는경우에는 `@require_http_methods` 라고만 붙이거든요.
- 그럼 2번에 있는 `decorator` 함수를 봅시다. func 라는 인자를 받았는데, 이것이 decorated 함수 자체를 의미합니다. 그리고 @wraps 로 데커레이트 된 `inner` 함수를 리턴하고 있죠.
- 4번 `inner` 는 이제 이 데커레이터의 주요 기능인 전처리로직을 포함하고 있는 내부 함수 입니다. 최종적으로 데커레이트 된 함수 자체를 바꿔치기 하게될 함수이기도 합니다. 자, 그럼 이쯤에서... 3번의 `@wraps` 라는 데커레이터 ... 이것은 왜 있는것일까요?
- `@wraps` 는 일단 결론부터 말하면 데커레이트 된 함수의 속성을 리턴하고자 하는 신규 함수로 복사해주기 위한 decorator 입니다. 왜 이렇게 할까요? 데커레이터는 기존의 함수에 일부 로직을 추가하기위한 수단인 것이기 떄문에 기존함수의 고유 속성값을 유실되게 두지 않고, 동일한 값으로 유지시켜 주기 위함입니다.
- 그래서, inner 라는 함수는 전처리 로직에서 통과 실패시 5번의 응답을, 성공 시 6번의 응답을 리턴해주게 됩니다. 6번에 보시면 기존에 func 로부터 넘어오는 인자값을 그대로 전달해주고 있음을 보실 수 있습니다.
