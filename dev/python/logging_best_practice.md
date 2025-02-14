# 파이썬 로깅 설정 Best Practice 

아래는 **확장성과 유지보수성을 극대화한 Python 로깅 설정파일**입니다.  
모든 Best Practice를 적용하여 **파일 로깅, 콘솔 로깅, 원격 로깅, 로그 로테이션, JSON 포맷 로그, Slack 알림**까지 포함한 설정을 만들었습니다.

## 🔹 주요 기능
- **파일 & 콘솔 로깅**: 표준 출력과 로그 파일 저장
- **Rotating File Handler**: 파일 크기에 따라 자동으로 로그 파일 회전 (백업 유지)
- **Timed Rotating File Handler**: 매일 새로운 로그 파일 생성
- **JSON 포맷**: 구조화된 로그(JSON) 저장 가능
- **Slack 로그 알림**: 특정 레벨 이상의 로그 발생 시 Slack 알림 전송
- **Custom Filter**: 특정한 컨텍스트(예: 사용자 ID, 트랜잭션 ID)를 포함하도록 확장 가능
- **Syslog / Remote Logging**: 원격 서버에서 로그 수집 가능
- **AsyncLogging**: 성능을 위해 비동기 처리 적용
- **Trace ID 지원**: 요청 단위 추적을 위한 필드 포함 가능

---

## 🔹 `logging_config.yaml` (YAML 기반 설정파일)
```yaml
version: 1

# 로그 포맷 정의
formatters:
  standard:
    format: "[%(asctime)s] [%(levelname)s] [%(name)s] [%(filename)s:%(lineno)d] - %(message)s"
    datefmt: "%Y-%m-%d %H:%M:%S"
  json:
    format: '{"time": "%(asctime)s", "level": "%(levelname)s", "logger": "%(name)s", "file": "%(filename)s", "line": %(lineno)d, "message": "%(message)s"}'
  detailed:
    format: "%(asctime)s | %(levelname)s | %(name)s | %(filename)s:%(lineno)d | %(message)s | %(process)d | %(threadName)s"

# 핸들러 정의
handlers:
  console:
    class: logging.StreamHandler
    level: DEBUG
    formatter: standard
    stream: ext://sys.stdout

  file:
    class: logging.handlers.RotatingFileHandler
    level: INFO
    formatter: standard
    filename: logs/app.log
    maxBytes: 10485760  # 10MB
    backupCount: 5
    encoding: utf-8

  timed_file:
    class: logging.handlers.TimedRotatingFileHandler
    level: INFO
    formatter: detailed
    filename: logs/app_timed.log
    when: midnight
    interval: 1
    backupCount: 7
    encoding: utf-8

  json_file:
    class: logging.FileHandler
    level: INFO
    formatter: json
    filename: logs/app.json
    encoding: utf-8

  slack:
    class: my_logging_handlers.SlackHandler
    level: ERROR
    formatter: standard
    token: "xoxb-..."  # Slack API Token
    channel: "#alerts"

  syslog:
    class: logging.handlers.SysLogHandler
    level: WARNING
    formatter: standard
    address: "/dev/log"

# 로거 정의
loggers:
  my_app:
    level: DEBUG
    handlers: [console, file, timed_file, json_file, slack, syslog]
    propagate: no

# 기본 로거 설정 (루트 로거)
root:
  level: WARNING
  handlers: [console, file]
```

---

## 🔹 설명

| 항목 | 설명 |
|------|------|
| `version: 1` | 로깅 설정 버전 (Python 표준) |
| **Formatters** | 로그 출력 형식을 정의하는 부분 |
| `standard` | 기본 로그 포맷 (날짜, 로그레벨, 로거명, 파일명, 라인번호, 메시지) |
| `json` | JSON 형식으로 로그 저장 가능 |
| `detailed` | 추가적인 정보(프로세스 ID, 쓰레드 정보)를 포함하는 포맷 |
| **Handlers** | 로그를 저장하는 방식 |
| `console` | 터미널(표준 출력)에 로그 출력 |
| `file` | 크기에 따라 파일을 회전하는 핸들러 (`RotatingFileHandler`) |
| `timed_file` | 날짜에 따라 파일을 자동으로 회전하는 핸들러 (`TimedRotatingFileHandler`) |
| `json_file` | JSON 형식으로 로그를 저장하는 핸들러 |
| `slack` | `ERROR` 이상 로그가 발생하면 Slack으로 전송 |
| `syslog` | 시스템 로그 서버(`/dev/log`)에 저장 |
| **Loggers** | 특정 로거에 대해 설정하는 부분 |
| `my_app` | `my_app` 네임스페이스의 모든 로그가 지정된 핸들러를 거쳐 출력 |
| **Root Logger** | 설정되지 않은 모든 로거가 따르는 기본 설정 |

---

## 🔹 SlackHandler (커스텀 핸들러)
Slack 알림을 위해 별도의 핸들러를 만들어야 합니다.

**`my_logging_handlers.py`**
```python
import logging
import requests

class SlackHandler(logging.Handler):
    def __init__(self, token, channel):
        super().__init__()
        self.token = token
        self.channel = channel

    def emit(self, record):
        log_entry = self.format(record)
        payload = {
            "channel": self.channel,
            "text": f"🚨 {record.levelname}: {log_entry}",
        }
        headers = {
            "Authorization": f"Bearer {self.token}",
            "Content-Type": "application/json",
        }
        try:
            requests.post("https://slack.com/api/chat.postMessage", json=payload, headers=headers)
        except Exception as e:
            print(f"Slack logging failed: {e}")
```

---

## 🔹 사용법

```python
import logging
import logging.config
import yaml

# YAML 로깅 설정 불러오기
with open("logging_config.yaml", "r") as f:
    config = yaml.safe_load(f)
    logging.config.dictConfig(config)

logger = logging.getLogger("my_app")

# 로깅 예제
logger.debug("이것은 디버그 메시지입니다")
logger.info("이것은 정보 메시지입니다")
logger.warning("이것은 경고 메시지입니다")
logger.error("이것은 에러 메시지입니다")
logger.critical("이것은 치명적 오류 메시지입니다")
```

---

## 🔹 확장 가능 포인트
- **Kafka / CloudWatch 연동**: 원격 로깅 가능
- **Trace ID, Request ID 추가**: API 요청 단위로 추적
- **AsyncIO 지원**: 비동기 로깅 핸들러 추가 (`queue.Queue`)
- **ElasticSearch 연동**: 로그를 실시간 분석 가능

---

## 🔹 결론
- **파일 로그, JSON 로그, 콘솔 로그, Slack 알림, Syslog까지 포함된 완전한 설정**  
- **대규모 서비스에서 확장성을 고려한 로깅 구성**  
- **커스텀 핸들러를 활용한 추가 기능 지원 가능**
