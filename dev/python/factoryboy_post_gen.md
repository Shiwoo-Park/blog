# factory_boy - @post_generation 사용법

> 날짜: 2024-04-30

[목록으로](https://shiwoo-park.github.io/blog)

---

`@post_generation` 데코레이터는 `factory_boy` 라이브러리에서 제공하는 기능으로, 팩토리를 통해 객체가 생성된 후에 추가적인 처리를 실행할 수 있도록 해줍니다. 이를 사용하면 객체의 초기 생성 로직이 완료된 직후에 특정 작업을 자동으로 수행할 수 있습니다. 이는 객체의 복잡한 상호 관계를 설정하거나, 객체 생성 후 초기화 로직을 실행하는 데 유용합니다.

## 기본 구조

`@post_generation` 데코레이터는 메소드를 정의할 때 사용되며, 이 메소드는 객체 생성 후에 호출됩니다. 기본적으로 이 메소드는 다음과 같은 매개변수를 받습니다:

- `self`: 팩토리 클래스의 인스턴스입니다.
- `create`: 객체가 실제로 생성되었는지 (`create()`) 또는 빌드만 되었는지 (`build()`) 여부를 나타내는 불리언 값입니다.
- `extracted`: 팩토리 호출 시 제공된 추가적인 값들을 포함하고 있습니다. 만약 특정 필드에 대해 팩토리 호출 시 값을 전달했다면, 이 값이 `extracted`로 전달됩니다.
- `**kwargs`: 팩토리 생성자에 전달된 추가적인 키워드 인수들입니다.

## 사용 예시

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
        if not create:  # build() 호출 시
            return

        if extracted:  # create() 호출 시
            for user in extracted:
                self.members.add(user)
        else:
            num_users = kwargs.get('num_users', 3)  # 기본적으로 3명의 사용자를 추가
            for _ in range(num_users):
                user = UserFactory.create()
                self.members.add(user)
```

## 적용 사례

`@post_generation`을 사용하는 주요 적용 사례는 다음과 같습니다:

- **복잡한 관계 설정**: 객체가 다른 여러 객체와 복잡한 관계를 가질 때 이를 자동으로 설정합니다.
- **조건부 로직 실행**: 객체 생성 시 특정 조건에 따라 추가적인 설정이 필요할 때 사용됩니다.
- **테스트 데이터 준비**: 테스트 시 특정 상태의 데이터를 미리 준비하고 싶을 때 유용합니다.

`@post_generation`은 팩토리를 통한 데이터 생성의 유연성을 크게 향상시키며, 복잡한 객체의 생성 과정을 간소화하는 데 큰 도움을 줍니다.

## build() 와 create() 의 차이

```shell
# 메모리 상에서만 UserGroup 객체를 생성 (데이터베이스에 저장 X)
coupon_group = UserGroupFactory.build()

# 데이터베이스에 UserGroup 객체를 저장
coupon_group = UserGroupFactory.create()
```

`factory_boy` 라이브러리에서 `build()`와 `create()`는 객체를 생성하는 두 가지 기본적인 메소드입니다. 이 두 메소드의 주요 차이는 객체가 데이터베이스에 실제로 저장되는지 여부에 있습니다.

### `build()`

- **데이터베이스에 저장되지 않음**: `build()` 메소드는 객체를 메모리 상에서만 생성합니다. 이는 데이터베이스를 거치지 않기 때문에 빠르고, 데이터베이스의 상태를 변경하지 않습니다. 테스트를 실행할 때 외부 의존성을 최소화하고자 할 때 유용하게 사용됩니다.
- **테스트 용도**: 특히 모델의 유효성 검사나 함수의 동작을 검사하는 데 필요한 객체를 빠르게 생성하고 싶을 때 `build()`를 사용합니다. 데이터베이스의 트랜잭션 비용을 줄일 수 있습니다.

### `create()`

- **데이터베이스에 저장됨**: `create()` 메소드는 객체를 생성하고 데이터베이스에 저장합니다. 이는 실제 데이터베이스에 저장되는 객체가 필요할 때 사용되며, 외래 키나 데이터베이스 트리거, 데이터 유효성 검사 등 실제 데이터베이스 환경에서 필요한 조건을 테스트할 수 있습니다.
- **실제 환경 테스트 용도**: 데이터베이스와의 상호 작용을 포함하는 프로세스를 테스트하거나, 실제 데이터베이스 환경에서의 객체 생성을 시뮬레이션할 필요가 있을 때 사용합니다.

### 선택 기준

- **속도가 중요하거나 데이터베이스의 영향을 받지 않아야 하는 경우**: `build()`
- **외래 키 연결이 중요하거나 데이터베이스 트랜잭션이 필요한 경우**: `create()`

---

[목록으로](https://shiwoo-park.github.io/blog)
