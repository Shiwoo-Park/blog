# 당신이 몰랐던 파이썬 이야기들

> 날짜: 2024-10-30

[목록으로](https://shiwoo-park.github.io/blog)

---

## 파이썬 동작방식 관련

- 메모리 공간 자동 관리 체계 (Garbage Collection)
  - 참조 횟수(reference counter) 기반 가비지 컬렉션
  - 주기적인 Generational Garbage Collector 에 의한 순환참조(circular reference) 감지 및 삭제
    - 신규 객체는 generation 0 이며 생존기간에 따라 `0 -> 1 -> 2` 순으로 상승
    - 높은 generation 일수록 순환참조 검사 및 가비지 컬렉션이 드물게 수행됨

## 파이썬 성능 관련

- list 객체의 append() 함수는 평균적으로 `O(1)`, 최악의 경우 `O(N)` 의 시간복잡도를 가진다.
  - 언제 최악의 경우가 발생하나? 메모리상에서 리스트에 할당된 용량이 꽉 찬 경우, 아예 공간을 재할당받아 전체 요소를 복사

## 파이썬 역사 관련


... continue

---

[목록으로](https://shiwoo-park.github.io/blog)
