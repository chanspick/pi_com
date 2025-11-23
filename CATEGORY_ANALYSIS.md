# 카테고리 대소문자 불일치 분석

## 🔍 현재 상황

### Firestore 데이터:
```
총 507개 listings:
- "cpu" (소문자): 306개
- "gpu" (소문자): 189개
- "mainboard" (소문자): 11개
- "CPU" (대문자): 1개만
```

## 📊 각 기능별 카테고리 사용 현황

### 1. 🛒 **판매 요청 (Sell Request) 생성 시**

**파일**: `lib/features/sell_request/presentation/screens/part_search_screen.dart`

**드롭다운 값** (line 24-31):
```dart
final List<Map<String, String>> _categories = [
  {'value': 'cpu', 'label': 'CPU'},      // ← 소문자 value
  {'value': 'gpu', 'label': 'GPU'},      // ← 소문자 value
  {'value': 'mainboard', 'label': '메인보드'},
  {'value': 'ram', 'label': 'RAM'},
  {'value': 'ssd', 'label': 'SSD'},
  {'value': 'psu', 'label': '파워'},
];
```

**BasePart 생성 시** (line 98):
```dart
category: _selectedCategory.toUpperCase(),  // ← 대문자로 변환!
```

**결과**: `'cpu'` → `'CPU'`, `'gpu'` → `'GPU'` ✅ 대문자로 저장

---

### 2. 🏪 **부품 쇼핑 (Part Shop) 필터**

**파일**: `lib/features/listing/presentation/screens/part_shop_screen.dart`

**현재 필터 카테고리** (추정, part_shop_screen_enhanced.dart line 240 기준):
```dart
final categories = ['All', 'CPU', 'GPU', 'RAM', '메인보드', '저장장치', '파워', '기타'];
```

**URL 파라미터 매핑** (line 55-76):
```dart
String _mapCategoryFromUrl(String urlCategory) {
  switch (urlCategory.toLowerCase()) {
    case 'cpu': return 'CPU';    // ← 소문자 URL → 대문자로 변환
    case 'gpu': return 'GPU';    // ← 소문자 URL → 대문자로 변환
    // ...
  }
}
```

**Firestore 쿼리** (`lib/features/listing/data/datasources/listing_remote_datasource.dart` line 73-74):
```dart
if (category != null && category != 'All') {
  query = query.where('category', isEqualTo: category);  // ← 정확히 일치해야 함!
}
```

**결과**:
- 필터에서 `'CPU'` 선택 → Firestore에서 `category == 'CPU'` 검색
- 하지만 Firestore에는 `'cpu'`로 저장되어 있음 ❌ **매칭 안 됨!**

---

### 3. 🌐 **웹 랜딩 페이지 카테고리 링크**

**파일**: `lib/features/web_public/presentation/screens/landing_page_v2.dart`

**카테고리 버튼** (line 65-70):
```dart
final categories = [
  {'icon': Icons.memory, 'label': 'CPU', 'route': '${Routes.partShop}?category=cpu'},     // ← URL은 소문자
  {'icon': Icons.videogame_asset, 'label': 'GPU', 'route': '${Routes.partShop}?category=gpu'},  // ← URL은 소문자
  {'icon': Icons.developer_board, 'label': '메인보드', 'route': '${Routes.partShop}?category=mainboard'},
  // ...
];
```

**결과**: URL은 소문자 → part_shop_screen에서 대문자로 변환 → Firestore 쿼리는 대문자 사용 ❌

---

### 4. 📊 **부품 시세 (Parts Price) 화면**

**파일**: `lib/features/parts_price/presentation/screens/part_category_screen.dart`

**카테고리 리스트** (line 21):
```dart
final List<String> _categories = ['cpu', 'gpu', 'ram', 'mainboard', 'ssd', 'psu'];  // ← 소문자
```

**결과**: 소문자 사용 ✅ Firestore와 일치 (만약 listings를 조회한다면)

---

### 5. 🔧 **BasePart 리포지토리**

**파일**: `lib/core/repositories/base_part_repository.dart`

**카테고리 리스트** (line 55):
```dart
final categories = ['cpu', 'gpu', 'mainboard', 'ram', 'ssd', 'psu', 'cooler', 'case'];  // ← 소문자
```

**주석** (line 13):
```dart
/// [category] 부품 카테고리 (cpu, gpu, mainboard, ram, ssd, psu, cooler, case)  // ← 소문자
```

**결과**: 소문자 사용 ✅

---

## 🎯 문제 요약

| 기능 | 사용하는 카테고리 | Firestore 저장값 | 결과 |
|------|------------------|----------------|------|
| 판매 요청 생성 | `CPU`, `GPU` (대문자) | `cpu`, `gpu` (기존 데이터) | ❌ 새 데이터만 대문자 |
| 부품 쇼핑 필터 | `CPU`, `GPU` (대문자) | `cpu`, `gpu` (소문자) | ❌ 매칭 안 됨 |
| 웹 랜딩 URL | `?category=cpu` (소문자) | → 대문자 변환 → `CPU` | ❌ 쿼리 실패 |
| 부품 시세 | `cpu`, `gpu` (소문자) | `cpu`, `gpu` (소문자) | ✅ 일치 |

---

## 💡 해결 방법

### 옵션 A: Firestore 데이터 정규화 (권장) ⭐
**모든 listing의 category를 대문자로 통일**

```bash
# Dry run (변경 미리보기)
node scripts/fix_listing_categories.js

# 실제 적용
node scripts/fix_listing_categories.js --live
```

**장점**:
- 새로운 판매 요청과 일치 (BasePart는 이미 대문자 사용)
- UI 표시가 깔끔함 (`CPU`, `GPU`)
- 향후 일관성 유지

**단점**:
- 506개 문서 업데이트 필요 (한 번만)

---

### 옵션 B: 앱 코드 수정 (소문자로 통일)

**1. part_search_screen.dart 수정**: `.toUpperCase()` 제거
```dart
// 변경 전
category: _selectedCategory.toUpperCase(),

// 변경 후
category: _selectedCategory,  // 소문자 그대로 사용
```

**2. part_shop_screen.dart 필터 수정**:
```dart
// 변경 전
final categories = ['All', 'CPU', 'GPU', 'RAM', '메인보드', '저장장치', '파워', '기타'];

// 변경 후
final categories = ['All', 'cpu', 'gpu', 'ram', 'mainboard', 'ssd', 'psu', '기타'];
```

**3. 필터 매핑도 소문자로 변경**

**장점**:
- Firestore 변경 불필요
- 기존 데이터와 호환

**단점**:
- UI에 소문자 표시 (`cpu` vs `CPU`)
- 여러 파일 수정 필요
- 새로 생성되는 데이터와 기존 데이터 형식 다름

---

## 🎯 최종 권장사항

**옵션 A (Firestore 정규화)를 추천합니다:**

1. 스크립트로 기존 데이터를 대문자로 일괄 변경
2. 앱 코드는 현재 상태 유지 (이미 대문자 사용 중)
3. 향후 Firestore Rules로 검증 추가:

```javascript
// firestore.rules
match /listings/{listingId} {
  allow create, update: if request.resource.data.category in [
    'CPU', 'GPU', 'RAM', '메인보드', '저장장치', '파워', '케이스', '쿨러', '기타'
  ];
}
```

이렇게 하면:
- ✅ 기존 506개 listings가 정상 작동
- ✅ 새로운 listings도 대문자로 통일
- ✅ 필터/검색 모두 정상 작동
- ✅ 향후 잘못된 데이터 입력 방지
