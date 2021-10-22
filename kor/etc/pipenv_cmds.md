# pipenv 기능 및 명령어

> 날짜: 2020-08-30

[공식 사이트](https://pipenv.pypa.io/en/latest/)

## Pipenv 소개

우리가 흔히 쓰는 pip 보다 더 향상된 파이썬 패키지 관리 기능을 제공하는 라이브러리

비슷한 라이브러리로는 [Poetry](https://python-poetry.org/) 가 있다.


## Pipenv 의 기능
- 파이썬 프로젝트의 가상환경 관리
- 파이썬 가상환경의 pip package 관리
- 패키지 별 보안 취약점 자동 검증
- 패키지 의존성 그래프 손쉽게 확인
- `Pipfile`: pipenv 에서 패키지 정보를 기록하는 파일
- `Pipfile.lock`: 설치한 패키지 하나하나에 대한 세부 정보를 담고있는 파일

### Basic Commands

내용 | 명령어 | 비고
--- | --- | ---
특정 패키지 설치 | `pipenv install <package>` | 
특정 패키지 및 version 설치  | `pipenv install requests~=1.2` | == 보다 ~= 을 사용하여 호환되는 버전을 자동으로 찾도록 한다
Production 용 패키지만 설치 | `pipenv install` |
개발용 패키지를 포함한 전체 패키지 설치 | `pipenv install --dev` |
파이썬 3.7 로 새 프로젝트 시작 | `pipenv --python 3.7` | 
프로젝트 가상환경 삭제 | `pipenv --rm` |
pre-releases 를 포함한 lockfile 생성 | `pipenv lock --pre` |
패키지 의존성 그래프 확인 | `pipenv graph` |
설치된 패키지 의존성의 보안 이슈 점검 | `pipenv check` |
기존 `pip freeze` 실행 | `pipenv run pip freeze` |
기존 `requirements.txt` 로부터 패키지 정보 읽어와서 설치 | `pipenv install -r path/to/requirements.txt` | 실행하는 path 에 requirements.txt 가 


### 패키지간 의존성 충돌 발생 시

- 문제가 되는 패키지만 단일 install 시도
- 의존성 충돌을 발생시키는 패키지의 호환 버전을 확인하여 수동 설치


---

[목록으로](https://shiwoo-park.github.io/blog/kor)
