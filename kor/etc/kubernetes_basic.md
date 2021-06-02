# Kubernetes 기본 지식

> 날짜: 2021-04-10

최근들어 회사 서비스들을 k8s 기반으로 이식하기 시작했다. 내가 하는것은 아니지만 어쩃든 앞으로 내가 유지보수 할 서비스들이 k8s에 있을것이기 때문에 기본적인 개념과 활용법은 알아놔야 겠다고 생각했다. 이 문서는 아주아주 최소한으로 k8s를 사용하는 개발자로써 알아야할 지식들을 가볍게 정리한 것이다.

좀 더 제대로 공부를 하고 싶다면 [공식 문서](https://kubernetes.io/ko/docs/concepts/overview/what-is-kubernetes/) 를 보도록 하자.

## Kubernetes 의 주요 개념

- Kubernetes
  - 짧게 부르고 싶어서 k8s 라고도 불린다 (8은 사이의 알파벳 개수)
  - 쿠버네티스는 컨테이너화된 워크로드와 서비스를 관리하기 위한 이식성이 있고, 확장가능한 오픈소스 플랫폼이다
- k8s componenets
  - cluster: node 의 집합
  - node (=set of worker machine): 쿠버네티스가 설치된 물리머신, 최소 1개 이상의 worker 머신이 필요

## Workload
- Pod
  - k8s

## k8s 의 주요 기능

- Service discovery, load balancing
- Storage orchestration
- Automated rollout & rollback
- Automated bin packing (=computing resource control)
- Self-healing
- Secret managements

## 기타 링크

- [Container부터 다시 살펴보는 Kubernetes Pod 동작 원리](https://speakerdeck.com/devinjeon/containerbuteo-dasi-salpyeoboneun-kubernetes-pod-dongjag-weonri?slide=7)
- ***

[목록으로](https://shiwoo-park.github.io/blog/kor)
