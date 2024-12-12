# django - 목록 조회 API 와 FilterSet 활용

## List API View

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


## FilterSet

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