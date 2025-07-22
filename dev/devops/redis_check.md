# 🔍 **Redis 연결 상태 통계 분석 명령어**

> 날짜: 2025-07-22

[목록으로](https://shiwoo-park.github.io/blog)

---

### **1. 기본 통계 정보**

```bash
# 전체 연결 수 확인
redis-cli -h MY_REDIS_HOST -p 6379 CLIENT LIST | wc -l

# 연결된 클라이언트 수
redis-cli -h MY_REDIS_HOST -p 6379 info | grep connected_clients
```

### **2. 클라이언트별 상세 분석**

```bash
# 클라이언트 IP별 연결 수 통계
redis-cli -h MY_REDIS_HOST -p 6379 CLIENT LIST | grep -o "addr=[^ ]*" | cut -d= -f2 | cut -d: -f1 | sort | uniq -c | sort -nr

# 클라이언트별 명령어 통계
redis-cli -h MY_REDIS_HOST -p 6379 CLIENT LIST | grep -o "cmd=[^ ]*" | cut -d= -f2 | sort | uniq -c | sort -nr

# 클라이언트별 DB 사용 통계
redis-cli -h MY_REDIS_HOST -p 6379 CLIENT LIST | grep -o "db=[^ ]*" | cut -d= -f2 | sort | uniq -c | sort -nr
```

### **3. 연결 상태별 분석**

```bash
# idle 시간별 클라이언트 수 (오래 쉬고 있는 연결 확인)
redis-cli -h MY_REDIS_HOST -p 6379 CLIENT LIST | grep -o "idle=[^ ]*" | cut -d= -f2 | sort -n | uniq -c

# age 시간별 클라이언트 수 (연결 지속 시간)
redis-cli -h MY_REDIS_HOST -p 6379 CLIENT LIST | grep -o "age=[^ ]*" | cut -d= -f2 | sort -n | uniq -c
```

### **4. 문제 연결 식별**

```bash
# 60초 이상 idle인 연결들 (잠재적 문제 연결)
redis-cli -h MY_REDIS_HOST -p 6379 CLIENT LIST | awk -F' ' '{for(i=1;i<=NF;i++) if($i~/^idle=/) {split($i,a,"="); if(a[2]>60) print $0}}'

# 1시간 이상 연결된 클라이언트들
redis-cli -h MY_REDIS_HOST -p 6379 CLIENT LIST | awk -F' ' '{for(i=1;i<=NF;i++) if($i~/^age=/) {split($i,a,"="); if(a[2]>3600) print $0}}'
```

### **5. Celery 관련 연결 분석**

```bash
# BRPOP 관련 연결 확인 (Celery 워커)
redis-cli -h MY_REDIS_HOST -p 6379 CLIENT LIST | grep -i "brpop\|block"

# 특정 IP 대역의 연결 수 (Celery 서버 IP 확인)
redis-cli -h MY_REDIS_HOST -p 6379 CLIENT LIST | grep "10.50." | wc -l
```

### **6. 실시간 모니터링**

```bash
# 실시간 연결 수 모니터링
watch -n 5 'redis-cli -h MY_REDIS_HOST -p 6379 info | grep connected_clients'

# 실시간 클라이언트 목록 모니터링 (상위 10개)
watch -n 10 'redis-cli -h MY_REDIS_HOST -p 6379 CLIENT LIST | head -10'
```

### **7. 연결 정리 (주의: 서비스 중단 가능)**

```bash
# 특정 클라이언트 연결 종료 (client-id 필요)
redis-cli -h MY_REDIS_HOST -p 6379 CLIENT KILL ID <client-id>

# 60초 이상 idle인 모든 연결 종료 (위험!)
redis-cli -h MY_REDIS_HOST -p 6379 CLIENT KILL TYPE normal
```

### **8. 종합 분석 스크립트**

```bash
# 한 번에 모든 통계 보기
echo "=== Redis 연결 상태 분석 ==="
echo "총 연결 수: $(redis-cli -h MY_REDIS_HOST -p 6379 CLIENT LIST | wc -l)"
echo ""
echo "IP별 연결 수:"
redis-cli -h MY_REDIS_HOST -p 6379 CLIENT LIST | grep -o "addr=[^ ]*" | cut -d= -f2 | cut -d: -f1 | sort | uniq -c | sort -nr | head -10
echo ""
echo "명령어별 통계:"
redis-cli -h MY_REDIS_HOST -p 6379 CLIENT LIST | grep -o "cmd=[^ ]*" | cut -d= -f2 | sort | uniq -c | sort -nr
echo ""
echo "60초 이상 idle인 연결 수:"
redis-cli -h MY_REDIS_HOST -p 6379 CLIENT LIST | grep -o "idle=[^ ]*" | cut -d= -f2 | awk '$1 > 60' | wc -l
```

### 기타

```bash
# Redis 타임아웃 설정 확인
redis-cli -h MY_REDIS_HOST -p 6379 CONFIG GET timeout
redis-cli -h MY_REDIS_HOST -p 6379 CONFIG GET tcp-keepalive

# 연결 수 모니터링
watch -n 5 'redis-cli -h MY_REDIS_HOST -p 6379 info | grep connected_clients'

```

이 명령어들을 사용해서 어떤 클라이언트들이 연결을 많이 점유하고 있는지, 어떤 명령어를 자주 사용하는지, 오래 쉬고 있는 연결이 있는지 등을 분석할 수 있습니다.

---

[목록으로](https://shiwoo-park.github.io/blog)
