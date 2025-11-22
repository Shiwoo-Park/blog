---
layout: post
title: "AWS - ALB를 이용하여 여러 도메인을 하나의 도메인으로 서비스하기"
date: 2024-08-12
categories: [aws, alb, networking]
---
아래와 같이 해당 내용을 채워 넣을 수 있습니다. 방금 설명드린 내용을 글에 맞게 정리해드리겠습니다.

---

## 전제조건

- AWS Route 53 으로 도메인을 등록하고 관리하고 있어야 함
- ACM(AWS Certificate Manager)으로 도메인의 인증서를 생성한 상태여야 함.
- ALB로 도메인을 연결하여 특정 서비스를 접근하는 방식이어야 함
- ALB에서는 80, 443을 열어놓지만 최종적으로는 HTTPS로만 응답하도록 세팅되어있어야 함.

## 여러 도메인을 연결하는 방법

일단 내 서비스 기본 도메인이 `coke.com`이라고 해보자.

그런데 추가적으로 아래의 도메인들도 같은 서비스를 이용하고 싶다고 가정한다.

- `the-coke.com`
- `www.coke.com`

이 경우 여러 도메인을 하나의 ALB에서 처리하고, `coke.com`으로 리다이렉션하도록 설정할 수 있다. 여기서는 AWS Application Load Balancer(ALB)를 이용하여 이 작업을 수행하는 방법을 설명한다.

### 1. ACM(AWS Certificate Manager)에서 인증서 생성

우선, 각 도메인에 대한 SSL 인증서를 생성해야 한다. `coke.com`, `the-coke.com`, `www.coke.com` 모두에 대해 인증서를 생성하되, 하나의 인증서로 통합하여 관리하는 것이 가능하다. 이를 위해서는 Wildcard SSL 인증서를 사용할 수 있다.

### 2. ALB 생성 및 HTTPS 리스너 설정

AWS 콘솔에서 새로운 ALB를 생성한다. ALB를 생성할 때 HTTPS(443)와 HTTP(80) 포트를 열어주지만, 최종적으로는 HTTPS로만 리디렉션을 설정할 것이다.

- HTTPS 리스너를 추가하고, 앞서 ACM에서 생성한 인증서를 선택한다.
- HTTP 리스너도 설정하고, 이후 모든 HTTP 요청을 HTTPS로 리디렉션하도록 구성한다.

### 3. ALB 리스너 규칙 설정

ALB의 리스너 규칙을 설정하여 여러 도메인으로 들어오는 요청을 `coke.com`으로 리디렉션한다.

- **조건**: 호스트 헤더가 `the-coke.com`, `www.coke.com`인 경우
- **작업**: 요청을 `https://coke.com$request_uri`로 리디렉션

이와 같은 규칙을 설정하면 `the-coke.com`이나 `www.coke.com`으로 들어온 모든 요청은 `coke.com`으로 리디렉션되며, 원래의 URI 경로와 쿼리 파라미터는 유지된다.

### 4. Route 53에서 DNS 설정

AWS Route 53에서 각 도메인에 대해 A 레코드와 CNAME 레코드를 설정하여 ALB에 연결한다. 모든 도메인은 ALB를 가리키도록 설정되며, 실제 트래픽은 ALB에서 처리되어 `coke.com`으로 리디렉션된다.


이러한 설정을 통해 `the-coke.com`, `www.coke.com` 등 모든 도메인을 단일 도메인 `coke.com`으로 일관되게 리디렉션할 수 있으며, 사용자에게는 동일한 콘텐츠를 제공할 수 있다.


