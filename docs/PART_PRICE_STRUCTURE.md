# Parts Price Feature - 현재 구조 분석

**작성일**: 2025-11-04
**상태**: 현재 구조 분석 완료

---

## 📋 개요

부품 시세(Parts Price) 피처는 PC 부품의 가격 정보를 카테고리별로 제공하고, 가격 추이를 보여주며, 실제 매물로 연결하는 기능입니다.

### 주요 기능
- ✅ 카테고리별 부품 시세 조회 (CPU, GPU, RAM, Mainboard, SSD, PSU)
- ✅ 부품 검색 (base_parts 컬렉션 기반)
- ✅ 가격 추이 차트
- ✅ 매물 연결 (ListingsByBasePartScreen)
- ⚠️ 부품 상세 스펙 보기 (구현되어 있지만 미사용)

---

## 🏗️ 아키텍처 구조

### Clean Architecture (3-Layer)

```
lib/features/parts_price/
├── domain/
│   ├── entities/
│   │   ├── base_part_entity.dart        ✅ 사용 중
│   │   ├── part_entity.dart             ⚠️ 정의되어 있지만 미사용
│   │   └── price_point_entity.dart      ✅ 사용 중
│   ├── repositories/
│   │   └── part_repository.dart         ✅ 인터페이스
│   └── usecases/
│       ├── get_base_parts_by_category_usecase.dart  ✅ 사용 중
│       ├── get_part_by_id_usecase.dart              ⚠️ 미사용
│       ├── get_price_history_usecase.dart           ✅ 사용 중
│       └── search_base_parts_usecase.dart           ✅ 사용 중
├── data/
│   ├── models/
│   │   ├── base_part_model.dart         ✅ 사용 중
│   │   ├── part_model.dart              ⚠️ 정의되어 있지만 미사용
│   │   └── price_point_model.dart       ✅ 사용 중
│   ├── datasources/
│   │   └── part_remote_datasource.dart  ✅ Firestore 연동
│   └── repositories/
│       └── part_repository_impl.dart    ✅ 구현체
└── presentation/
    ├── providers/
    │   └── part_provider.dart           ✅ Riverpod providers
    ├── screens/
    │   ├── part_category_screen.dart    ✅ 메인 화면
    │   ├── price_history_screen.dart    ✅ 가격 추이 화면
    │   └── base_part_search_screen.dart ✅ 검색 화면
    └── widgets/
        ├── base_part_card.dart          ✅ 부품 카드
        ├── price_history_chart.dart     ✅ 차트
        ├── cpu_details_widget.dart      ⚠️ 미사용
        ├── gpu_details_widget.dart      ⚠️ 미사용
        └── mainboard_details_widget.dart ⚠️ 미사용
```

---

## 📊 데이터 모델

### 1. BasePartEntity (현재 사용 중)

**용도**: 부품의 기본 정보와 가격 집계 데이터

```dart
class BasePartEntity {
  final String basePartId;       // base_parts 문서 ID
  final String modelName;         // 부품 모델명 (예: "RTX 4090")
  final String category;          // 카테고리 (cpu, gpu, ram, etc.)
  final int lowestPrice;          // 최저가
  final double averagePrice;      // 평균가
  final int listingCount;         // 현재 판매 중인 매물 개수

  // Computed properties
  bool get hasListings => listingCount > 0;
  bool get hasPriceInfo => lowestPrice > 0;
  String get priceRangeText;      // "150,000원~"
}
```

**Firestore 컬렉션**: `base_parts`

```firestore
base_parts/{basePartId}
{
  modelName: "Intel Core i9-14900K",
  category: "cpu",
  lowestPrice: 650000,
  averagePrice: 680000.5,
  listingCount: 15
}
```

### 2. PartEntity (정의되어 있지만 미사용) ⚠️

**용도**: 부품의 상세 스펙 정보 (CPU/GPU/Mainboard별 세부 정보)

```dart
abstract class PartEntity {
  final String partId;
  final String basePartId;        // base_part 참조
  final PartCategory category;
  final String brand;
  final String modelName;
  final int? referencePrice;
  final String? imageUrl;
  final int? powerConsumptionW;
}

// CPU 상세 스펙
class CpuPartEntity extends PartEntity {
  final String socket;            // 소켓 (AM5, LGA1700)
  final int cores;                // 코어 수
  final int threads;              // 쓰레드 수
  final double baseClockGhz;      // 기본 클럭
  final double boostClockGhz;     // 부스트 클럭
  final double l3CacheMb;         // L3 캐시
  final bool hasIntegratedGraphics;
  final String? igpuName;
  final MemorySpecEntity memory;  // 메모리 스펙
  final bool coolerIncluded;
}

// GPU 상세 스펙
class GpuPartEntity extends PartEntity {
  final String chipset;           // 칩셋 (GA102, AD102)
  final int memorySizeGb;         // 메모리 용량
  final String memoryType;        // 메모리 타입 (GDDR6X)
  final String? interfaceType;    // PCIe 4.0 x16
  final int? boostClockMhz;
  final int? cudaCores;
}

// Mainboard 상세 스펙
class MainboardPartEntity extends PartEntity {
  final String socket;
  final String chipset;
  final String formFactor;        // ATX, mATX, ITX
  final String memoryType;        // DDR4, DDR5
  final int memorySlots;
  final int maxMemoryGb;
  final int sataPorts;
  final int m2Slots;
}
```

**Firestore 컬렉션**: `parts` (정의되어 있지만 현재 미사용)

### 3. PricePointEntity

**용도**: 가격 추이 데이터 포인트

```dart
class PricePointEntity {
  final DateTime date;
  final double price;
  final int count;              // 해당 날짜의 거래 건수
}
```

**데이터 소스**: `listings` 컬렉션에서 `status == 'sold'`인 항목의 soldAt, price 추출

---

## 🔄 주요 플로우

### 1. 부품 시세 조회 플로우

```
PartsCategoryScreen (부품 시세 메인)
  └─ TabBar (CPU, GPU, RAM, Mainboard, SSD, PSU)
     └─ basePartsStreamProvider(category)
        └─ Firestore: base_parts where category == 'cpu'
           └─ GridView: BasePartCard 리스트
              └─ 클릭 → PriceHistoryScreen
```

### 2. 검색 플로우

```
검색바 클릭 (PartsCategoryScreen 또는 HomeScreen)
  └─ BasePartSearchScreen
     └─ 검색어 입력
        └─ searchBasePartsUseCase(query)
           └─ Firestore: base_parts.limit(200)
              └─ 클라이언트 측 필터링 (modelName, category)
                 └─ 검색 결과 리스트
                    └─ 클릭 → ListingsByBasePartScreen
```

### 3. 가격 추이 플로우

```
BasePartCard 클릭
  └─ PriceHistoryScreen(basePart)
     └─ priceHistoryFutureProvider(basePartId)
        └─ getPriceHistoryUseCase
           └─ Firestore: listings
              where partId == basePartId
              where status == 'sold'
              orderBy soldAt
              limit 100
              └─ 가격 데이터 추출 → PriceHistoryChart
```

### 4. 매물 보기 플로우

```
PriceHistoryScreen → "매물 보기" 버튼
  └─ ListingsByBasePartScreen(basePartId, partName)
     └─ listingsByBasePartIdProvider
        └─ Firestore: listings where basePartId == basePartId
           └─ 실제 판매 중인 매물 목록
```

---

## 📡 Firestore 쿼리 분석

### 1. 카테고리별 부품 조회

```dart
// part_remote_datasource.dart:31
Stream<List<BasePartModel>> getBasePartsByCategory(String category) {
  return _firestore
      .collection('base_parts')
      .where('category', isEqualTo: category)
      .orderBy('listingCount', descending: true)  // 매물 많은 순
      .snapshots()
      .map((snapshot) => snapshot.docs.map(...).toList());
}
```

**특징**:
- ✅ 실시간 스트림 (StreamProvider)
- ✅ 매물 개수 기준 정렬
- ⚠️ 인덱스 필요: `base_parts` (category, listingCount DESC)

### 2. 부품 검색

```dart
// part_remote_datasource.dart:76
Future<List<BasePartModel>> searchBaseParts(String query) async {
  // 1. 상위 200개 가져오기
  final snapshot = await _firestore
      .collection('base_parts')
      .orderBy('listingCount', descending: true)
      .limit(200)
      .get();

  // 2. 클라이언트 측 필터링
  final lowerQuery = query.toLowerCase();
  final results = snapshot.docs
      .map((doc) => BasePartModel.fromFirestore(doc))
      .where((part) =>
          part.modelName.toLowerCase().contains(lowerQuery) ||
          part.category.toLowerCase().contains(lowerQuery))
      .toList();

  return results;
}
```

**특징**:
- ⚠️ **클라이언트 측 필터링** (Firestore 제약 때문)
- ⚠️ 최대 200개만 검색 가능
- ⚠️ 성능 문제 가능 (모든 문서 다운로드 후 필터링)
- 💡 **개선 필요**: Algolia 같은 검색 엔진 도입 고려

### 3. 가격 이력 조회

```dart
// part_remote_datasource.dart:42
Future<List<Map<String, dynamic>>> getPriceHistory(String partId) async {
  final querySnapshot = await _firestore
      .collection('listings')
      .where('partId', isEqualTo: partId)
      .where('status', isEqualTo: 'sold')
      .orderBy('soldAt', descending: false)
      .limit(100)
      .get();

  final pricePoints = <Map<String, dynamic>>[];
  for (final doc in querySnapshot.docs) {
    final data = doc.data();
    final soldAt = data['soldAt'] as Timestamp?;
    final price = data['price'] as num?;

    if (soldAt != null && price != null) {
      pricePoints.add({
        'date': soldAt.toDate().toIso8601String(),
        'price': price.toDouble(),
        'count': 1,
      });
    }
  }
  return pricePoints;
}
```

**특징**:
- ✅ 판매 완료된 매물에서 가격 데이터 추출
- ⚠️ **partId vs basePartId 혼동 가능**
  - `listings.partId`가 실제로는 `basePartId`를 의미하는지 확인 필요
- ⚠️ 인덱스 필요: `listings` (partId, status, soldAt)
- 💡 **개선 필요**: 별도 price_history 컬렉션 고려

---

## 🎨 UI 컴포넌트

### 1. PartsCategoryScreen

**경로**: `lib/features/parts_price/presentation/screens/part_category_screen.dart`

**기능**:
- TabController로 6개 카테고리 전환 (CPU, GPU, RAM, Mainboard, SSD, PSU)
- 검색바 (BasePartSearchScreen으로 이동)
- GridView로 BasePartCard 2열 표시
- RefreshIndicator (당겨서 새로고침)

**Provider 사용**:
```dart
final selectedCategory = ref.watch(selectedPartCategoryProvider);
final basePartsAsync = ref.watch(basePartsStreamProvider(category));
```

### 2. BasePartSearchScreen

**경로**: `lib/features/parts_price/presentation/screens/base_part_search_screen.dart`

**기능**:
- 검색어 입력 TextField
- 검색 버튼
- 검색 결과 리스트 (BasePartCard 형태)
- 빈 상태 UI (검색 전, 결과 없음)
- 카테고리 아이콘 자동 매칭

**플로우**:
```
검색어 입력 → searchBasePartsUseCase 호출 → 결과 표시 → 선택 → ListingsByBasePartScreen
```

### 3. PriceHistoryScreen

**경로**: `lib/features/parts_price/presentation/screens/price_history_screen.dart`

**기능**:
- 부품 기본 정보 Card (카테고리, 모델명, 최저가, 평균가, 매물 개수)
- 가격 추이 차트 (PriceHistoryChart)
- "매물 보기" 버튼 (ListingsByBasePartScreen으로 이동)

**Provider 사용**:
```dart
final priceHistoryAsync = ref.watch(priceHistoryFutureProvider(basePart.basePartId));
```

### 4. BasePartCard

**경로**: `lib/features/parts_price/presentation/widgets/base_part_card.dart`

**표시 정보**:
- 부품 모델명
- 최저가
- 매물 개수
- 클릭 → PriceHistoryScreen

### 5. PriceHistoryChart

**경로**: `lib/features/parts_price/presentation/widgets/price_history_chart.dart`

**기능**:
- fl_chart 사용
- 가격 추이 라인 차트
- 날짜 축, 가격 축

---

## ⚠️ 현재 문제점 및 개선 필요 사항

### 1. 미사용 코드 ⚠️

**문제**:
- `PartEntity` (CPU/GPU/Mainboard 상세 스펙)가 완전히 정의되어 있지만 사용되지 않음
- `PartModel` (복잡한 파싱 로직 포함)이 미사용
- `GetPartByIdUseCase`가 미사용
- `cpu_details_widget.dart`, `gpu_details_widget.dart`, `mainboard_details_widget.dart` 미사용

**개선안**:
1. **부품 상세 페이지 추가**
   - BasePartCard 클릭 → PriceHistoryScreen 대신
   - BasePartCard 클릭 → **PartDetailScreen** (새로 구현)
   - PartDetailScreen에서 CPU 스펙, GPU 스펙 등을 상세히 표시
   - 기존 DetailsWidget 활용

2. **데이터 구조 명확화**
   - `base_parts`: 부품 요약 정보 (가격, 매물 개수)
   - `parts`: 부품 상세 스펙 (CPU 코어/클럭, GPU VRAM 등)
   - 관계: `parts.basePartId` → `base_parts.basePartId`

3. **사용 여부 결정**
   - 상세 스펙이 필요 없다면: PartEntity, PartModel 제거
   - 상세 스펙이 필요하다면: PartDetailScreen 구현

### 2. 검색 성능 문제 ⚠️

**문제**:
- 클라이언트 측 필터링 (200개 문서 전체 다운로드)
- Firestore 쿼리 제약으로 full-text search 불가능
- 대소문자, 띄어쓰기 처리 제한적

**개선안**:
1. **Algolia 도입**
   ```dart
   // Algolia 설정
   final algolia = Algolia.init(
     applicationId: 'YOUR_APP_ID',
     apiKey: 'YOUR_API_KEY',
   );

   // 검색
   final query = algolia.instance.index('base_parts').query(searchText);
   final results = await query.getObjects();
   ```

2. **Cloud Functions + Full-Text Search**
   - Cloud Functions에서 searchParts 구현
   - Firestore의 array-contains, in 쿼리 활용
   - 또는 Elasticsearch 연동

3. **검색 인덱스 개선**
   - base_parts에 `searchKeywords` 필드 추가
   - 예: `["rtx", "4090", "nvidia", "gpu"]`
   - `array-contains-any` 쿼리 사용

### 3. 가격 이력 데이터 구조 ⚠️

**문제**:
- listings 컬렉션에서 soldAt, price를 실시간으로 조회
- 가격 이력 조회마다 listings 전체 스캔
- 집계 데이터가 없음 (일별, 주별, 월별)

**개선안**:
1. **별도 price_history 컬렉션 생성**
   ```firestore
   price_history/{basePartId}/daily/{date}
   {
     date: "2025-11-04",
     lowestPrice: 650000,
     averagePrice: 680000,
     transactionCount: 5,
     prices: [650000, 670000, 680000, 690000, 700000]
   }
   ```

2. **Cloud Functions 트리거**
   - Listing이 sold 상태로 변경될 때
   - price_history 자동 업데이트

3. **집계 기간 제공**
   - 일별, 주별, 월별 선택 가능
   - 더 빠른 차트 렌더링

### 4. 카테고리 일관성 ⚠️

**문제**:
- 일부는 'mainboard', 일부는 'mb'
- 일부는 'psu', 일부는 'power'
- 대소문자 처리 불일치

**개선안**:
1. **Enum으로 통일**
   ```dart
   enum PartCategory {
     cpu('CPU'),
     gpu('GPU'),
     mainboard('메인보드'),  // 'mb' 대신 'mainboard'로 통일
     ram('RAM'),
     ssd('SSD'),
     psu('파워'),           // 'power' 대신 'psu'로 통일
     cooler('쿨러'),
     pccase('케이스');

     final String displayName;
     const PartCategory(this.displayName);
   }
   ```

2. **마이그레이션 스크립트**
   - Firestore 데이터 일괄 수정
   - 'mb' → 'mainboard'
   - 'power' → 'psu'

### 5. basePartId vs partId 혼동 ⚠️

**문제**:
- listings 컬렉션의 `partId` 필드가 실제로는 `basePartId`를 의미하는지 불명확
- getPriceHistory에서 `partId`로 조회하지만, 실제로는 basePartId여야 함

**개선안**:
1. **필드명 명확화**
   - listings에 `basePartId` 필드 추가
   - `partId`는 상세 스펙의 ID로 사용 (미래 확장성)

2. **데이터 관계 문서화**
   ```
   base_parts (부품 요약)
     ↑
     |--- listings.basePartId (판매 매물)
     |--- parts.basePartId (상세 스펙)
   ```

### 6. Riverpod Provider 구조 개선 💡

**현재**:
```dart
// part_provider.dart
final selectedPartCategoryProvider = StateProvider<String>((ref) => 'cpu');
final basePartsStreamProvider = StreamProvider.family<List<BasePartEntity>, String>(...);
final priceHistoryFutureProvider = FutureProvider.family<List<PricePointEntity>, String>(...);
```

**개선안**:
1. **AsyncNotifier 사용**
   - 더 나은 상태 관리
   - 로딩, 에러 상태 명확화

2. **Provider 그룹화**
   - 카테고리 관련 provider
   - 검색 관련 provider
   - 가격 이력 관련 provider

---

## 💡 개선 로드맵 제안

### Phase 1: 즉시 개선 가능 (1-2일)

1. ✅ 검색바 base_part_search로 통일 (완료)
2. 카테고리 일관성 개선 ('mb' → 'mainboard', 'power' → 'psu')
3. basePartId vs partId 명확화
4. 미사용 코드 제거 또는 활용 결정

### Phase 2: 성능 개선 (3-5일)

1. Algolia 검색 도입
2. price_history 컬렉션 생성 + Cloud Functions 트리거
3. Firestore 인덱스 최적화
4. 이미지 최적화 (CachedNetworkImage)

### Phase 3: 기능 확장 (1주)

1. 부품 상세 페이지 구현 (PartDetailScreen)
2. CPU/GPU/Mainboard DetailsWidget 활용
3. 부품 비교 기능
4. 가격 알림 기능 (특정 가격 이하면 알림)

### Phase 4: 데이터 품질 (진행 중)

1. base_parts 자동 집계 (Cloud Functions)
2. 가격 이력 데이터 정제
3. 이상치 제거 (outlier detection)
4. 부품 이미지 크롤링 자동화

---

## 📈 현재 사용 통계

### 컬렉션별 역할

| 컬렉션 | 용도 | 현재 상태 |
|--------|------|----------|
| `base_parts` | 부품 요약 정보 (가격, 매물 개수) | ✅ 사용 중 |
| `parts` | 부품 상세 스펙 (CPU 코어, GPU VRAM 등) | ⚠️ 정의되어 있지만 미사용 |
| `listings` | 실제 판매 매물 | ✅ 사용 중 (가격 이력 소스) |
| `price_history` | 가격 추이 집계 | ❌ 없음 (개선 필요) |

### Provider 사용 현황

| Provider | 화면 | 상태 |
|----------|------|------|
| `basePartsStreamProvider` | PartsCategoryScreen | ✅ 사용 중 |
| `priceHistoryFutureProvider` | PriceHistoryScreen | ✅ 사용 중 |
| `searchBasePartsUseCaseProvider` | BasePartSearchScreen | ✅ 사용 중 |
| `getPartByIdUseCaseProvider` | - | ⚠️ 미사용 |

### UseCase 사용 현황

| UseCase | 설명 | 상태 |
|---------|------|------|
| `GetBasePartsByCategoryUseCase` | 카테고리별 부품 조회 | ✅ 사용 중 |
| `SearchBasePartsUseCase` | 부품 검색 | ✅ 사용 중 |
| `GetPriceHistoryUseCase` | 가격 이력 조회 | ✅ 사용 중 |
| `GetPartByIdUseCase` | 부품 상세 조회 | ⚠️ 미사용 |

---

## 🔗 관련 피처 연결

```
Parts Price (부품 시세)
  ├─ Listing (매물) ← ListingsByBasePartScreen
  ├─ Cart (장바구니) ← 매물에서 장바구니 담기
  ├─ Checkout (결제) ← 장바구니에서 결제
  └─ DragonBall (보관함) ← 결제 시 드래곤볼 선택
```

---

## 📝 결론

Parts Price 피처는 기본적인 부품 시세 조회, 검색, 가격 추이 기능이 잘 구현되어 있습니다.

**강점**:
- ✅ Clean Architecture 잘 적용됨
- ✅ Riverpod 상태 관리 체계적
- ✅ 실시간 스트림 활용
- ✅ 매물 연결이 자연스러움

**개선 필요**:
- ⚠️ 미사용 코드 정리 (PartEntity, PartModel, DetailsWidgets)
- ⚠️ 검색 성능 개선 (Algolia 도입)
- ⚠️ 가격 이력 데이터 구조 개선 (price_history 컬렉션)
- ⚠️ 카테고리 일관성 개선
- ⚠️ basePartId vs partId 명확화

**다음 단계**:
1. 개선 우선순위 결정
2. Phase별 구현 계획 수립
3. 데이터 마이그레이션 전략 수립

---

**작성자**: Claude Code
**문서 버전**: 1.0
