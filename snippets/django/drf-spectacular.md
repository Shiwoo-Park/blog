# drf-spectacular

API-Spec 관리를 위한 패키지

## setting

```py
# API Spec 관련 설정 (drf-spectacular 패키지)
from baro.enums.environment import Environment

SPECTACULAR_TAG_DICT = {
    # 서비스별 기본 Tag 지정
    "BARO_WEB": "Baro Web",
    "DODO_WEB": "Dodo Web",
    "BARO_COMMON": "Common",
}


SPECTACULAR_SETTINGS = {
    "TITLE": "나의앱 api-v2",
    "DESCRIPTION": "나의앱 API Spec 문서",
    "VERSION": "1.0.0",
    # 3.1.0 으로 업그레이드 시 모바일쪽 파싱 모듈에서 호환오류 발생함으로 호환성 확인 전엔 3.0.0 으로 고정
    "OAS_VERSION": "3.0.0",
    "SERVE_INCLUDE_SCHEMA": False,  # drf-spectacular endpoint 들을 API Spec 문서에 포함할지 여부
    # "ENFORCE_NON_BLANK_FIELDS": True,  # 기본으로 추가되는 minLength 활성화 여부
    # "COMPONENT_SPLIT_REQUEST": False,  # request body 를 별도의 컴포넌트로 분리
    # "ENABLE_LIST_MECHANICS_ON_NON_2XX": True,
    # "COMPONENT_NO_READ_ONLY_REQUIRED": True,  # 읽기 전용 필드를 필수 필드 목록에서 제외
    # "SCHEMA_PATH_PREFIX": r"/dodo/*",  # 태그 추출 시 생략할 prefix 를 regex 로 지정
    # 참고 https://github.com/tfranzel/drf-spectacular/issues/1210
    "COMPONENT_NO_READ_ONLY_REQUIRED": True,  # False 일 경우 read_only일 경우 모든설정을 무시하고 required True로 설정됨
    "PREPROCESSING_HOOKS": ["baro.drf_spectacular.hooks.preprocess_schema"],
    "POSTPROCESSING_HOOKS": [
        "baro.drf_spectacular.hooks.postprocess_schema",
    ],
    "DEFAULT_API_CONSUMES": ["application/json"],  # Default Content-Type for request
    "DEFAULT_API_PRODUCES": ["application/json"],  # Default Content-Type for response
    "BARO_TEST_ENV_PAGE_CACHE_TTL": 60 * 10,  # 10분
    "SCHEMA_COERCE_PATH_PK_SUFFIX": False,
    "TAGS": [
        {
            "name": "default",
            "description": "기타 분류되지 않은 API",
        },
        {
            "name": SPECTACULAR_TAG_DICT["BARO_WEB"],
            "description": "나의앱1",
        },
        {
            "name": SPECTACULAR_TAG_DICT["DODO_WEB"],
            "description": "나의앱2",
        },
    ],
    # swagger openapi 확장설정 (개별 스키마에 영향)
    # https://swagger.io/specification/#specification-extensions
    "EXTENSIONS_INFO": {},
    # swagger 최상위 스펙 설정 (전체 스키마에 영향)
    # https://swagger.io/specification/#specification-extensions
    "EXTENSIONS_ROOT": {
        # 그룹 수직 관계 설정 (1 depth 만 가능)
        "x-tagGroups": [
            {
                "name": "MY_APP_1",
                "tags": [
                    SPECTACULAR_TAG_DICT["BARO_WEB"],
                ],
            },
            {
                "name": "MY_APP_2",
                "tags": [
                    SPECTACULAR_TAG_DICT["DODO_WEB"],
                ],
            },
            {
                "name": "Common",
                "tags": [
                    SPECTACULAR_TAG_DICT["BARO_COMMON"],
                    "auth",
                    "COMMON",
                    "PROMOTION",
                    "me",
                ],
            },
            {
                "name": "Others",
                "tags": ["default"],
            },
        ],
    },
    # ------------------------------------------------------------------------------
    # Custom 설정 (prefix: BARO_)
    # ------------------------------------------------------------------------------
    # API Spec 페이지를 제공할 배포환경 지정
    "BARO_ALLOWED_ENV_LIST": [
        Environment.LOCAL.code,
        Environment.DEVELOPMENT_1.code,
        Environment.STAGE.code,
    ],
    # API Spec 제공할 endpoint 지정
    # - A-Z 알파벳순으로 추가
    # - 단일 endpoint: BARO_INCLUDE_URLS 에 추가
    # - 패턴으로 여러 endpoint: BARO_INCLUDE_URL_REGEX 에 추가
    "BARO_INCLUDE_URLS": [
        # "/api/v1/path1",  # example
        "/auth/token",
    ],
    "BARO_INCLUDE_URL_REGEX": [
        # examples
        # r"^/api/v1/regex_path/\d+/$",
        # r"^/barolives*",
        # --------------------
        r"^/app*",
    ],
}

```

## hook

```py
import logging
import re

from django.conf import settings

logger = logging.getLogger("drf_spectacular")


def preprocess_schema(endpoints):
    """
    스키마를 생성하기 전에 실행되는 Hook
    - 스키마 페이지에 포함시킬 endpoint 를 필터링 한다.
    """
    try:
        # URL 하나씩 직접 지정
        included_paths = settings.SPECTACULAR_SETTINGS["BARO_INCLUDE_URLS"]
        # URL 여러개를 Regex 로 지정
        included_regexes = settings.SPECTACULAR_SETTINGS["BARO_INCLUDE_URL_REGEX"]

        def is_included(path):
            if any(included_path == path for included_path in included_paths):
                return True
            if any(re.match(pattern, path) for pattern in included_regexes):
                return True
            return False

        filtered_endpoints = []
        for path, path_regex, method, callback in endpoints:
            if is_included(path):
                endpoint_info = (path, path_regex, method, callback)
                filtered_endpoints.append(endpoint_info)

        return filtered_endpoints
    except Exception as e:
        logger.error(f"Error processing endpoints: {e}")
        raise e


def postprocess_schema(result, generator, request, public):
    try:
        # Postprocess the schema and handle potential errors

        # API Spec 페이지에서 좌측 메뉴 중 그 어떤 곳에도 소속되지 못한 endpoint들0
        # - default 메뉴 하위로 포함시킴
        # - 태그 list 교집합으로 체크
        managed_tags = set(settings.SPECTACULAR_TAG_DICT.values())
        for path, path_item in result["paths"].items():
            for method, operation in path_item.items():
                tags = operation.get("tags", [])
                if len(set(tags).intersection(managed_tags)) == 0:
                    operation["tags"] = ["default"]

        return result
    except Exception as e:
        logger.error(f"Error postprocessing schema: {e}")
        raise e
```

## util

```py
from typing import Type

from drf_spectacular.utils import OpenApiExample

from baro.choices_enum import ChoicesEnum


class DRFSpectacularUtil:
    @staticmethod
    def get_api_param_examples(enum_cls: Type[ChoicesEnum]):
        return [
            OpenApiExample(
                enum.code,  # example 의 고유식별자
                value=enum.code,
                summary=enum.text,
            )
            for enum in enum_cls
        ]
```

## ViewSet 의 스키마

```py
from django.conf import settings
from drf_spectacular.utils import (
    extend_schema,
    extend_schema_view,
    inline_serializer,
    OpenApiParameter,
    OpenApiExample,
)
from rest_framework import serializers

from apps.coupon.models.coupon import Coupon
from apps.coupon.serializers import MyCouponItemSerializer
from baro.utils2.spectacular import DRFSpectacularUtil


class _WholesalerInfoSerializer(serializers.Serializer):
    id = serializers.IntegerField(label="도매ID")
    type = serializers.CharField(label="도매 타입")
    url = serializers.URLField(label="도매 URL", required=False, allow_null=True)
    delivery_coupon_count = serializers.IntegerField(label="도매 배송쿠폰 개수")


class _WholesalerInfosSerializer(serializers.Serializer):
    """
    "236": {
        "id": 236,
        "delivery_coupon_count": 0,
        "type": "QUASIDRUG",
        "url": "/quasi-drug-mall/236"
    },
    """

    도매_ID = _WholesalerInfoSerializer(label="도매 정보")


user_coupon_item_viewset_schema = extend_schema_view(
    list=extend_schema(
        methods=["GET"],
        tags=[
            settings.SPECTACULAR_TAG_DICT["BARO_APP"],
            settings.SPECTACULAR_TAG_DICT["BARO_WEB"],
        ],
        operation_id="나의 쿠폰 목록",
        parameters=[
            OpenApiParameter(
                name="date_type",
                description="날짜필터 기준 (created_at, used_at, expiry_date)",
                required=False,
                type=str,
            ),
            OpenApiParameter(
                name="start_date",
                description="검색 시작날짜 (ex. 2025-01-01)",
                required=False,
                type=str,
            ),
            OpenApiParameter(
                name="end_date",
                description="검색 종료 날짜 (ex. 2025-12-01)",
                required=False,
                type=str,
            ),
            OpenApiParameter(
                name="type",
                description="쿠폰 타입",
                required=False,
                type=str,
                enum=Coupon.Type.choices(),
                examples=DRFSpectacularUtil.get_api_param_examples(Coupon.Type),
            ),
            OpenApiParameter(
                name="tab",
                description="선택한 쿠폰내역의 탭 (usable, used, expired)",
                required=False,
                type=str,
            ),
            OpenApiParameter(
                name="code",
                description="쿠폰 코드",
                required=False,
                type=str,
            ),
            OpenApiParameter(
                name="q",
                description="Search by coupon name",
                required=False,
                type=str,
            ),
        ],
        responses={
            200: inline_serializer(
                name="UserCouponListResponse",
                fields={
                    "total": serializers.IntegerField(label="전체 쿠폰 개수"),
                    "per_page": serializers.IntegerField(label="페이지당 쿠폰 개수"),
                    "current_page": serializers.IntegerField(label="현재 페이지"),
                    "last_page": serializers.IntegerField(label="마지막 페이지"),
                    "items": MyCouponItemSerializer(many=True),
                    "wholesalers_info": _WholesalerInfosSerializer(),
                },
            )
        },
    ),
)
```