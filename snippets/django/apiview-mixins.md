# django - APIView mixins

## 효율적인 쿼리를 날리는데 도움을 주는 EagerLoadingMixin

- 장고의 고질적인 N+1 쿼리 현상을 미연에 방지하고자 View 레벨에서부터 관리할 수 있음
- `get_queryset(), serializer_class` 를 지정하는 APIView 클래스에 적합

```python
class EagerLoadingMixin:
    """
    get_queryset() 를 사용하는 View, ViewSet 에서 활용
    - 로직에서 다른 모델과의 join 이 필요한 경우, 이를 미리 명시적으로 지정함으로써
    - 쿼리가 효율적으로 동작할 수 있도록 보장합니다.
    - 참고자료: https://www.notion.so/baropharm/select-by-eager-loading-f9327eeef4c64133959f0928421a6183

    <사용 예시>
    class AuthorViewSet(EagerLoadingMixin, viewsets.ModelViewSet):
        queryset = Author.objects.all()
        serializer_class = AuthorSerializer

        # 1. attribute 를 적거나
        queryset_prefetch_related_list = ["books"]

        # 2. 직접 함수를 override
        def setup_eager_loading(self, queryset):
            return queryset.prefetch_related('books')
    """

    queryset_select_related_list = []
    queryset_prefetch_related_list = []

    def setup_eager_loading(self, queryset: QuerySet) -> QuerySet:
        """
        Modify this method to add select_related and prefetch_related
        """
        if self.queryset_select_related_list:
            queryset = queryset.select_related(*self.queryset_select_related_list)

        if self.queryset_prefetch_related_list:
            queryset = queryset.prefetch_related(*self.queryset_select_related_list)

        return queryset

    def get_queryset(self):
        queryset = super().get_queryset()
        return self.setup_eager_loading(queryset)
```


## DRF ValidationError 응답(=400)으로 한글화된 메시지를 줄 수 있는 ModelSerializerMessageMixin

```python
class ModelSerializerMessageMixin:
    """
    ModelSerializer 의 한글화 된 오류 메시지 제공해주는 Mixin

    - 전제조건: Model 의 모든 필드에 verbose_name 이 세팅되어있어야 함.
    - ValidationError 의 경우에만 해당됨
    - Model의 verbose_name을 사용하여 "{verbose_name} 입력 오류: "를 추가해줌

    [사용법]
    class YourModelSerializer(ModelSerializerMessageMixin, serializers.ModelSerializer):
        class Meta:
            model = YourModel
            fields = '__all__'  # 또는 필요한 필드만 지정
    """

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.customize_error_messages()

    def customize_error_messages(self):
        for field_name, field in self.fields.items():
            try:
                model_field = self.Meta.model._meta.get_field(field_name)
                verbose_name = model_field.verbose_name

                # 기존 에러 메시지를 복사
                original_messages = field.error_messages.copy()

                # 모든 에러 메시지에 verbose_name 추가
                for key, message in original_messages.items():
                    field.error_messages[key] = _(f"{verbose_name} 입력 오류: {message}")

                # null, blank, required에 대해서는 특별한 메시지 사용
                special_messages = {
                    "null": _(f"{verbose_name} 입력 오류: 필수 입력 항목입니다."),
                    "blank": _(f"{verbose_name} 입력 오류: 필수 입력 항목입니다."),
                    "required": _(f"{verbose_name} 입력 오류: 필수 입력 항목입니다."),
                }
                field.error_messages.update(special_messages)

            except FieldDoesNotExist:  # 유효한 필드가 아닐때 (관련모델필드, SerializerMethodField 등)
                pass
            except Exception as e:
                logger.warning(
                    f"Error customizing messages for field {field_name}: {str(e)}"
                )
```