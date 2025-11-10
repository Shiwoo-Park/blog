# 개발자에게 유용한 AI 프롬프트

> 날짜: 2025-11-10

[목록으로](https://shiwoo-park.github.io/blog)

---

## 온보딩 문서 생성 요청

### 문서 초안

```sql
# 내서비스 - 슈퍼오더

## 관련 endpoints

- GET /me/super-order
- POST /me/super-order
- GET /me/super-order/recent
- GET /me/super-order/cancellation
- GET /v1/me/super-order-cart
- GET /me/order-items/returnable

```

### 요청 프롬프트

@super_order.md 파일의 주어진 endpoint 코드들을 참고하여

슈퍼오더 라는 서비스를 전혀 모르는 사람도 전반적인 서비스 내용과 스펙을 이해할 수 있도록 온보딩 문서를 완성시켜줘

문서 작성 시, 아래 사항들을 참고해줘

1. 문서 내용을 비개발자도 이해할 수 있도록 코드레벨에서 설명하기보다 각 코드가 어떤 목적을 가지고 있는지 어떤 스펙을 가지고 있는지 서술할것.
2. “관련 모델” 섹션을 따로 두어서 어떤 모델을 어떤 용도로 사용하고 있는지 설명할 것
3. 제일 하이레벨(개발자가 아닌 회사 대표 입장) 에서의 서비스 자체에 대한 파악부터 시작하여 차츰 세부적인 항목별 설명 형태로 문서를 작성해줘
4. endpoint 별 설명도 간단하게 별도 섹션으로 정리해줘

---

## 샘플 데이터 생성 요청

```
tmp/sql/sample_order.sql 파일에

Order
OrderItem
OrderItemDetail

이 3개 모델에 해당하는 테이블에 관계성까지 따져서 골고루 데이터가 삽입될 수 있도록

Order 기준으로 100개 그리고 OrderItem 200개 이상 OrderItemDetail 는 300개 이상 레코드를 삽입하는 쿼리를 생성해줄 수 있어?
테스트 코드로 활용하려고 해

추가적으로 아래 사항 참고해줘

- 작업을 위해 더 필요한 정보가 있다면 나에게 질문할 것 (구체적 필드별 스펙 등)
- 최대한 케이스별로 다양한 데이터가 들어갈 수 있도록 필드별 데이터를 골고루 생성할 것 (길이)
- user_id 는 112233 을 사용할 것.
```

---

[목록으로](https://shiwoo-park.github.io/blog)
