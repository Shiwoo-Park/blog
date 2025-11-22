---
layout: post
title: "푸시(Push) / 풀(Pull) 아키텍처 개념 및 사례"
date: 2025-02-23
categories: [backend, architecture]
---
## 푸시(Push) 아키텍처

**정의**  
- 데이터 생산자가 직접 데이터를 소비자에게 전송하는 방식  
- 실시간성이 중요한 경우 사용됨  
- **푸시(Push) 아키텍처**를 사용하려면 서버가 클라이언트에 미리 연결되어 있어야 함
- **서버가 클라이언트의 상태를 유지**해야 푸시가 가능


### ✅ HTTP 기반에서 푸시가 어려운 이유

**기본적으로 HTTP는**  
- **Stateless(상태 없음)**: 요청을 보낼 때마다 새로운 연결을 만든다.
- **Request-Response 모델**: 클라이언트가 요청을 보내야 서버가 응답할 수 있다.

**즉, 일반적인 HTTP 요청 방식에서는**  
🚫 **서버가 먼저 클라이언트에게 데이터를 보낼 방법이 없다**  
(클라이언트가 요청하지 않으면 서버는 아무것도 못 함)

---

### 웹소켓(WebSocket) - 양방향 실시간 통신
- 클라이언트가 웹소켓 연결을 열어두면, 서버가 언제든 데이터를 보낼 수 있음.
- **활용 사례**: 실시간 채팅, 게임, 주식 가격 업데이트  
✅ **장점**: HTTP보다 오버헤드가 적고 실시간성이 뛰어남.  
🚫 **단점**: 클라이언트가 연결을 유지해야 함.

```python
import asyncio
import websockets

async def handler(websocket, path):
    while True:
        await websocket.send("Hello Client!")
        await asyncio.sleep(1)  # 1초마다 메시지 전송

start_server = websockets.serve(handler, "localhost", 8765)

asyncio.get_event_loop().run_until_complete(start_server)
asyncio.get_event_loop().run_forever()
```

### SSE(Server-Sent Events) - 단방향 푸시

- HTTP 기반이지만 클라이언트가 한 번 연결을 열어두면 서버가 계속 데이터를 보낼 수 있음.
- **활용 사례**: 실시간 대시보드, 뉴스 피드  
✅ **장점**: HTTP 기반이라 방화벽/프록시에서 사용하기 쉬움.  
🚫 **단점**: 클라이언트 → 서버 메시지를 보낼 수 없음 (단방향).

#### Client 코드 예시

```js
const eventSource = new EventSource("http://localhost:5000/events");

eventSource.onmessage = function(event) {
    console.log("Received event:", event.data);
};

// 연결이 닫혔을 때
eventSource.onerror = function(event) {
    console.error("EventSource failed:", event);
    eventSource.close();  // 필요하면 연결 닫기
};
```

#### Server 코드 예시

```python
from flask import Flask, Response
import time

app = Flask(__name__)

@app.route('/events')
def events():
    def generate():
        while True:
            yield f"data: {time.ctime()}\n\n"
            time.sleep(2)
    return Response(generate(), mimetype='text/event-stream')

app.run(port=5000)
```

### Long Polling - 가짜 푸시 방식

- 클라이언트가 요청을 보내면, 서버는 **즉시 응답하지 않고** 이벤트가 발생할 때까지 기다렸다가 응답.
- **활용 사례**: 푸시 알림 대체, 채팅 시스템 (단순 구현)  
✅ **장점**: 별도 프로토콜 없이 일반 HTTP로 구현 가능.  
🚫 **단점**: 요청을 계속 유지해야 해서 네트워크 부하가 큼.

```python
from flask import Flask, jsonify
import time

app = Flask(__name__)

@app.route('/poll')
def poll():
    time.sleep(5)  # 새로운 데이터가 생길 때까지 기다린다고 가정
    return jsonify({"message": "New event received!"})

app.run(port=5001)
```
(클라이언트는 일정 간격으로 `GET /poll` 요청을 보내면서 대기)


### 내용 정리

- **일반 HTTP 기반에서는 서버가 먼저 클라이언트에게 보낼 방법이 없음.**
- **푸시를 하려면 지속적인 연결이 필요**하므로, 웹소켓/WebRTC/SSE 같은 기술이 필요함.
- **Long Polling**도 HTTP 기반에서 푸시처럼 보이게 할 수 있지만 효율이 떨어짐.

✅ **최적의 선택**
- **실시간 채팅, 알림, 금융 데이터 → WebSocket**
- **뉴스 업데이트, 대시보드 → SSE**
- **API가 HTTP 기반이고 기존 시스템과 연동해야 한다면 → Long Polling**

## 종류별 푸시 아키텍처 사용사례 모음

사용하는 **서비스의 특성**에 따라 다르지만, **실시간성이 필요한 경우**라면 **WebSocket**이 가장 많이 사용돼.  
다만, 기존의 HTTP 기반 시스템과 쉽게 통합하려면 **SSE**나 **Long Polling**도 여전히 활용되고 있어.

---

### ✅ **가장 많이 사용하는 기술별 주요 활용 사례**
| 기술 | 주요 활용 사례 | 특징 |
|------|-------------|------|
| **WebSocket** | 채팅, 게임, 실시간 주식 데이터, WebRTC | ✅ 양방향 통신 가능, 실시간성이 가장 뛰어남 |
| **SSE (Server-Sent Events)** | 실시간 대시보드, 뉴스 업데이트 | ✅ HTTP 기반으로 설정이 간편, 단방향 통신 |
| **Long Polling** | 푸시 알림 대체, 간단한 채팅 시스템 | ✅ 기존 HTTP 기반 시스템과 쉽게 연동 가능 |
| **gRPC Streaming** | MSA 환경의 서비스 간 실시간 데이터 전송 | ✅ HTTP/2 기반, 성능 최적화된 스트리밍 지원 |

---

### 🔥 **가장 많이 사용되는 방식은?**
1️⃣ **웹 기반 실시간 서비스 → WebSocket**  
   - ✅ 실시간 채팅 (WhatsApp, Slack, Zoom 등)  
   - ✅ 주식 거래/크립토 거래소 (Binance, Upbit, NASDAQ API 등)  
   - ✅ 실시간 알림 시스템 (SNS 알림, 푸시 서비스)  

2️⃣ **모니터링 & 데이터 스트리밍 → SSE(Server-Sent Events)**  
   - ✅ 실시간 로그 모니터링 (Grafana, Kibana, Prometheus)  
   - ✅ 뉴스/라이브 스포츠 점수 업데이트  
   - ✅ 실시간 대시보드 (Google Analytics, DevOps 모니터링)  

3️⃣ **일반적인 HTTP 서비스에서 푸시 필요 → Long Polling**  
   - ✅ REST API와 쉽게 통합해야 할 때  
   - ✅ HTTP 기반 푸시 알림 (Firebase Cloud Messaging 대체)  
   - ✅ 기존 시스템에 실시간 기능 추가  

---

### 🚀 **결론: 언제 WebSocket, SSE, Long Polling을 선택해야 할까?**
| 사용 목적 | 추천 기술 |
|-----------|----------|
| 실시간 채팅, 게임, 금융 데이터 | **WebSocket** |
| 서버에서 클라이언트로만 실시간 데이터 전송 | **SSE** |
| 기존 HTTP 시스템에서 푸시 비슷한 기능 필요 | **Long Polling** |

---

## 풀(Pull) 아키텍처

**정의**  
- 소비자가 필요할 때 데이터 생산자로부터 요청하여 가져오는 방식  
- 데이터 요청 부담을 소비자가 조절 가능  

**활용 사례**  
- **모니터링 시스템 (Prometheus)**: 서버가 일정 주기로 데이터를 수집  
- **REST API 기반 데이터 조회**: 클라이언트가 필요할 때 서버에 요청  
- **배치 작업 (Batch Processing)**: 일정 시간마다 데이터 수집  

**파이썬 구현 (Prometheus 스타일 데이터 수집)**  
```python
import time
import requests

def fetch_metrics():
    response = requests.get("http://localhost:8000/metrics")
    return response.json()

while True:
    metrics = fetch_metrics()
    print(metrics)
    time.sleep(5)  # 5초마다 데이터 가져오기
```
👆 **설명**: 특정 URL에서 메트릭을 일정 주기로 가져오는 간단한 풀 방식 코드.  
(실제 Prometheus는 `/metrics` 엔드포인트에서 데이터를 가져와 모니터링함)

---

## 푸시 vs 풀 비교 요약

|  | 푸시 (Push) | 풀 (Pull) |
|---|---|---|
| **데이터 흐름** | 생산자가 직접 전달 | 소비자가 요청 |
| **실시간성** | 높음 | 상대적으로 낮음 |
| **부하 조절** | 소비자가 제어 불가 | 소비자가 제어 가능 |
| **활용 사례** | 실시간 알림, IoT 센서 | 모니터링, REST API |

✅ **결론**  
- **실시간 대응이 필요하면 `푸시(Push)`**  
- **시스템 부하를 조절해야 하면 `풀(Pull)`**  
- **하이브리드** 방식도 가능 (예: Webhook + API Polling)

