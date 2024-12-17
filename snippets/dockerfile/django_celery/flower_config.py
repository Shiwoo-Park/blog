# flowerconfig.py - flower 환경설정 파일

# 환경별로 달라지는 값
broker = "redis://my_redis_uri:6379/2"  # Redis 브로커 URL
purge_offline_workers = True  # 오프라인 워커 데이터 삭제
loglevel = "WARNING"  # 로그 레벨
port = 5555  # Flower가 사용할 포트

# 데이터베이스 파일 (sqlite3)
persistent = True  # 작업 데이터 유지 여부
db = "/data/flower_db/prod.db"  # EC2용
# db = "/app/flower.db"  # 도커용
# 도커용 - 컨테이너 내부에서 돌기때문에 배포 하더라도 데이터 유지를 위해 방법을 찾아야 함.
# (HOST Disk, EFS, S3 중 택1)

address = "0.0.0.0"  # Flower가 바인딩할 IP 주소
# basic_auth = ["hello:Hello123!"]  # 기본 인증 (여러 사용자 가능)
inspect_timeout = 5000.0  # 워커 검사 타임아웃 (밀리초)
max_tasks = 10000  # Flower 대시보드에 표시할 최대 작업 수
auto_refresh = True  # 대시보드 자동 새로고침 여부
timeout = 5  # 브로커 연결 타임아웃 (초)
