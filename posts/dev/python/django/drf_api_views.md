---
layout: post
title: "DRF APIView 클래스 선택 가이드"
date: 2025-12-02
categories: [python, django, DRF]
---

Django REST Framework(DRF)에서 API를 구현할 때 어떤 뷰 클래스를 선택해야 할지 실무 관점에서 정리한 가이드입니다.

---

## 1. APIView란 무엇인가?

`APIView`는 DRF의 모든 뷰 클래스의 최상위 부모 클래스로, Django의 `View`를 상속받습니다.

### 핵심 특징

- **HTTP 메소드 매핑**: GET, POST, PUT, DELETE 등의 HTTP 메소드를 Python 메소드(`get()`, `post()`, `put()`, `delete()`)에 자동 매핑
- **인증/권한/스로틀링 처리**: DRF의 인증(Authentication), 권한(Permission), 스로틀링(Throttling) 기능을 기본 제공
- **커스텀 로직 구현**: 모든 비즈니스 로직을 직접 구현해야 하는 가장 기본적인 뷰 클래스

### 기본 사용 예시

```python
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status

class CustomAPIView(APIView):
    def get(self, request):
        # 커스텀 로직 구현
        return Response({"message": "Hello"}, status=status.HTTP_200_OK)

    def post(self, request):
        # 커스텀 로직 구현
        return Response({"message": "Created"}, status=status.HTTP_201_CREATED)
```

---

## 2. APIView 하위클래스의 구조와 구분

DRF의 뷰 클래스는 목적과 기능에 따라 **6단계 계층 구조**로 구성되어 있습니다.

### 계층 구조 도표

```
APIView (최상위 부모)
  ├── GenericAPIView (모델 기반 공통 로직)
  │     ├── Mixin 클래스들 (CRUD 기능 단위)
  │     │     ├── ListModelMixin
  │     │     ├── CreateModelMixin
  │     │     ├── RetrieveModelMixin
  │     │     ├── UpdateModelMixin
  │     │     └── DestroyModelMixin
  │     │
  │     ├── Concrete Views (미리 조합된 뷰)
  │     │     ├── ListAPIView
  │     │     ├── CreateAPIView
  │     │     ├── RetrieveAPIView
  │     │     ├── UpdateAPIView
  │     │     ├── DestroyAPIView
  │     │     ├── ListCreateAPIView
  │     │     └── RetrieveUpdateDestroyAPIView
  │     │
  │     └── ViewSet 계열
  │           ├── GenericViewSet
  │           ├── ModelViewSet
  │           └── ReadOnlyModelViewSet
```

### 각 계층별 특징

#### 1단계: APIView

- **역할**: 모든 DRF 뷰의 근간
- **특징**: HTTP 메소드별 로직을 직접 구현해야 함
- **사용 시점**: 모델과 무관한 복잡한 커스텀 로직이 필요할 때

#### 2단계: GenericAPIView

- **역할**: 모델 기반의 공통 로직을 추상화
- **추가 기능**:
  - `queryset`: 데이터베이스 쿼리셋 지정
  - `serializer_class`: 시리얼라이저 지정
  - `pagination_class`: 페이지네이션 설정
- **특징**: Mixin과 결합하여 사용 (단독 사용 불가)

#### 3단계: Mixin 클래스

- **역할**: CRUD 로직을 제공하는 기능 단위
- **종류**:
  - `ListModelMixin`: 목록 조회 (`GET /api/items/`)
  - `CreateModelMixin`: 생성 (`POST /api/items/`)
  - `RetrieveModelMixin`: 단일 조회 (`GET /api/items/{id}/`)
  - `UpdateModelMixin`: 수정 (`PUT/PATCH /api/items/{id}/`)
  - `DestroyModelMixin`: 삭제 (`DELETE /api/items/{id}/`)
- **특징**: `GenericAPIView`와 결합하여 사용

#### 4단계: Concrete Views

- **역할**: 자주 사용되는 Mixin 조합을 미리 제공
- **종류**:
  - `ListAPIView`: 목록 조회만
  - `CreateAPIView`: 생성만
  - `RetrieveAPIView`: 단일 조회만
  - `ListCreateAPIView`: 목록 조회 + 생성
  - `RetrieveUpdateDestroyAPIView`: 단일 조회 + 수정 + 삭제
- **특징**: 가장 빠르고 흔한 선택지

#### 5단계: GenericViewSet

- **역할**: Router와 연동되는 뷰
- **특징**:
  - HTTP 메소드 대신 **액션(Action)** 메소드 사용 (`list`, `retrieve`, `create` 등)
  - `DefaultRouter`와 함께 사용하면 URL 매핑 자동화
- **사용 예시**:

```python
from rest_framework import viewsets
from rest_framework.routers import DefaultRouter

class ItemViewSet(viewsets.GenericViewSet):
    queryset = Item.objects.all()
    serializer_class = ItemSerializer

    def list(self, request):
        # 목록 조회 로직
        pass

router = DefaultRouter()
router.register(r'items', ItemViewSet)
# 자동으로 /api/items/ (list) 엔드포인트 생성
```

#### 6단계: ModelViewSet / ReadOnlyModelViewSet

- **ModelViewSet**:
  - 모든 CRUD 액션 제공 (`list`, `retrieve`, `create`, `update`, `partial_update`, `destroy`)
  - 하나의 모델에 대한 모든 API 엔드포인트를 한 클래스로 처리
- **ReadOnlyModelViewSet**:
  - 읽기 전용 (`list`, `retrieve`만 제공)
  - 생성, 수정, 삭제 불가

---

## 3. 실무 선택 가이드

### 선택 기준표

| 상황                                 | 추천 클래스                                              | 이유                      |
| :----------------------------------- | :------------------------------------------------------- | :------------------------ |
| **모델과 무관한 복잡한 커스텀 로직** | `APIView`                                                | 완전한 제어가 필요할 때   |
| **단일 목적의 간단한 CRUD**          | `Concrete Views`<br/>(`ListAPIView`, `CreateAPIView` 등) | 빠르고 명확한 구현        |
| **목록 + 생성 조합**                 | `ListCreateAPIView`                                      | 가장 흔한 조합            |
| **상세 + 수정 + 삭제 조합**          | `RetrieveUpdateDestroyAPIView`                           | 가장 흔한 조합            |
| **커스텀 Mixin 조합 필요**           | `GenericAPIView` + Mixin                                 | 유연한 커스터마이징       |
| **Router로 자동 URL 매핑**           | `ModelViewSet`                                           | 높은 생산성, RESTful 설계 |
| **읽기 전용 API**                    | `ReadOnlyModelViewSet`                                   | 안전한 조회 전용 API      |

### 실무 예시

#### 예시 1: ListCreateAPIView (가장 추천하는 조합)

```python
from rest_framework.generics import ListCreateAPIView
from rest_framework.permissions import IsAuthenticated

class ItemListCreateView(ListCreateAPIView):
    permission_classes = [IsAuthenticated]
    queryset = Item.objects.all()
    serializer_class = ItemSerializer

    def get_queryset(self):
        # 커스텀 필터링
        return Item.objects.filter(user=self.request.user)
```

**URL 설정**:

```python
# urls.py
urlpatterns = [
    path('api/items/', ItemListCreateView.as_view()),  # GET, POST
]
```

#### 예시 2: RetrieveUpdateDestroyAPIView

```python
from rest_framework.generics import RetrieveUpdateDestroyAPIView

class ItemDetailView(RetrieveUpdateDestroyAPIView):
    queryset = Item.objects.all()
    serializer_class = ItemSerializer
    permission_classes = [IsAuthenticated]
```

**URL 설정**:

```python
urlpatterns = [
    path('api/items/<int:pk>/', ItemDetailView.as_view()),  # GET, PUT, PATCH, DELETE
]
```

#### 예시 3: ModelViewSet (Router 사용)

```python
from rest_framework.viewsets import ModelViewSet
from rest_framework.routers import DefaultRouter

class ItemViewSet(ModelViewSet):
    queryset = Item.objects.all()
    serializer_class = ItemSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return Item.objects.filter(user=self.request.user)

# Router 설정
router = DefaultRouter()
router.register(r'items', ItemViewSet)

# 자동 생성되는 URL:
# GET    /api/items/          -> list()
# POST   /api/items/          -> create()
# GET    /api/items/{id}/     -> retrieve()
# PUT    /api/items/{id}/     -> update()
# PATCH  /api/items/{id}/     -> partial_update()
# DELETE /api/items/{id}/     -> destroy()
```

#### 예시 4: APIView (완전 커스텀)

```python
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status

class CustomLogicView(APIView):
    def post(self, request):
        # 모델과 무관한 복잡한 비즈니스 로직
        data = request.data
        # 외부 API 호출, 복잡한 계산 등
        result = complex_business_logic(data)
        return Response(result, status=status.HTTP_200_OK)
```

### 실무 팁

1. **가장 흔한 조합**: `ListCreateAPIView` + `RetrieveUpdateDestroyAPIView`

   - 대부분의 CRUD API를 이 두 클래스로 커버 가능
   - URL 디자인을 직접 제어할 수 있어 명확함

2. **ModelViewSet 주의사항**:

   - Router에 등록하면 즉시 6개 엔드포인트가 생성됨
   - 의도하지 않은 엔드포인트가 노출될 수 있음
   - 필요한 액션만 허용하려면 `@action` 데코레이터로 제한

3. **성능 최적화**:

   - `get_queryset()`에서 `select_related()`, `prefetch_related()` 활용
   - `EagerLoadingMixin` 같은 커스텀 Mixin 활용

4. **권한 관리**:
   - 클래스 레벨: `permission_classes` 속성
   - 메소드 레벨: `@action(permission_classes=[...])` 데코레이터

---

## 요약

- **`APIView`**: 모든 DRF 뷰의 근간, 완전 커스텀 로직 구현 시 사용
- **`GenericAPIView` + Mixin**: 유연한 커스터마이징이 필요할 때
- **`Concrete Views`**: 가장 빠르고 흔한 선택 (특히 `ListCreateAPIView`, `RetrieveUpdateDestroyAPIView`)
- **`ModelViewSet`**: Router와 함께 사용하여 높은 생산성, RESTful 설계

**실무 추천**: 대부분의 경우 `ListCreateAPIView`와 `RetrieveUpdateDestroyAPIView` 조합으로 시작하고, 필요에 따라 다른 클래스로 확장하는 것이 좋습니다.
