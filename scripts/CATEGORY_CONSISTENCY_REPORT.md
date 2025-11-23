# 🚨 카테고리 대소문자 불일치 문제 리포트

## 📊 현재 상황

### Firestore 실제 데이터 (508개)
```
"CPU"      : 308개  ← 대문자
"GPU"      : 189개  ← 대문자
"메인보드"   : 11개   ← 한글
```

### 앱 코드 (part_category_screen.dart:21)
```dart
final List<String> _categories = ['cpu', 'gpu', 'ram', 'mainboard', 'ssd', 'psu'];
                                  ↑      ↑      ↑      ↑
                                  소문자 사용
```

### 업로드 스크립트 (upload_excel_to_firestore.js:402)
```javascript
const files = [
  { path: '../datas/CPU.xlsx', category: 'cpu' },        ← 소문자
  { path: '../datas/GPU.xlsx', category: 'gpu' },        ← 소문자
  { path: '../datas/Mainboard.xlsx', category: 'mainboard' },  ← 소문자
];
```

---

## ⚠️ 문제점

### 1. 필터링 실패 가능성
**코드 위치**: `lib/features/listing/data/datasources/listing_remote_datasource.dart:102`
```dart
listings = listings.where((listing) => listing.category == category).toList();
//                                     ↑ 정확히 일치해야 함
```

**시나리오**:
- 앱에서 'cpu' 카테고리 선택 → Firestore 쿼리 없음 (대소문자 정확히 일치 필요)
- Firestore에는 "CPU"로 저장되어 있음
- 결과: 필터링 안 됨, 빈 리스트 반환

### 2. 기존 데이터와 신규 데이터 불일치
- **기존 508개**: "CPU", "GPU", "메인보드" (대문자/한글)
- **새로 업로드할 데이터**: 'cpu', 'gpu', 'mainboard' (소문자)
- **결과**: 같은 카테고리가 두 가지 형태로 중복 존재

---

## ✅ 해결 방안

### 방안 1: 기존 데이터를 소문자로 변환 (권장 ⭐)

**장점**:
- 앱 코드 수정 불필요
- 스크립트 수정 불필요
- 일관성 확보

**실행 방법**:
```bash
cd scripts
node fix_category_to_lowercase.js
```

**변환 내용**:
```
"CPU"    → "cpu"
"GPU"    → "gpu"
"메인보드" → "mainboard"
```

---

### 방안 2: 앱 코드를 대문자로 변경

**장점**:
- 기존 Firestore 데이터 유지

**단점**:
- 앱 코드 여러 곳 수정 필요
- 배포 후 기존 사용자 영향 가능성

**수정 필요 파일**:
- `lib/features/parts_price/presentation/screens/part_category_screen.dart`
- `lib/features/listing/presentation/providers/listing_provider.dart`
- 기타 category 사용하는 모든 위치

---

### 방안 3: 업로드 스크립트를 대문자로 변경

**장점**:
- 기존 데이터와 일관성 유지

**단점**:
- 앱 코드와 불일치 (앱은 소문자 사용 중)
- 필터링 여전히 안 됨

---

## 🎯 권장 해결책

### Step 1: 기존 데이터를 소문자로 변환 (스크립트 제공)
```bash
cd scripts
node fix_category_to_lowercase.js
```

### Step 2: 변환 결과 확인
```bash
node check_category_case.js
```

### Step 3: 예상 결과
```
✅ 카테고리 대소문자 일관성 문제 없음

📊 발견된 카테고리 값들:
  "cpu"       : 308개
  "gpu"       : 189개
  "mainboard" : 11개
```

### Step 4: 새 데이터 업로드 (소문자로 저장)
```bash
node upload_excel_to_firestore.js
```

---

## 📝 변환 스크립트

### fix_category_to_lowercase.js
이 스크립트는:
1. 모든 listings 문서를 순회
2. category 필드를 소문자로 변환
   - "CPU" → "cpu"
   - "GPU" → "gpu"
   - "메인보드" → "mainboard"
3. 배치 작업으로 효율적으로 업데이트
4. 진행 상황 표시

**안전 기능**:
- 드라이런 모드 지원 (실제 변경 전 미리보기)
- 백업 생성 옵션
- 변경 카운트 표시

---

## 🔍 추가 확인 사항

### 1. BaseParts 컬렉션도 확인 필요
baseParts 문서도 category 필드를 가질 수 있으므로 동일하게 확인 필요

### 2. Cloud Functions 영향
Functions에서 category를 하드코딩한 곳이 있는지 확인

### 3. 기타 컬렉션
- sellRequests
- notifications
- priceHistory

등에서도 category 필드 사용 여부 확인

---

## 📞 다음 단계

1. ✅ **현재 완료**: 문제 파악 및 분석
2. ⏳ **다음**: fix_category_to_lowercase.js 스크립트 실행
3. ⏳ **확인**: 변환 결과 검증
4. ⏳ **업로드**: 새 Excel 데이터 업로드

---

## 💡 예방 대책

향후 이런 문제를 방지하기 위해:

1. **TypeScript enum 사용** (Functions 코드)
2. **Dart enum 사용** (앱 코드)
3. **Validation 규칙** 추가 (Firestore Rules)
4. **단위 테스트** 작성

```typescript
// functions/src/types.ts
export enum PartCategory {
  CPU = 'cpu',
  GPU = 'gpu',
  RAM = 'ram',
  MAINBOARD = 'mainboard',
  SSD = 'ssd',
  PSU = 'psu',
}
```

```dart
// lib/core/enums/part_category.dart
enum PartCategory {
  cpu('cpu'),
  gpu('gpu'),
  ram('ram'),
  mainboard('mainboard'),
  ssd('ssd'),
  psu('psu');

  final String value;
  const PartCategory(this.value);
}
```
