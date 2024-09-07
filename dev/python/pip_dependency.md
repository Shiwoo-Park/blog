# 특정 pip 패키지의 다른 패키지 의존성 확인하기

> 날짜: 2024-03-20

특정 pip 패키지의 패키지 의존성 트리를 보고 싶다면 `pipdeptree` 라는 도구를 사용할 수 있습니다. `pipdeptree`는 설치된 Python 패키지의 의존성 트리를 시각적으로 표시해주는 유틸리티입니다. 이 도구는 각 패키지가 의존하는 다른 패키지와 그 관계를 잘 이해할 수 있게 도와줍니다.

### pipdeptree 설치하기

`pipdeptree`를 사용하기 위해서는 먼저 이를 설치해야 합니다. 다음 명령어로 설치할 수 있습니다:

```bash
pip install pipdeptree
```

### 패키지 의존성 트리 보기

`pipdeptree`가 설치되었다면, 다음과 같이 명령어를 실행하여 설치된 전체 패키지의 의존성 트리를 볼 수 있습니다:

```bash
pipdeptree
```

특정 패키지에 대한 의존성 트리만 보고 싶다면, `-p` 또는 `--package` 옵션을 사용하여 패키지 이름을 지정할 수 있습니다. 예를 들어, `requests` 패키지의 의존성 트리를 보고 싶다면 다음과 같이 실행합니다:

```bash
pipdeptree -p requests
```

또는

```bash
pipdeptree --package requests
```

이 명령은 `requests` 패키지와 그 패키지가 의존하는 모든 하위 패키지들의 의존성 관계를 보여줍니다.

### 추가적인 옵션들

`pipdeptree`는 여러 유용한 옵션을 제공합니다. 예를 들어, `-r` 또는 `--reverse` 옵션을 사용하면, 특정 패키지를 의존하는 상위 패키지들의 리스트를 볼 수 있습니다. 이는 어떤 패키지가 특정 패키지에 의존하는지 역추적하고 싶을 때 유용합니다.

```bash
pipdeptree -r -p requests
```

자세한 옵션들은 `pipdeptree --help` 명령을 실행하여 확인할 수 있습니다.

---

[목록으로](https://shiwoo-park.github.io/blog)
