---
layout: post
title: "Django Model ViewSet"
date: 2024-01-01
categories: [django, drf, viewset]
---

Django REST Framework의 ModelViewSet을 활용한 예제입니다. EagerLoadingMixin과 ExcelDownloadMixin을 사용하여 효율적인 쿼리와 엑셀 다운로드 기능을 구현합니다.

---

## 1. ViewSet 구현

ModelViewSet을 상속받아 구현한 예제입니다.

```python
import logging

from django.db import transaction
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework import status, serializers
from rest_framework.decorators import action
from rest_framework.exceptions import ValidationError
from rest_framework.filters import OrderingFilter
from rest_framework.permissions import IsAdminUser
from rest_framework.response import Response
from rest_framework.viewsets import ModelViewSet

from apps.partner.services.base import get_partner_info
from apps.product.models2.wholesaler import WholeSaler
from baro.consts import HexColor
from baro.mixins import EagerLoadingMixin
from baro.mixins2.xls_download import ExcelDownloadMixin
from baro.permissions import IsPartnerAdmin
from dodo_apps.inven.filters.dodo_inven import DodoInventoryFilter
from dodo_apps.inven.models.dodo_inven import DodoInventory
from dodo_apps.inven.serializers.cms_dodo_inven import (
    CMSDodoInventoryListSerializer,
    CMSDodoInventoryDetailSerializer,
)
from dodo_apps.inven.serializers.dodo_inven import (
    DodoInventoryListSerializer,
    DodoInventoryDetailSerializer,
    DodoInventoryExcelSerializerForERPSyncWholesaler,
    DodoInventoryExcelSerializerForSelfManageWholesaler,
)
from dodo_apps.inven.services.dodo_inven import DodoInventoryService

logger = logging.getLogger(__name__)


class DodoInventoryViewSet(EagerLoadingMixin, ExcelDownloadMixin, ModelViewSet):
    permission_classes = [IsPartnerAdmin]
    queryset = DodoInventory.objects.all()
    queryset_select_related_list = ["product", "wholesaler"]
    filter_backends = [DjangoFilterBackend, OrderingFilter]
    filterset_class = DodoInventoryFilter
    ordering_fields = ["id"]
    ordering = ["-id"]
    wholesaler = None
    excel_download_header_bg_color = HexColor.BLUE_1.code

    def filter_queryset(self, queryset):
        try:
            return super().filter_queryset(queryset)
        except ValueError as ve:
            logger.warning(
                "도도팜 재고 목록 조회: 입력된 필터 정보 오류 - %s",
                self.request.query_params,
            )
            raise serializers.ValidationError("필터링 정보가 잘못 되었습니다")

    def get_queryset(self):
        partner = get_partner_info(self.request.user.id)
        self.wholesaler = partner.whole_saler
        queryset = super().get_queryset()
        return queryset.filter(wholesaler=self.wholesaler)

    def get_serializer_context(self):
        context = super().get_serializer_context()
        context["wholesaler"] = self.wholesaler
        return context

    def get_serializer_class(self):
        if self.action == "list":
            return DodoInventoryListSerializer

        return DodoInventoryDetailSerializer

    def get_excel_download_serializer_class(self):
        order_type_enum = WholeSaler.OrderType.get_member(self.wholesaler.order_type)
        if order_type_enum == WholeSaler.OrderType.EXTERNAL_DB_CONNECT:
            for i in range(10):
                self.set_column_bg_color(i, HexColor.GREY_2.code)
            for i in range(11, 16):
                self.set_column_bg_color(i, HexColor.GREY_2.code)
            for i in [10, 16, 17, 18, 19]:
                self.set_column_bg_color(i, HexColor.YELLO_1.code)
            return DodoInventoryExcelSerializerForERPSyncWholesaler
        elif order_type_enum == WholeSaler.OrderType.INTERNAL_DB_CONNECT:
            for i in range(8):
                self.set_column_bg_color(i, HexColor.GREY_2.code)
            for i in range(8, 19):
                self.set_column_bg_color(i, HexColor.YELLO_1.code)
            return DodoInventoryExcelSerializerForSelfManageWholesaler
        else:
            raise ValidationError(f"주문방식이 {order_type_enum.text} 인 도매는 다운로드가 불가합니다.")

    def list(self, request, *args, **kwargs):
        response = super().list(request, *args, **kwargs)
        DodoInventoryService.set_product_data(response.data["items"])
        return response

    def retrieve(self, request, *args, **kwargs):
        response = super().retrieve(request, *args, **kwargs)
        DodoInventoryService.set_product_data([response.data])
        return response

    @action(detail=False, methods=["put"], url_path="bulk-update")
    def bulk_update(self, request, *args, **kwargs):
        """
        여러개 인벤토리 정보를 한번에 수정할 수 있는 API

        - Request Body = Dict List 형태
        - 전부 다 성공 하거나 전부다 실패하도록 처리
        - 입력된 데이터 순서대로 리턴
        """
        data = request.data
        if not isinstance(data, list):
            raise ValidationError("입력 데이터 형식이 잘못되었습니다.")

        request_data_dic = {item["id"]: item for item in data}
        inventories = self.get_queryset().filter(id__in=request_data_dic.keys())
        if len(inventories) == 0:
            raise ValidationError("업데이트할 재고정보를 찾지 못했습니다.")

        updated_objects = []
        updated_fields = set()
        with transaction.atomic():
            for inven in inventories:
                try:
                    serializer = self.get_serializer(
                        inven, data=request_data_dic[inven.id], partial=True
                    )
                    serializer.is_valid(raise_exception=True)
                    for field, value in serializer.validated_data.items():
                        updated_fields.add(field)
                        setattr(inven, field, value)
                except serializers.ValidationError as ve:
                    ve.detail["id"] = inven.id
                    raise ve

            DodoInventory.objects.bulk_update(inventories, fields=list(updated_fields))
            serializer = self.get_serializer(inventories, many=True)
            updated_objects = serializer.data

        return Response({"data": updated_objects}, status=status.HTTP_200_OK)


class CMSDodoInventoryViewSet(DodoInventoryViewSet):
    permission_classes = [IsAdminUser]

    def get_queryset(self):
        return DodoInventory.objects.all().select_related("product", "wholesaler")

    def get_serializer_class(self):
        if self.action == "list":
            return CMSDodoInventoryListSerializer

        return CMSDodoInventoryDetailSerializer

    def get_excel_download_serializer_class(self):
        return DodoInventoryExcelSerializerForERPSyncWholesaler

    def get_object(self):
        inven = super().get_object()
        self.wholesaler = inven.wholesaler
        return inven

```