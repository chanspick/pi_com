# 🐛 Listing 캐시 문제 디버깅 가이드

**문제**: 삭제된 listing ID가 계속 참조되어 "Document not found" 에러 발생
**확인 완료**: Firestore에 문서 없음, Favorites에도 없음
**원인**: 앱 로컬 캐시 또는 Riverpod 상태 캐싱

---

## 🔍 문제가 발생하는 위치 찾기

### 1. 에러 로그에서 확인할 정보
```
I/flutter (24958): 🔍 [ListingDataSource] Fetching listing with ID: f848cf62-...
                   ^^^ 어디서 이 함수를 호출했는지 확인

I/flutter (24958): ❌ [ListingDataSource] Document not found: f848cf62-...
```

**질문**:
- Home 화면에서 발생? → `product_list_section.dart`
- Favorites 화면에서 발생? → `favorites_screen.dart`
- ListingDetail 화면에서 발생? → 직접 접근 시
- 특정 카드 클릭 시? → 어느 카드인지

---

## 🧹 해결 방법 1: 앱 캐시 완전 삭제

### Android (추천)
```bash
# 방법 1: adb 명령어로 앱 데이터 완전 삭제
adb shell pm clear app.picom.team.pi_com

# 방법 2: 앱 언인스톨 후 재설치
flutter clean
flutter pub get
flutter run --uninstall-first
```

### iOS (해당되는 경우)
```bash
# 앱 삭제 후 재설치
flutter clean
flutter pub get
flutter run
```

### 개발 중 빠른 클리어
```bash
# 앱이 실행 중일 때
adb shell am force-stop app.picom.team.pi_com
adb shell pm clear app.picom.team.pi_com
flutter run
```

---

## 🔧 해결 방법 2: Firestore 오프라인 캐시 비활성화 (임시)

**파일 위치 찾기**:
```bash
# main.dart에서 Firestore 초기화 부분 찾기
grep -r "FirebaseFirestore.instance" lib/
```

**임시 해결책**: `main.dart` 또는 초기화 파일에 추가

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // 🔥 임시: Firestore 캐시 비활성화 (디버깅용)
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: false, // 로컬 캐시 비활성화
  );

  runApp(const MyApp());
}
```

**주의**:
- 오프라인 지속성이 비활성화됨
- 디버깅 후 다시 활성화 필요
- 프로덕션에서는 사용하지 말 것

---

## 🔍 해결 방법 3: 어디서 참조하는지 추적

### Home 화면 확인
**파일**: `lib/features/home/presentation/widgets/product_list_section.dart`

**확인 사항**:
```dart
final listingsAsync = ref.watch(
  listingsFutureProvider(
    ListingQueryParams(category: null, sortBy: '최신순'),
  ),
);
```

**디버그 로그 추가**:
```dart
listingsAsync.when(
  data: (listings) {
    print('🏠 [Home] Loaded ${listings.length} listings');
    for (var listing in listings) {
      print('  - ${listing.listingId}: ${listing.brand} ${listing.modelName}');
    }
    // ... 나머지 코드
  },
  // ...
)
```

---

### Riverpod Provider 캐시 강제 무효화

앱 시작 시 또는 특정 화면에서:
```dart
// 모든 listing 관련 provider 무효화
ref.invalidate(listingsFutureProvider);
ref.invalidate(listingProvider);
ref.invalidate(favoritesListingsProvider);
```

또는 **autoDispose 확인**:
```dart
// listing_provider.dart에서 확인
final listingsFutureProvider = FutureProvider.autoDispose.family<...>
                                              ^^^^^^^^^^^^
// autoDispose가 있어야 화면을 벗어날 때 자동으로 캐시 제거됨
```

---

## 🧪 디버깅 단계

### Step 1: 앱 데이터 완전 삭제 후 재시작
```bash
# 터미널에서 실행
adb shell pm clear app.picom.team.pi_com
flutter run
```

**결과 확인**:
- ✅ 에러 사라짐 → 로컬 캐시 문제였음
- ❌ 에러 계속 발생 → Step 2로

---

### Step 2: 에러가 발생하는 화면 정확히 파악

**질문에 답해주세요**:
1. 어느 화면에서 에러가 발생하나요?
   - [ ] Home 화면 (최신 상품 섹션)
   - [ ] Favorites 화면
   - [ ] ListingDetail 화면 (직접 접근)
   - [ ] 기타: _______

2. 카드를 클릭했을 때 발생하나요?
   - [ ] 예 → 어느 카드인지 (브랜드/모델명)
   - [ ] 아니요 → 화면 로드 시 자동 발생

3. 에러 로그 전체를 공유해주세요
   ```
   (여기에 붙여넣기)
   ```

---

### Step 3: 특정 listing ID 추적

**파일**: `lib/features/listing/data/datasources/listing_remote_datasource.dart:28`

**이미 추가된 로그 확인**:
```dart
print('🔍 [ListingDataSource] Fetching listing with ID: $listingId');
```

**추가 확인**: 이 로그 직전에 호출 스택 추가
```dart
@override
Stream<ListingModel> getListing(String listingId) {
  // 로깅 추가: 조회하는 listingId 확인
  print('🔍 [ListingDataSource] Fetching listing with ID: $listingId');
  print('📞 [ListingDataSource] Called from: ${StackTrace.current}'); // 호출 위치 추적

  return _firestore
      .collection('listings')
      .doc(listingId)
      .snapshots(includeMetadataChanges: false)
      .map((doc) {
    // ... 나머지 코드
  });
}
```

---

## 🎯 예상 원인 및 해결

### 원인 1: Firestore 로컬 캐시
**증상**: 앱 재시작 시에도 동일한 에러
**해결**: `adb shell pm clear` 또는 오프라인 캐시 비활성화

---

### 원인 2: Riverpod FutureProvider 캐싱
**증상**: 특정 화면을 다시 열 때 동일한 데이터
**해결**: `autoDispose` 확인 또는 `ref.invalidate()` 사용

---

### 원인 3: Home 화면의 getListings() 결과 캐싱
**증상**: Home 화면의 "최신 상품"에 삭제된 listing 표시
**해결**:
```dart
// product_list_section.dart
final listingsAsync = ref.watch(
  listingsFutureProvider(
    ListingQueryParams(category: null, sortBy: '최신순'),
  ),
);

// 화면 진입 시 강제 새로고침
@override
void initState() {
  super.initState();
  Future.microtask(() {
    ref.invalidate(listingsFutureProvider);
  });
}
```

---

### 원인 4: ListingCard에서 삭제된 listing 직접 참조
**증상**: 카드가 표시되고, 클릭 시 에러
**확인**:
```dart
// listing_card.dart:33
onTap: () {
  print('🖱️ [ListingCard] Clicked: ${listing.listingId}');
  Navigator.of(context).push(MaterialPageRoute(
    builder: (_) => ListingDetailScreen(listingId: listing.listingId),
  ));
},
```

---

## 🚀 권장 해결 순서

1. **즉시 실행** (30초):
   ```bash
   adb shell pm clear app.picom.team.pi_com
   flutter run
   ```

2. **에러 여전히 발생 시** (1분):
   - 에러 로그 전체 복사
   - 어느 화면에서 발생하는지 확인
   - 이 문서에 기록

3. **Firestore 캐시 비활성화** (2분):
   - `main.dart`에서 `persistenceEnabled: false` 추가
   - 앱 재시작
   - 에러 사라지는지 확인

4. **문제 지속 시**:
   - 호출 스택 추적 코드 추가
   - 로그 공유
   - 추가 디버깅

---

## 📞 추가 도움이 필요하면

다음 정보를 공유해주세요:
1. 어느 화면에서 에러 발생?
2. 에러 로그 전체
3. `adb shell pm clear` 실행 후에도 발생?
4. 새로 생성한 listing은 정상 표시되는지?

---

**작성일**: 2025-11-12
**마지막 업데이트**: 에러 원인 파악 후 추가 예정
