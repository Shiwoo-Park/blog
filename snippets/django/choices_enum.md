# ChoicesEnum : Enum 을 쉽고 편리하게 관리


## ChoicesEnum class

- Enum 데이터를 python code 에 정의할 수 있도록 도와준다.
- 기본적으로 변수명(enum name), 값(code), 설명(text) 을 지정하며 
- `__init__()` 함수 override 를 통해 확장도 가능
- 매우 다양한 유틸함수를 제공하며 기본적으로 `members()` 함수를 기반으로 동작하기 때문에 `include, exclude, text_contains` 파라미터 사용이 가능하다.

```python
import logging
from enum import Enum
from typing import List, Tuple, Dict, Optional

logger = logging.getLogger(__name__)


class ChoicesEnum(Enum):
    """
    Python Utility class for Enum

    <Function Usage>
    1. All
      ex) Destination.choices()
    2. Selected
      ex) Destination.choices(include=[Destination.DT00, Destination.DT01])
    3. Exclude
      ex) Destination.choices(exclude=[Destination.DT00, Destination.DT01])

    1. 기본 사용법
    class Link(ChoicesEnum):
        APP_STORE_LINK = ('LK01', 'Apple Link')
        PLAY_STORE_LINK = ('LK02', 'Banana Link')
    print(Link.APP_STORE_LINK.code)  # "LK01"
    print(Link.APP_STORE_LINK.text)  # "Apple Link"
    print(Link.choices())  # [("LK01", "Apple Link"), ("LK02", "Banana Link")]

    2. 확장된 사용법 (override __init__)
    class Link(ChoicesEnum):
        APP_STORE_LINK = ('LK01', 'Apple Link', 'https://link1.com')
        PLAY_STORE_LINK = ('LK02', 'Banana Link', 'https://link2.com')
        def __init__(self, *args, **kwargs):
            super().__init__(*args, **kwargs)
            self.url = args[2]

    print(Link.APP_STORE_LINK.url)  # "https://link1.com"
    """

    @classmethod
    def get_attribute_error_message(cls):
        return "'code' and 'text' should be declared for 'ChoicesEnum' subclass enum element"

    @classmethod
    def members(cls, **kwargs) -> List:
        """
        <Return example>
        [EnumObj1, EnumObj2, ...]
        """
        try:
            if "include" in kwargs:
                return [member for member in kwargs["include"] if member in cls]
            if "exclude" in kwargs:
                return [member for member in cls if member not in kwargs["exclude"]]
            if "text_contains" in kwargs and kwargs["text_contains"] is not None:
                return [
                    member for member in cls if kwargs["text_contains"] in member.text
                ]

            return [member for member in cls]

        except AttributeError:
            raise AttributeError(cls.get_attribute_error_message())

    @classmethod
    def choices(cls, **kwargs) -> List[Tuple]:
        """
        <Return example>
        [("CODE_01", "TEXT_01"), ("CODE_02": "TEXT_02"), ...]
        """
        return [(member.code, member.text) for member in cls.members(**kwargs)]

    @classmethod
    def as_dict(cls, **kwargs) -> Dict:
        """
        <Return example>
        {"CODE_01": "TEXT_01", "CODE_02": "TEXT_02", ...}
        """
        return {member.code: member.text for member in cls.members(**kwargs)}

    @classmethod
    def as_text_dict(cls, **kwargs) -> Dict:
        """
        <Return example>
        {"TEXT_01": "CODE_01", "TEXT_02": "CODE_02", ...}
        """
        return {member.text: member.code for member in cls.members(**kwargs)}

    @classmethod
    def as_dict_list(cls, **kwargs) -> List[Dict]:
        """
        <Return example>
        [{code: "CODE_01", text: "TEXT_01"}, ...]
        """
        return [
            {"code": member.code, "text": member.text}
            for member in cls.members(**kwargs)
        ]

    @classmethod
    def as_code_list(cls, **kwargs) -> List:
        """
        <Return example>
        ["CODE_01", "CODE_02", ...]
        """
        return [member.code for member in cls.members(**kwargs)]

    @classmethod
    def as_text_list(cls, **kwargs):
        """
        <Return example>
        ["TEXT_01", "TEXT_02", ...]
        """
        return [member.text for member in cls.members(**kwargs)]

    @classmethod
    def get_text(cls, code, default=None) -> Optional[str]:
        try:
            return cls.get_member(code).text
        except AttributeError:
            return default

    @classmethod
    def get_member(cls, code):
        """
        :param code: ENUM_CODE (string)
        :return: Enum Object
        """
        try:
            return next(member for member in cls if member.code == code)
        except StopIteration:
            return None
        except AttributeError:
            raise AttributeError(cls.get_attribute_error_message())

    def __init__(self, *args, **kwargs):
        if len(args) < 2:
            raise AttributeError(self.get_attribute_error_message())
        self.code = args[0]
        self.text = args[1]

    def __str__(self):
        return f"{self.text}({self.code})"
```

## 용법1: Django Model 에서 사용하기

```python
class PaymentTransaction(models.Model):
    class TransactionType(ChoicesEnum):
        PAYMENT = ("TT_01", "결제완료")
        REFUND = ("TT_02", "결제취소")

    transaction_type = models.CharField(
        max_length=5,
        choices=TransactionType.choices(),
        default=TransactionType.PAYMENT.code,
    )

    @property
    def transaction_type_display(self):
        return self.TransactionType.get_text(
            self.transaction_type, default=self.transaction_type
        )

print(PaymentTransaction.transaction_type.PAYMENT.code)  # TT_01
print(PaymentTransaction.transaction_type.PAYMENT.text)  # 결제완료
```

## 용법2: 단독으로 사용하기

```python
class PaymentResponseCode(ChoicesEnum):
    SUCCESS = (0, "성공")
    BAD_REQUEST = (400, "잘못된 요청입니다.")
    NOT_FOUND = (404, "결제번호가 없습니다.")
    ALREADY_PROCESSED = (409, "이미 처리된 결제")
    ERP_FAILED = (424, "ERP 전송 실패")
    MAX_RETRIES_EXCEEDED = (429, "최대 재시도 횟수 초과")
    INVALID_HASH = (499, "해쉬값 불일치")
    FAILED = (999, "Callback 프로세스 처리 실패")

print(PaymentResponseCode.NOT_FOUND.code)  # 400
print(PaymentResponseCode.NOT_FOUND.text)  # 결제번호가 없습니다.
```

## 용법3: 확장된 사용법

```python
class SearchAdvertisement(models.Model):

    class AdType(ChoicesEnum):
        SINGLE = ("SINGLE", "단일", 1, 1)
        GROUP = ("GROUP", "묶음", 3, 5)

        def __init__(self, *args, **kwargs):
            super().__init__(*args, **kwargs)
            # 광고에 노출할 상품 개수
            self.expose_product_count = args[2]
            # 광고 상품 선정에 활용될 검색결과 최상위 N개 상품을 지정
            self.reference_product_count = args[3]

# views.py
ad_type_enum = SearchAdvertisement.AdType.get_member(search_ad.ad_type)
products_data = SearchAdvertisementService.get_products_data(
    self.request.user, search_ad, ad_type_enum.expose_product_count
)
```