---
layout: post
title: "Excel 다운로드 기능을 제공하는 ExcelDownloadMixin"
date: 2024-01-01
categories: [django, drf, excel, download]
---

ModelViewSet에 추가하여 자동으로 엑셀 다운로드용 endpoint를 제공하는 Mixin입니다. openpyxl을 사용하여 엑셀 파일을 생성하고 다운로드합니다.

---

## 1. ExcelDownloadMixin 클래스

엑셀 다운로드 기능을 제공하는 Mixin 클래스입니다.

```python
from io import BytesIO

import openpyxl
from django.http import StreamingHttpResponse
from django.utils import timezone
from openpyxl.styles import Font, PatternFill
from rest_framework.decorators import action
from rest_framework.exceptions import ValidationError


class ExcelDownloadMixin:
    """
    ModelViewSet 에 추가하여 간단히 액셀 다운로드용 endpoint 를 제공할 수 있는 mixin

    [용법]
    class MyModelViewSet(ExcelDownloadMixin, ModelViewSet):
        excel_download_serializer_class = MyExcelDownloadSerializer

        def __init__(self, *args, **kwargs):
            super().__init__(*args, **kwargs)
            self.excel_download_record_bg_color = "F0F0F0"
            self.set_column_bg_color(0, "FFCCCB")  # 엑셀 특정 열의 배경색 지정
    """

    excel_download_file_prefix = "downloaded_xls"  # 파일명
    excel_download_url_path = "download-xls"  # 제공할 endpoint url path
    excel_download_header_font_color = "000000"  # 엑셀 헤더 폰트 색상
    excel_download_header_bg_color = "FFFF9F"  # 엑셀 헤더 배경 색상
    excel_download_record_bg_color = "FFFFFF"  # 엑셀 레코드 배경색
    excel_download_column_bg_colors = {}  # 엑셀 특정 열의 배경색 (첫번째 열=0), 예: {0: "FFFF0F"}
    excel_download_serializer_class = None  # 엑셀 데이터용 시리얼라이져 클래스
    excel_download_allow_row_limit = 1000
    excel_download_value_convert_map = {
        # 특정 str(value) 의 액셀 표시 문자열
        "None": "-",
        "True": "Y",
        "False": "N",
    }

    @action(detail=False, methods=["get"], url_path=excel_download_url_path)
    def excel_download(self, request, *args, **kwargs):
        try:
            if "queryset" in kwargs:
                queryset = kwargs["queryset"]
            else:
                queryset = self.filter_queryset(self.get_queryset())

            requested_record_count = queryset.count()
            if requested_record_count > self.excel_download_allow_row_limit:
                raise ValidationError(
                    f"다운로드 가능 한도 초과: 최대 {self.excel_download_allow_row_limit} 개 까지 조회 가능합니다. "
                    f"(요청 레코드 수: {requested_record_count})"
                )

            response = StreamingHttpResponse(
                streaming_content=self.generate_excel(queryset),
                content_type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
            )
            response[
                "Content-Disposition"
            ] = f'attachment; filename="{self.get_excel_filename()}"'
            return response
        except Exception as e:
            raise ValidationError(f"Excel 다운로드 중 오류가 발생했습니다: {str(e)}")

    def is_valid_excel_download_request(self):
        """
        유효한 다운로드 요청인지 확인
        - self.request.query_param 등의 요청 검증
        - 데이터 조회 기간을 제한하거나, 수량을 제한
        - 요청 검증에 실패 하였을 시, raise ValidationError
        """
        return True

    def get_excel_download_serializer_class(self):
        if self.excel_download_serializer_class is None:
            raise NotImplementedError("엑셀 다운로드 설정 오류: serializer 를 지정해주세요")
        return self.excel_download_serializer_class

    def generate_excel(self, queryset):
        wb = openpyxl.Workbook()
        ws = wb.active
        ws.title = "Data"

        # Add headers
        headers = self.get_excel_headers()
        ws.append(headers)

        # Apply style to headers
        self.style_header_row(ws[1])

        # Add data rows
        for item in queryset:
            serializer_cls = self.get_excel_download_serializer_class()
            serializer = serializer_cls(item)
            row = self.get_excel_row(serializer.data)
            ws.append(row)
            self.style_data_row(ws[ws.max_row])

        excel_file = BytesIO()
        wb.save(excel_file)
        excel_file.seek(0)

        # Generator to stream the file
        yield from excel_file

    def get_excel_filename(self):
        timestamp = timezone.now().strftime("%Y%m%d_%H%M%S")
        return f"{self.excel_download_file_prefix}_{timestamp}.xlsx"

    def get_excel_headers(self):
        serializer_cls = self.get_excel_download_serializer_class()
        serializer = serializer_cls()
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

    def get_excel_row(self, item):
        row_data = []
        for value in item.values():
            str_val = str(value)
            if str_val in self.excel_download_value_convert_map:
                converted_val = self.excel_download_value_convert_map[str_val]
                row_data.append(converted_val)
            else:
                row_data.append(str_val)
        return row_data

    def style_header_row(self, row):
        for cell in row:
            cell.font = Font(bold=True, color=self.excel_download_header_font_color)
            cell.fill = PatternFill(
                start_color=self.excel_download_header_bg_color,
                end_color=self.excel_download_header_bg_color,
                fill_type="solid",
            )

    def style_data_row(self, row):
        for idx, cell in enumerate(row):
            bg_color = self.excel_download_column_bg_colors.get(
                idx, self.excel_download_record_bg_color
            )
            cell.fill = PatternFill(
                start_color=bg_color,
                end_color=bg_color,
                fill_type="solid",
            )

    def set_column_bg_color(self, column_index, color):
        self.excel_download_column_bg_colors[column_index] = color
```

---

## 2. Backend: View Code

ExcelDownloadMixin을 사용하는 ViewSet 예제입니다.

### 2-1. 2가지 타입의 파일을 하나의 endpoint로 서비스

조건에 따라 다른 엑셀 형식을 제공하는 예제입니다.

```python
class InventoryViewSet(ExcelDownloadMixin, ModelViewSet):
    queryset = Inventory.objects.all()
    excel_download_header_bg_color = HexColor.BLUE_1.code
    group = None

    def get_excel_download_serializer_class(self):
        order_type_enum = Group.OrderType.get_member(self.group.order_type)
        if order_type_enum == Group.OrderType.EXTERNAL_DB_CONNECT:
            for i in range(10):
                self.set_column_bg_color(i, HexColor.GREY_2.code)
            for i in range(11, 16):
                self.set_column_bg_color(i, HexColor.GREY_2.code)
            for i in [10, 16, 17, 18, 19]:
                self.set_column_bg_color(i, HexColor.YELLO_1.code)
            return InventoryExcelSerializerForSyncGroup
        elif order_type_enum == Group.OrderType.INTERNAL_DB_CONNECT:
            for i in range(8):
                self.set_column_bg_color(i, HexColor.GREY_2.code)
            for i in range(8, 19):
                self.set_column_bg_color(i, HexColor.YELLO_1.code)
            return InventoryExcelSerializerForSelfManageGroup
        else:
            raise ValidationError(f"주문방식이 {order_type_enum.text} 인 그룹은 다운로드가 불가합니다.")
```

### 2-2. 서로 다른 파일을 여러 개의 endpoint로 서비스

여러 개의 엑셀 다운로드 endpoint를 제공하는 예제입니다.

```python
class CmsDodoOrderViewSet(ExcelDownloadMixin, ModelViewSet):
    """CMS 주문관련 API"""

    queryset = DodoOrder.objects.exclude(
        status__in=DodoOrder.Status.get_exclude_status_codes()
    ).order_by("-created_at")
    http_method_names = ["get", "post"]
    serializer_class = CmsOrderListSerializer
    permission_classes = [IsStaff]

    @action(
        detail=False,
        methods=["get"],
        url_path="download-orders",
        url_name="download-orders",
    )
    def download_orders(self, request, *args, **kwargs):
        self.excel_download_file_prefix = "주문내역"
        self.excel_download_serializer_class = CmsOrderExcelSerializer
        return self.excel_download(request)

    @action(
        detail=False,
        methods=["get"],
        url_path="download-order-items",
        url_name="download-order-items",
    )
    def download_order_items(self, request, *args, **kwargs):
        orders = self.filterset_class(
            data=request.query_params, queryset=self.get_queryset()
        ).qs
        order_ids = list(orders.values_list("id", flat=True))

        queryset = (
            OrderItem.objects.filter(order_id__in=order_ids)
            .select_related("product", "info")
            .order_by("-order__created_at")
        )

        self.excel_download_file_prefix = "주문상품내역"
        self.excel_download_serializer_class = CmsOrderItemExcelSerializer
        return self.excel_download(request, **{"queryset": queryset})
```

---

## 3. Front-end Code

엑셀 파일을 다운로드하는 프론트엔드 코드 예제입니다.

```js
export default {
  baseURL: '/inventories',
  async getDownloadExcel(params) {
    return await ApiController.get(`${this.baseURL}/download-xls`, {
      params: params,
      responseType: 'blob',
    })
      .then((response) => {
        const contentDisposition = response.headers['content-disposition']
        let fileName = 'downloaded_file.xlsx'
        if (contentDisposition) {
          const fileNameMatch = contentDisposition.match(/filename="?(.+)"?/i)
          if (fileNameMatch.length === 2) fileName = fileNameMatch[1]
        }

        const blob = new Blob([response.data], {
          type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        })
        const url = window.URL.createObjectURL(blob)
        const link = document.createElement('a')
        link.href = url
        link.setAttribute('download', fileName)
        document.body.appendChild(link)
        link.click()
        link.parentNode.removeChild(link)
        window.URL.revokeObjectURL(url)

        return response.data
      })
      .catch((error) => {
        console.error('Excel download failed:', error)
        throw error
      })
  },
}
```