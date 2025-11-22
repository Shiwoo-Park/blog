---
layout: post
title: "Django 목록 조회 API와 FilterSet 활용"
date: 2024-01-01
categories: [django, drf, filter]
---

Django REST Framework에서 목록 조회 API를 구현하고 FilterSet을 활용하여 필터링 기능을 추가하는 방법입니다.

---

## 1. List API View

목록 조회를 위한 ViewSet 설정 예제입니다.

```python
from rest_framework.viewsets import ModelViewSet
from django_filters.rest_framework import DjangoFilterBackend
from rest_framework.filters import OrderingFilter

class InventoryViewSet(ModelViewSet):
    permission_classes = [IsAdmin]
    queryset = Inventory.objects.all()
    filter_backends = [DjangoFilterBackend, OrderingFilter]
    filterset_class = InventoryFilter
    ordering_fields = ["id"]
    ordering = ["-id"]
```

---

## 2. FilterSet

필터링을 위한 FilterSet 클래스 예제입니다.

```python
import django_filters
from .models import Inventory


class InventoryFilter(django_filters.FilterSet):
    name = django_filters.CharFilter(field_name="name", lookup_expr="icontains")
    is_soldout = django_filters.BooleanFilter(label="품절 여부", method="filter_is_soldout")
    manufacturer = django_filters.CharFilter(
        field_name="product__manufacturer", lookup_expr="icontains"
    )
    is_exposed = django_filters.BooleanFilter(
        label="노출 여부", method="filter_is_exposed"
    )
    group_id = django_filters.CharFilter(
        field_name="group__id", lookup_expr="exact"
    )

    class Meta:
        model = Inventory
        fields = {
            "id": ["exact"],
            "is_erp_synced": ["exact"],
            "used": ["exact"],
            "in_service": ["exact"],
            "wholesaler_item_code": ["exact"],
        }

    def filter_is_soldout(self, queryset, name, value):
        if value:
            return queryset.filter(qty=0)

        return queryset.exclude(qty=0)
```