# 📘 Django ORM VS SQLAlchemy 극명한 쿼리 작성 체계의 차이점 분석

> 날짜: 2025-06-08

[목록으로](https://shiwoo-park.github.io/blog)

---

## 들어가며

Python 생태계에서 ORM(Object-Relational Mapping) 라이브러리로 대표되는 두 가지는 바로 **Django ORM**과 **SQLAlchemy**입니다.

두 라이브러리는 모두 RDB와 객체지향 모델 간의 매핑을 제공하지만, **쿼리 작성 방식과 추상화 수준**에 있어 극명한 차이를 보입니다.

이 글에서는 **복잡한 조건 필터 + 관계 로딩 + 정렬**이 섞인 실전 예제를 기준으로,
**Django ORM**과 **SQLAlchemy**가 어떻게 접근 방식이 다른지 살펴보겠습니다.

---

## 예제 시나리오

다음과 같은 모델 구조를 가정합니다.

* `User(1) → Post(N)`
* `Post(N) → Tag(M)` (ManyToMany)

> 조건:
>
> * `Post.title`에 "FastAPI" 포함
> * `Post.published_at IS NOT NULL`
> * `Tag.name == "파이썬"`
> * `User.name` 기준 정렬
> * `Post.user`, `Post.tags`는 미리 로딩 (Eager Load)

---

## 1. Django ORM 방식

```python
Post.objects.select_related("user") \
    .prefetch_related("tags") \
    .filter(
        title__icontains="FastAPI",
        published_at__isnull=False,
        tags__name="파이썬"
    ) \
    .order_by("user__name")
```

### ✅ 특징

* 관계 필드는 `__` 로 접근
* 조인, eager load, 조건 필터링 모두 **모델 기반 DSL로 추상화**
* 중간 테이블 명시 X → ORM이 자동 처리
* **짧고, 의도를 파악하기 쉬움**

---

## 2. SQLAlchemy 방식

```python
stmt = (
    select(Post)
    .join(Post.user)
    .join(post_tag_table, post_tag_table.c.post_id == Post.id)
    .join(Tag, Tag.id == post_tag_table.c.tag_id)
    .where(
        and_(
            Post.title.ilike("%FastAPI%"),
            Post.published_at.is_not(None),
            Tag.name == "파이썬"
        )
    )
    .order_by(User.name.asc())
    .options(
        selectinload(Post.user),
        selectinload(Post.tags)
    )
)
results = session.exec(stmt).all()
```

### ✅ 특징

* join은 명시적, 관계 경로가 아닌 테이블 기준
* 다대다(N\:N) 관계는 중간 테이블을 **반드시 직접 지정**
* 관계 로딩은 `.options(selectinload(...))` 별도 설정
* **SQL 제어는 완벽**, 대신 코드량이 많고 구조가 복잡함

---

## 비교 요약

| 항목         | Django ORM                          | SQLAlchemy                          |
| ---------- | ----------------------------------- | ----------------------------------- |
| 추상화 수준     | 매우 높음 (모델 기반 DSL)                   | 낮음 (SQL 기반 조합)                      |
| 관계 로딩      | select\_related / prefetch\_related | selectinload / joinedload (options) |
| N\:N 관계 처리 | ORM이 자동 조인                          | 중간 테이블 직접 명시 필요                     |
| 쿼리 가독성     | 간결, 의도 중심                           | 명시적, 구조 중심                          |
| 쿼리 유연성     | 제한적                                 | 매우 높음                               |
| 학습 난이도     | 진입 장벽 낮음                            | 진입 장벽 높음, 정밀 제어 가능                  |

---

## 왜 이런 차이가 생겼을까?

* **Django ORM**은 **웹 개발 생산성 극대화**를 목표로, 쿼리 작성도 모델 중심 추상화에 집중
  → 선언적이고 직관적인 API 제공

* **SQLAlchemy**는 **SQL 자체를 최대한 자유롭게 표현**하려는 철학을 기반으로 설계
  → 쿼리 구조에 대한 **완전한 제어권**을 개발자에게 위임

---

## 어떤 상황에 어떤 ORM이 유리할까?

| 상황                              | 추천 ORM       |
| ------------------------------- | ------------ |
| 빠른 CRUD 웹 서비스 구축                | ✅ Django ORM |
| 복잡한 조인, 성능 최적화, SQL 제어          | ✅ SQLAlchemy |
| 명확한 관계 정의 + 자동화된 로딩             | ✅ Django ORM |
| ORM을 넘나드는 SQL 조합, 서브쿼리, Union 등 | ✅ SQLAlchemy |

---

## 마무리

두 ORM은 서로 다른 철학을 갖고 있고, 사용하는 개발자에게도 **다른 기대와 책임**을 요구합니다.
단순히 "어떤 게 더 낫다"가 아니라, \*\*"어떤 상황에 어떤 도구가 적합한가"\*\*를 이해하고 선택하는 것이 중요합니다.

필자는 Django ORM의 간결함에 익숙해 있었지만, SQLAlchemy를 접하면서 데이터 흐름을 보다 명확하게 통제할 수 있는 매력을 느꼈습니다.

ORM을 넘어서 SQL까지 이해하고 싶은 개발자라면 SQLAlchemy도 한 번 도전해보시길 추천합니다.

---

[목록으로](https://shiwoo-park.github.io/blog)
