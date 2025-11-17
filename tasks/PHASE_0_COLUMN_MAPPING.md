# 📋 PiCom 컬럼 매핑 테이블 (실제 데이터 기반)

## ============================================================================
## Phase 0: 엑셀 파일 수정 작업 가이드
## ============================================================================

### 🎯 작업 목표
추천 시스템을 위한 호환성 정보 컬럼 추가

---

## 1️⃣ CPU.xlsx

### ✅ 현재 있는 컬럼 (24개)
```
1. 판매글 게시일자
2. 날짜 선택
3. 브랜드             ← basePartId, brand 사용
4. 시리즈             ← basePartId, modelName 사용
5. 모델 번호           ← basePartId, modelName 사용
6. 접미사             ← basePartId, modelName 사용
7. 판매가             ← price
8. 다나와 검색
9. 신제품 판매가       ← referencePrice
10. 좋아요 수          ← likesCount
11. 채팅 수           ← chatCount
12. 조회수            ← viewCount
13. 미개봉 여부        ← isSealed (O/X)
14. 소유권 이전횟수    ← ownershipTransfers
15. AS기간           ← warrantyPeriod
16. 사용빈도          ← usageFrequency
17. 구매일           ← purchaseDate
18. 사진 개수
19. 파일명(복사용)
20. 사진1            ← imageUrls[0]
21. 사진2            ← imageUrls[1]
22. 사진3            ← imageUrls[2]
23. 사진4            ← imageUrls[3]
24. 사진5            ← imageUrls[4]
```

### 🆕 추가해야 할 컬럼 (1개)
```
25. 소켓
```

### 📝 작업 방법
1. CPU.xlsx 파일 열기
2. 24번 컬럼(사진5) 뒤에 **"소켓"** 컬럼 추가
3. 각 행에 소켓 정보 입력

### 📊 소켓 값 가이드

**AMD Ryzen (AM4 소켓)**
- Ryzen 1000 시리즈 (1200, 1300X, 1400, 1500X, 1600, 1700, 1800X 등) → `AM4`
- Ryzen 2000 시리즈 (2200G, 2400G, 2600, 2700, 2700X 등) → `AM4`
- Ryzen 3000 시리즈 (3100, 3300X, 3600, 3700X, 3800X, 3900X, 3950X 등) → `AM4`
- Ryzen 4000 시리즈 (4350G, 4650G, 4750G 등) → `AM4`
- Ryzen 5000 시리즈 (5600, 5600X, 5700X, 5800X, 5900X, 5950X 등) → `AM4`

**AMD Ryzen (AM5 소켓)**
- Ryzen 7000 시리즈 (7600, 7600X, 7700X, 7800X3D, 7900X, 7950X 등) → `AM5`
- Ryzen 9000 시리즈 (9700X, 9900X, 9950X 등) → `AM5`

**Intel Core (LGA1151 소켓)**
- 6세대: Core i3-6100, i5-6400, i7-6700K 등 → `LGA1151`
- 7세대: Core i3-7100, i5-7400, i7-7700K 등 → `LGA1151`
- 8세대: Core i3-8100, i5-8400, i7-8700K 등 → `LGA1151`
- 9세대: Core i3-9100, i5-9400F, i7-9700K, i9-9900K 등 → `LGA1151`

**Intel Core (LGA1200 소켓)**
- 10세대: Core i3-10100, i5-10400, i7-10700K 등 → `LGA1200`
- 11세대: Core i3-11100, i5-11400, i7-11700K 등 → `LGA1200`

**Intel Core (LGA1700 소켓)**
- 12세대: Core i3-12100, i5-12400, i5-12600K, i7-12700K, i9-12900K 등 → `LGA1700`
- 13세대: Core i5-13400, i5-13600K, i7-13700K, i9-13900K 등 → `LGA1700`
- 14세대: Core i5-14400, i5-14600K, i7-14700K, i9-14900K 등 → `LGA1700`

**기타**
- AMD Threadripper (1세대~3세대) → `TR4`
- AMD Threadripper (5세대) → `sTRX4`

### ✅ 예시 (샘플 데이터 기준)

| 브랜드 | 시리즈 | 모델 번호 | 접미사 | **소켓** |
|--------|--------|-----------|--------|----------|
| AMD Ryzen | 5 | 2600 | X | **AM4** |
| AMD Ryzen | 5 | 3500 | X | **AM4** |
| AMD Ryzen | 5 | 5600 | X | **AM4** |
| AMD Ryzen | 7 | 7700 | X | **AM5** |
| Intel Core | i5 | 10400 | F | **LGA1200** |
| Intel Core | i5 | 13600 | K | **LGA1700** |

---

## 2️⃣ GPU.xlsx

### ✅ 현재 있는 컬럼 (27개)
```
1. 판매글 게시일자
2. 날짜 선택
3. 브랜드             ← basePartId, modelName 사용
4. 제조사             ← brand 사용
5. 시리즈             ← basePartId, modelName 사용
6. 모델 번호           ← basePartId, modelName 사용
7. 접미사             ← basePartId, modelName 사용
8. 세부 모델명         ← modelName 사용
9. 메모리 용량         ← basePartId, modelName, vramSize 사용
10. 판매가            ← price
11. 다나와 검색
12. 신제품 판매가      ← referencePrice
13. 좋아요 수         ← likesCount
14. 채팅 수          ← chatCount
15. 조회수           ← viewCount
16. 미개봉 여부       ← isSealed
17. 소유권 이전횟수   ← ownershipTransfers
18. AS기간          ← warrantyPeriod
19. 사용빈도         ← usageFrequency
20. 구매일          ← purchaseDate
21. 사진 개수
22. 파일명(복사용)
23. 사진1           ← imageUrls[0]
24. 사진2           ← imageUrls[1]
25. 사진3           ← imageUrls[2]
26. 사진4           ← imageUrls[3]
27. 사진5           ← imageUrls[4]
```

### 🆕 추가해야 할 컬럼 (1개 - 선택사항)
```
28. TDP (W)
```

### 📝 작업 방법
**선택사항**: PSU 계산 정확도를 높이고 싶다면 추가
- 추가하지 않아도 추천 시스템은 작동 (기본값 사용)
- 추가하면 더 정확한 PSU 추천 가능

### 📊 TDP 값 가이드 (대략적 값)

**NVIDIA RTX 40 시리즈**
- RTX 4090: 450W
- RTX 4080: 320W
- RTX 4070 Ti: 285W
- RTX 4070: 200W
- RTX 4060 Ti: 160W
- RTX 4060: 115W

**NVIDIA RTX 30 시리즈**
- RTX 3090 Ti: 450W
- RTX 3090: 350W
- RTX 3080 Ti: 350W
- RTX 3080: 320W
- RTX 3070 Ti: 290W
- RTX 3070: 220W
- RTX 3060 Ti: 200W
- RTX 3060: 170W
- RTX 3050: 130W

**AMD Radeon RX 7000 시리즈**
- RX 7900 XTX: 355W
- RX 7900 XT: 300W
- RX 7800 XT: 263W
- RX 7700 XT: 245W
- RX 7600: 165W

**AMD Radeon RX 6000 시리즈**
- RX 6950 XT: 335W
- RX 6900 XT: 300W
- RX 6800 XT: 300W
- RX 6800: 250W
- RX 6750 XT: 250W
- RX 6700 XT: 230W
- RX 6650 XT: 180W
- RX 6600 XT: 160W
- RX 6600: 132W
- RX 6500 XT: 107W

**AMD Radeon RX 5000 시리즈**
- RX 5700 XT: 225W
- RX 5700: 180W
- RX 5600 XT: 150W
- RX 5500 XT: 130W

### ⚠️ 주의사항
- 정확한 TDP는 제조사마다 다를 수 있음
- 모를 경우 비워두면 됨 (스크립트가 기본값 사용)
- **지금은 건너뛰어도 OK!** (나중에 추가 가능)

---

## 3️⃣ Mainboard.xlsx

### ✅ 현재 있는 컬럼 (26개)
```
1. 판매글 게시일자
2. 날짜 선택
3. 제조사            ← basePartId, brand, modelName 사용
4. 시리즈            ← basePartId, modelName 사용
5. 칩셋             ← basePartId, modelName 사용
6. 모델명            ← basePartId, modelName 사용
7. 세부특징1         ← basePartId, modelName 사용
8. 세부특징2         ← basePartId, modelName 사용
9. 판매가            ← price
10. 다나와 검색
11. 신제품 판매가     ← referencePrice
12. 좋아요 수        ← likesCount
13. 채팅 수         ← chatCount
14. 조회수          ← viewCount
15. 미개봉 여부      ← isSealed
16. 소유권 이전횟수  ← ownershipTransfers
17. AS기간         ← warrantyPeriod
18. 사용빈도        ← usageFrequency
19. 구매일         ← purchaseDate
20. 사진 개수
21. 파일명(복사용)
22. 사진1          ← imageUrls[0]
23. 사진2          ← imageUrls[1]
24. 사진3          ← imageUrls[2]
25. 사진4          ← imageUrls[3]
26. 사진5          ← imageUrls[4]
```

### 🆕 추가해야 할 컬럼 (3개)
```
27. 소켓
28. 메모리 타입
29. 폼팩터
```

### 📝 작업 방법
1. Mainboard.xlsx 파일 열기
2. 26번 컬럼(사진5) 뒤에 3개 컬럼 추가
3. 각 행에 정보 입력

### 📊 값 가이드

#### 소켓 (CPU와 일치해야 함)
- AMD: `AM4`, `AM5`, `TR4`, `sTRX4`
- Intel: `LGA1151`, `LGA1200`, `LGA1700`, `LGA1851`

**칩셋별 소켓 매핑**
- A320, B350, X370, B450, X470, A520, B550, X570 → `AM4`
- A620, B650, X670, B850, X870 → `AM5`
- H310, B360, Z370, H370, B365, Z390 → `LGA1151`
- H410, B460, H470, Z490, B560, H510, H570, Z590 → `LGA1200`
- H610, B660, H670, Z690, B760, H770, Z790, B860, Z890 → `LGA1700`

#### 메모리 타입
- `DDR3`
- `DDR4`
- `DDR5`

**칩셋별 메모리 타입 (대부분의 경우)**
- A320, B350, X370, B450, X470, A520, B550, X570 → `DDR4`
- A620, B650, X670, B850, X870 → `DDR5` (일부 보드는 DDR4도 지원)
- H310, B360, Z370, H370, B365, Z390 → `DDR4`
- H410, B460, H470, Z490, B560, H510, H570, Z590 → `DDR4`
- H610, B660, H670, Z690 → `DDR4` 또는 `DDR5` (혼재)
- B760, H770, Z790, B860, Z890 → `DDR5` (일부 보드는 DDR4도 지원)

⚠️ **주의**: 정확한 메모리 타입은 제품 사양 확인 필요

#### 폼팩터
- `ATX` (표준, 305mm x 244mm)
- `mATX` (Micro-ATX, 244mm x 244mm)
- `Mini-ITX` (170mm x 170mm)
- `E-ATX` (Extended-ATX, 305mm x 330mm)

**세부특징에서 힌트 얻기**
- 세부특징에 "M-ATX" → `mATX`
- 세부특징에 "ITX" → `Mini-ITX`
- 세부특징에 "ATX" (단독) → `ATX`
- 특별한 언급 없으면 → `ATX` (대부분의 경우)

### ✅ 예시 (샘플 데이터 기준)

| 제조사 | 칩셋 | 모델명 | 세부특징1 | **소켓** | **메모리 타입** | **폼팩터** |
|--------|------|--------|-----------|----------|----------------|-----------|
| ASRock | 970 | EXtreme3 | - | **AM3+** | **DDR3** | **ATX** |
| ASRock | A320 | - | M-ATX | **AM4** | **DDR4** | **mATX** |
| ASUS | B550 | TUF Gaming | - | **AM4** | **DDR4** | **ATX** |
| MSI | Z790 | Gaming Plus | - | **LGA1700** | **DDR5** | **ATX** |

---

## 4️⃣ RAM.xlsx

### ✅ 현재 있는 컬럼 (26개)
```
1. 판매글 게시일자
2. 날짜 선택
3. 제조사            ← basePartId, brand, modelName 사용
4. 메모리 규격        ← basePartId, modelName, memoryType 사용 ⭐
5. 시리즈/모델명      ← modelName 사용
6. 클럭 (MHz)       ← basePartId, modelName, speed 사용
7. 용량 (GB)        ← basePartId, modelName, capacity 사용
8. 판매 개수         ← quantity (price 계산에 사용)
9. 판매가(개당)      ← pricePerUnit (price = 개당가 × 개수)
10. 다나와 검색
11. 신제품 판매가    ← referencePrice
12. 좋아요 수       ← likesCount
13. 채팅 수        ← chatCount
14. 조회수         ← viewCount
15. 미개봉 여부     ← isSealed
16. 소유권 이전횟수 ← ownershipTransfers
17. AS기간        ← warrantyPeriod
18. 사용빈도       ← usageFrequency
19. 구매일        ← purchaseDate
20. 사진 개수
21. 파일명(복사용)
22. 사진1         ← imageUrls[0]
23. 사진2         ← imageUrls[1]
24. 사진3         ← imageUrls[2]
25. 사진4         ← imageUrls[3]
26. 사진5         ← imageUrls[4]
```

### 🆕 추가해야 할 컬럼
**없음!** ✅ 이미 "메모리 규격" 컬럼이 있음 (DDR4, DDR5)

### ⚠️ 주의사항
- **메모리 규격**: `DDR4` 또는 `DDR5`로 정확히 입력
- **용량**: `8GB`, `16GB` 형식 (GB 포함)
- **클럭**: `3200`, `3600` (숫자만, 또는 `3200MHz` 형식)
- **판매가**: 개당 가격 × 판매 개수 = 총 가격으로 자동 계산됨

---

## 5️⃣ SSD.xlsx

### ✅ 현재 있는 컬럼 (24개)
```
1. 판매글 게시일자
2. 날짜 선택
3. 제조사           ← basePartId, brand, modelName 사용
4. 시리즈/모델명     ← basePartId, modelName 사용
5. 폼팩터           ← modelName 사용
6. 용량            ← basePartId, modelName, capacity 사용
7. 판매가           ← price
8. 다나와 검색
9. 신제품 판매가     ← referencePrice
10. 좋아요 수       ← likesCount
11. 채팅 수        ← chatCount
12. 조회수         ← viewCount
13. 미개봉 여부     ← isSealed
14. 소유권 이전횟수 ← ownershipTransfers
15. AS기간        ← warrantyPeriod
16. 사용빈도       ← usageFrequency
17. 구매일        ← purchaseDate
18. 사진 개수
19. 파일명(복사용)
20. 사진1         ← imageUrls[0]
21. 사진2         ← imageUrls[1]
22. 사진3         ← imageUrls[2]
23. 사진4         ← imageUrls[3]
24. 사진5         ← imageUrls[4]
```

### 🆕 추가해야 할 컬럼 (1개 - 선택사항)
```
25. 인터페이스
```

### 📝 작업 방법
**선택사항**: 추천 시스템에서 NVMe/SATA 구분하고 싶다면 추가
- 추가하지 않아도 추천 시스템은 작동
- 추가하면 더 정확한 호환성 체크 가능

### 📊 인터페이스 값 가이드
- `NVMe` (PCIe 인터페이스, M.2 또는 U.2)
- `SATA` (SATA 3.0, 2.5인치 또는 M.2)

**폼팩터로 추정**
- `M.2 (2280)`, `M.2 (2242)`, `M.2 NVMe` → 대부분 `NVMe`
- `M.2 SATA` → `SATA`
- `2.5인치` → `SATA`

### ⚠️ 주의사항
- **지금은 건너뛰어도 OK!** (나중에 추가 가능)
- 모를 경우 비워두면 됨

---

## ============================================================================
## Phase 0 체크리스트
## ============================================================================

### ✅ 필수 작업
- [ ] **CPU.xlsx**: "소켓" 컬럼 추가 및 데이터 입력
- [ ] **Mainboard.xlsx**: "소켓", "메모리 타입", "폼팩터" 컬럼 추가 및 데이터 입력
- [ ] **RAM.xlsx**: 수정 없음 (이미 완료)

### 🔲 선택 작업 (나중에 추가 가능)
- [ ] **GPU.xlsx**: "TDP (W)" 컬럼 추가 (PSU 계산 정확도 향상)
- [ ] **SSD.xlsx**: "인터페이스" 컬럼 추가 (NVMe/SATA 구분)

---

## ============================================================================
## 컬럼 매핑 요약표
## ============================================================================

### CPU
| 엑셀 컬럼 | 용도 | 예시 값 |
|-----------|------|---------|
| 브랜드 | basePartId, modelName, brand (파싱) | `AMD Ryzen` → brand: `AMD` |
| 시리즈 | basePartId, modelName | `5` |
| 모델 번호 | basePartId, modelName | `5600` |
| 접미사 | basePartId, modelName | `X` |
| **소켓** | **socket (호환성)** | **`AM4`, `AM5`, `LGA1700`** |

**basePartId**: `AMD_Ryzen_5_5600X`  
**modelName**: `AMD Ryzen 5 5600X`  
**brand**: `AMD` (파싱 필요)

---

### GPU
| 엑셀 컬럼 | 용도 | 예시 값 |
|-----------|------|---------|
| 브랜드 | basePartId, modelName | `NVIDIA GeForce` |
| 제조사 | brand | `ASUS`, `MSI` |
| 시리즈 | basePartId, modelName | `RTX` |
| 모델 번호 | basePartId, modelName | `3060` |
| 접미사 | basePartId, modelName | `Ti` |
| 메모리 용량 | basePartId, modelName, vramSize | `12GB` |
| **TDP (W)** | **tdp (PSU 계산)** | **`170` (숫자만)** |

**basePartId**: `NVIDIA_GeForce_RTX_3060_Ti_12GB`  
**modelName**: `NVIDIA GeForce RTX 3060 Ti 12GB`  
**brand**: `ASUS`  
**vramSize**: `12` (숫자 추출)

---

### Mainboard
| 엑셀 컬럼 | 용도 | 예시 값 |
|-----------|------|---------|
| 제조사 | basePartId, brand, modelName | `ASUS` |
| 시리즈 | basePartId, modelName | `TUF Gaming` |
| 칩셋 | basePartId, modelName | `B550` |
| 모델명 | basePartId, modelName | `Pro` |
| 세부특징1 | basePartId, modelName | `WiFi` |
| 세부특징2 | basePartId, modelName | `ATX` |
| **소켓** | **socket (CPU 호환성)** | **`AM4`, `LGA1700`** |
| **메모리 타입** | **memoryType (RAM 호환성)** | **`DDR4`, `DDR5`** |
| **폼팩터** | **formFactor (케이스 호환성)** | **`ATX`, `mATX`** |

**basePartId**: `ASUS_B550_TUF_Gaming_Pro_WiFi`  
**modelName**: `ASUS B550 TUF Gaming Pro WiFi`  
**brand**: `ASUS`

---

### RAM
| 엑셀 컬럼 | 용도 | 예시 값 |
|-----------|------|---------|
| 제조사 | basePartId, brand, modelName | `Samsung` |
| **메모리 규격** | **basePartId, modelName, memoryType** | **`DDR4`, `DDR5`** ✅ |
| 시리즈/모델명 | modelName | `Trident Z` |
| 클럭 (MHz) | basePartId, modelName, speed | `3200` |
| 용량 (GB) | basePartId, modelName, capacity | `16GB` |
| 판매 개수 | quantity | `2` |
| 판매가(개당) | pricePerUnit | `30000` |

**basePartId**: `Samsung_DDR4_16GB_3200MHz`  
**modelName**: `Samsung DDR4 16GB 3200MHz Trident Z`  
**brand**: `Samsung`  
**price**: `60000` (30000 × 2)

---

### SSD
| 엑셀 컬럼 | 용도 | 예시 값 |
|-----------|------|---------|
| 제조사 | basePartId, brand, modelName | `Samsung` |
| 시리즈/모델명 | basePartId, modelName | `980 PRO` |
| 폼팩터 | modelName | `M.2 (2280)` |
| 용량 | basePartId, modelName, capacity | `1TB`, `500GB` |
| **인터페이스** | **interface (호환성)** | **`NVMe`, `SATA`** |

**basePartId**: `Samsung_980_PRO_1TB`  
**modelName**: `Samsung 980 PRO M.2 (2280) 1TB`  
**brand**: `Samsung`

---

## ============================================================================
## Phase 0 완료 후 다음 단계
## ============================================================================

Phase 0 완료되면 알려주세요!
→ Phase 1 (수정된 업로드 스크립트) 작성 시작합니다.

질문 있으시면 언제든지 물어보세요! 🚀
