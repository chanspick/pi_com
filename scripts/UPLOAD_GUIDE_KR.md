# 📊 Listings 정보 업데이트 가이드

## 1️⃣ 현재 상태 확인

### Firestore Listings 컬렉션 현황
- **총 Listings**: 508개
- **카테고리별**:
  - CPU: 308개
  - GPU: 189개
  - 메인보드: 11개
- **상태별**:
  - available: 499개
  - sold_external: 7개
  - sold: 2개

### 사용 가능한 Excel 파일
```
datas/
├── CPU.xlsx          ✅ 업로드 준비됨
├── GPU.xlsx          ✅ 업로드 준비됨
├── Mainboard.xlsx    ✅ 업로드 준비됨
├── RAM.xlsx          ⚠️ 스크립트 수정 필요
├── SSD.xlsx          ⚠️ 스크립트 수정 필요
└── images/           📁 이미지 파일들
```

---

## 2️⃣ 업로드 프로세스

### 방법 1: 기존 데이터 유지 + 새 데이터 추가

**장점**: 기존 데이터 보존, 증분 업데이트
**단점**: 중복 체크 필요

```bash
cd scripts
node upload_excel_to_firestore.js
```

### 방법 2: 전체 데이터 초기화 후 업로드

**장점**: 깨끗한 데이터, 중복 없음
**단점**: 기존 데이터 삭제 (⚠️ 주의!)

```bash
# 1. 기존 listings 백업 (선택사항)
node backup_listings.js

# 2. listings 삭제
node delete_all_listings.js

# 3. 새 데이터 업로드
node upload_excel_to_firestore.js
```

---

## 3️⃣ 업데이트 전 체크리스트

### ✅ 필수 확인사항

- [ ] **판매자 ID 설정**
  `upload_excel_to_firestore.js` 파일 19번째 줄:
  ```javascript
  const SELLER_ID = 'G7BfeVct9kTL3SjdLJjD7qGJh313';  // ✅ 이미 설정됨
  ```

- [ ] **Firebase 인증**
  `scripts/serviceAccountKey.json` 파일 존재 확인

- [ ] **Excel 파일 준비**
  각 Excel 파일에 다음 시트가 있어야 함:
  - `거래완료`
  - `예약중`
  - `판매중`

- [ ] **필수 컬럼 확인**
  각 카테고리별로 필요한 컬럼이 있는지 확인

### 📋 CPU.xlsx 필수 컬럼
```
브랜드, 시리즈, 모델 번호, 접미사, 판매가, 신제품 판매가,
미개봉 여부, 좋아요 수, 채팅 수, 조회수, 사진1~5,
판매글 게시일자, 소유권 이전횟수, AS기간, 사용빈도, 구매일
```

### 📋 GPU.xlsx 필수 컬럼
```
브랜드, 제조사, 시리즈, 모델 번호, 접미사, 세부 모델명,
메모리 용량, 판매가, 신제품 판매가, 미개봉 여부,
좋아요 수, 채팅 수, 조회수, 사진1~5, 판매글 게시일자,
소유권 이전횟수, AS기간, 사용빈도, 구매일
```

### 📋 Mainboard.xlsx 필수 컬럼
```
제조사, 시리즈, 칩셋, 모델명, 세부특징1, 세부특징2,
판매가, 신제품 판매가, 미개봉 여부, 좋아요 수, 채팅 수,
조회수, 사진1~5, 판매글 게시일자, 소유권 이전횟수,
AS기간, 사용빈도, 구매일
```

---

## 4️⃣ 업로드 실행

### Step 1: 현재 상태 확인
```bash
cd scripts
node check_current_listings.js
```

### Step 2: Excel 구조 확인 (선택사항)
```bash
node check_excel_structure.js
```

### Step 3: 업로드 실행
```bash
node upload_excel_to_firestore.js
```

### 예상 출력:
```
🚀 Excel → Firestore 업로드 시작
============================================================

📊 처리 시작: CPU.xlsx (category: cpu)
============================================================

📋 시트 처리: 거래완료
  총 996개 행 발견
  ✅ 996개 업로드 완료

📋 시트 처리: 예약중
  총 999개 행 발견
  ✅ 999개 업로드 완료

📋 시트 처리: 판매중
  총 50개 행 발견
  ✅ 50개 업로드 완료

✅ CPU.xlsx 처리 완료: 총 2045개 업로드

[GPU.xlsx, Mainboard.xlsx 동일한 프로세스...]

============================================================
✅ 전체 업로드 완료: 총 3900개 Listing 생성
============================================================
```

---

## 5️⃣ 업로드 후 자동 처리

### Cloud Functions가 자동으로 수행하는 작업:

1. **baseParts 컬렉션 업데이트**
   - 각 basePartId별로 통계 계산
   - lowestPrice, averagePrice 업데이트
   - listingCount 업데이트

2. **priceHistory 생성**
   - 가격 변동 감지
   - 시간별 가격 기록 생성
   - 차트 데이터 준비

3. **알림 생성 (해당되는 경우)**
   - 가격 하락 알림
   - 새 상품 알림

---

## 6️⃣ 업로드 후 확인사항

### 1. Firestore Console 확인
```
https://console.firebase.google.com/project/picom-team/firestore
```
- `listings` 컬렉션 개수 확인
- `baseParts` 컬렉션 자동 생성 확인
- `priceHistory` 컬렉션 확인

### 2. 스크립트로 확인
```bash
# listings 개수 확인
node check_listings_count.js

# category별 통계
node check_listing_categories.js

# basePartId 연결 확인
node check_listing_baseparts.js
```

### 3. 앱에서 확인
- Flutter 앱 실행
- 파츠샵 화면에서 상품 목록 확인
- 가격 차트 확인
- 이미지 로딩 확인

---

## 7️⃣ 추가 작업: RAM, SSD 업로드

현재 `upload_excel_to_firestore.js`는 CPU, GPU, Mainboard만 지원합니다.
RAM, SSD를 추가하려면 스크립트 수정이 필요합니다.

### 수정 필요 위치:

**1. `generateBasePartId` 함수 (42번째 줄)**
```javascript
case 'ram': {
  const brand = sanitize(data['브랜드']);
  const type = sanitize(data['타입']);  // DDR4, DDR5
  const capacity = sanitize(data['용량']);  // 16GB, 32GB
  const speed = sanitize(data['속도']);  // 3200MHz, 5600MHz

  const parts = [brand, type, capacity, speed].filter(p => p);
  return parts.join('_');
}

case 'ssd': {
  const brand = sanitize(data['브랜드']);
  const type = sanitize(data['타입']);  // NVMe, SATA
  const capacity = sanitize(data['용량']);  // 500GB, 1TB

  const parts = [brand, type, capacity].filter(p => p);
  return parts.join('_');
}
```

**2. `generateModelName` 함수 (87번째 줄)**
```javascript
case 'ram': {
  const brand = data['브랜드'] || '';
  const type = data['타입'] || '';
  const capacity = data['용량'] || '';
  const speed = data['속도'] || '';
  const modelName = data['모델명'] || '';

  return [brand, type, capacity, speed, modelName].filter(p => p).join(' ');
}

case 'ssd': {
  const brand = data['브랜드'] || '';
  const type = data['타입'] || '';
  const capacity = data['용량'] || '';
  const modelName = data['모델명'] || '';

  return [brand, type, capacity, modelName].filter(p => p).join(' ');
}
```

**3. `extractBrand` 함수 (130번째 줄)**
```javascript
case 'ram':
case 'ssd':
  return data['브랜드'] || data['제조사'] || '';
```

**4. `main` 함수의 files 배열 (401번째 줄)**
```javascript
const files = [
  { path: path.join(__dirname, '../datas/CPU.xlsx'), category: 'cpu' },
  { path: path.join(__dirname, '../datas/GPU.xlsx'), category: 'gpu' },
  { path: path.join(__dirname, '../datas/Mainboard.xlsx'), category: 'mainboard' },
  { path: path.join(__dirname, '../datas/RAM.xlsx'), category: 'ram' },      // ✅ 추가
  { path: path.join(__dirname, '../datas/SSD.xlsx'), category: 'ssd' },      // ✅ 추가
];
```

---

## 8️⃣ 이미지 업로드

Excel의 `사진1`~`사진5` 컬럼에 파일명이 있다면, 실제 이미지를 Firebase Storage에 업로드해야 합니다.

### 방법 1: 수동 업로드
1. Firebase Console → Storage → listings 폴더
2. 이미지 파일 드래그 앤 드롭

### 방법 2: 스크립트 사용
```bash
node upload_images_to_storage.js
```

이 스크립트는:
- `datas/images/` 폴더의 모든 이미지 스캔
- Firebase Storage `listings/` 경로로 업로드
- 진행 상황 표시

---

## 9️⃣ 문제 해결

### Q: "판매자 ID를 설정해주세요" 에러
**A**: `upload_excel_to_firestore.js` 19번째 줄의 `SELLER_ID` 확인

### Q: 이미지가 표시되지 않음
**A**: Firebase Storage에 이미지 먼저 업로드 필요

### Q: baseParts가 생성되지 않음
**A**: Cloud Functions 배포 확인
```bash
firebase deploy --only functions
```

### Q: 중복 데이터가 생성됨
**A**: 기존 listings 삭제 후 재업로드
```bash
node delete_all_listings.js
node upload_excel_to_firestore.js
```

### Q: conditionScore가 이상하게 계산됨
**A**: Excel에 `conditionScore` 컬럼을 추가하여 직접 지정 가능

---

## 🔟 요약

### 빠른 시작 (기본 업로드)
```bash
# 1. 현재 상태 확인
cd scripts
node check_current_listings.js

# 2. Excel 업로드
node upload_excel_to_firestore.js

# 3. 결과 확인
node check_current_listings.js
```

### 완전 초기화 후 업로드
```bash
# 1. 백업 (선택)
node backup_listings.js

# 2. 삭제
node delete_all_listings.js

# 3. 업로드
node upload_excel_to_firestore.js

# 4. 확인
node check_current_listings.js
```

---

## 📞 추가 지원

- 스크립트 위치: `scripts/upload_excel_to_firestore.js`
- 가이드 문서: `scripts/EXCEL_UPLOAD_GUIDE.md`
- 현재 상태 확인: `scripts/check_current_listings.js`
