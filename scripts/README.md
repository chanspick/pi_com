# Scripts 사용 가이드

Firebase Firestore 데이터 관리를 위한 스크립트 모음입니다.

## 📋 목차

1. [필수 설정](#필수-설정)
2. [데이터 업로드](#데이터-업로드)
3. [데이터 삭제](#데이터-삭제)
4. [상태 관리](#상태-관리)
5. [유틸리티](#유틸리티)

---

## 필수 설정

### ServiceAccount Key 설정
모든 스크립트 실행 전에 `serviceAccountKey.json` 파일이 필요합니다.

```bash
# Firebase Console → Project Settings → Service Accounts → Generate New Private Key
# 다운로드한 파일을 scripts/ 폴더에 serviceAccountKey.json으로 저장
```

### Dependencies 설치
```bash
cd scripts
npm install
```

---

## 📤 데이터 업로드

### 1. 전체 데이터 순차 업로드 (메인)
**파일:** `upload_sequential.js`

모든 카테고리(CPU, GPU, Mainboard, SSD, RAM)를 순차적으로 업로드합니다.
- 50ms 간격으로 하나씩 업로드
- createdAt 기준 정렬 (오래된 것부터)
- Price Chart 그래프용 최적화

```bash
node upload_sequential.js
```

**처리 내용:**
- CPU: 거래완료, 예약중, 판매중 시트
- GPU: 거래완료, 예약중, 판매중 시트
- Mainboard: 거래완료, 예약중, 판매중 시트
- SSD: 거래완료, 예약중, 판매중 시트
- RAM: 판매중 시트만

**결과:**
- 약 700개 listings 업로드
- 각 listing마다 고유한 timestamp
- Cloud Functions가 자동으로 BasePart 생성

---

### 2. RAM 전용 업로드
**파일:** `upload_ram_only.js`

RAM 데이터만 업로드합니다. (RAM은 Excel 구조가 다름)
- '판매가(개당)' 필드 사용
- 판매중 시트만 처리

```bash
node upload_ram_only.js
```

---

### 3. 거래완료 데이터 처리 (그래프용)
**파일:** `upload_sold_transactions.js`

거래완료 시트 데이터를 처리합니다.
1. available 상태로 업로드 (그래프 데이터 생성)
2. 30초 대기 (BasePart 생성 대기)
3. sold 상태로 순차 변경

```bash
node upload_sold_transactions.js
```

**주의:** 즉시 sold로 전환되어 그래프에서 조작한 티가 날 수 있음
→ `mark_for_sold.js` 사용 권장

---

## 🗑️ 데이터 삭제

### 1. 전체 컬렉션 삭제
**파일:** `delete_collections.js`

listings, base_parts, priceHistory 컬렉션 전체 삭제

```bash
node delete_collections.js
```

**삭제 대상:**
- `listings` 컬렉션
- `base_parts` 컬렉션
- `priceHistory` 컬렉션

---

### 2. 전체 Listings만 삭제
**파일:** `delete_all_listings.js`

listings 컬렉션만 삭제 (base_parts, priceHistory 유지)

```bash
node delete_all_listings.js
```

---

### 3. RAM만 삭제
**파일:** `delete_ram_only.js`

RAM 카테고리 listings만 삭제

```bash
node delete_ram_only.js
```

---

## 🏷️ 상태 관리

### 1. Sold 마킹 (그래프 데이터 유지)
**파일:** `mark_for_sold.js`

현재 sold 상태인 listings를 available로 복원하고 마킹합니다.
- 그래프에 자연스럽게 표시
- 나중에 원할 때 sold로 전환 가능

```bash
node mark_for_sold.js
```

**추가 필드:**
- `markedForSold: true`
- `markedAt: timestamp`

---

### 2. 마킹된 Listings를 Sold로 전환
**파일:** `convert_marked_to_sold.js`

markedForSold가 true인 listings를 sold로 전환합니다.
- 100ms 간격으로 순차 처리
- 마킹 플래그 제거

```bash
node convert_marked_to_sold.js
```

---

### 3. Available → Sold 즉시 전환
**파일:** `change_to_sold.js`

모든 available listings를 sold로 즉시 전환합니다.

```bash
node change_to_sold.js
```

---

## 🔧 유틸리티

### 1. BasePart 수동 생성
**파일:** `trigger_basepart_generation.js`

모든 listings 기반으로 BasePart를 수동 생성합니다.
- Cloud Functions가 실행되지 않았을 때 사용

```bash
node trigger_basepart_generation.js
```

---

### 2. 이미지 업로드
**파일:** `upload_images_to_storage.js`

로컬 이미지를 Firebase Storage에 업로드합니다.

```bash
node upload_images_to_storage.js
```

**설정:**
- 이미지 폴더 경로 수정 필요
- Storage 버킷 경로: `listings/`

---

### 3. Firestore 데이터 확인
**파일:** `check_firestore_data.js`

Firestore 데이터를 조회하여 확인합니다.

```bash
node check_firestore_data.js
```

---

## 📊 일반적인 워크플로우

### 처음 데이터 업로드
```bash
# 1. 컬렉션 비우기 (선택사항)
node delete_collections.js

# 2. 전체 데이터 순차 업로드
node upload_sequential.js

# 3. Cloud Functions가 BasePart 자동 생성 (1-2분 대기)
```

### 거래완료 데이터 그래프 관리
```bash
# 1. 거래완료 데이터를 available로 업로드
node upload_sold_transactions.js

# 2. 즉시 sold 전환 방지 - 마킹하기
node mark_for_sold.js

# 3. 나중에 sold로 전환 (원할 때)
node convert_marked_to_sold.js
```

### RAM 데이터만 업데이트
```bash
# 1. 기존 RAM 삭제
node delete_ram_only.js

# 2. RAM 재업로드
node upload_ram_only.js
```

---

## ⚠️ 주의사항

1. **serviceAccountKey.json 보안**
   - `.gitignore`에 포함되어 있는지 확인
   - 절대 GitHub에 커밋하지 말 것

2. **데이터 삭제 전 백업**
   - 삭제 스크립트 실행 전 Firestore 콘솔에서 확인
   - 중요 데이터는 백업 권장

3. **Cloud Functions 대기 시간**
   - BasePart 자동 생성: 약 1-2분 소요
   - PriceHistory 업데이트: 실시간

4. **순차 업로드 시간**
   - 700개 데이터: 약 35초 (50ms × 700)
   - 중간에 중단하지 말 것

---

## 🔍 디버깅

### Firestore 데이터 확인
```bash
node check_firestore_data.js
```

### BasePart 수동 재생성
```bash
node trigger_basepart_generation.js
```

---

## 📝 사용 중인 스크립트

### 📤 업로드
- `upload_sequential.js` - 전체 순차 업로드
- `upload_ram_only.js` - RAM 전용
- `upload_sold_transactions.js` - 거래완료 처리

### 🗑️ 삭제
- `delete_collections.js` - 전체 컬렉션
- `delete_all_listings.js` - Listings만
- `delete_ram_only.js` - RAM만

### 🏷️ 상태 관리
- `mark_for_sold.js` - Sold 마킹
- `convert_marked_to_sold.js` - Sold 전환
- `change_to_sold.js` - 즉시 Sold

### 🔧 유틸리티
- `trigger_basepart_generation.js` - BasePart 생성
- `upload_images_to_storage.js` - 이미지 업로드
- `check_firestore_data.js` - 데이터 확인

---

## 💡 Tips

- **Price Chart 최적화**: `upload_sequential.js` 사용 (순차 업로드)
- **자연스러운 그래프**: `mark_for_sold.js` → 나중에 `convert_marked_to_sold.js`
- **빠른 테스트**: `delete_collections.js` → `upload_sequential.js`
- **RAM만 수정**: `delete_ram_only.js` → `upload_ram_only.js`
