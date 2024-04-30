# factory_boy - @post_generation 사용법

> 날짜: 2024-04-30

[목록으로](https://shiwoo-park.github.io/blog/kor)

---

`@post_generation` 데코레이터는 `factory_boy` 라이브러리에서 제공하는 기능으로, 팩토리를 통해 객체가 생성된 후에 추가적인 처리를 실행할 수 있도록 해줍니다. 이를 사용하면 객체의 초기 생성 로직이 완료된 직후에 특정 작업을 자동으로 수행할 수 있습니다. 이는 객체의 복잡한 상호 관계를 설정하거나, 객체 생성 후 초기화 로직을 실행하는 데 유용합니다.

### 기본 구조

`@post_generation` 데코레이터는 메소드를 정의할 때 사용되며, 이 메소드는 객체 생성 후에 호출됩니다. 기본적으로 이 메소드는 다음과 같은 매개변수를 받습니다:

- `self`: 팩토리 클래스의 인스턴스입니다.
- `create`: 객체가 실제로 생성되었는지 (`create()`) 또는 빌드만 되었는지 (`build()`) 여부를 나타내는 불리언 값입니다.
- `extracted`: 팩토리 호출 시 제공된 추가적인 값들을 포함하고 있습니다. 만약 특정 필드에 대해 팩토리 호출 시 값을 전달했다면, 이 값이 `extracted`로 전달됩니다.
- `**kwargs`: 팩토리 생성자에 전달된 추가적인 키워드 인수들입니다.

### 사용 예시

예를 들어, 사용자가 특정 그룹에 자동으로 여러 명의 사용자를 할당하고자 할 때 `@post_generation`을 사용할 수 있습니다. 다음은 `UserGroup` 팩토리에 대한 간단한 예제입니다.

```python
class UserFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = User

    username = factory.Faker('user_name')

class UserGroupFactory(factory.django.DjangoModelFactory):
    class Meta:
        model = UserGroup

    name = factory.Faker('word')

    @post_generation
    def users(self, create, extracted, **kwargs):
        if not create:
            return
        
        if extracted:
            for user in extracted:
                self.members.add(user)
        else:
            num_users = kwargs.get('num_users', 3)  # 기본적으로 3명의 사용자를 추가
            for _ in range(num_users):
                user = UserFactory.create()
                self.members.add(user)
```

### 적용 사례

`@post_generation`을 사용하는 주요 적용 사례는 다음과 같습니다:

- **복잡한 관계 설정**: 객체가 다른 여러 객체와 복잡한 관계를 가질 때 이를 자동으로 설정합니다.
- **조건부 로직 실행**: 객체 생성 시 특정 조건에 따라 추가적인 설정이 필요할 때 사용됩니다.
- **테스트 데이터 준비**: 테스트 시 특정 상태의 데이터를 미리 준비하고 싶을 때 유용합니다.

`@post_generation`은 팩토리를 통한 데이터 생성의 유연성을 크게 향상시키며, 복잡한 객체의 생성 과정을 간소화하는 데 큰 도움을 줍니다.

---

[목록으로](https://shiwoo-park.github.io/blog/kor)
