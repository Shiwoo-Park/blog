# Django 에서 Group By Query 만드는 법

> 날짜: 2020-08-04

장고에서 아래의 쿼리를 group by 로 만들고 싶다고 가정하자

```sql
SELECT name AS changed_name, count(count)
FROM test
GROUP BY name;
```

이렇게 QuerySet 을 작성할 수 있다

```python
queryset = Test.objects.values('name').annotate(
    max_count=Count('count'),
    changed_name=F('name')
).values('max_count', 'changed_name')
```

위 코드에 대한 설명 및 주의사항
1. 반드시 group by 하고자 하는 필드에 대해 values('GROUPBY_FIELD') 를 해준다.
2. 1번 함수 call 이후 annotate() 로 Count, Max 등의 aggregate 함수를 아무거나 call 한것과, group by 필드의 `변경된 이름` 필드를 지정해준다.
3. 2번의 aggregate 한 필드명과 변경된 이름의 group by 필드명을 values 로 얻어준다.

---

[목록으로](https://shiwoo-park.github.io/blog/kor)

