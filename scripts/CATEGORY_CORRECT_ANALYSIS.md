# ✅ 카테고리 대소문자 정확한 분석 (수정본)

## 📊 현재 상황 (재확인)

### 1. Firestore 실제 데이터 ✅ 올바름
```
"CPU"      : 308개  ← 대문자
"GPU"      : 189개  ← 대문자
"메인보드"   : 11개   ← 한글
```

### 2. 앱 코드 기대값 ✅ 대문자 사용

**part_shop_screen.dart:334-339**
```dart
final categories = [
  'All',
  'CPU',        ← 대문자 ✅
  'GPU',        ← 대문자 ✅
  'RAM',        ← 대문자 ✅
  '메인보드',    ← 한글 ✅
  'SSD',
  '파워',
];
```

**part_shop_screen.dart:102-123**
```dart
String _mapCategoryFromUrl(String urlCategory) {
  switch (urlCategory.toLowerCase()) {
    case 'cpu':
      return 'CPU';        ← URL의 'cpu'를 'CPU'로 변환
    case 'gpu':
      return 'GPU';        ← URL의 'gpu'를 'GPU'로 변환
    case 'mainboard':
      return '메인보드';    ← URL의 'mainboard'를 '메인보드'로 변환
    ...
  }
}
```

### 3. 검색/필터 로직 ✅ 정확히 일치 필요

**listing_remote_datasource.dart:102**
```dart
listings = listings.where((listing) => listing.category == category).toList();
//                                     ↑
// Firestore의 category 값과 앱의 category 값이 정확히 일치해야 함
```

**흐름:**
1. UI에서 'CPU' 선택
2. `selectedCategoryProvider.state = 'CPU'` (대문자)
3. Firestore 쿼리: `listing.category == 'CPU'`
4. Firestore에 "CPU"로 저장된 데이터 반환
5. ✅ 정상 작동!

---

## ❌ 문제: 업로드 스크립트가 소문자로 저장하려고 함

### upload_excel_to_firestore.js:402-405
```javascript
const files = [
  { path: '../datas/CPU.xlsx', category: 'cpu' },          ← 소문자 ❌
  { path: '../datas/GPU.xlsx', category: 'gpu' },          ← 소문자 ❌
  { path: '../datas/Mainboard.xlsx', category: 'mainboard' },  ← 소문자 ❌
];
```

**만약 이대로 업로드하면:**
```
기존 데이터:
  "CPU": 308개    ← 앱에서 필터링됨 ✅

새로 업로드된 데이터:
  "cpu": 2000개   ← 앱에서 필터링 안 됨 ❌

결과:
  - 'CPU' 선택 시 기존 308개만 표시
  - 새 2000개는 보이지 않음
  - 사실상 데이터 유실
```

---

## ✅ 해결 방법: 스크립트를 대문자로 수정

### 수정할 파일: upload_excel_to_firestore.js

**1. main 함수의 files 배열 (402줄)**
```javascript
// ❌ 잘못된 코드 (현재)
const files = [
  { path: path.join(__dirname, '../datas/CPU.xlsx'), category: 'cpu' },
  { path: path.join(__dirname, '../datas/GPU.xlsx'), category: 'gpu' },
  { path: path.join(__dirname, '../datas/Mainboard.xlsx'), category: 'mainboard' },
];

// ✅ 올바른 코드 (수정)
const files = [
  { path: path.join(__dirname, '../datas/CPU.xlsx'), category: 'CPU' },
  { path: path.join(__dirname, '../datas/GPU.xlsx'), category: 'GPU' },
  { path: path.join(__dirname, '../datas/Mainboard.xlsx'), category: '메인보드' },
  { path: path.join(__dirname, '../datas/RAM.xlsx'), category: 'RAM' },      // 추가
  { path: path.join(__dirname, '../datas/SSD.xlsx'), category: 'SSD' },      // 추가
];
```

**2. RAM, SSD 지원 추가**

RAM과 SSD도 업로드하려면 다음 함수들 수정 필요:

**generateBasePartId (42줄)**
```javascript
case 'RAM': {  // 대문자
  const brand = sanitize(data['브랜드']);
  const type = sanitize(data['타입']);  // DDR4, DDR5
  const capacity = sanitize(data['용량']);
  const speed = sanitize(data['속도']);

  const parts = [brand, type, capacity, speed].filter(p => p);
  return parts.join('_');
}

case 'SSD': {  // 대문자
  const brand = sanitize(data['브랜드']);
  const type = sanitize(data['타입']);  // NVMe, SATA
  const capacity = sanitize(data['용량']);

  const parts = [brand, type, capacity].filter(p => p);
  return parts.join('_');
}
```

**generateModelName (87줄)**
```javascript
case 'RAM': {  // 대문자
  const brand = data['브랜드'] || '';
  const type = data['타입'] || '';
  const capacity = data['용량'] || '';
  const speed = data['속도'] || '';
  const modelName = data['모델명'] || '';

  return [brand, type, capacity, speed, modelName].filter(p => p).join(' ');
}

case 'SSD': {  // 대문자
  const brand = data['브랜드'] || '';
  const type = data['타입'] || '';
  const capacity = data['용량'] || '';
  const modelName = data['모델명'] || '';

  return [brand, type, capacity, modelName].filter(p => p).join(' ');
}
```

**extractBrand (130줄)**
```javascript
case 'RAM':  // 대문자
case 'SSD':  // 대문자
  return data['브랜드'] || data['제조사'] || '';
```

---

## 📊 예상 결과 (수정 후)

### 업로드 전 (현재)
```
Firestore:
  "CPU": 308개
  "GPU": 189개
  "메인보드": 11개
```

### 업로드 후 (수정된 스크립트 사용)
```
Firestore:
  "CPU": 308 + 2000 = 2308개      ✅ 정상 통합
  "GPU": 189 + 1800 = 1989개      ✅ 정상 통합
  "메인보드": 11 + 900 = 911개     ✅ 정상 통합
  "RAM": 1500개 (신규)            ✅
  "SSD": 1200개 (신규)            ✅
```

### 앱에서 필터링
```
'CPU' 선택 → 2308개 모두 표시    ✅
'GPU' 선택 → 1989개 모두 표시    ✅
'RAM' 선택 → 1500개 표시         ✅
```

---

## 🎯 정리

### 현재 상태
- ✅ **Firestore 데이터**: 대문자 "CPU", "GPU", "메인보드" (올바름)
- ✅ **앱 코드**: 대문자 'CPU', 'GPU', '메인보드' 사용 (올바름)
- ❌ **업로드 스크립트**: 소문자 'cpu', 'gpu', 'mainboard' (잘못됨)

### 해결책
1. **upload_excel_to_firestore.js 수정** (필수)
   - category 값을 대문자로 변경
   - RAM, SSD 지원 추가

2. **기존 데이터 변환 불필요** (이미 올바름)
   - 현재 Firestore 데이터는 그대로 유지
   - fix_category_to_lowercase.js 실행하지 않음 ⚠️

### 다음 단계
1. ✅ **현재 완료**: 문제 정확히 파악
2. ⏳ **다음**: upload_excel_to_firestore.js 수정
3. ⏳ **확인**: 수정된 스크립트로 테스트 업로드
4. ⏳ **업로드**: 실제 데이터 업로드

---

## ⚠️ 주의사항

1. **fix_category_to_lowercase.js 실행하지 마세요!**
   - 기존 데이터를 소문자로 바꾸면 앱에서 필터링 안 됨
   - 현재 데이터는 이미 올바른 형식

2. **대소문자 일관성 유지**
   - 모든 새 데이터는 대문자로 업로드
   - 'CPU', 'GPU', 'RAM', 'SSD', '메인보드', '파워' 등

3. **한글 카테고리 주의**
   - '메인보드' (한글) 그대로 사용
   - '파워' (한글) 그대로 사용
   - '저장장치' 대신 'SSD' 사용
