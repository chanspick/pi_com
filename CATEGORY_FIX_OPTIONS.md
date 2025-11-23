# 카테고리 대소문자 불일치 수정 방법

## 문제 상황
- Firestore에 저장된 listings: `"cpu"`, `"gpu"` (소문자)
- 앱에서 필터링할 때 사용: `"CPU"`, `"GPU"` (대문자)
- 결과: 카테고리 필터가 작동하지 않음

## 🔍 1단계: 현재 상태 확인

먼저 실제로 어떤 카테고리들이 저장되어 있는지 확인:

```bash
node scripts/check_listing_categories.js
```

## 해결 방법

### 옵션 A: Firestore 데이터 수정 (권장)
**장점**: 데이터 일관성 유지, 향후 문제 방지
**단점**: 한 번 실행 필요

#### 1. Dry run으로 먼저 확인 (변경 없이 미리보기)
```bash
node scripts/fix_listing_categories.js
```

#### 2. 실제로 적용
```bash
node scripts/fix_listing_categories.js --live
```

#### 매핑 규칙:
- `cpu` → `CPU`
- `gpu` → `GPU`
- `ram` → `RAM`
- `mainboard`, `motherboard` → `메인보드`
- `ssd`, `storage` → `저장장치`
- `psu`, `power` → `파워`

---

### 옵션 B: 앱 코드를 대소문자 무시하도록 수정
**장점**: Firestore 변경 불필요, 더 유연함
**단점**: 조금 더 복잡한 코드

#### 수정할 파일:
1. `lib/features/listing/data/datasources/listing_remote_datasource.dart`
2. `lib/features/listing/presentation/screens/part_shop_screen.dart` (또는 part_shop_screen_enhanced.dart)

#### 구현 방법:
카테고리 정규화 함수를 추가하고 Firestore 쿼리 전에 소문자로 변환

---

### 옵션 C: 하이브리드 (양쪽 다 수정)
**가장 안전한 방법**

1. Firestore 데이터를 대문자로 통일 (옵션 A)
2. 앱 코드에도 대소문자 무시 로직 추가 (옵션 B)

→ 기존 데이터와 새 데이터 모두 호환

---

## 추천 순서

1. **먼저 확인**: `node scripts/check_listing_categories.js`
2. **Dry run 테스트**: `node scripts/fix_listing_categories.js`
3. **실제 적용**: `node scripts/fix_listing_categories.js --live`
4. **앱 테스트**: Flutter 앱에서 카테고리 필터 작동 확인

---

## 향후 예방책

### 새로운 listing 업로드 시:
항상 대문자 카테고리 사용:
- ✅ `CPU`, `GPU`, `RAM`
- ❌ `cpu`, `gpu`, `ram`

### Firestore Rules로 검증 추가:
```javascript
match /listings/{listingId} {
  allow create, update: if request.resource.data.category in [
    'CPU', 'GPU', 'RAM', '메인보드', '저장장치', '파워', '케이스', '쿨러', '기타'
  ];
}
```

이렇게 하면 잘못된 카테고리로 업로드하는 것을 방지할 수 있습니다.
