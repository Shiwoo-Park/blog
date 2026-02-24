---
layout: post
title: "AWS RDS 성능 개선 도우미(Performance Insights) 활용 방법"
date: 2026-02-13
categories: [aws, rds, monitoring, performance]
description: "RDS Performance Insights로 DB 부하를 대기 이벤트·Top SQL로 분석하는 방법과 실전 활용 팁. AAS, 대기 이벤트, 진단 흐름을 간단히 정리합니다."
keywords: "AWS, RDS, Performance Insights, 성능 모니터링, AAS, 대기 이벤트, Database Insights"
image: "/resources/og-dev.png"
---

RDS에서 “DB가 느리다”고 할 때, CPU 수치만으로는 원인을 좁히기 어렵습니다. **성능 개선 도우미(Performance Insights)** 는 DB 부하를 **대기 이벤트**와 **상위 SQL**로 쪼개서 보여주는 RDS 기본 모니터링 도구입니다. 이 글에서는 Performance Insights가 무엇인지, 어떤 용도인지, 실전에서 어떻게 쓰면 좋은지 핵심만 정리합니다.

> **참고**: AWS는 Performance Insights를 **2026년 6월 30일**에 종료하고, **CloudWatch Database Insights** 로 전환할 예정입니다. 기존에 Performance Insights를 쓰고 있다면 Database Insights(Standard/Advanced) 전환을 검토하는 것이 좋습니다.

---

## 1. RDS 성능 개선 도우미(Performance Insights)란?

**성능 개선 도우미(Performance Insights)** 는 RDS 인스턴스에 붙어 있는 **DB 부하 모니터링·분석 기능**입니다. CloudWatch 기본 지표(CPU, IOPS 등)보다 한 단계 더 들어가서,

- **“어떤 대기(wait) 때문에 시간을 쓰는지”**
- **“어떤 SQL이 부하를 많이 만드는지”**

를 시각적으로 보여줍니다. RDS 콘솔에서 인스턴스별로 **Performance Insights** 탭을 켜두면 사용할 수 있습니다.

---

## 2. 기능 소개 및 용도

### 2-1. Database Load(DB 부하)와 AAS

Performance Insights의 중심 지표는 **Database Load** 입니다. “DB가 얼마나 바쁜가”를 **평균 활성 세션 수(AAS, Average Active Sessions)** 로 나타냅니다.

- **AAS**: 일정 구간 동안 “동시에 활성인 세션”이 평균 몇 개였는지.
- 세션이 **CPU를 쓰는 중**이거나 **어떤 자원을 기다리는 중**이면 “활성”으로 칩니다.

즉, CPU 사용률만 높을 때 “CPU가 원인이다”로 끝내지 않고, **CPU vs 대기** 비율을 나눠 볼 수 있습니다.

### 2-2. 대기 이벤트(Wait events)

**대기 이벤트**는 세션이 **무엇을 기다리는지**를 구분한 단위입니다. 예를 들면:

- **CPU**: CPU 사용 중(대기가 아니라 작업 중)
- **Lock / Latch**: 행·객체 잠금, 래치 대기
- **IO**: 디스크 읽기/쓰기 대기
- **Buffer / Log**: 버퍼 풀, 로그 쓰기 관련 대기

대시보드에서는 “DB 부하가 이 구간에서는 주로 어떤 대기로 차 있는지”를 **막대/영역**으로 보여줍니다. 그래서 “CPU는 낮은데 느리다”면 **어떤 대기**가 높은지 바로 확인할 수 있습니다.

### 2-3. Top SQL

**Top SQL** 은 선택한 시간 구간에서 **부하(Active sessions 등)를 가장 많이 만든 SQL** 목록입니다. 대기 이벤트로 “Lock이 많다”까지 알았다면, Top SQL에서 **어떤 쿼리가 Lock을 유발하는지** 좁혀갈 수 있습니다.

### 2-4. 용도 정리

| 용도 | 설명 |
|------|------|
| **병목 구간 찾기** | 특정 시간대에 DB 부하가 났을 때, 그때 대기 이벤트·Top SQL 확인 |
| **느린 쿼리 후보 좁히기** | CPU/Lock/IO 중 무엇이 주인지 보고, 해당 부하에 기여한 SQL 확인 |
| **트래픽 패턴과 부하 관계** | 시간축 그래프로 “요청이 몰릴 때 어떤 대기가 늘어나는지” 파악 |

---

## 3. 실전 활용 방법

### 3-1. 대시보드 들어가기

1. **AWS 콘솔** → **RDS** → **데이터베이스**
2. 대상 **인스턴스** 선택
3. 상단 **성능 개선 도우미(Performance Insights)** 또는 **Performance Insights** 탭 클릭  
   (해당 인스턴스에서 Performance Insights가 활성화되어 있어야 합니다.)

### 3-2. 전형적인 진단 흐름

1. **Database load 차트**  
   - 시간축으로 **AAS(DB 부하)** 가 높았던 구간을 찾습니다.  
   - 보통 **Max CPU** 선과 비교해서, AAS가 Max CPU를 넘으면 “CPU만으로는 설명이 안 되는 대기”가 있다는 뜻입니다.

2. **대기별 로드(대기 이벤트)**  
   - 그 구간에서 **막대가 큰 대기 유형**(CPU, Lock, IO 등)을 확인합니다.  
   - 예: Lock 비중이 크면 → 동시성/트랜잭션·쿼리 패턴을 의심.

3. **Top SQL**  
   - 같은 구간을 선택한 상태에서 **Top SQL** 탭으로 이동합니다.  
   - 부하(Active sessions 등) 기준 상위 쿼리를 보고, 2번에서 본 대기와 연결해 “이 쿼리가 Lock을 유발한다” 등으로 가설을 세웁니다.

4. **조치**  
   - 쿼리 튜닝(인덱스, 쿼리 단순화), 트랜잭션 시간 단축, 동시성 조절(Connection pool, 배치 분산) 등을 검토합니다.

### 3-3. 활용 시 유의점

- **보존 기간**: 기본적으로 Performance Insights는 **최대 7일** 정도 데이터를 보관합니다. (장기 보존은 유료 옵션.)
- **2026년 전환**: 2026년 6월 30일 이후에는 **CloudWatch Database Insights** 로 전환이 권장됩니다. 장기 데이터나 고급 분석이 필요하면 Database Insights Advanced 모드를 미리 검토하는 것이 좋습니다.

---

## 핵심요약

- **성능 개선 도우미(Performance Insights)** 는 RDS DB 부하를 **대기 이벤트**와 **Top SQL** 로 나눠서 보여주는 모니터링 기능이다.
- **AAS(평균 활성 세션)** 가 DB 부하 지표이며, **대기 이벤트**로 CPU vs Lock/IO 등 원인을 구분할 수 있다.
- **실전 흐름**: Database load에서 부하 구간 확인 → 대기 이벤트에서 주된 대기 유형 확인 → Top SQL에서 해당 부하를 만든 쿼리 추적 → 쿼리/트랜잭션/동시성 개선.
- AWS는 Performance Insights를 **2026년 6월 30일** 종료 예정이며, **CloudWatch Database Insights** 로 전환할 계획이므로, 새로 구축하는 모니터링은 Database Insights를 고려하는 것이 좋다.
