# Redis tip 모음

> 날짜: 2024-05-14

[목록으로](https://shiwoo-park.github.io/blog)

---

## URI 지정

- 기본 URI 포맷: `redis://[:password]@hostname:port/db_number`
- db_number 를 지정하지 않을경우, 0번이 자동으로 선택됨
- URI example (Django Cache)
  - `CACHE_LOCATION=redis://my-server.com:6379/2,redis://my-server-ro.com:6379/2`

## Redis 쿼리

Redis는 다양한 데이터 유형과 다양한 작업을 지원하는 인-메모리 데이터 구조 저장소입니다. Redis를 사용할 때 유용하게 쓰이는 몇 가지 주요 명령어와 패턴을 소개하겠습니다. 이 명령들은 기본적인 데이터 조작부터 복잡한 데이터 처리까지 다양한 상황에서 사용됩니다.

### 기본 데이터 조작

1. **SET** - 키에 값을 할당합니다.
   ```bash
   SET key value
   ```

2. **GET** - 키의 값을 검색합니다.
   ```bash
   GET key
   ```

3. **DEL** - 하나 이상의 키를 삭제합니다.
   ```bash
   DEL key1 key2
   ```

4. **EXISTS** - 키가 존재하는지 확인합니다.
   ```bash
   EXISTS key
   ```

5. **EXPIRE** - 키의 만료 시간을 설정합니다 (초 단위).
   ```bash
   EXPIRE key seconds
   ```

6. **TTL** - 키의 남은 만료 시간을 확인합니다.
   ```bash
   TTL key
   ```

### 리스트와 세트 조작

1. **LPUSH/RPUSH** - 리스트의 왼쪽/오른쪽에 요소를 추가합니다.
   ```bash
   LPUSH mylist value
   RPUSH mylist value
   ```

2. **LPOP/RPOP** - 리스트의 왼쪽/오른쪽에서 요소를 제거하고 반환합니다.
   ```bash
   LPOP mylist
   RPOP mylist
   ```

3. **SADD** - 세트에 요소를 추가합니다.
   ```bash
   SADD myset value1 value2
   ```

4. **SMEMBERS** - 세트의 모든 요소를 반환합니다.
   ```bash
   SMEMBERS myset
   ```

5. **SREM** - 세트에서 하나 이상의 요소를 제거합니다.
   ```bash
   SREM myset value1 value2
   ```

### 해시 조작

1. **HSET** - 해시에 키-값 쌍을 설정합니다.
   ```bash
   HSET myhash field1 value1 field2 value2
   ```

2. **HGET** - 해시에서 지정한 필드의 값을 반환합니다.
   ```bash
   HGET myhash field
   ```

3. **HGETALL** - 해시의 모든 필드와 값을 반환합니다.
   ```bash
   HGETALL myhash
   ```

4. **HDEL** - 해시에서 하나 이상의 필드를 삭제합니다.
   ```bash
   HDEL myhash field1 field2
   ```

### 발행/구독

1. **SUBSCRIBE** - 하나 이상의 채널을 구독합니다.
   ```bash
   SUBSCRIBE channel1 channel2
   ```

2. **PUBLISH** - 채널에 메시지를 발행합니다.
   ```bash
   PUBLISH channel message
   ```

### 고급 기능

1. **SORT** - 리스트, 세트 또는 정렬된 세트의 요소를 정렬합니다.
   ```bash
   SORT mylist
   ```

2. **ZADD** - 정렬된 세트에 요소를 추가합니다.
   ```bash
   ZADD myzset score1 value1
   ```

3. **ZSCORE** - 정렬된 세트에서 요소의 점수를 검색합니다.
   ```bash
   ZSCORE myzset value
   ```

### 기타

```sql
-- db_number=1 선택
SELECT 1

-- DB 데이터 전체 삭제
FLUSHDB
```

---

[목록으로](https://shiwoo-park.github.io/blog)
