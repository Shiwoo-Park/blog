# Pytest 소개 및 기능

> 날짜: 2021-10-14

내가 파이썬 프로젝트를 유지보수 할때, 가장 많이 썻던 test framework 인 pytest 에 대하여 한버 정리해보고자 한다.<br/>
시작하기 전에, 일단 영어 잘하는 분은 [공식 사이트](https://docs.pytest.org/) 만 한 곳이 없으니 참고하시길!

## pytest 소개

pytest 란 무엇일까? 일단 공식사이트 내용에 따르면 아래와 같다
> The pytest framework makes it easy to write small tests, yet scales to support complex functional testing for applications and libraries.<br/>
> = pytest 는 Application 및 Library 를 위한 작은 것부터 복잡한 테스트를 쉽게 작성할 수 있게 해주는 프레임 워크이다

## pytest 특징

- 파이썬 3.6+, Pypy 3 에 지원
- 실패한 `assert statement` 에 대한 깔끔+명료한 결과 출력 (+ self.assertXXX 등의 함수 기억할 필요 X)
- test 모듈 및 함수 자동 탐지
- 작거나 매개변수화 된 장시간 살아있는 test 자원으 `모듈식(=Modular) fixture` 으로 관리
- (trial 을 포함한) 모든 파이썬 unittest, [nose](https://nose.readthedocs.io/en/latest/) 로 작성된 test 실행 가능
- 315개 이상의 풍부한 [plug-in](https://docs.pytest.org/en/latest/reference/plugin_list.html) 시스템 그리고 발달된 커뮤니티

## pytest 기본 용어

pytest 프레임 워크 내에서 사용되는 기본 용어들과 그 개념을 살펴보자.

- fixture
  - fixture 는 test function 들을 초기화 한다.
  - 여기서 초기화라 함은, `서비스 | 각종 상태값 | 구동환경` 등을 setup 하는것을 말한다
  - fixture 는 그렇게 고정된 기반 데이터를 제공하여 신뢰성 높은 test 작성을 가능하게 하며,
  - 일관성있고 반복성이 뛰어난 결과를 얻도록 도와준다
  - test function 의 argument 형식으로 접근이 가능

## 뽀너스: 유용한 pytest plug-in 7개

[참고 자료](https://miguendes.me/7-pytest-plugins-you-must-definitely-use)

- `pytest-cov` : 테스트 결과에 코드 커버리지 report 추가
- `pytest-django` : `django.test.TestCase` 에서 제공되는 모든 fixture, assert 방식들을 제공
  - django_db 커넥션 지원
  - test client object 사용가능
- `pytest-asyncio` : async program 을 테스트하기 좋은 플러그인. 기존 pytest 에 async 형식의 기능을 훌륭히 제공해준다
- `pytest-randomly` : unit-test 를 무작위 순서로 실행해주는 기능 제공. unit-test 간 의존성 검증에 효과적
- `pytest-clarity` : pytest 실패내역에 대한 출력 결과를 한차원 더 또렷하게 보여주는 기능 제공. 결고 가시성이 매우 뛰어남
- `pytest-bdd` : `BDD(=Behavior-driven Development)` 는 `TDD(Test-driven Development)` 의 확장팩이다. 
   어떠한 특정 도메인 또는 흐름(=story)에 따라 테스트를 연결지을 수 있는 기능 제공 (feat. [Gherkin format](https://www.guru99.com/gherkin-test-cucumber.html) )


---

[목록으로](https://shiwoo-park.github.io/blog/kor)
