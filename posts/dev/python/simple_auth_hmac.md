---
layout: post
title: "간단하면서도 안전한 인증 토큰 만들기 (Python, HMAC, ID/SECRET 기반)"
date: 2025-06-07
categories: [python, security, authentication]
---
# 🔐 간단하면서도 안전한 인증 토큰 만들기 (Python, HMAC, ID/SECRET 기반)

> 날짜: 2025-06-07

[목록으로](https://shiwoo-park.github.io/blog)

API 서버 간의 안전한 통신이나 임시 인증이 필요할 때 사용할 수 있는 HMAC 기반의 간단한 토큰 생성 로직을 소개합니다.

이 방식은 **ID + SECRET + TIMESTAMP** 조합으로 생성된 토큰을 이용하여, 수신 측에서는 동일한 알고리즘으로 토큰을 검증할 수 있습니다.


## ✅ HMAC 인증이란?

* **HMAC**은 Hash-based Message Authentication Code의 약자입니다.
* 공유된 \*\*비밀 키(SECRET\_KEY)\*\*를 이용해, 변조나 위조 없이 메시지의 무결성을 검증할 수 있습니다.
* 타임스탬프 기반 유효기간 제한도 손쉽게 추가 가능하므로, 인증 토큰 용도로 적합합니다.


## 🧩 토큰 생성 및 검증 모듈 (`auth_token.py`)

```python
# auth_token.py
import hmac
import hashlib
import time

class AuthToken:
    def __init__(self, client_id: str, client_secret: str, hash_algo: str = 'sha256', valid_window: int = 3):
        """
        인증 토큰 생성기 초기화

        Args:
            client_id (str): 클라이언트 식별자 (예: 'my-client')
            client_secret (str): 클라이언트 비밀 키 (HMAC 서명용)
            hash_algo (str): 사용할 해시 알고리즘 (기본값: 'sha256')
            valid_window (int): 토큰 유효 시간(초 단위, 기본값: 3초)
        """
        self.client_id = client_id
        self.secret_key = client_secret.encode()
        self.hash_algo = getattr(hashlib, hash_algo)
        self.valid_window = valid_window

    def generate(self, timestamp: int = None) -> str:
        if timestamp is None:
            timestamp = int(time.time())
        raw = f"{self.client_id}.{timestamp}"
        signature = hmac.new(self.secret_key, raw.encode(), self.hash_algo).hexdigest()
        return f"{self.client_id}:{timestamp}:{signature}"

    def verify(self, token: str) -> bool:
        try:
            parts = token.split(":")
            if len(parts) != 3:
                return False

            token_id, token_ts, token_sig = parts
            if token_id != self.client_id:
                return False

            token_ts = int(token_ts)
            now = int(time.time())
            if abs(now - token_ts) > self.valid_window:
                return False

            expected_token = self.generate(token_ts)
            return hmac.compare_digest(token, expected_token)
        except Exception:
            return False
```


## 🧪 사용 예시

```python
from auth_token import AuthToken

auth = AuthToken(client_id="example-client", client_secret="shared_secret")

# 1. 서버에서 토큰 생성
token = auth.generate()
print("🔐 Generated:", token)

# 2. 다른 서버 또는 수신 측에서 토큰 검증
is_valid = auth.verify(token)
print("✅ Valid:", is_valid)
```


## 📌 특징 요약

- **독립적인 모듈**로 설계되어 어떤 웹 프레임워크와도 함께 사용 가능
- `SECRET_KEY` 기반 HMAC 토큰으로 **변조 위험 최소화**
- `timestamp` 기반 유효기간 설정으로 **재사용 방지**
- `hmac.compare_digest()`를 사용해 **타이밍 공격 방어**
  - 타이밍 공격 이란, 일반 문자열 비교의 경우 앞글자부터 순차적으로 비교하다가 실패시 리턴하는데
  - 이때 일치 문자열이 있으면 아주 미미하게 응답속도 차이가 생기고 이것을 공격자가 이용하여 전체 토큰 문자열을 유추해내는 것


## 🧠 활용 팁

* API 요청 헤더에 `X-Auth-Token` 형식으로 포함시키면 좋습니다.
* 클라이언트에 발급된 `client_id` + `secret_key`를 미리 등록해두고 검증하는 방식으로 확장 가능합니다.
* 토큰 유효기간을 짧게 유지하면 실시간 보안 수준을 높일 수 있습니다.


## ✅ HMAC 인증 토큰의 실제 사용 사례

- HMAC 기반 인증 토큰은 **많은 IT 회사에서 실제로 널리 사용**됩니다. 
- 다만 **JWT, OAuth, API Key** 같은 다른 방식들과 용도나 보안 수준에 따라 선택적으로 사용되는 경우가 많습니다.

1. **서버 간 통신 (서버 → 서버)**

   * 서로 알고 있는 `client_id` + `secret_key` 기반으로 토큰을 생성하고 검증.
   * 예: 백오피스 → API 서버, 모바일 푸시 서버 → 인증 서버

2. **내부 API 인증 (공개되지 않는 내부 시스템 간)**

   * VPN이나 내부 네트워크에서 실행되는 마이크로서비스 간 통신.

3. **3rd Party API 인증 (간단한 API Key + 서명 방식)**

   * 예: 금융 API (금융결제원, 카드사 등), 물류 API (택배사 등)
   * `timestamp` + `path` + `params`를 HMAC으로 서명 후 헤더에 포함

4. **Webhook 인증**

   * 외부 시스템에서 전송한 웹훅 요청이 위조되지 않았는지 HMAC 서명으로 검증


## ⚠️ HMAC 기반 인증 방식의 취약점과 한계

### 1. **클라이언트 시크릿 유출 시 보안 완전 붕괴**

* `client_secret`이 노출되면 누구든지 유효한 토큰을 만들 수 있음
* **대응책:** secret 주기적 rotation, IP allow list 등 추가 보안 필요.

### 2. **토큰 재사용 (Replay Attack)**

* 유효한 토큰을 탈취해 같은 요청을 반복적으로 보낼 수 있음
* **대응책:** `timestamp` + `nonce` 사용하거나, Redis로 토큰 1회 사용 제한, 토큰 유효기간을 짧게 설정.

### 3. **HTTPS 미사용 시 중간자 공격**

* 네트워크 상에서 HMAC 토큰이 노출될 수 있음
* **대응책:** 반드시 HTTPS 사용. 토큰 유효기간을 짧게 설정.

### 4. **탈중앙 인증이 어려움**

* 인증 상태를 외부에서 공유하거나 위임하기 어려움 (JWT보다 불리)
* **대응책:** 인증 권한 위임이 필요한 경우에는 OAuth2 또는 JWT 사용 고려

## ✅ 결론 요약

| 항목     | HMAC 인증 방식의 특징                      |
| ------ | ----------------------------------- |
| 장점     | 구현 간단, 의존성 없음, 빠름, 토큰 위조 방지         |
| 단점     | secret 유출 시 위험, 탈취 방지 필요, 위임 인증 어려움 |
| 적합한 경우 | 서버 간 통신, 내부 API, 웹훅 보안 등 제한된 신뢰 환경  |

간단하지만 안전한 인증 구조가 필요할 때 위 HMAC 기반 토큰 방식을 적극 활용해 보세요.
추후 필요 시, IP 제한, 요청 URL 포함, Nonce 추가 등으로 확장도 가능합니다.
