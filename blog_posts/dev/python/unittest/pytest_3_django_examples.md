---
layout: post
title: "Django + pytest 실용 예제 모음"
date: 2021-10-28
categories: [python, django, pytest]
---

# Django + pytest 실용 예제 모음

> 날짜: 2021-10-28

## 다양한 case 별 UnitTest 예제 소개

### 응답코드 및 메세지 비교

가장 기본적이고 많이 쓰이는 test 이다.

```python
@pytest.mark.django_db
def test_fail_no_auth_header(client):
    mock_res = MockResponse()

    with patch.object(requests, "request", return_value=mock_res):
        response = client.get(
            "/test/post/path",
        )

        assert response.status_code == status.HTTP_401_UNAUTHORIZED
        assert "Authentication credentials were not provided" in str(
            response.content.decode("utf8")
        )
```

### Set HTTP Header

`Authorization` HTTP header 를 set 하기 위해서 어떻게 했는지 한번 보자

```python
@pytest.mark.django_db
def test_fail_no_app_id_header(client, default_user_data):
    mock_res = MockResponse()

    with patch.object(requests, "request", return_value=mock_res):
        response = client.get(
            "/test/post/path",
            HTTP_AUTHORIZATION=default_user_data["auth_token"],
        )

        assert response.status_code == status.HTTP_400_BAD_REQUEST
        assert "Please set App ID on header" in str(response.content.decode("utf8"))
```

### 파라미터 검증

`requests.request()` 함수를 mocking 한뒤, API call 을 하고, passed parameter 를 확인

```python
@pytest.mark.django_db
def test_pass_post(client, default_user_data, default_org_app_data):
    mock_res = MockResponse(response_json={"status": "DONE"})
    app = default_org_app_data["app"]

    with patch.object(requests, "request", return_value=mock_res):
        response = client.post(
            "/test/post/path",
            HTTP_AUTHORIZATION=default_user_data["auth_token"],
            HTTP_APP_ID=app.app_id,
            content_type="application/json",
            data={},
        )

        response_text = str(response.content.decode("utf8"))

        assert response.status_code == status.HTTP_200_OK
        assert "DONE" in response_text

        # check requested data
        args, kwargs = requests.request.call_args  # tuple, dict
        assert isinstance(kwargs["json"], dict)
        requested_data = json.loads(kwargs["data"])
        assert requested_data == "expected_val1"
```


### File upload API test

```python
@pytest.fixture
def png_file():
    f = open(f"{settings.BASE_DIR}/resource/test_3.png", 'rb')
    yield f
    f.close()


def test_fail_upload_file_invalid_extension(client, png_file):
    response = client.post(
        "/file/upload/path",
        {'file': png_file}
    )

    assert response.status_code == status.HTTP_400_BAD_REQUEST

    response_text = str(response.content.decode("utf8"))
    # response_text = {"file":["파일 확장자 'png'는 허용되지 않습니다. 허용된 확장자: 'pdf, zip'."]}
    assert "파일 확장자" in response_text
    assert "허용되지 않습니다" in response_text
```

### Transaction rollback test


```python
@pytest.mark.django_db
def test_fail_transaction_check(
    client, default_service_data, api_auth_token
):
    user = default_service_data["user"]
    diary = default_service_data["diary"]
    
    # user - diary 는 1:n 관계이며 삭제 API 호출 시, 같이 제거되어야 하는 상황

    with pytest.raises(ExplicitError):
        with patch.object(
            User, "save", side_effect=ExplicitError("explicit error")  # transaction 걸린 구간에서 강제 에러 발생
        ):
            response = client.delete(
                f"/my_api/users/{user.id}",
                HTTP_AUTHORIZATION=api_auth_token,
                data={},
            )

        assert response.status_code == status.HTTP_500_INTERNAL_SERVER_ERROR
        assert diary.deleted_at is None  # User 삭제에 실패했기 때문에 그 유저의 Diary 도 삭제되지 않음
```

### Monkey patching external API calls

```python
import time
from datetime import datetime, timedelta
from unittest.mock import patch

import pytest
import stripe

from app.logics import create_upfront_invoice, mail_queue
from app.logics.subscription import charge_failed_invoice
from app.models import Payment
from app.tests.test_utils import ExplicitError


class MockClass:
    # mocking 이 필요한 각종 attribute 및 function 을 임의로 전부 추가해준다.
    
    id = "mock_id"
    due_date = time.mktime((datetime.now() + timedelta(days=15)).timetuple())
    invoice_pdf = "mock_pdf_link"
    charge = "mock_charge"
    data = [{"id": "mock_payment_method_id"}]

    def pay(self, *args, **kwargs):
        return self

    def save(self):
        return self


def mock_func(*args, **kwargs):
    # function 이 mocking 되어야 할때 이렇게 해보자
    return MockClass()


@pytest.fixture
def monkeypatch_stripe_api_calls(monkeypatch):
    # mocking 이 필요한 모든 function들... (하나로 퉁친다)
    monkeypatch.setattr(stripe.Invoice, "create", mock_func)
    monkeypatch.setattr(stripe.Invoice, "retrieve", mock_func)
    monkeypatch.setattr(stripe.InvoiceItem, "create", mock_func)
    monkeypatch.setattr(stripe.Charge, "retrieve", mock_func)
    monkeypatch.setattr(stripe.PaymentMethod, "list", mock_func)


@pytest.fixture
def monkeypatch_email_api_calls(monkeypatch):
    # 예를들어 mocking 이 필요한 다른 외부 API 가 또 있다고 해본다
    monkeypatch.setattr(
        mail_queue, "get_billing_emails", lambda x: ["mock_email"]
    )
    monkeypatch.setattr(mail_queue, "add_billing_emails_to_queue", mock_func)


@pytest.mark.django_db
def test_charge_failed_invoice_pass(
    default_subscription, monkeypatch_stripe_api_calls, monkeypatch_email_api_calls
):
    invoice = create_upfront_invoice(default_subscription)
    invoice.status = invoice.Status.FAILED
    invoice.save()

    charge_failed_invoice(invoice.uid)  # 모든 외부 API call 이 완벽히 mocking 되었으므로 테스트는 이상없이 마무리된다.

    invoice.refresh_from_db()
    payments = Payment.objects.filter(invoice=invoice)
    
    assert invoice.status == "PAID"
    assert payments.count() == 1
```


## 기타

### Mock Response for requests

우리는 파이썬 프로젝트에서 HTTP client 로 requests 를 많이 활용하곤 한다.<br/>
이때 unittest를 작성하다보면 심심찮게 requests 로 외부 API 를 호출하는 코드 부분의 mocking 이 필요해진다. <br/>
이때 마술처럼 원하는 응답을 손쉽게 Mocking 해주는 클래스

```python
import json
from typing import Dict


class MockResponse:
    """
    Mocked response object of "requests" package
    <Usage example>
    import requests
    from unittest.mock import patch
    from app.tests.common_test_utils import MockResponse
    with patch.object(requests, "post", return_value=MockResponse(400, response_json={"success":False})):
        # Some test code calls [requests.post] internally comes here
        # ...
    """

    ok = True
    status_code = None
    response_json = None
    content = b""
    text = ""

    def __init__(
        self,
        status_code: int = 200,
        response_json: Dict = None,
        response_text: str = "",
    ):
        if response_json and response_text:
            raise ValueError(
                "Set only one of [response_json | response_text] as a response"
            )

        self.response_json = response_json
        self.status_code = status_code
        if response_json:
            self.text = json.dumps(self.response_json)
        else:
            self.text = response_text
        self.content = self.text.encode("utf-8")

    def json(self):
        return json.loads(self.text)
```

### unittest 를 class 로 묶어서 작성하기

- unittest 들을 하나의 class 로 묶어서 처리
- [fixture scoping](https://docs.pytest.org/en/6.2.x/fixture.html#fixture-scopes) 활용

```python
import pytest
from django.contrib.messages.storage.fallback import FallbackStorage
from pytest_django.fixtures import _django_db_fixture_helper
from rest_framework import status

from apps_etc.givevod.views import GiveVODCreateView, GiveVODUpdateView
from core.models.content.t_extra_video_event import TExtraVideoEvent, TExtraVideoEventReward
from core.models.user.t_single_product import TSingleProduct
from core.utils import string_util, time_util


@pytest.fixture(scope="module")
def module_scoped_db(request, django_db_setup, django_db_blocker):
    if "django_db_reset_sequences" in request.funcargnames:
        request.getfixturevalue("django_db_reset_sequences")
    if (
            "transactional_db" in request.funcargnames
            or "live_server" in request.funcargnames
    ):
        request.getfixturevalue("transactional_db")
    else:
        _django_db_fixture_helper(request, django_db_blocker, transactional=False)


@pytest.fixture(scope="module")
def event_data():
    test_single = TSingleProduct.filtered_objects.only_movie_ppv().first()
    data = {
        'title': "[TEST] give vod",
        'activation': 'N',
        'start_dt': time_util.get_current_datetime_str(),
        'end_dt': time_util.get_week_after_datetime_str(),
        'series_id': test_single.series_id,
        'single_id': test_single.product_id
    }
    return data


@pytest.fixture(scope="module")
def random_event_obj(module_scoped_db, event_data):
    event = TExtraVideoEvent.objects.create(**event_data)
    TExtraVideoEventReward.objects.create(
        event=event, series_id=event_data['series_id'], single_id=event_data['single_id'])

    yield event
    event.delete()


@pytest.mark.django_db
class TestGiveVOD:
    def test_url_list(self, client):
        res = client.get("/give-vod/list/")
        assert res.status_code == status.HTTP_200_OK

    def test_url_create(self, client):
        res = client.get("/give-vod/create/")
        assert res.status_code == status.HTTP_200_OK

    def test_url_update(self, client, random_event_obj):
        res = client.get(f"/give-vod/{random_event_obj.uid}/update/")
        assert res.status_code == status.HTTP_200_OK

    def test_url_api(self, client, random_event_obj):
        res = client.get(f"/give-vod/api/{random_event_obj.uid}/")
        assert res.status_code == status.HTTP_200_OK
    
    def test_api_update(self, client, random_event_obj):
        data = string_util.json_stringify({'activation': "Y"})
        res = client.patch(f"/give-vod/api/{random_event_obj.uid}/", data, content_type="application/json")
        assert res.status_code == status.HTTP_200_OK

        res = client.get(f"/give-vod/api/{random_event_obj.uid}/")
        assert res.status_code == status.HTTP_200_OK
        assert res.data['activation'] == "Y"

    def test_api_delete(self, client, random_event_obj):
        res = client.delete(f"/give-vod/api/{random_event_obj.uid}/")
        assert res.status_code == status.HTTP_204_NO_CONTENT
```

---

[목록으로](https://shiwoo-park.github.io/blog)
