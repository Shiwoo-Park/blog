---
layout: post
title: "ApiSelect용 Django DRF 베이스 코드"
date: 2024-01-01
categories: [django, drf, api]
---

ApiSelect 컴포넌트를 사용하기 위한 Django REST Framework 백엔드 엔드포인트 생성 기반 코드입니다. `snippets/js/api-select.md`와 함께 사용할 수 있으며, select 형식의 UI를 지원하는 Backend endpoint를 생성할 수 있습니다.

---

## 1. Base Code

ApiSelect 컴포넌트를 위한 기본 Serializer와 APIView 클래스입니다.

```python
from collections import OrderedDict
from typing import Tuple

from django.core.exceptions import ObjectDoesNotExist
from django.db.models import Model, Q
from rest_framework import serializers
from rest_framework.exceptions import APIException
from rest_framework.generics import ListAPIView
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from baro.choices_enum import ChoicesEnum
from baro.pagination import LimitOffsetPaginationSize10


class BaseApiSelectSerializer(serializers.Serializer):
    """
    <ApiSelect> 컴포넌트용 응답데이터를 제공하는 serializer 추상클래스
    - 현재 CMS 에만 존재
    """

    label = serializers.SerializerMethodField()
    value = serializers.SerializerMethodField()

    def get_label(self, obj: Model) -> str:
        """
        select 박스에서 표시될 문자열

        [주의사항]
        *** 검색어로 입력한 텍스트가 무조건 리턴 텍스트에 포함되어야함 ***
        만약 검색어가 리턴문자열에 존재하지 않으면 응답데이터는 있더라도 UI 상으로 보이지 않을 수 있음!!!
        """

        return str(obj)  # 해당 모델의 __str__() 리턴값 활용

    def get_value(self, obj: Model) -> str:
        return obj.pk


class DefaultApiSelectSerializerForEnum(BaseApiSelectSerializer):
    def get_value(self, obj) -> str:
        return obj[0]

    def get_label(self, obj) -> str:
        return obj[1]


class BaseApiSelectAPIView(ListAPIView):
    """
    ApiSelect 컴포넌트을 사용하기 위한 연동 API 의 기본 틀
    - 현재는 해당 컴포넌트가 CMS 에만 있음
    - 데이터를 동적으로 불러와 입력하기위한 API 생성시 활용

    [사용법1. queryset 지정하기]
    DB 테이블에서 데이터를 불러와서 보여줘야 하는 경우 활용
    1. queryset 지정 또는 get_queryset 함수 override
    2. 검색할때 사용할 필드를 search_fields 에 지정
    3. serializer_class 에 BaseSelectDataSerializer 를 상속받은 시리얼라이져 만들어서 매핑

    [사용법2. enum 지정하기]
    enum 클래스 데이터를 불러와서 보여줘야 하는 경우 활용
    1. enum_class 에 ChoicesEnum 을 상속받은 enum 클래서 지정
    """

    pagination_class = LimitOffsetPaginationSize10
    permission_classes = [IsAuthenticated]
    serializer_class = None
    queryset = None
    search_fields = []
    enum_class = None
    swagger_schema = None

    boolean_true_values = ["true", "y", "Y", "O"]
    boolean_false_values = ["false", "n", "N", "X"]
    empty_values = ["", "null", "undefined"]

    def get_serializer_class(self):
        if self.serializer_class is None:
            if self.queryset is not None:
                return BaseApiSelectSerializer
            elif self.enum_class is not None:
                return DefaultApiSelectSerializerForEnum
        return super().get_serializer_class()

    def get_clean_value(self, value: str, key: str = None) -> Tuple:
        """
        query param 으로 넘어오는 key, value 를 필터 가능한 유효한 데이터로 정제

        - value 에 콤마가 들어있는 경우 {field}__in: [1,2] 처리
        - value 가 boolean 텍스트인경우 bool 타입으로 변경
        """
        if value in self.boolean_true_values:
            return key, True

        if value in self.boolean_false_values:
            return key, False

        if key is not None:
            if "," in value:  # value = 111,222,333
                return f"{key}__in", [
                    self.get_clean_value(elem)[1] for elem in value.split(",")
                ]

        return key, value

    def filter_queryset(self, queryset):
        query_params = self.request.query_params.dict()
        search = query_params.pop("search", "").strip()

        if len(search) > 0 and self.queryset is not None:
            pk_filter_applied = False
            try:
                # 검색어="#{숫자}" 으로 입력 시 PK 기준 매칭
                if str(search).startswith("#"):
                    primary_key = int(search[1:])
                    queryset = queryset.filter(pk=primary_key)
                    if not queryset.exists():
                        raise ObjectDoesNotExist
                    pk_filter_applied = True
            except (TypeError, IndexError, ValueError, ObjectDoesNotExist):
                pass

            if not pk_filter_applied:
                # 일반 검색으로 전환
                or_filter_info = Q()
                for field in self.search_fields:
                    or_filter_info |= Q(**{f"{field}__icontains": search})
                queryset = queryset.filter(or_filter_info)

        # 기타 유효 query_params 에 대하여 equal 필터 적용
        valid_model_fields = set()
        valid_model_field_prefixes = set()
        for field in queryset.model._meta.get_fields():
            if field.is_relation:
                valid_model_fields.add(f"{field.name}_id")
                valid_model_field_prefixes.add(f"{field.name}")
            else:
                valid_model_fields.add(field.name)

        for field_name, value in query_params.items():
            if (field_name in valid_model_fields) or (
                "__" in field_name
                and field_name.split("__")[0] in valid_model_field_prefixes
            ):
                cleaned_key, cleaned_val = self.get_clean_value(value, field_name)
                if cleaned_val in self.empty_values:
                    continue
                queryset = queryset.filter(**{cleaned_key: cleaned_val})

        return queryset

    def get_no_pagination_default_response(self, results) -> Response:
        """
        pagination 이 없을때도 동일한 포맷으로 리턴해주기 위한 기본 응답포맷
        """
        return Response(
            data=OrderedDict(
                [
                    ("count", len(results)),
                    ("next", None),
                    ("previous", None),
                    ("results", results),
                ]
            )
        )

    def get_response_by_queryset(self, queryset=None) -> Response:
        if not issubclass(self.get_serializer_class(), BaseApiSelectSerializer):
            raise TypeError(
                "serializer_class 를 지정해주세요: "
                "반드시 BaseSelectDataResponseSerializer 을 상속받아야 합니다."
            )

        if queryset:
            queryset = self.filter_queryset(queryset)
        else:
            queryset = self.filter_queryset(self.get_queryset())

        page = self.paginate_queryset(queryset)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)

        serializer = self.get_serializer(queryset, many=True)
        return self.get_no_pagination_default_response(serializer.data)

    def get_response_by_enum(self) -> Response:
        if not issubclass(self.enum_class, ChoicesEnum):
            raise TypeError("enum_class 는 반드시 ChoicesEnum 을 상속받아야 합니다.")

        self.serializer_class = DefaultApiSelectSerializerForEnum
        search = self.request.query_params.get("search")
        serializer = self.get_serializer(
            self.enum_class.choices(text_contains=search), many=True
        )
        return self.get_no_pagination_default_response(serializer.data)

    def list(self, request, *args, **kwargs):

        if self.queryset is not None:
            return self.get_response_by_queryset()

        elif self.enum_class:
            return self.get_response_by_enum()

        else:
            raise APIException(
                "self.queryset 또는 self.enum_class 둘중 하나를 반드시 지정해주세요."
            )
```

---

## 2. ApiView 생성 예제

실제 사용 예제입니다. BaseApiSelectAPIView를 상속받아 커스텀 Serializer와 함께 사용합니다.

```python
class CMSInventoryAPISelectSerializer(BaseApiSelectSerializer):
    def get_label(self, obj: Inventory) -> str:
        wholesaler_info = f"[{obj.whole_saler.account_type_display} | {obj.whole_saler.type_display}] {obj.whole_saler.name}"
        additional_infos = []
        if obj.kd_code:
            additional_infos.append(f"KD:{obj.kd_code}")
        if obj.edi_code:
            additional_infos.append(f"EDI:{obj.edi_code}")

        if additional_infos:
            return f"[#{obj.id}] {obj.name} / {wholesaler_info} ({', '.join(additional_infos)})"

        return f"[#{obj.id}] {obj.name} / {wholesaler_info}"


class CMSInventoryAPISelectAPIView(BaseApiSelectAPIView):
    permission_classes = [IsAdminUser]
    queryset = Inventory.objects.all().select_related("whole_saler")
    search_fields = ["name"]
    serializer_class = CMSInventoryAPISelectSerializer
```
