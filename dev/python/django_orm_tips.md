# Django ORM Tips

> 날짜: 2023-04-09

## ORM 성능 최적화 하기

예제코드용 모델

```python
from django.db import models

class Author(models.Model):
    name = models.CharField(max_length=100)

class Book(models.Model):
    title = models.CharField(max_length=100)
    author = models.ForeignKey(Author, on_delete=models.CASCADE)
```


### Read / Write DB 가 다를경우 복제지연에 대처하는 우리의 자세

- write + read 가 공존하는 로직에서는 반드시 복제지연이 발생할것을 대비하자
- write 가 수행된 데이터를 다시 select 하지말고 생성, 수정 후 리턴된 객체를 그냥 쓰자! (메모리에 있으니)
- `transaction.atomic(using="write_db")` → 믿을게 못됨 (그 안에서도 read DB 참조)
- `MyModel.objects.using("write_db")` 사용하기 (직접 참조하므로 DB router를 아예 참조하지 않음)


### select_related()와 prefetch_related() 메서드를 사용하여 join 을 통해 쿼리 성능 최적화하기

```python
# Author와 관련된 Book을 가져올 때 select_related() 사용 예시
author = Author.objects.get(id=1)
books = Book.objects.filter(author=author).select_related('author')

# 여러 개의 쿼리를 사용하여 관련된 객체를 가져올 때 prefetch_related() 사용 예시
authors = Author.objects.all().prefetch_related('book_set')
```

### values()나 values_list() 메서드를 사용하여 필요한 정보만 조회하여 결과 최적화하기

```python
# 필요한 필드만 선택하여 가져오기 (values() 메서드 사용 예시)
books = Book.objects.filter(published=True).values('title', 'author__name')

# 필요한 필드만 선택하여 가져오기 (values_list() 메서드 사용 예시)
books = Book.objects.filter(published=True).values_list('title', 'author__name')
```

### only()나 defer() 메서드를 사용하여 필요한 필드만 가져오도록 하기

```python 
# 필요한 필드만 선택하여 가져오기 (only() 메서드 사용 예시)
books = Book.objects.filter(published=True).only('title', 'author')

# 특정 필드를 제외하고 가져오기 (defer() 메서드 사용 예시)
books = Book.objects.filter(published=True).defer('description')
```

### bulk_create() 메서드를 사용하여 여러 개의 객체를 한 번에 생성하기

```python
# 여러 개의 객체를 한 번에 생성하는 예시
books = [Book(title="book1"), Book(title="book2"), Book(title="book3")]
Book.objects.bulk_create(books)
```

### bulk_update() 메서드를 사용하여 여러 개의 객체를 한 번에 업데이트하기

```python
# 여러 개의 객체를 한 번에 업데이트하는 예시
books = Book.objects.filter(published=True)
books.update(published=False)
```

### iterator() 메서드를 사용하여 쿼리셋의 결과를 메모리에 로드하지 않고 하나씩 처리하기

```python
# iterator() 메서드 사용 예시
books = Book.objects.all().iterator()
for book in books:
    print(book.title)
```

### 쿼리 결과 캐싱

```python
from django.core.cache import cache
from myapp.models import Product

def get_products():
    # 쿼리 결과를 캐시에서 가져오기
    cached_products = cache.get('products')
    if cached_products is not None:
        return cached_products

    # 쿼리 실행 및 캐시 저장
    products = Product.objects.all()
    cache.set('products', products, timeout=3600)

    return products
```

## 간단 Tip

- Queryset 의 Raw Query 확인하기: `print(queryset.query)`
- queryset 사용할때 모델의 related model object를 참조하는 코드가 암묵적으로 존재하면 `N+1 query problem` 이 발생한다는 점을 늘 인지할 것.
- 생성날짜 필드에 `auto_now_add=True` 대신 `default=timezone.now` 사용하기.
  - 이유: 가끔 임의로 created_at 을 직접 지정하고 싶어도 ORM 의 auto_now_add 옵션이 그 값을 무시해버림
- 쿼리셋 related field 에 임의로 queryset 을 연결시키기: related_field 에서 `set()` 을 활용
  - 잘못된 예시: `setattr(self.instance, "rewards", self.get_reward_qs(mission))`
  - 올바른 예시: `self.instance.rewards.set(self.get_reward_qs(mission))`

---

[목록으로](https://shiwoo-park.github.io/blog)
