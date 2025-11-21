---
layout: post
title: "파이썬으로 로깅 잘하기"
date: 2025-02-15
categories: [python, logging]
---

# 파이썬으로 로깅 잘하기

> 날짜: 2025-02-15

[목록으로](https://shiwoo-park.github.io/blog)

---

## 1. 파이썬 로깅 기초

### 1.1 로깅 시스템 컴포넌트

파이썬의 `logging` 모듈은 다음과 같은 주요 컴포넌트로 구성됨:

- **Logger**: 로그 메시지를 생성하는 핵심 객체
  ```python
  import logging
  logger = logging.getLogger("example")
  logger.setLevel(logging.INFO)
  ```
- **Handler**: 로그를 어디에 기록할지 결정 (콘솔, 파일, 원격 서버 등)
  ```python
  console_handler = logging.StreamHandler()
  file_handler = logging.FileHandler("app.log")
  logger.addHandler(console_handler)
  logger.addHandler(file_handler)
  ```
- **Formatter**: 로그 메시지의 출력 형식 지정
  ```python
  formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
  console_handler.setFormatter(formatter)
  file_handler.setFormatter(formatter)
  ```
- **Filter**: 특정 기준을 만족하는 로그만 기록하도록 필터링
  ```python
  class InfoFilter(logging.Filter):
      def filter(self, record):
          return record.levelno == logging.INFO
  console_handler.addFilter(InfoFilter())
  ```

### 1.2 로깅 환경 설정

파이썬에서 로깅을 설정하는 기본적인 방법:
```python
import logging

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler("app.log"),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger("MyApp")
logger.info("로그 메시지 테스트")
```

### 1.3 `dictConfig`를 사용한 로깅 설정

보다 체계적이고 유지보수하기 쉬운 설정을 위해 `logging.config.dictConfig` 사용을 권장함:
```python
import logging.config

LOGGING_CONFIG = {
    "version": 1,
    "disable_existing_loggers": False,
    "formatters": {
        "detailed": {
            "format": "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
        }
    },
    "handlers": {
        "file": {
            "class": "logging.FileHandler",
            "filename": "app.log",
            "formatter": "detailed"
        },
        "console": {
            "class": "logging.StreamHandler",
            "formatter": "detailed"
        }
    },
    "root": {  # 루트 로거 설정 추가
        "level": "INFO",
        "handlers": ["file", "console"]
    },
    "loggers": {
        "my_module": {
            "level": "DEBUG",
            "handlers": ["console"],
            "propagate": False
        }
    }
}
logging.config.dictConfig(LOGGING_CONFIG)
logger = logging.getLogger("MyApp")
logger.info("dictConfig 기반 설정 적용")
```

## 2. 파이썬 로그 시스템 Tips

### 2.1 파이썬의 로거 탐색 방식

- **로거를 불러올때는 `__name__`을 활용**
```python
logger = logging.getLogger(__name__)
```
- 파이썬에서 `__name__`을 로거 이름으로 사용하면 패키지 구조에 맞춰 로거를 불러올 수 있음.
- 예를 들어, `aaa.bbb.ccc`라는 모듈에서 `logging.getLogger(__name__)`을 호출하면 아래 순서로 로거 설정을 찾음:
1. `aaa.bbb.ccc`
2. `aaa.bbb`
3. `aaa`
4. 루트 로거 (`""`)
- 이를 통해 특정 패키지의 모든 로깅을 한 번에 조정할 수 있음.

### 2.2 특정 패키지 로그만 이메일로 보내기

- SMTPHandler를 사용하여 ERROR 이상의 로그를 이메일로 전송
- my_app.critical_service 로거에만 이메일 핸들러 추가
- 아래 예제코드에서 확인

### 2.3 특정 패키지 로그만 무시하기 or 로그레벨 조정하기

- requests 패키지의 로그 레벨을 WARNING으로 설정하여 DEBUG/INFO 로그를 무시
- urllib3 패키지의 로그를 완전히 무시 (레벨을 CRITICAL로 설정)
- 아래 예제코드에서 확인

### 예제 코드

```python
import logging
import logging.config
import smtplib
from email.utils import formataddr

LOGGING_CONFIG = {
    "version": 1,
    "disable_existing_loggers": False,  # 기존 로거 비활성화 방지

    "formatters": {
        "standard": {
            "format": "[%(asctime)s] [%(levelname)s] [%(name)s] %(message)s",
            "datefmt": "%Y-%m-%d %H:%M:%S"
        }
    },

    "handlers": {
        # 콘솔 로그
        "console": {
            "class": "logging.StreamHandler",
            "level": "DEBUG",
            "formatter": "standard",
            "stream": "ext://sys.stdout",
        },

        # 파일 로그
        "file": {
            "class": "logging.FileHandler",
            "level": "INFO",
            "formatter": "standard",
            "filename": "logs/app.log",
            "encoding": "utf-8"
        },

        # 이메일 로그 (특정 패키지용)
        "email": {
            "class": "logging.handlers.SMTPHandler",
            "level": "ERROR",
            "formatter": "standard",
            "mailhost": ("smtp.gmail.com", 587),
            "fromaddr": formataddr(("Error Logger", "your-email@gmail.com")),
            "toaddrs": ["admin@example.com"],
            "subject": "[CRITICAL ERROR] Log Alert",
            "credentials": ("your-email@gmail.com", "your-email-password"),
            "secure": (),
        },
    },

    "loggers": {
        # 특정 패키지의 ERROR 이상 로그만 이메일로 전송
        "my_app.critical_service": {
            "level": "ERROR",
            "handlers": ["email", "console"],
            "propagate": False
        },

        # 특정 패키지 로그레벨 조정 (DEBUG/INFO 로그 무시)
        "requests": {
            "level": "WARNING",
            "handlers": ["console"],
            "propagate": False
        },

        # 특정 패키지 로그 완전 무시
        "urllib3": {
            "level": "CRITICAL",
            "handlers": [],
            "propagate": False
        },
    },

    "root": {
        "level": "WARNING",
        "handlers": ["console", "file"]
    }
}

# 로깅 설정 적용
logging.config.dictConfig(LOGGING_CONFIG)

# 로거 가져오기
logger = logging.getLogger("my_app.critical_service")
requests_logger = logging.getLogger("requests")
urllib3_logger = logging.getLogger("urllib3")

# 로그 예제
logger.info("이 메시지는 이메일로 가지 않음 (INFO)")
logger.error("이 메시지는 이메일로 전송됨 (ERROR)")
logger.critical("이 메시지도 이메일로 전송됨 (CRITICAL)")

requests_logger.debug("이 메시지는 무시됨 (DEBUG)")  # 출력되지 않음
requests_logger.info("이 메시지도 무시됨 (INFO)")  # 출력되지 않음
requests_logger.warning("이 메시지는 콘솔에 출력됨 (WARNING)")

urllib3_logger.error("이 메시지는 무시됨 (CRITICAL 수준 미만)")  # 출력되지 않음
urllib3_logger.critical("이 메시지는 무시됨 (CRITICAL이지만 handlers 없음)")  # 출력되지 않음

```

---

[목록으로](https://shiwoo-park.github.io/blog)




```
전문가를 위한 파이썬 프로그래밍

챕터 영역
- 12 chp. 애플리케이션 동작과 성능 관측 (12.1~12.2)
  - 에러와 로그 캡쳐

본문 내용
- 파이썬 로깅 기초
  - 로깅 시스템 컴포넌트
  - 로깅 환경 설정
- 좋은 로깅 프랙티스
  - 일반적으로 적용될수 있는 것들
  - 파이썬 로깅일때 특별히 더 할수 있는것들
- 사후리뷰를 위한 에러캡쳐
  - 파이썬 기반으로 이를 해낼 수 있는 각종 방법 (솔루션등 추천)
- 분산 로깅
  - 개념 정리
  - 로깅 인프라의 복잡성 정도 (레벨 0~4)
- 기타 라이브러리
  - sentry 목적, 장단점, 간단 사용법
  - logrotate 목적 및 간단 사용법
  - logging ubiquity 개념
  - syslog
```