---
layout: post
title: "Django DRF Serializer"
date: 2024-01-01
categories: [django, drf, serializer]
---

Django REST Framework의 Serializer를 활용한 예제입니다. Mixin을 사용하여 관련 데이터를 포함하고, 동적 필드 처리를 구현합니다.

---

## 1. Serializer 구현

관련 모델 데이터를 포함하는 Serializer 예제입니다.

```python
from typing import Dict

from rest_framework import serializers

from apps.product.models import Product, WholeSaler
from silva.mixins import ModelSerializerMessageMixin
from inven.models.dodo_inven import DodoInventory


class InventoryRelatedDataSerializerMixin(serializers.Serializer):

    product_manufacturer = serializers.CharField(
        source="product.manufacturer", read_only=True
    )
    product_name = serializers.CharField(source="product.name", read_only=True)
    product_type = serializers.CharField(source="product.type_display", read_only=True)

    @staticmethod
    def get_product_field_names():
        return [
            "product_manufacturer",
            "product_name",
            "product_type",
        ]


class DodoInventoryListSerializer(
    InventoryRelatedDataSerializerMixin, serializers.ModelSerializer
):

    is_erp_used = serializers.BooleanField(source="used")

    class Meta:
        model = DodoInventory
        fields = [
            "id",
            "product_id",
            *InventoryRelatedDataSerializerMixin.get_product_field_names(),
            "name",
            "created_at",
            "updated_at",
        ]
        read_only_fields = fields


class DodoInventoryDetailSerializer(
    ModelSerializerMessageMixin,
    InventoryRelatedDataSerializerMixin,
    serializers.ModelSerializer,
):

    product_id = serializers.PrimaryKeyRelatedField(
        queryset=Product.objects.all(), source="product"
    )
    display_qty = serializers.IntegerField(label="노출 재고 초기값(from 프론트)")
    qty_diff = serializers.IntegerField(label="qty 차액(from 프론트)", write_only=True)
    is_erp_used = serializers.BooleanField(source="used")

    class Meta:
        model = DodoInventory
        fields = [
            "id",
            "product_id",
            *InventoryRelatedDataSerializerMixin.get_product_field_names(),
            "name",
            "created_at",
            "updated_at",
        ]

        read_only_fields = [
            "id",
            *InventoryRelatedDataSerializerMixin.get_product_field_names(),
            "created_at",
            "updated_at",
        ]

    def apply_read_only_on_synced_fields(self):
        """
        직접 관리가 가능한 필드인지 확인하고
        그게 아닌 필드에 대해서는 read_only 처리
        """

        if not self.is_update:
            return

        is_connected = self.initial_data.get(
            "is_connected", self.instance.is_erp_synced
        )
        self.can_self_manage_fields = is_connected or (
            is_connected and not is_erp_synced
        )
        if self.can_self_manage_fields:
            return

        # 여기로 제어가 들어오면 ERP 연동된 도매
        # -> ERP 로부터 자동으로 동기화 되는 필드에 대해서는 수정 불가 처리 (입력 무시)
        for erp_synced_field in DodoInventory.erp_synced_fields():
            if erp_synced_field in self.fields:
                self.fields[erp_synced_field].read_only = True

    def check_set_required_false(self):
        if not self.is_update:
            return
        for field in self.fields:
            self.fields[field].required = False

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.group = self.context["group"]
        self.is_update = hasattr(self, "initial_data") and isinstance(
            self.instance, DodoInventory
        )
        self.can_self_manage_fields = False
        self.apply_read_only_on_synced_fields()
        self.check_set_required_false()

    def validate(self, attrs: Dict):
        if self.is_update:
            qty_diff = attrs.pop("qty_diff", 0)
            is_qty_changed = qty_diff != 0
            display_qty = attrs.pop("display_qty", None)

            if is_qty_changed and self.can_self_manage_fields:
                try:
                    if display_qty is None:
                        raise serializers.ValidationError("재고 초기값이 없습니다.")

                    self.update_qty(display_qty, qty_diff)
                except KeyError:
                    raise serializers.ValidationError("재고 초기값이 없습니다.")

            elif is_qty_changed and not self.can_self_manage_fields:
                raise serializers.ValidationError("동기화 중 일때는 재고를 변경할 수 없습니다.")

        return attrs
```