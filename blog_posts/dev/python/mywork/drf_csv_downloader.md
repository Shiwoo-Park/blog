---
layout: post
title: "Django + DRF + Celery 에서 사용가능한 대용량 CSV 다운로드 모듈 – CSVDownloader 소개"
date: 2025-06-08
categories: [python, django, celery]
---

# 📄 Django + DRF + Celery 에서 사용가능한 대용량 CSV 다운로드 모듈 – `CSVDownloader` 소개

> 날짜: 2025-06-08

[목록으로](https://shiwoo-park.github.io/blog)

---

## 1. 배경 및 목적

CSV 다운로드 기능은 관리 서비스에서 자주 사용되며, 필터링, 정렬, 포맷 제어, 비동기 처리, 파일 업로드 등 복잡한 요구사항이 많다. CSVDownloader는 이런 반복 작업을 공통화하여 빠르고 안정적으로 처리하기 위해 만들어졌다.

내가 만든 CSVDownloader는 아래의 기능을 제공한다.

* **목록에 표시되는 리스트 결과(특정필드 필터가 적용된)를 보이는 그대로 다운로드 가능 (query_param + queryset + FilterSet)**
* **모델 데이터 그대로가 아닌 요청 조건에 따라 좀 더 많은 정보를(join) 원하는 형태로 가공 (queryset + DRF serializer)**
* **원하는 정렬 및 적정 다운로드 속도 제공 (정렬필드 지정 및 다운로드 가능 row 수 제한)**
* **Celery 기반 비동기 다운로드 지원**
* **S3 업로드 및 다운로드 URL 제공**

`CSVDownloader`는 실무에서 필요한 CSV 다운로드 기능을 하나의 클래스로 깔끔하게 캡슐화한 유틸리티이다.

Django + DRF 기반에서 관리 화면, 어드민툴, 백오피스 다운로드 기능을 구현할 때 빠르게 적용할 수 있고,
S3 업로드까지 자동으로 처리해주는 구조로 대량 데이터 처리도 무리 없이 대응 가능하다.

---

## 2. 코드 소개

`CSVDownloader`는 다음 컴포넌트들로 구성됩니다:

* `queryset`, `filterset_class`, `serializer_class` 기반으로 대상 데이터 설정
* 요청 param 필터링 → 정렬 → row 제한 → CSV 직렬화 → 출력
* 결과는 S3 업로드 or StreamingHttpResponse로 반환
* Celery task ID가 있으면 row 진행률도 주기적으로 업데이트

```python
import csv
from io import StringIO
from typing import List

from django.conf import settings
from django.http import StreamingHttpResponse
from django.utils import timezone
from rest_framework.exceptions import ValidationError


def set_progress(task_id, progress, total):
    """Celery task 의 진행현황 정보를 redis 에 set 해주는 함수"""
    try:
        cache.set(
            CacheKey.CELERY_TASK_PROGRESS.get(task_id=task_id),
            {"progress": progress, "total": total},
            CacheKey.CELERY_TASK_PROGRESS.timeout,
        )
    except Exception as e:
        logger.warning(f"비동기 처리 set_process 오류: {e}")


def upload_s3(temp_path: str, upload_path: str, bucket: str) -> str:
    try:
        s3_client = AWSS3ClientService.get_client()
        s3_client.upload_file(temp_path, bucket, upload_path)

        download_url = AWSS3ClientService.generate_presigned_url(
            "get",
            bucket,
            upload_path,
            expires_in=24 * 60 * 60,
        )
        return download_url
    except Exception as e:
        logger.error(f"s3 업로드 실패 {e}")
        raise


class CSVDownloader:
    """
    CSV 다운로드 시, 좀 더 쉽고 빠르게 개발하기위하여
    Django + DRF + Celery 의 유용한 기능을 최대한 활용하여 만든 모듈

    - 이 클래스를 상속받은 하위 클래스를 만들고
    - 필요시 class 속성을 override 하여
    - 원하는 데이터를 원하는 방식으로 CSV 출력하여 사용하세요
    """
 
    filterset_class = None  # queryset 필터 클래스
    query_params = None  # GET request 의 query_param 그대로 전달
    queryset = None   # Django ORM 의 QuerySet 객체 (DB 에서 불러올 데이터)
    ordering_fields = None  # 정렬 조건 ["-id", "-created_at"]
    serializer_class = None  # CSV 데이터용 시리얼라이져 클래스
    value_convert_map = {  # CSV 로 출력할때 자동 변환할 필드 데이터
        "None": "-",
        "True": "Y",
        "False": "N",
    }

    # 기타 세팅
    allow_row_limit = 100000
    s3_bucket = settings.AWS_STORAGE_PRIVATE_BUCKET_NAME
    s3_path = None
    file_prefix = "csv_download"  # 파일명
    celery_task_id = None  # progress 체킹용 (redis 에 저장)
    celery_progress_row_offset = 50  # progress 데이터를 갱신할 처리 row 개수 기준

    def __init__(self, *args, **kwargs):
        self.user_id = kwargs.get("user_id")
        self.query_params = kwargs.get("query_params", {})
        self.filterset_class = kwargs.get("filterset_class", self.filterset_class)
        self.serializer_class = kwargs.get("serializer_class", self.serializer_class)
        self.value_convert_map = kwargs.get("value_convert_map", self.value_convert_map)
        self.allow_row_limit = kwargs.get("allow_row_limit", self.allow_row_limit)
        self.file_prefix = kwargs.get("file_prefix", self.file_prefix)
        self.s3_bucket = kwargs.get("s3_bucket", self.s3_bucket)

        if self.s3_path is None:
            today = timezone.now().strftime("%Y%m%d")
            self.s3_path = kwargs.get("s3_path", f"download/{today}/csv")

        queryset = kwargs.get("queryset")
        if queryset is None:
            raise ValidationError("queryset is required")
        self.queryset = self.get_queryset(queryset)

        self.celery_task_id = kwargs.get("celery_task_id")
        if self.celery_task_id:
            set_progress(self.celery_task_id, 1, 100)

    def get_queryset(self, queryset):
        if self.filterset_class:
            filterset = self.filterset_class(self.query_params, queryset=queryset)
            queryset = filterset.qs
        requested_record_count = queryset.count()

        if self.allow_row_limit and requested_record_count > self.allow_row_limit:
            raise ValidationError(
                f"다운로드 한도 초과: 최대 {self.allow_row_limit} 개 까지 조회 가능합니다. "
                f"(요청 레코드 수: {requested_record_count})"
            )

        if self.ordering_fields:
            queryset = queryset.order_by(*self.ordering_fields)
        else:
            queryset = queryset.order_by("-pk")

        return queryset

    def get_result_as_download_url(self) -> str:
        """업로드한 CSV 파일의 다운로드 URL 리턴"""
        csv_content = self.generate_csv()
        server_file_path = f"{settings.TMP_FILE_DIR}/{self.get_filename()}"
        s3_upload_path = f"{self.s3_path}/{self.get_filename()}"
        with open(server_file_path, "w", newline="", encoding="utf-8-sig") as f:
            f.write(csv_content.getvalue())

        download_url = upload_s3(server_file_path, s3_upload_path, self.s3_bucket)
        return download_url

    def get_result_as_streaming_response(self) -> StreamingHttpResponse:
        """CSV 파일을 스트리밍 응답으로 리턴"""
        response = StreamingHttpResponse(
            (line + "\n" for line in self.generate_csv_lines()),  # generator 사용
            content_type="text/csv"
        )
        response["Content-Disposition"] = f'attachment; filename="{self.get_filename()}"'
        return response

    def generate_csv_lines(self):
        yield ",".join(self.get_csv_headers())
        for idx, item in enumerate(self.queryset.iterator()):  # iterator() 사용
            serializer = self.get_serializer_class()(item)
            yield ",".join(self.get_csv_row(serializer.data))

            if self.celery_task_id and idx % self.celery_progress_row_offset == 0:
                set_progress(self.celery_task_id, int(idx / len(self.queryset) * 100), 100)

    def generate_csv(self) -> StringIO:
        csv_file = StringIO()
        writer = csv.writer(csv_file, quoting=csv.QUOTE_ALL)

        headers = self.get_csv_headers()
        writer.writerow(headers)

        total = len(self.queryset)
        for idx, item in enumerate(self.queryset):
            serializer_class = self.get_serializer_class()
            serializer = serializer_class(item)
            row = self.get_csv_row(serializer.data)
            writer.writerow(row)

            if (
                idx % self.celery_progress_row_offset == 0
            ) and self.celery_task_id is not None:
                set_progress(self.celery_task_id, int(idx / total * 100), 100)

        csv_file.seek(0)
        return csv_file

    def get_serializer_class(self):
        if self.serializer_class is None:
            raise NotImplementedError("serializer_class is required")
        return self.serializer_class

    def get_filename(self):
        timestamp = timezone.now().strftime("%Y%m%d_%H%M%S")
        return f"{self.file_prefix}_{timestamp}.csv"

    def get_csv_headers(self) -> List[str]:
        serializer_class = self.get_serializer_class()
        serializer = serializer_class()
        headers = []
        for field_name, field in serializer.fields.items():
            if field.label is not None:
                headers.append(str(field.label))
            elif hasattr(field, "Meta") and hasattr(field.Meta, "model"):
                model_field = field.Meta.model._meta.get_field(field_name)
                headers.append(str(model_field.verbose_name))
            else:
                headers.append(field_name)
        return headers

    def get_csv_row(self, item) -> List[str]:
        row_data = []
        for value in item.values():
            str_val = str(value)
            if str_val in self.value_convert_map:
                converted_val = self.value_convert_map[str_val]
                row_data.append(converted_val)
            else:
                row_data.append(str_val)

        return row_data
```

---

## 3. 사용법 (예제 코드)

### 🎯 View 에서 스트리밍 응답으로 직접 다운로드

```python
from myapp.csv_downloader import CSVDownloader

def download_view(request):
    downloader = CSVDownloader(
        user_id=request.user.id,
        queryset=MyModel.objects.all(),
        filterset_class=MyModelFilter,
        serializer_class=MyModelSerializer,
        query_params=request.GET,
    )
    return downloader.get_result_as_streaming_response()
```

### ☁️ Celery Task 에서 S3 업로드 후 URL 리턴

- Celery task 에서는 set_progress() 를 통해 진행율 지속 업데이트
- 프론트에서 celery task 가 끝날때까지 주기적으로 task 상태 체크 하다가
- 작업이 완료되면 응답된 URL 직접 액세스 하여 다운로드

```python
class CMSMissionRewardLogCSVDownloader(CSVDownloader):
    filterset_class = CMSMissionRewardLogFilter
    file_prefix = "cms_mission_reward_log_csv_download"
    s3_bucket = settings.AWS_STORAGE_PRIVATE_BUCKET_NAME
    serializer_class = CMSMissionRewardLogSerializerForCSV


@shared_task()
def mission_reward_log_csv_download(query_params: dict):
    queryset = (
        MissionRewardLog.objects.all()
        .select_related("user", "mission", "reward")
        .order_by("-id")
    )

    download_url = CMSMissionRewardLogCSVDownloader(
        query_params=query_params,
        queryset=queryset,
        celery_task_id=current_task.request.id,
    ).get_result_as_download_url()

    return {"file_url": download_url}
```

---

## 4. 동작원리

1. **초기화**

   * 전달받은 queryset에 대해 filterset으로 필터링
   * 레코드 수가 `allow_row_limit` 초과 시 오류 발생
   * 정렬 옵션(ordering\_fields) 적용

2. **CSV 생성**

   * `serializer_class`를 통해 헤더 생성
   * 각 row를 serializer를 통해 변환
   * `True`, `False`, `None`은 커스텀 문자열로 변환 (`value_convert_map`)
   * `celery_task_id`가 있으면 일정 row마다 `set_progress()` 호출

3. **결과 반환**

   * S3 업로드 → URL 리턴
   * 또는 StreamingHttpResponse로 직접 전송

---

## 5. 장점 및 단점

### ✅ 장점

| 항목     | 설명                                         |
| ------ | ------------------------------------------ |
| 범용성    | filterset, serializer 주입 방식으로 어디서든 사용 가능   |
| 확장성    | 진행률 트래킹, S3 업로드, 파일 이름 등 커스터마이징 가능         |
| 일관성    | DRF serializer를 그대로 사용하여 API 응답과 동일한 포맷 유지 |
| 실무 최적화 | row 제한, label 헤더, value 변환 등 실제 운영에 적합     |

---

### ❗ 단점

| 항목                                       | 설명                                    |
| ---------------------------------------- | ------------------------------------- |
| 메모리 기반 처리                                | 전체 CSV를 메모리에 올리는 구조 (10만건 이상 시 유의 필요) |
| serializer 성능                            | 필드가 복잡하거나 수십만 건 이상일 경우 느려질 수 있음       |
| row 에러 처리 없음                             | 특정 row 직렬화 에러 발생 시 전체 실패 가능성          |

---

[목록으로](https://shiwoo-park.github.io/blog)
