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
- marker
  - 말그대로 각 test 마다 marking 을 하는데 쓰이는 기능
  - test function 에 `@pytest.mark` 를 사용하여 다양한 meta 정보를 지정할 수 있고, 이는 각각 고유한 기능을 가지고 있다
  - Custom marker 를 만들 수도 있다


### 몇가지 marker 소개

marker 에 대한 이해를 돕기 위해 built-in marker 중 자주 쓰이는 것들 일부를 소개한다.<br/>
전체 built-in marker 목록은 [여기](https://docs.pytest.org/en/6.2.x/reference.html#marks-ref) 에서 볼 수 있음<br/>
`pytest --markers` 명령어를 이용해 현재 사용 가능한 marker 목록을 볼 수도 있다

- usefixtures : fixture 를 직접적으로 테스트에서 참조하지 않지만 내부적으로 필요한 경우 사용
- filterwarnings: test 시 발생하는 특정 warning 무시
- skip: 해당 test 는 항상 skip 처리
- skipif: 특정 condition 일때, 해당 test 는 항상 skip 처리
- xfail: 특정 condition 일때, `expected failure` 결과를 출력
- parameterize: 서로다른 input argument 로 동일한 test 를 여러번 실행할때 사용


---

[목록으로](https://shiwoo-park.github.io/blog/kor)
