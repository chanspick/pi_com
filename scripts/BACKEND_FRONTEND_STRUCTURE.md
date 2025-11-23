# 🏗️ PiCom 백엔드-프론트엔드 구조 가이드

## 📋 목차
1. [전체 아키텍처 개요](#전체-아키텍처-개요)
2. [Clean Architecture 계층 설명](#clean-architecture-계층-설명)
3. [데이터 흐름 (Data Flow)](#데이터-흐름-data-flow)
4. [Listing 기능 예시](#listing-기능-예시)
5. [에러 발생 시 디버깅 가이드](#에러-발생-시-디버깅-가이드)
6. [코드 수정 시 체크리스트](#코드-수정-시-체크리스트)

---

## 전체 아키텍처 개요

PiCom은 **Clean Architecture**를 채택하여 3개의 계층으로 분리되어 있습니다:

```
┌─────────────────────────────────────────────────────┐
│              Presentation Layer                      │
│  (UI, Screens, Widgets, Providers)                  │
│  - 사용자 인터랙션 처리                                 │
│  - 상태 관리 (Riverpod)                               │
│  lib/features/*/presentation/                        │
└──────────────────┬──────────────────────────────────┘
                   │
                   ↓
┌─────────────────────────────────────────────────────┐
│              Domain Layer                            │
│  (Entities, UseCases, Repository Interfaces)        │
│  - 비즈니스 로직                                       │
│  - 순수 Dart 코드 (외부 의존성 없음)                    │
│  lib/features/*/domain/                              │
└──────────────────┬──────────────────────────────────┘
                   │
                   ↓
┌─────────────────────────────────────────────────────┐
│              Data Layer                              │
│  (Models, DataSources, Repository Implementations)  │
│  - Firebase 연동                                      │
│  - 데이터 변환 (Firestore ↔ Entity)                  │
│  lib/features/*/data/                                │
└──────────────────┬──────────────────────────────────┘
                   │
                   ↓
              ┌────────┐
              │Firebase│
              │Firestore│
              └────────┘
```

---

## Clean Architecture 계층 설명

### 1️⃣ Presentation Layer (표현 계층)

**역할**: 사용자에게 UI를 보여주고 입력을 받음

**주요 파일**:
- **screens/**: 각 화면 (예: `listing_detail_screen.dart`)
- **widgets/**: 재사용 가능한 UI 컴포넌트
- **providers/**: Riverpod 상태 관리

**예시**: `lib/features/listing/presentation/`
```dart
// listing_detail_screen.dart
class ListingDetailScreen extends ConsumerWidget {
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Provider를 통해 데이터 요청
    final listingAsync = ref.watch(listingProvider(listingId));

    // 2. 로딩/에러/데이터 상태 처리
    return listingAsync.when(
      data: (listing) => _buildUI(listing),
      loading: () => CircularProgressIndicator(),
      error: (error, stack) => Text('에러: $error'),
    );
  }
}
```

**수정 시점**: UI 디자인 변경, 사용자 인터랙션 로직 변경

---

### 2️⃣ Domain Layer (도메인 계층)

**역할**: 비즈니스 로직과 규칙 정의 (외부 의존성 없음)

**주요 파일**:
- **entities/**: 핵심 데이터 구조 (예: `listing_entity.dart`)
- **usecases/**: 비즈니스 로직 (예: `get_listing_usecase.dart`)
- **repositories/**: 데이터 접근 인터페이스 (추상 클래스)

**예시**: `lib/features/listing/domain/`

#### Entity (엔티티)
```dart
// listing_entity.dart
class ListingEntity {
  final String listingId;
  final String brand;
  final int price;
  // ... 순수 비즈니스 데이터

  // 비즈니스 로직
  bool canBePurchasedBy(String userId) {
    return isAvailable && sellerId != userId;
  }
}
```

#### UseCase (유스케이스)
```dart
// get_listing_usecase.dart
class GetListingUseCase {
  final ListingRepository repository;

  Stream<ListingEntity> call(String listingId) {
    return repository.getListing(listingId);
  }
}
```

#### Repository Interface (저장소 인터페이스)
```dart
// repositories/listing_repository.dart
abstract class ListingRepository {
  Stream<ListingEntity> getListing(String listingId);
  Future<List<ListingEntity>> getListings({String? category});
}
```

**수정 시점**: 비즈니스 규칙 변경, 새로운 기능 추가

---

### 3️⃣ Data Layer (데이터 계층)

**역할**: Firebase와 통신하고 데이터 변환

**주요 파일**:
- **models/**: Firestore 데이터 모델 (예: `listing_model.dart`)
- **datasources/**: Firebase 접근 (예: `listing_remote_datasource.dart`)
- **repositories/**: Repository 구현체 (예: `listing_repository_impl.dart`)

**예시**: `lib/features/listing/data/`

#### Model (모델)
```dart
// listing_model.dart
class ListingModel {
  // Firestore 문서 → Model 변환
  factory ListingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ListingModel(
      listingId: data['listingId'],
      brand: data['brand'],
      // ...
    );
  }

  // Model → Entity 변환
  ListingEntity toEntity() {
    return ListingEntity(
      listingId: listingId,
      brand: brand,
      // ...
    );
  }

  // Entity → Firestore 문서 변환
  Map<String, dynamic> toFirestore() {
    return {
      'listingId': listingId,
      'brand': brand,
      // ...
    };
  }
}
```

#### DataSource (데이터소스)
```dart
// listing_remote_datasource.dart
class ListingRemoteDataSourceImpl {
  final FirebaseFirestore _firestore;

  Stream<ListingModel> getListing(String listingId) {
    return _firestore
        .collection('listings')
        .doc(listingId)
        .snapshots()
        .map((doc) => ListingModel.fromFirestore(doc));
  }
}
```

#### Repository Implementation (저장소 구현)
```dart
// listing_repository_impl.dart
class ListingRepositoryImpl implements ListingRepository {
  final ListingRemoteDataSource remoteDataSource;

  @override
  Stream<ListingEntity> getListing(String listingId) {
    // DataSource에서 Model을 가져와 Entity로 변환
    return remoteDataSource
        .getListing(listingId)
        .map((model) => model.toEntity());
  }
}
```

**수정 시점**: Firebase 구조 변경, API 연동 변경

---

## 데이터 흐름 (Data Flow)

### 읽기 흐름 (예: Listing 상세보기)

```
[사용자 클릭]
     ↓
[ListingDetailScreen] ← Presentation
     ↓ ref.watch(listingProvider(id))
[ListingProvider] ← Riverpod State Management
     ↓ getListingUseCase.call(id)
[GetListingUseCase] ← Domain (Business Logic)
     ↓ repository.getListing(id)
[ListingRepository] ← Domain (Interface)
     ↓
[ListingRepositoryImpl] ← Data (Implementation)
     ↓ remoteDataSource.getListing(id)
[ListingRemoteDataSource] ← Data (Firebase Access)
     ↓ Firestore.collection('listings').doc(id)
[Firebase Firestore] ← Backend
     ↓ doc.data()
[ListingModel.fromFirestore(doc)] ← Data (Parse)
     ↓ model.toEntity()
[ListingEntity] ← Domain (Business Object)
     ↓
[ListingDetailScreen] ← Presentation (Display)
     ↓
[사용자 화면에 표시]
```

### 쓰기 흐름 (예: Listing 생성)

```
[사용자 입력]
     ↓
[Screen] ← Presentation
     ↓ createListingUseCase.call(data)
[CreateListingUseCase] ← Domain
     ↓ repository.createListing(entity)
[ListingRepositoryImpl] ← Data
     ↓ model = ListingModel.fromEntity(entity)
     ↓ remoteDataSource.create(model)
[ListingRemoteDataSource] ← Data
     ↓ Firestore.collection('listings').add(model.toFirestore())
[Firebase Firestore] ← Backend
     ↓
[성공/실패 반환]
```

---

## Listing 기능 예시

### 파일 구조
```
lib/features/listing/
├── presentation/
│   ├── screens/
│   │   └── listing_detail_screen.dart    ← 화면
│   ├── widgets/
│   │   └── listing_card.dart             ← UI 컴포넌트
│   └── providers/
│       └── listing_provider.dart         ← 상태 관리
├── domain/
│   ├── entities/
│   │   └── listing_entity.dart           ← 비즈니스 데이터
│   ├── usecases/
│   │   └── get_listing_usecase.dart      ← 비즈니스 로직
│   └── repositories/
│       └── listing_repository.dart       ← 인터페이스
└── data/
    ├── models/
    │   └── listing_model.dart            ← Firestore 모델
    ├── datasources/
    │   └── listing_remote_datasource.dart ← Firebase 접근
    └── repositories/
        └── listing_repository_impl.dart  ← 구현체
```

### 실제 코드 흐름 예시

#### 1. 사용자가 Listing 클릭
```dart
// part_shop_screen.dart (목록 화면)
onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ListingDetailScreen(listingId: listing.listingId),
    ),
  );
}
```

#### 2. Provider에서 데이터 요청
```dart
// listing_provider.dart
final listingProvider = StreamProvider.autoDispose.family<ListingEntity, String>((ref, id) {
  return ref.watch(getListingProvider).call(id);
});
```

#### 3. UseCase 실행
```dart
// get_listing_usecase.dart
Stream<ListingEntity> call(String listingId) {
  return repository.getListing(listingId);
}
```

#### 4. Repository에서 DataSource 호출
```dart
// listing_repository_impl.dart
Stream<ListingEntity> getListing(String listingId) {
  return remoteDataSource.getListing(listingId)
      .map((model) => model.toEntity());
}
```

#### 5. DataSource에서 Firestore 조회
```dart
// listing_remote_datasource.dart
Stream<ListingModel> getListing(String listingId) {
  return _firestore
      .collection('listings')
      .doc(listingId)
      .snapshots()
      .map((doc) {
        if (!doc.exists) {
          throw Exception('Listing not found');  // ← 에러 발생 지점!
        }
        return ListingModel.fromFirestore(doc);
      });
}
```

#### 6. Model → Entity 변환
```dart
// listing_model.dart
ListingEntity toEntity() {
  return ListingEntity(
    listingId: listingId,
    brand: brand,
    price: price,
    // ...
  );
}
```

#### 7. 화면에 표시
```dart
// listing_detail_screen.dart
listingAsync.when(
  data: (listing) => ListingHeader(listing: listing),
  loading: () => CircularProgressIndicator(),
  error: (error, stack) => Text('에러: $error'),
);
```

---

## 에러 발생 시 디버깅 가이드

### 🔍 "Listing not found" 에러 예시

**증상**: Firebase Console에는 listing이 있는데 앱에서 "Listing not found" 에러

**디버깅 순서**:

#### 1단계: 에러 발생 위치 파악
```
에러 메시지 확인 → 어느 계층에서 발생했는지 확인

예: "Exception: Listing not found"
↓
listing_remote_datasource.dart:33에서 throw된 에러
```

#### 2단계: 관련 파일 확인
```
listing_remote_datasource.dart:26-36 확인
↓
if (!doc.exists) {
  throw Exception('Listing not found');
}
```

#### 3단계: 원인 분석
가능한 원인:
- ✅ **listingId 불일치**: 전달된 ID가 실제 문서 ID와 다름
- ✅ **Firestore Rules**: 읽기 권한 없음
- ✅ **타이밍 이슈**: 문서가 삭제됨
- ✅ **데이터 파싱 에러**: fromFirestore()에서 에러

#### 4단계: 각 원인별 확인 방법

**A) listingId 확인**
```dart
// listing_remote_datasource.dart
Stream<ListingModel> getListing(String listingId) {
  print('🔍 Fetching listing with ID: $listingId');  // 로그 추가
  return _firestore.collection('listings').doc(listingId).snapshots()...
}
```

**B) Firebase Console 확인**
1. Firebase Console → Firestore Database
2. `listings` 컬렉션 클릭
3. 해당 listingId 문서가 존재하는지 확인
4. 문서의 필드들이 올바른지 확인

**C) Firestore Rules 확인**
```javascript
// firestore.rules
match /listings/{listingId} {
  allow read: if request.auth != null;  // 로그인 필요?
}
```

**D) 데이터 파싱 확인**
```dart
// listing_model.dart
factory ListingModel.fromFirestore(DocumentSnapshot doc) {
  try {
    final data = doc.data() as Map<String, dynamic>;
    print('🔍 Parsing data: $data');  // 로그 추가
    return ListingModel(...);
  } catch (e, stackTrace) {
    print('❌ Parse error: $e');
    print('📋 Stack: $stackTrace');
    rethrow;
  }
}
```

---

## 코드 수정 시 체크리스트

### ✅ UI 수정 (Presentation)
- [ ] `lib/features/*/presentation/screens/` 파일 수정
- [ ] `lib/features/*/presentation/widgets/` 파일 수정
- [ ] Hot Reload로 즉시 확인 가능
- [ ] 비즈니스 로직은 건드리지 않음

### ✅ 비즈니스 로직 수정 (Domain)
- [ ] `lib/features/*/domain/entities/` 수정 시 → Model도 함께 수정
- [ ] `lib/features/*/domain/usecases/` 수정
- [ ] 테스트 코드 작성 권장

### ✅ Firebase 연동 수정 (Data)
- [ ] `lib/features/*/data/models/` 수정 시 → Entity도 함께 수정
- [ ] `lib/features/*/data/datasources/` 수정 시 → Firestore 구조 확인
- [ ] `firestore.rules` 확인
- [ ] Firebase Console에서 실제 데이터 확인

### ✅ Provider 수정
- [ ] `lib/features/*/presentation/providers/` 수정
- [ ] 의존성 주입 확인
- [ ] Hot Restart 필요

---

## 새로운 기능 추가 시 순서

### 예: "리뷰 기능" 추가

#### 1. Domain 계층 먼저 설계
```dart
// lib/features/review/domain/entities/review_entity.dart
class ReviewEntity {
  final String reviewId;
  final String listingId;
  final String userId;
  final int rating;
  final String comment;
}
```

#### 2. Data 계층 구현
```dart
// lib/features/review/data/models/review_model.dart
class ReviewModel {
  factory ReviewModel.fromFirestore(DocumentSnapshot doc) {...}
  ReviewEntity toEntity() {...}
  Map<String, dynamic> toFirestore() {...}
}

// lib/features/review/data/datasources/review_remote_datasource.dart
class ReviewRemoteDataSourceImpl {
  Stream<List<ReviewModel>> getReviews(String listingId) {...}
  Future<void> createReview(ReviewModel review) {...}
}
```

#### 3. UseCase 작성
```dart
// lib/features/review/domain/usecases/get_reviews_usecase.dart
class GetReviewsUseCase {
  Stream<List<ReviewEntity>> call(String listingId) {...}
}
```

#### 4. Provider 설정
```dart
// lib/features/review/presentation/providers/review_provider.dart
final reviewsProvider = StreamProvider.family<List<ReviewEntity>, String>((ref, listingId) {
  return ref.watch(getReviewsUseCaseProvider).call(listingId);
});
```

#### 5. UI 작성
```dart
// lib/features/review/presentation/screens/reviews_screen.dart
class ReviewsScreen extends ConsumerWidget {
  final reviewsAsync = ref.watch(reviewsProvider(listingId));
  // ...
}
```

---

## 유용한 디버깅 팁

### 1. Provider 상태 확인
```dart
ref.listen(listingProvider(id), (previous, next) {
  print('State changed: $previous → $next');
});
```

### 2. Firestore 쿼리 로그
```dart
FirebaseFirestore.setLoggingEnabled(true);  // main.dart에 추가
```

### 3. 에러 스택 트레이스 출력
```dart
try {
  // ...
} catch (e, stackTrace) {
  print('Error: $e');
  print('Stack: $stackTrace');
  rethrow;
}
```

### 4. Firebase Console 실시간 확인
- Firestore → 데이터 탭에서 실시간 변경사항 확인
- Functions → 로그에서 클라우드 함수 실행 로그 확인

---

## 자주 하는 실수

### ❌ Entity와 Model 혼동
```dart
// 잘못된 예
ListingEntity entity = ListingModel.fromFirestore(doc);  // ❌

// 올바른 예
ListingModel model = ListingModel.fromFirestore(doc);   // ✅
ListingEntity entity = model.toEntity();                // ✅
```

### ❌ Provider 의존성 순환
```dart
// providerA가 providerB를 참조하고
// providerB가 providerA를 참조하면 에러!
```

### ❌ Stream과 Future 혼동
```dart
// Stream: 실시간 업데이트
StreamProvider<ListingEntity, String>((ref, id) {
  return repository.getListing(id);  // Stream 반환
});

// Future: 일회성 조회
FutureProvider<List<ListingEntity>>((ref) {
  return repository.getListings();  // Future 반환
});
```

---

**최종 수정일**: 2025-01-12
**작성자**: Claude Code
**문의**: 팀 슬랙/이슈 트래커
