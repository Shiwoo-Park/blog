# 주석 및 타입힌트 보강 요청

- 지정한 파일 또는 reference 에 대하여
- 각 클래스 및 함수 코드의 주석 및 타입힌트 보강해줘
- 코드나 변수를 곁들여 설명하기보다 맥락을 이해할 수 있도록 인간이 알아듣기 쉬운 언어로 작성해줘
- 기존 주석들이 있다면 타당성 검토 및 보완 + 업데이트도 같이 해줘
- 코드 분석중 버그가 발견되면 기존 비즈니스로직은 절대로 건드리지말고 항목들을 모아 리포트 해줘

## 주석에 포함되어야 할 사항

- 내부 로직의 핵심내용
- 로직이 수행하는 작업의 목적과 의미
- 함수일 경우
  - argument, return 값이 복잡한 경우에만 docstring 작성
  - 단순 primitive 타입인경우 문서화에서 제외
  - List, Dict 타입은 필수

## Python 프로젝트 특화 요청

- DRF 에서 기본으로 제공하는 Endpoint 가 아닌 함수들의 경우 skip
  - ex) get_queryset, filter_queryset, get_serializer_context
- model 의 경우
  - 각 필드의 사용처를 조사
  - 필드명을 명시하고 100자 이내로 help_text 를 채워줘.
  - 이미 너무 명시적이면 적지 않아도 됨.

### Python Example

```py
# API View
class CMSOrderBulkUpdateAPIView(APIView):
    """[CMS] 주문 상태 일괄 변경.

    - [주문상태=배송준비중] 으로 일괄 변경.
    - [주문상태=확인/결제완료] 상태만 처리 가능.
    """
    pass # 생략

# Service
class CartService:
    def list_cart_discounts(
        self, cart_items: List[CartItem]
    ) -> Optional[Dict[str, str]]:
        """
        장바구니에서 쿠폰 적용 가능 항목과 예상 할인 금액 반환.

        기능:
        - 쿠폰 타입(도매/상품)에 따라 할인 금액 계산.
        - 쿠폰 사용 조건(최소 주문 금액 등)을 검증하여 적용 가능 항목 반환.
            - 정렬을 하기 위해 [할인 금액, 남은 기간, 쿠폰 번호] 정보를 함께 리턴

        :param cart_items: 장바구니 품목들
        :returns: {
            "coupon_item": CouponItem,
            "max_discount_amount": int,
            "date_left": int,
            "coupon_id": int,
            "targets": [
                {
                    "whole_saler_id": Optional[int],
                    "inventory_id": Optional[int],
                    "amount": int, (=discount_amount, will be deprecated)
                    "discount_amount": int,
                    "insufficient_amount": int,
                },
                ...
            ]
        }
        """
        pass # 생략

# Model
class MissionReward(models.Model):
    """미션 보상 정보"""

    mission = models.ForeignKey(
        Mission, on_delete=models.DO_NOTHING, related_name="rewards", verbose_name="미션"
    )
    title = models.CharField(
        "리워드 제목",
        max_length=50,
        null=True,
        help_text="서비스에 표시할 리워드 대표 문구",
    )

```
