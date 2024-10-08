# 파이썬 프로젝트 requirements.txt 에서 미사용 패키지 찾아내기

> 날짜: 2024-03-20

파이썬 프로젝트의 `requirements.txt` 파일에서 현재 사용하지 않는 패키지를 찾아내어 삭제하는 과정은 주로 수동으로 이루어지기 쉽지만, 몇 가지 도구와 절차를 사용하여 이 과정을 자동화하거나 쉽게 만들 수 있습니다. 여기에는 `pipreqs`, `pip-check` 같은 도구들이 포함됩니다. 가장 일반적인 접근 방법은 다음과 같습니다:

### 1. `pipreqs` 사용하기

`pipreqs`는 현재 프로젝트에서 실제로 사용되고 있는 패키지를 분석하여 새로운 `requirements.txt`를 생성하는 도구입니다. 이 방법은 프로젝트 내의 모든 파일을 스캔하여 실제로 사용되는 패키지를 찾아냅니다.

```bash
pip install pipreqs
pipreqs /path/to/your/project
```

이렇게 하면 `/path/to/your/project` 경로에 새로운 `requirements.txt` 파일이 생성됩니다. 이 파일에는 실제로 사용되는 패키지만 명시되어 있습니다. 그런 다음 원래의 `requirements.txt` 파일과 비교하여 사용되지 않는 패키지를 확인할 수 있습니다.

### 2. `pip-check` 사용하기

`pip-check`는 설치된 패키지와 그 의존성을 보여줍니다. 설치되어 있지만 사용되지 않는 패키지를 찾는 데 유용할 수 있습니다.

```bash
pip install pip-check
pip-check
```

이 도구는 설치된 패키지의 사용 여부를 직접 알려주지는 않지만, 프로젝트에서 사용되지 않는 패키지를 수동으로 식별하는 데 도움을 줄 수 있습니다.

결론적으로, 프로젝트에서 더 이상 사용하지 않는 패키지를 식별하고 제거하는 과정은 프로젝트의 성능을 최적화하고, 관리를 용이하게 만들어 줄 수 있습니다. 그러나 어떤 패키지를 제거할지 결정하기 전에 그 패키지가 프로젝트의 다른 부분에 의해 간접적으로 사용되고 있지 않은지 주의 깊게 확인해야 합니다.

---

[목록으로](https://shiwoo-park.github.io/blog)
