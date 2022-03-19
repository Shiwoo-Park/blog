# DRF(Django REST Framewoark) 활용, 최적화 등의 Tip 모음

> 날짜: 2022-03-19

DRF 를 활용할때 알아두면 좋은 갖가지 팁을 모아보았습니다.
거의 결론만 적었기때문에 상세한 원인이 궁금하신분은 관련내용을 구글링하여 직접 찾아보시기 바랍니다.


### Serializer

- Serializer 클래스별 성능(처리속도) 비교: `ModelSerializer < ModelSerializer + ReadOnly < Serializer = Serializer + ReadOnly < 직접만든 custom serializer`
- Serializer 사용 시, read_only_fields 로 최대한 writable field 수를 줄여라
- 성능이 문제되는 경우라면, ModelSerializer 보다 일반 Serializer 를 사용하라
- 반드시 써야하는게 아니면 굳이 Serializer 를 사용할 필요는 없다 (By. DRF 제작자)
- DRF 의 ModelSerializer - field validation 에서 lazy 함수를 사용하는것에 대한 패치가 완료된 Django, DRF 최신버전을 사용하라
- 2개 이상의 Model 이 섞인(=JOIN operation 이 필요한) Nested Serializer 일경우, Serializer 의 seed data 로 넘기게 되는 queryset 에서 prefetch_related 또는 selected_related 함수를 사용하여 미리 join 된 데이터를 얻도록 처리한다 (안할경우 N+1 query problem 발생)
- 커스텀 데이터를 read only 로 추가해야하는경우 `SerializerMethodField` 를 활용

### ViewSet

- Router 와 함께 활용하기에 URL 디자인을 RESTful 하게 가져갈 수 있는 이점이 있다.
- 하지만 여러 endpoint 를 하나의 클래스에 담는 구조기때문에 코드 덩어리가 너무 커질 수 있다.
- 기본적으로 라우터에 register 즉시 6개 endpoint 가 생겨버리기때문에 본인이 의도하지 않게 endpoint가 양산될 수 있다.
- `@action` 이라는 데커레이터로 추가적인 커스텀 endpoint 를 생성 및 설정 할 수 있음
  - permission_classes, renderer_classes 등의 별도 지정 가능


### GenericAPIView 하위클래스들

- 개인적으로 가장 선호하는 APIView class 로써, ViewSet 과는 달리 필요한 기능만을 모아 컴팩트 하게 기능을 제공할 수 있다
- URL 디자인을 직접해줘야 한다. (오히려 좋음)

### ETC

- JSON 응답 포맷을 커스터마이징 하고 싶다면 커스텀 `Renderer` 를 만들어서 전체 또는 부분적인 endpoint 에 적용할 수 있다. 

---

[목록으로](https://shiwoo-park.github.io/blog/kor)
