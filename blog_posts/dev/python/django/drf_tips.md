---
layout: post
title: "DRF(Django REST Framework) Tip 모음"
date: 2022-03-19
categories: [python, django, drf]
---

# DRF(Django REST Framewoark) Tip 모음

> 날짜: 2022-03-19

Django 로 API 개발 시, DRF 를 사용할때 알아두면 좋은 갖가지 팁을 모아보았습니다.
거의 결론만 적었기때문에 상세한 이유가 궁금하신분은 관련내용을 구글링하여 직접 찾아보시기 바랍니다.


### [Serializer](https://www.django-rest-framework.org/api-guide/serializers/)

- 성능 최적화
  - Serializer 클래스별 성능(처리속도) 비교: `ModelSerializer < ModelSerializer + ReadOnly < Serializer = Serializer + ReadOnly < 직접만든 custom serializer`
  - Serializer 사용 시, `read_only_fields` 로 최대한 writable field 수를 줄여라
  - 성능이 문제되는 경우라면, ModelSerializer 보다 일반 Serializer 를 사용하라
  - DRF 의 ModelSerializer - field validation 에서 lazy 함수를 사용하는것에 대한 패치가 완료된 Django, DRF 최신버전을 사용하라
- 용도 단순화
  - 기본적으로 데이터 검증, 가공, 입력->DB->응답 과정의 serialization 이라는 너무 많은 역할을 가지고 있다.
  - 역할을 줄여서 명확한 목적 하나만을 위해 사용가능
  - ex. 단순 입력값 검증용 request serializer
- `Nested Serializer`
  - 2개 이상의 Model 데이터가 섞인(=JOIN operation 이 필요한) 경우를 뜻함
  - Serializer object 생성 시, seed data 로 넘기게 되는 queryset 을 `prefetch_related` 또는 `selected_related` 함수를 사용하여 미리 join 된 데이터를 얻도록 처리한다 (안할경우 N+1 query problem 발생)
  - `setup_eager_loading` 에 대해 찾아보자.
- 기타 Tip
  - 커스텀 데이터를 read only 로 추가해야하는경우 `SerializerMethodField` 를 활용
  - Model property 도 `source` 속성으로 지정할 수 있음


### [ViewSet](https://www.django-rest-framework.org/api-guide/viewsets/)

- Router 와 함께 활용하기에 URL 디자인을 RESTful 하게 가져갈 수 있는 이점이 있다.
- 하지만 여러 endpoint 를 하나의 클래스에 담는 구조기때문에 코드 덩어리가 너무 커질 수 있다.
- 기본적으로 라우터에 register 즉시 6개 endpoint 가 생겨버리기때문에 본인이 의도하지 않게 endpoint가 양산될 수 있다.
- `@action` 이라는 데커레이터로 추가적인 커스텀 endpoint 를 생성 및 설정 할 수 있음
  - permission_classes, renderer_classes 등의 별도 지정 가능


### [Generic Views](https://www.django-rest-framework.org/api-guide/generic-views/)

- 개인적으로 가장 선호하는 APIView class 로써, ViewSet 과는 달리 필요한 기능만을 모아 컴팩트 하게 기능을 제공할 수 있다
- ListCreateAPIView, RetrieveUpdateDestroyAPIView 조합을 가장 선호함
- URL 디자인을 직접해줘야 한다. (오히려 좋음)

### [Exceptions](https://www.django-rest-framework.org/api-guide/exceptions/)

- `APIException` 클래스를 상속받은 exception 클래스를 만들면 APIView 하위클래스 비즈니스로직 그 어느곳에서라도 raise 했을때 지정한 status_code 의 HTTP response 를 리턴할 수 있다.
- custom_exception_handler 를 만들어서 django settings 에 붙여놓으면 커스터마이징 된 에러코드나 응답 포맷등을 만들어서 예쁘게 에러응답 관리가 

### ETC

- JSON 응답 포맷을 커스터마이징 하고 싶다면 커스텀 `Renderer` 를 만들어서 전체 또는 부분적인 endpoint 에 적용할 수 있다. 
- 라우터에서 URL 디자인 시, 맨 끝에 슬래시를 제거하고 싶으면 `router = DefaultRouter(trailing_slash=False)` 와 같이 라우터를 만들어 쓸 수 있다.

---

[목록으로](https://shiwoo-park.github.io/blog)
